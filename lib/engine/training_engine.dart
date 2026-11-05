import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/guitar_math.dart';
import '../models/note.dart';
import '../models/scale.dart';
import '../models/training_question.dart';
import '../models/tuning.dart';
import 'adaptive_planner.dart';
import 'training_audio_port.dart';

/// Training lifecycle.
enum TrainingState {
  idle,
  configuring,
  playingRoot,
  audioError,
  waitingAnswer,
  showingResult,
  completed,
}

typedef Delay = Future<void> Function(Duration duration);

/// Per-interval tally for a session.
class IntervalTally {
  final int firstTryCorrect;
  final int total;

  const IntervalTally(this.firstTryCorrect, this.total);

  double get accuracy => total == 0 ? 0 : firstTryCorrect / total * 100;

  IntervalTally operator +(IntervalTally other) => IntervalTally(
    firstTryCorrect + other.firstTryCorrect,
    total + other.total,
  );
}

/// Coordinates question generation, playback and answer evaluation.
///
/// The engine owns concrete fretboard positions. UI code never has to infer a
/// string or fret from a MIDI number, and every asynchronous operation is
/// guarded by a generation token so reset/start cannot resurrect old work.
///
/// Scoring model:
/// * [correctCount], [accuracy] and streaks count **first-try** answers only;
///   finding the pitch by trying several frets is practice, not recognition.
/// * A wrong attempt keeps the question open until [maxFailedAttempts] is
///   reached or the user calls [revealAnswer].
/// * A missed interval is reviewed again a few questions later in the same
///   session (with a different root), so weak spots get immediate repetition.
class TrainingEngine extends ChangeNotifier {
  TrainingEngine({Random? random, Delay? delay})
    : _random = random ?? Random(),
      _delay = delay ?? ((duration) => Future<void>.delayed(duration));

  static const Duration rootToTargetGap = Duration(milliseconds: 600);
  static const Duration targetToAnswerGap = Duration(milliseconds: 300);
  static const Duration correctResultHold = Duration(milliseconds: 1400);
  static const Duration revealResultHold = Duration(milliseconds: 2600);

  /// How many questions later a missed interval is reviewed.
  static const int reviewDistance = 2;

  final Random _random;
  final Delay _delay;

  String currentKey = 'C';
  ScaleType scaleType = ScaleType.major;
  Tuning currentTuning = Tuning.standard;
  DifficultyConfig difficulty = AppConstants.difficulties['easy']!;
  TrainingAudioPort? audioEngine;
  AnswerMode answerMode = AnswerMode.exactPitch;

  /// Re-ask missed intervals later in the same session.
  bool reviewMissedIntervals = true;

  /// Optional per-interval weights from [AdaptivePlanner.weightsFor]. Null
  /// gives every interval the same number of questions.
  Map<int, double>? intervalWeights;
  Map<int, int> _plannedAllocation = const {};

  /// Questions planned per interval for the current session.
  Map<int, int> get plannedAllocation => Map.unmodifiable(_plannedAllocation);

  int _questionsPerSession = AppConstants.defaultQuestionsPerSession;
  int get questionsPerSession => _questionsPerSession;
  set questionsPerSession(int value) {
    _questionsPerSession = value
        .clamp(AppConstants.minQuestions, AppConstants.maxQuestions)
        .toInt();
  }

  TrainingState _state = TrainingState.idle;
  int _currentQuestion = 0;
  int _correctCount = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  TrainingQuestion? _activeQuestion;
  FretPosition? _userAnswerPosition;
  int? _userAnswerMidi;
  bool _lastAnswerCorrect = false;
  PitchDirection? _lastDirection;
  DateTime? _sessionStartTime;
  DateTime? _sessionEndTime;
  DateTime? _answerPromptTime;
  double? _firstResponseSeconds;
  final List<double> _responseTimes = [];
  final List<QuestionOutcome> _outcomes = [];
  final Set<FretPosition> _wrongPositions = {};
  List<TrainingQuestion> _questionPool = [];
  Map<int, List<TrainingQuestion>> _questionsByInterval = {};
  int _poolIndex = 0;
  int _sessionQuestionCount = 0;
  int _generation = 0;
  int _failedAttempts = 0;
  bool _showCorrectPosition = false;
  bool _isReplaying = false;
  int maxFailedAttempts = 3;

  TrainingState get state => _state;
  int get currentQuestion => _currentQuestion;

  /// Number of questions answered correctly on the first attempt.
  int get correctCount => _correctCount;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  TrainingQuestion? get activeQuestion => _activeQuestion;
  FretPosition? get rootPosition => _activeQuestion?.root;
  FretPosition? get targetPosition => _activeQuestion?.target;
  FretPosition? get userAnswerPosition => _userAnswerPosition;
  int? get rootMidi => rootPosition?.midi;
  int? get targetMidi => targetPosition?.midi;
  int? get userAnswerMidi => _userAnswerMidi;
  bool get lastAnswerCorrect => _lastAnswerCorrect;

  /// Whether the last wrong attempt was below or above the target.
  PitchDirection? get lastDirection => _lastDirection;
  bool get isWaitingAnswer => _state == TrainingState.waitingAnswer;
  bool get isReplaying => _isReplaying;
  bool get showCorrectPosition => _showCorrectPosition;
  int get failedAttempts => _failedAttempts;

  /// Remaining wrong attempts before the answer is revealed, or null when
  /// answers are never revealed automatically.
  int? get attemptsRemaining => maxFailedAttempts == 0
      ? null
      : max(0, maxFailedAttempts - _failedAttempts);

  /// Positions the user already tried (and missed) for the active question.
  Set<FretPosition> get wrongPositions => Set.unmodifiable(_wrongPositions);

  /// True while a question is being announced and taps must not interrupt it.
  bool get isAnnouncing =>
      _state == TrainingState.configuring ||
      _state == TrainingState.playingRoot;

  bool get isSessionActive =>
      _state != TrainingState.idle &&
      _state != TrainingState.completed &&
      _state != TrainingState.audioError;

  int get totalQuestions =>
      _sessionQuestionCount == 0 ? questionsPerSession : _sessionQuestionCount;
  double get progress => totalQuestions == 0
      ? 0
      : (_currentQuestion / totalQuestions).clamp(0.0, 1.0).toDouble();

  /// First-try accuracy over answered questions, in percent.
  double get accuracy =>
      _currentQuestion == 0 ? 0 : _correctCount / _currentQuestion * 100;
  double get averageResponseTime => _responseTimes.isEmpty
      ? 0
      : _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;
  List<QuestionOutcome> get outcomes => List.unmodifiable(_outcomes);

  /// First-try results grouped by interval (semitones → tally).
  Map<int, IntervalTally> get intervalTallies {
    final result = <int, IntervalTally>{};
    for (final outcome in _outcomes) {
      result.update(
        outcome.intervalSemitones,
        (tally) => tally + IntervalTally(outcome.firstTryCorrect ? 1 : 0, 1),
        ifAbsent: () => IntervalTally(outcome.firstTryCorrect ? 1 : 0, 1),
      );
    }
    return result;
  }

  @visibleForTesting
  List<int> get questionPoolIntervals => List<int>.unmodifiable(
    _questionPool.map((question) => question.intervalSemitones),
  );

  @visibleForTesting
  List<TrainingQuestion> get questionPool => List.unmodifiable(_questionPool);

  Duration get sessionDuration => _sessionStartTime == null
      ? Duration.zero
      : (_sessionEndTime ?? DateTime.now()).difference(_sessionStartTime!);

  KeySignature get currentKeySignature => KeySignature(
    NoteName.values.firstWhere(
      (n) => n.sharpName == currentKey || n.flatName == currentKey,
      orElse: () => NoteName.c,
    ),
    scaleType,
  );

  void configure({required TrainingAudioPort engine, required Tuning tuning}) {
    audioEngine = engine;
    currentTuning = tuning;
  }

  Future<void> start() async {
    final engine = audioEngine;
    await engine?.stopAll();
    if (engine == null || !engine.isReady) return;
    final token = ++_generation;
    _state = TrainingState.configuring;
    _currentQuestion = 0;
    _correctCount = 0;
    _currentStreak = 0;
    _bestStreak = 0;
    _responseTimes.clear();
    _outcomes.clear();
    _sessionStartTime = DateTime.now();
    _sessionEndTime = null;
    _buildQuestionPool();
    notifyListeners();
    await _nextQuestion(token);
  }

  void _buildQuestionPool() {
    final keySig = currentKeySignature;
    final positionsByMidi = <int, List<FretPosition>>{};
    for (
      var string = difficulty.stringRange.$1;
      string <= difficulty.stringRange.$2;
      string++
    ) {
      for (
        var fret = difficulty.fretRange.$1;
        fret <= difficulty.fretRange.$2;
        fret++
      ) {
        final position = FretPosition.fromTuning(
          tuning: currentTuning,
          stringIndex: string,
          fret: fret,
        );
        if (!GuitarMath.isInKey(position.midi, keySig)) continue;
        positionsByMidi.putIfAbsent(position.midi, () => []).add(position);
      }
    }

    final pitches = positionsByMidi.keys.toList()..sort();
    final allowed = difficulty.allowedIntervals.toSet();
    final questionsByInterval = <int, List<TrainingQuestion>>{};

    void addPair(int rootMidi, int targetMidi) {
      final interval = targetMidi - rootMidi;
      // Every placement of the root pitch is a separate question so the
      // anchor moves around the fretboard instead of always sitting on the
      // highest string that happens to contain it.
      for (final root in positionsByMidi[rootMidi]!) {
        questionsByInterval
            .putIfAbsent(interval, () => [])
            .add(
              TrainingQuestion(
                root: root,
                target: _canonicalTarget(positionsByMidi[targetMidi]!),
                intervalSemitones: interval,
              ),
            );
      }
    }

    for (final rootMidi in pitches) {
      for (final targetMidi in pitches) {
        final interval = targetMidi - rootMidi;
        if (interval <= 0 || interval > 12) continue;
        if (allowed.contains(interval)) addPair(rootMidi, targetMidi);
      }
    }

    if (questionsByInterval.isEmpty && pitches.length >= 2) {
      // Sparse scales or narrow ranges can miss every configured interval;
      // fall back to adjacent scale steps so a session can still run.
      for (var i = 0; i < pitches.length - 1; i++) {
        final interval = pitches[i + 1] - pitches[i];
        if (interval <= 0 || interval > 12) continue;
        addPair(pitches[i], pitches[i + 1]);
      }
    }

    // Picking uniformly from every root/target pair biases the session toward
    // intervals that happen to have more physical placements in the selected
    // fret range (most visibly perfect fourths and fifths). Build the session
    // from interval buckets instead: every available interval gets the same
    // number of questions, with a difference of at most one.
    final intervals = questionsByInterval.keys.toList()..sort();
    for (final bucket in questionsByInterval.values) {
      bucket.shuffle(_random);
    }
    // Balanced by default; with [intervalWeights] (cross-session history)
    // weaker intervals receive extra questions while every interval keeps at
    // least one when the session is long enough.
    final allocation = AdaptivePlanner.allocate(
      intervals,
      questionsPerSession,
      intervalWeights,
      _random,
    );
    _plannedAllocation = allocation;
    final pool = <TrainingQuestion>[];
    for (final interval in intervals) {
      final bucket = questionsByInterval[interval]!;
      for (var i = 0; i < allocation[interval]!; i++) {
        pool.add(bucket[i % bucket.length]);
      }
    }
    pool.shuffle(_random);
    _spreadRepeats(pool);
    _questionPool = pool;
    _questionsByInterval = questionsByInterval;
    _poolIndex = 0;
    // A session keeps its requested length. Once the finite pool is
    // exhausted, _nextQuestion cycles through the same shuffled order.
    _sessionQuestionCount = questionsPerSession;
  }

  /// The target is judged by pitch, so its stored position only matters for
  /// exact-position mode; use the lowest fret as the canonical placement.
  FretPosition _canonicalTarget(List<FretPosition> placements) {
    return placements.reduce(
      (best, candidate) => candidate.fret < best.fret ? candidate : best,
    );
  }

  /// Avoids playing the exact same pitch pair twice in a row where possible.
  void _spreadRepeats(List<TrainingQuestion> pool) {
    bool samePair(TrainingQuestion a, TrainingQuestion b) =>
        a.root.midi == b.root.midi && a.target.midi == b.target.midi;
    for (var i = 1; i < pool.length; i++) {
      if (!samePair(pool[i], pool[i - 1])) continue;
      for (var j = i + 1; j < pool.length; j++) {
        if (!samePair(pool[j], pool[i - 1])) {
          final swap = pool[i];
          pool[i] = pool[j];
          pool[j] = swap;
          break;
        }
      }
    }
  }

  Future<void> _nextQuestion(int token) async {
    if (!_isCurrent(token)) return;
    if (_currentQuestion >= totalQuestions || _questionPool.isEmpty) {
      _state = TrainingState.completed;
      _sessionEndTime = DateTime.now();
      _activeQuestion = null;
      notifyListeners();
      return;
    }

    final question = _questionPool[_poolIndex % _questionPool.length];
    _poolIndex++;
    _activeQuestion = question;
    _userAnswerPosition = null;
    _userAnswerMidi = null;
    _lastAnswerCorrect = false;
    _lastDirection = null;
    _failedAttempts = 0;
    _wrongPositions.clear();
    _showCorrectPosition = false;
    _firstResponseSeconds = null;
    _answerPromptTime = null;
    _state = TrainingState.playingRoot;
    notifyListeners();

    if (!await _announce(question, token)) return;
    if (!_isCurrent(token)) return;
    await _delay(targetToAnswerGap);
    if (!_isCurrent(token)) return;
    _state = TrainingState.waitingAnswer;
    _answerPromptTime = DateTime.now();
    notifyListeners();
  }

  /// Plays root then target. Returns false (and enters [audioError]) when a
  /// cue could not be played; returns true when superseded so callers simply
  /// re-check their token.
  Future<bool> _announce(TrainingQuestion question, int token) async {
    final rootPlayed = await audioEngine!.playNote(question.root.midi);
    if (!_isCurrent(token)) return true;
    if (!rootPlayed) {
      _state = TrainingState.audioError;
      notifyListeners();
      return false;
    }
    await _delay(rootToTargetGap);
    if (!_isCurrent(token)) return true;
    final targetPlayed = await audioEngine!.playNote(question.target.midi);
    if (!_isCurrent(token)) return true;
    if (!targetPlayed) {
      _state = TrainingState.audioError;
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Accepts a concrete [FretPosition] or an int (MIDI) for pitch-class mode.
  ///
  /// Wrong answers keep the engine in [TrainingState.waitingAnswer] so the
  /// user can retry, up to [maxFailedAttempts] per question.  Once the limit
  /// is reached the correct position is revealed, the question is marked
  /// wrong, and the engine advances automatically.  Set [maxFailedAttempts]
  /// to 0 for the one-shot behaviour (advance after any answer).
  Future<void> submitAnswer(Object answer) async {
    final question = _activeQuestion;
    if (_state != TrainingState.waitingAnswer || question == null) {
      return;
    }
    if (answer is! FretPosition && answer is! int) return;

    final target = question.target;
    final FretPosition? position = answer is FretPosition ? answer : null;
    final midi = answer is int ? answer : position!.midi;

    // Every attempted fret should be audible. Start the cue immediately and
    // keep the judgement flow non-blocking so rapid retries stay responsive;
    // the audio engine fades the previous cue when a new one begins.
    _isReplaying = false;
    unawaited(audioEngine?.playNote(midi));

    _userAnswerPosition = position;
    _userAnswerMidi = midi;
    final isCorrect = switch (answerMode) {
      AnswerMode.exactPitch => midi == target.midi,
      AnswerMode.exactPosition => position != null && position == target,
      AnswerMode.pitchClass => midi % 12 == target.midi % 12,
    };
    _lastAnswerCorrect = isCorrect;
    _lastDirection = isCorrect
        ? null
        : midi == target.midi
        ? null
        : midi % 12 == target.midi % 12
        ? PitchDirection.samePitchClassWrongOctave
        : midi < target.midi
        ? PitchDirection.tooLow
        : PitchDirection.tooHigh;

    final isFirstAttempt = _failedAttempts == 0;
    if (isFirstAttempt && _answerPromptTime != null) {
      _firstResponseSeconds =
          DateTime.now().difference(_answerPromptTime!).inMilliseconds / 1000;
      _responseTimes.add(_firstResponseSeconds!);
    }

    if (isCorrect) {
      if (isFirstAttempt) {
        _correctCount++;
        _currentStreak++;
        _bestStreak = max(_bestStreak, _currentStreak);
      }
      await _finishQuestion(
        solved: true,
        revealed: false,
        hold: correctResultHold,
      );
      return;
    }

    // Wrong answer
    _currentStreak = 0;
    _failedAttempts++;
    if (position != null) _wrongPositions.add(position);

    if (maxFailedAttempts == 0) {
      // One-shot: advance immediately, never reveal.
      await _finishQuestion(
        solved: false,
        revealed: false,
        hold: correctResultHold,
      );
    } else if (_failedAttempts >= maxFailedAttempts) {
      await _finishQuestion(
        solved: false,
        revealed: true,
        hold: revealResultHold,
      );
    } else {
      // Stay on the same question – user can try again.
      notifyListeners();
    }
  }

  /// Gives up on the active question: reveals the target and moves on.
  Future<void> revealAnswer() async {
    if (_state != TrainingState.waitingAnswer || _activeQuestion == null) {
      return;
    }
    _currentStreak = 0;
    _lastAnswerCorrect = false;
    _lastDirection = null;
    unawaited(audioEngine?.playNote(_activeQuestion!.target.midi));
    await _finishQuestion(
      solved: false,
      revealed: true,
      hold: revealResultHold,
    );
  }

  Future<void> _finishQuestion({
    required bool solved,
    required bool revealed,
    required Duration hold,
  }) async {
    final question = _activeQuestion!;
    final firstTryCorrect = solved && _failedAttempts == 0;
    _outcomes.add(
      QuestionOutcome(
        question: question,
        attempts: _failedAttempts + (solved ? 1 : 0),
        firstTryCorrect: firstTryCorrect,
        solved: solved,
        revealed: revealed,
        firstResponseSeconds: _firstResponseSeconds,
      ),
    );
    if (!firstTryCorrect) _scheduleReview(question);
    _showCorrectPosition = revealed || solved;
    _currentQuestion++;
    _isReplaying = false;
    final token = _generation;
    _state = TrainingState.showingResult;
    notifyListeners();
    await _delay(hold);
    await _nextQuestion(token);
  }

  /// Replaces an upcoming question with another one of the missed interval
  /// (ideally from a different root) so the weak spot is heard again soon.
  void _scheduleReview(TrainingQuestion missed) {
    if (!reviewMissedIntervals) return;
    final remaining = totalQuestions - _currentQuestion - 1;
    if (remaining <= 0) return;
    final bucket = _questionsByInterval[missed.intervalSemitones];
    if (bucket == null || bucket.isEmpty) return;
    final candidates = bucket
        .where((candidate) => candidate.root.midi != missed.root.midi)
        .toList();
    final choices = candidates.isEmpty ? bucket : candidates;
    final replacement = choices[_random.nextInt(choices.length)];
    final int slot = _poolIndex + min<int>(reviewDistance, remaining - 1);
    final poolSlot = slot % _questionPool.length;
    // Don't overwrite a review that is already queued for the same interval.
    if (_questionPool[poolSlot].intervalSemitones == missed.intervalSemitones) {
      return;
    }
    _questionPool = [..._questionPool]..[poolSlot] = replacement;
  }

  Future<void> replayRoot() async {
    final midi = rootMidi;
    if (midi != null) await audioEngine?.playNote(midi);
  }

  Future<void> replayTarget() async {
    final midi = targetMidi;
    if (midi != null) await audioEngine?.playNote(midi);
  }

  /// Plays the root followed by the target again, without leaving the answer
  /// state. Answering mid-replay simply interrupts it.
  Future<void> replayQuestion() async {
    final question = _activeQuestion;
    if (question == null || _state != TrainingState.waitingAnswer) return;
    final token = _generation;
    _isReplaying = true;
    notifyListeners();
    await audioEngine?.playNote(question.root.midi);
    if (_isCurrent(token) && _isReplaying && _activeQuestion == question) {
      await _delay(rootToTargetGap);
    }
    if (_isCurrent(token) && _isReplaying && _activeQuestion == question) {
      await audioEngine?.playNote(question.target.midi);
    }
    if (_isCurrent(token) && _activeQuestion == question && _isReplaying) {
      _isReplaying = false;
      notifyListeners();
    }
  }

  /// Ends the session early, keeping the answered questions as the result.
  Future<void> finishEarly() async {
    if (!isSessionActive) return;
    _generation++;
    await audioEngine?.stopAll();
    _sessionQuestionCount = _currentQuestion;
    _state = TrainingState.completed;
    _sessionEndTime = DateTime.now();
    _activeQuestion = null;
    _isReplaying = false;
    notifyListeners();
  }

  void reset() {
    _generation++;
    _plannedAllocation = const {};
    _state = TrainingState.idle;
    _currentQuestion = 0;
    _sessionQuestionCount = 0;
    _correctCount = 0;
    _currentStreak = 0;
    _bestStreak = 0;
    _activeQuestion = null;
    _userAnswerPosition = null;
    _userAnswerMidi = null;
    _lastDirection = null;
    _questionPool = [];
    _questionsByInterval = {};
    _poolIndex = 0;
    _responseTimes.clear();
    _outcomes.clear();
    _wrongPositions.clear();
    _failedAttempts = 0;
    _showCorrectPosition = false;
    _isReplaying = false;
    _sessionStartTime = null;
    _sessionEndTime = null;
    _answerPromptTime = null;
    notifyListeners();
  }

  bool _isCurrent(int token) => token == _generation && !isDisposed;
  bool isDisposed = false;

  @override
  void dispose() {
    isDisposed = true;
    _generation++;
    super.dispose();
  }
}
