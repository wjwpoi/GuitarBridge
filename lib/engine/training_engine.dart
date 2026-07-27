import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../models/scale.dart';
import '../models/tuning.dart';
import '../core/constants.dart';
import '../core/guitar_math.dart';
import 'audio_engine.dart';

/// 训练状态机
enum TrainingState {
  idle,         // 未开始
  configuring,  // 配置中
  playingRoot,  // 播放基准音
  waitingAnswer,// 等待用户回答
  showingResult,// 显示结果
  completed,    // 本轮完成
}

/// 训练引擎（对应原 Swift TrainingEngine.swift）
/// 核心逻辑：调性建立 -> 物理锚点 -> 听觉挑战 -> 寻址判定
class TrainingEngine extends ChangeNotifier {
  final Random _random = Random();

  // === 配置状态 ===
  String currentKey = 'C';
  ScaleType scaleType = ScaleType.major;
  Tuning currentTuning = Tuning.standard;
  DifficultyConfig difficulty = AppConstants.difficulties['easy']!;
  int questionsPerSession = AppConstants.defaultQuestionsPerSession;
  AudioEngine? audioEngine;

  // === 训练状态 ===
  TrainingState _state = TrainingState.idle;
  int _currentQuestion = 0;
  int _correctCount = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int? _rootMidi;
  int? _targetMidi;
  int? _userAnswerMidi;
  bool _lastAnswerCorrect = false;

  // 已出过的题目（防止重复）
  final Set<String> _askedQuestions = {};

  // === 计时 ===
  DateTime? _sessionStartTime;
  DateTime? _questionStartTime;
  final List<double> _responseTimes = [];

  // === 公开 getters ===
  TrainingState get state => _state;
  int get currentQuestion => _currentQuestion;
  int get correctCount => _correctCount;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  int? get rootMidi => _rootMidi;
  int? get targetMidi => _targetMidi;
  int? get userAnswerMidi => _userAnswerMidi;
  bool get lastAnswerCorrect => _lastAnswerCorrect;
  bool get isWaitingAnswer => _state == TrainingState.waitingAnswer;

  int get totalQuestions => questionsPerSession;
  double get progress => questionsPerSession > 0
      ? _currentQuestion / questionsPerSession
      : 0;
  double get accuracy => _currentQuestion > 0
      ? _correctCount / _currentQuestion * 100
      : 0;
  double get averageResponseTime => _responseTimes.isNotEmpty
      ? _responseTimes.reduce((a, b) => a + b) / _responseTimes.length
      : 0;

  Duration get sessionDuration => _sessionStartTime != null
      ? DateTime.now().difference(_sessionStartTime!)
      : Duration.zero;

  KeySignature get currentKeySignature =>
      KeySignature(NoteName.values.firstWhere(
        (n) => n.sharpName == currentKey || n.flatName == currentKey,
        orElse: () => NoteName.c,
      ), scaleType);

  // === 配置 ===
  void configure({
    required AudioEngine engine,
    required Tuning tuning,
  }) {
    audioEngine = engine;
    currentTuning = tuning;
  }

  // === 开始训练 ===
  Future<void> start() async {
    if (audioEngine == null || !audioEngine!.isReady) return;

    _state = TrainingState.configuring;
    _currentQuestion = 0;
    _correctCount = 0;
    _currentStreak = 0;
    _bestStreak = 0;
    _askedQuestions.clear();
    _responseTimes.clear();
    _sessionStartTime = DateTime.now();
    notifyListeners();

    await _nextQuestion();
  }

  // === 下一题 ===
  Future<void> _nextQuestion() async {
    if (_currentQuestion >= questionsPerSession) {
      _state = TrainingState.completed;
      notifyListeners();
      return;
    }

    _state = TrainingState.playingRoot;
    notifyListeners();

    // 生成题目
    final keySig = currentKeySignature;
    final scaleNotes = keySig.notesInKey();

    // 选择基准音（在指定品位范围内）
    _rootMidi = _pickRootNote(scaleNotes);
    // 选择目标音（不同音程）
    _targetMidi = _pickTargetNote(_rootMidi!, scaleNotes);

    // 防止重复出题
    final questionKey = '${_rootMidi}_${_targetMidi}';
    if (_askedQuestions.contains(questionKey)) {
      await _nextQuestion(); // 重新生成
      return;
    }
    _askedQuestions.add(questionKey);

    _userAnswerMidi = null;
    _lastAnswerCorrect = false;
    _questionStartTime = DateTime.now();

    // 播放基准音
    await audioEngine!.playNote(_rootMidi!);
    await Future.delayed(const Duration(milliseconds: 600));

    // 播放目标音
    await audioEngine!.playNote(_targetMidi!);
    await Future.delayed(const Duration(milliseconds: 400));

    // 等待用户回答
    _state = TrainingState.waitingAnswer;
    notifyListeners();
  }

  /// 在调内选择一个基准音
  int _pickRootNote(List<int> scaleNotes) {
    final validNotes = scaleNotes.where((n) {
      // 必须在吉他范围内
      if (n < AppConstants.guitarLowestMidi ||
          n > AppConstants.guitarHighestMidi) {
        return false;
      }
      // 必须在难度指定的品位范围内有指板位置
      final positions = GuitarMath.findNoteOnFretboard(n, currentTuning);
      return positions.any((p) =>
          p.$2 >= difficulty.fretRange.$1 &&
          p.$2 <= difficulty.fretRange.$2);
    }).toList();

    if (validNotes.isEmpty) return scaleNotes.first;
    return validNotes[_random.nextInt(validNotes.length)];
  }

  /// 选择目标音（与基准音不同音程）
  int _pickTargetNote(int root, List<int> scaleNotes) {
    final semitonesInKey = scaleNotes
        .map((n) => ((n - root) % 12 + 12) % 12)
        .toSet()
        .toList()
      ..sort();

    // 过滤允许的音程
    final allowed = semitonesInKey
        .where((s) => difficulty.allowedIntervals.contains(s) && s != 0)
        .toList();

    if (allowed.isEmpty) return root + 7; // fallback: P5

    final semitone = allowed[_random.nextInt(allowed.length)];
    return root + semitone;
  }

  // === 用户回答 ===
  Future<void> submitAnswer(int answerMidi) async {
    if (_state != TrainingState.waitingAnswer) return;
    if (_targetMidi == null) return;

    _userAnswerMidi = answerMidi;
    _lastAnswerCorrect = (answerMidi % 12) == (_targetMidi! % 12);

    // 记录响应时间
    if (_questionStartTime != null) {
      _responseTimes.add(
        DateTime.now().difference(_questionStartTime!).inMilliseconds / 1000.0,
      );
    }

    if (_lastAnswerCorrect) {
      _correctCount++;
      _currentStreak++;
      if (_currentStreak > _bestStreak) {
        _bestStreak = _currentStreak;
      }
    } else {
      _currentStreak = 0;
    }

    _currentQuestion++;
    _state = TrainingState.showingResult;
    notifyListeners();

    // 短暂显示结果后进入下一题
    await Future.delayed(const Duration(milliseconds: 1200));
    await _nextQuestion();
  }

  /// 重播当前基准音
  Future<void> replayRoot() async {
    if (_rootMidi != null && audioEngine != null) {
      await audioEngine!.playNote(_rootMidi!);
    }
  }

  /// 重播当前目标音
  Future<void> replayTarget() async {
    if (_targetMidi != null && audioEngine != null) {
      await audioEngine!.playNote(_targetMidi!);
    }
  }

  // === 重置 ===
  void reset() {
    _state = TrainingState.idle;
    _currentQuestion = 0;
    _correctCount = 0;
    _currentStreak = 0;
    _bestStreak = 0;
    _rootMidi = null;
    _targetMidi = null;
    _userAnswerMidi = null;
    _askedQuestions.clear();
    _responseTimes.clear();
    _sessionStartTime = null;
    _questionStartTime = null;
    notifyListeners();
  }
}
