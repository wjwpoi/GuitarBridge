import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/guitar_math.dart';
import '../models/note.dart';
import '../models/scale.dart';
import '../models/training_question.dart';
import '../models/tuning.dart';
import 'audio_engine.dart';

/// Training lifecycle.
enum TrainingState {
  idle,
  configuring,
  playingRoot,
  waitingAnswer,
  showingResult,
  completed,
}

typedef Delay = Future<void> Function(Duration duration);

/// Coordinates question generation, playback and answer evaluation.
///
/// The engine owns concrete fretboard positions. UI code never has to infer a
/// string or fret from a MIDI number, and every asynchronous operation is
/// guarded by a generation token so reset/start cannot resurrect old work.
class TrainingEngine extends ChangeNotifier {
  TrainingEngine({Random? random, Delay? delay})
      : _random = random ?? Random(),
        _delay = delay ?? ((duration) => Future<void>.delayed(duration));

  final Random _random;
  final Delay _delay;

  String currentKey = 'C';
  ScaleType scaleType = ScaleType.major;
  Tuning currentTuning = Tuning.standard;
  DifficultyConfig difficulty = AppConstants.difficulties['easy']!;
  AudioEngine? audioEngine;
  AnswerMode answerMode = AnswerMode.exactPosition;

  int _questionsPerSession = AppConstants.defaultQuestionsPerSession;
  int get questionsPerSession => _questionsPerSession;
  set questionsPerSession(int value) {
    _questionsPerSession = value.clamp(
      AppConstants.minQuestions,
      AppConstants.maxQuestions,
    ).toInt();
  }

  TrainingState _state = TrainingState.idle;
  int _currentQuestion = 0;
  int _correctCount = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  FretPosition? _rootPosition;
  FretPosition? _targetPosition;
  FretPosition? _userAnswerPosition;
  int? _userAnswerMidi;
  bool _lastAnswerCorrect = false;
  DateTime? _sessionStartTime;
  DateTime? _questionStartTime;
  final List<double> _responseTimes = [];
  List<TrainingQuestion> _questionPool = [];
  int _poolIndex = 0;
  int _sessionQuestionCount = 0;
  int _generation = 0;

  TrainingState get state => _state;
  int get currentQuestion => _currentQuestion;
  int get correctCount => _correctCount;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  FretPosition? get rootPosition => _rootPosition;
  FretPosition? get targetPosition => _targetPosition;
  FretPosition? get userAnswerPosition => _userAnswerPosition;
  int? get rootMidi => _rootPosition?.midi;
  int? get targetMidi => _targetPosition?.midi;
  int? get userAnswerMidi => _userAnswerMidi;
  bool get lastAnswerCorrect => _lastAnswerCorrect;
  bool get isWaitingAnswer => _state == TrainingState.waitingAnswer;
  int get totalQuestions => _sessionQuestionCount == 0
      ? questionsPerSession
      : _sessionQuestionCount;
  double get progress => totalQuestions == 0
      ? 0
      : (_currentQuestion / totalQuestions).clamp(0.0, 1.0).toDouble();
  double get accuracy => _currentQuestion == 0
      ? 0
      : _correctCount / _currentQuestion * 100;
  double get averageResponseTime => _responseTimes.isEmpty
      ? 0
      : _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;
  Duration get sessionDuration => _sessionStartTime == null
      ? Duration.zero
      : DateTime.now().difference(_sessionStartTime!);

  KeySignature get currentKeySignature => KeySignature(
        NoteName.values.firstWhere(
          (n) => n.sharpName == currentKey || n.flatName == currentKey,
          orElse: () => NoteName.c,
        ),
        scaleType,
      );

  void configure({required AudioEngine engine, required Tuning tuning}) {
    audioEngine = engine;
    currentTuning = tuning;
  }

  Future<void> start() async {
    final engine = audioEngine;
    if (engine == null || !engine.isReady) return;
    final token = ++_generation;
    _state = TrainingState.configuring;
    _currentQuestion = 0;
    _correctCount = 0;
    _currentStreak = 0;
    _bestStreak = 0;
    _responseTimes.clear();
    _sessionStartTime = DateTime.now();
    _buildQuestionPool();
    notifyListeners();
    await _nextQuestion(token);
  }

  void _buildQuestionPool() {
    final keySig = currentKeySignature;
    final positions = <FretPosition>[];
    for (var string = difficulty.stringRange.$1;
        string <= difficulty.stringRange.$2;
        string++) {
      for (var fret = difficulty.fretRange.$1;
          fret <= difficulty.fretRange.$2;
          fret++) {
        positions.add(FretPosition.fromTuning(
          tuning: currentTuning,
          stringIndex: string,
          fret: fret,
        ));
      }
    }

    final roots = positions
        .where((position) => GuitarMath.isInKey(position.midi, keySig))
        .toList();
    final targets = roots;
    final pool = <TrainingQuestion>[];
    final allowed = difficulty.allowedIntervals.toSet();
    for (final root in roots) {
      for (final target in targets) {
        if (root == target) continue;
        final interval = ((target.midi - root.midi) % 12 + 12) % 12;
        if (allowed.contains(interval) && interval != 0) {
          pool.add(TrainingQuestion(
            root: root,
            target: target,
            intervalSemitones: interval,
          ));
        }
      }
    }

    if (pool.isEmpty && roots.length >= 2) {
      for (var i = 0; i < roots.length; i++) {
        final target = roots[(i + 1) % roots.length];
        pool.add(TrainingQuestion(
          root: roots[i],
          target: target,
          intervalSemitones: ((target.midi - roots[i].midi) % 12 + 12) % 12,
        ));
      }
    }

    pool.shuffle(_random);
    _questionPool = pool;
    _poolIndex = 0;
    // A session keeps its requested length. Once the finite pool is
    // exhausted, _nextQuestion cycles through the same shuffled order.
    _sessionQuestionCount = questionsPerSession;
  }

  Future<void> _nextQuestion(int token) async {
    if (!_isCurrent(token)) return;
    if (_currentQuestion >= totalQuestions || _questionPool.isEmpty) {
      _state = TrainingState.completed;
      notifyListeners();
      return;
    }

    final question = _questionPool[_poolIndex % _questionPool.length];
    _poolIndex++;
    _rootPosition = question.root;
    _targetPosition = question.target;
    _userAnswerPosition = null;
    _userAnswerMidi = null;
    _lastAnswerCorrect = false;
    _questionStartTime = DateTime.now();
    _state = TrainingState.playingRoot;
    notifyListeners();

    await audioEngine!.playNote(question.root.midi);
    if (!_isCurrent(token)) return;
    await _delay(const Duration(milliseconds: 600));
    if (!_isCurrent(token)) return;
    await audioEngine!.playNote(question.target.midi);
    if (!_isCurrent(token)) return;
    await _delay(const Duration(milliseconds: 400));
    if (!_isCurrent(token)) return;
    _state = TrainingState.waitingAnswer;
    notifyListeners();
  }

  /// Accepts a concrete [FretPosition]. The integer form is retained for
  /// service-level callers and tests; it intentionally uses pitch-class mode.
  Future<void> submitAnswer(Object answer) async {
    if (_state != TrainingState.waitingAnswer || _targetPosition == null) return;
    if (answer is! FretPosition && answer is! int) return;

    final target = _targetPosition!;
    final FretPosition? position = answer is FretPosition ? answer : null;
    final midi = answer is int ? answer : position!.midi;
    _userAnswerPosition = position;
    _userAnswerMidi = midi;
    final isCorrect = answer is int
        ? midi % 12 == target.midi % 12
        : answerMode == AnswerMode.exactPosition
            ? position != null &&
        position == target
            : midi % 12 == target.midi % 12;
    _lastAnswerCorrect = isCorrect;

    if (_questionStartTime != null) {
      _responseTimes.add(
        DateTime.now().difference(_questionStartTime!).inMilliseconds / 1000,
      );
    }
    if (isCorrect) {
      _correctCount++;
      _currentStreak++;
      _bestStreak = max(_bestStreak, _currentStreak);
    } else {
      _currentStreak = 0;
    }
    _currentQuestion++;
    final token = _generation;
    _state = TrainingState.showingResult;
    notifyListeners();
    await _delay(const Duration(milliseconds: 1200));
    await _nextQuestion(token);
  }

  Future<void> replayRoot() async {
    final midi = _rootPosition?.midi;
    if (midi != null) await audioEngine?.playNote(midi);
  }

  Future<void> replayTarget() async {
    final midi = _targetPosition?.midi;
    if (midi != null) await audioEngine?.playNote(midi);
  }

  void reset() {
    _generation++;
    _state = TrainingState.idle;
    _currentQuestion = 0;
    _sessionQuestionCount = 0;
    _correctCount = 0;
    _currentStreak = 0;
    _bestStreak = 0;
    _rootPosition = null;
    _targetPosition = null;
    _userAnswerPosition = null;
    _userAnswerMidi = null;
    _questionPool = [];
    _poolIndex = 0;
    _responseTimes.clear();
    _sessionStartTime = null;
    _questionStartTime = null;
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
