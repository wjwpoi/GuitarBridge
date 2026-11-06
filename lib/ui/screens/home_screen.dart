import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../engine/adaptive_planner.dart';
import '../../engine/audio_engine.dart';
import '../../engine/training_engine.dart';
import '../../models/practice_record.dart';
import '../../models/training_config.dart';
import '../../models/training_question.dart';
import '../../services/haptic_manager.dart';
import '../../services/storage_service.dart';
import '../../services/streak_manager.dart';
import '../widgets/completion_animation.dart';
import '../widgets/fretboard_widget.dart';
import '../widgets/interval_breakdown.dart';
import '../widgets/training_options.dart';
import '../widgets/training_status.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  final AudioEngine audioEngine;
  final StorageService storage;
  final StreakManager streakManager;
  final UserPreferences initialPreferences;

  /// App-wide theme mode, updated from the settings screen.
  final ValueNotifier<ThemeMode>? themeMode;

  const HomeScreen({
    super.key,
    required this.audioEngine,
    required this.storage,
    required this.streakManager,
    required this.initialPreferences,
    this.themeMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TrainingEngine _trainingEngine;
  late final AudioEngine _audioEngine;
  late TrainingConfig _config;
  bool _showCompletion = false;
  bool _sessionRecorded = false;
  bool _wasSessionActive = false;

  UserPreferences get _prefs => widget.initialPreferences;

  @override
  void initState() {
    super.initState();
    _audioEngine = widget.audioEngine;
    _audioEngine.addListener(_onAudioStateChange);
    _audioEngine.setVolume(_prefs.audioVolume);
    _config = TrainingConfig.fromPreferences(_prefs);
    _trainingEngine = TrainingEngine()..addListener(_onTrainingChanged);
    _applyConfigToEngine();
  }

  Map<int, IntervalTally> get _history =>
      AdaptivePlanner.historyFrom(widget.streakManager.records);

  void _applyConfigToEngine() {
    final difficulty = _config.difficultyConfig;
    _trainingEngine
      ..configure(engine: _audioEngine, tuning: _config.tuning)
      ..answerMode = AnswerMode.exactPitch
      ..maxFailedAttempts = _prefs.maxFailedAttempts
      ..currentKey = _config.key
      ..scaleType = _config.scale
      ..difficulty = difficulty
      ..questionsPerSession = _prefs.questionsPerSession
      ..intervalWeights = _prefs.adaptiveTraining
          ? AdaptivePlanner.weightsFor(difficulty.allowedIntervals, _history)
          : null;
  }

  List<FocusInterval> get _focus {
    if (!_prefs.adaptiveTraining) return const [];
    final history = _history;
    return [
      for (final interval in AdaptivePlanner.focusIntervals(
        _config.difficultyConfig.allowedIntervals,
        history,
      ))
        (
          name: IntervalBreakdown.nameFor(interval),
          accuracy: history[interval]!.accuracy,
        ),
    ];
  }

  @override
  void dispose() {
    _audioEngine.removeListener(_onAudioStateChange);
    _trainingEngine.removeListener(_onTrainingChanged);
    _trainingEngine.reset();
    _trainingEngine.dispose();
    super.dispose();
  }

  bool get _hasKeyboard =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  // ---------------------------------------------------------------------------
  // Layout

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    final c = context.gb;
    return Scaffold(
      bottomNavigationBar: compact
          ? ListenableBuilder(
              listenable: _trainingEngine,
              builder: (context, _) {
                final show =
                    _trainingEngine.isSessionActive &&
                    _trainingEngine.state != TrainingState.showingResult;
                if (!show) return const SizedBox.shrink();
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.canvas,
                    border: Border(top: BorderSide(color: c.hairline)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                      child: _actions(bar: true),
                    ),
                  ),
                );
              },
            )
          : null,
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final padding = compact ? 16.0 : 56.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(padding, 0, padding, 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppTheme.contentMaxWidth + 112,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(compact: compact),
                            if (_audioEngine.state ==
                                AudioEngineState.error) ...[
                              _buildAudioError(),
                              const SizedBox(height: 12),
                            ],
                            SetupStrip(
                              config: _config,
                              locked: _trainingEngine.isSessionActive,
                              compact: width < 1000,
                              onChanged: _onConfigChanged,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: compact ? 22 : 38,
                              ),
                              child: _buildStatus(compact: compact),
                            ),
                            _buildFretboardSection(compact: compact),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_showCompletion)
              Positioned.fill(
                child: CompletionAnimationWidget(
                  correctCount: _trainingEngine.correctCount,
                  totalQuestions: _trainingEngine.totalQuestions,
                  streak: _trainingEngine.bestStreak,
                  intervalTallies: _trainingEngine.intervalTallies,
                  outcomes: _trainingEngine.outcomes,
                  averageResponseSeconds: _trainingEngine.averageResponseTime,
                  adaptive: _prefs.adaptiveTraining,
                  subtitle: _summarySubtitle(),
                  onDismiss: () => setState(() => _showCompletion = false),
                  onRestart: () {
                    setState(() => _showCompletion = false);
                    _onStartTraining();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _summarySubtitle() {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return '${now.month} 月 ${now.day} 日 $time · '
        '${_config.key} ${_config.scale.chineseName} · '
        '${TrainingConfig.difficultyLabel(_config.difficulty)}';
  }

  Widget _buildHeader({required bool compact}) {
    final c = context.gb;
    final streakDays = widget.streakManager.currentStreak;
    return SizedBox(
      height: compact ? 60 : 76,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'GuitarBridge',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.serifStyle(
                size: compact ? 19 : 22,
                color: c.textPrimary,
              ),
            ),
          ),
          if (streakDays > 0 && !compact)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '连续 '),
                    TextSpan(
                      text: '$streakDays',
                      style: AppTheme.monoStyle(
                        size: 14,
                        color: c.accent,
                        weight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: ' 天'),
                  ],
                ),
                style: TextStyle(fontSize: 14, color: c.textSecondary),
              ),
            ),
          TextButton(onPressed: _openStats, child: const Text('统计')),
          TextButton(onPressed: _openSettings, child: const Text('设置')),
        ],
      ),
    );
  }

  Widget _buildAudioError() {
    final c = context.gb;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: c.wrongSoft,
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _audioEngine.error ?? '音频初始化失败',
              style: TextStyle(fontSize: 13.5, color: c.wrong),
            ),
          ),
          TextButton(onPressed: _ensureAudioReady, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _actions({bool bar = false}) => TrainingActions(
    engine: _trainingEngine,
    bar: bar,
    showShortcuts: _hasKeyboard && !bar,
    onReplayRoot: _trainingEngine.replayRoot,
    onReplayTarget: _trainingEngine.replayTarget,
    onReplayQuestion: _trainingEngine.replayQuestion,
    onReveal: _trainingEngine.revealAnswer,
    onFinish: _trainingEngine.finishEarly,
  );

  Widget _buildStatus({required bool compact}) {
    final needsActivation =
        _audioEngine.state == AudioEngineState.uninitialized;
    return Semantics(
      label: '训练状态与控制',
      container: true,
      child: TrainingStatusWidget(
        engine: _trainingEngine,
        showShortcuts: _hasKeyboard && !compact,
        showActions: !compact,
        startLabel: needsActivation ? '开启声音并开始' : null,
        focus: _focus,
        inlayOnly: !_config.showScaleNotes,
        onStart: _onStartTraining,
        onReplayRoot: _trainingEngine.replayRoot,
        onReplayTarget: _trainingEngine.replayTarget,
        onReplayQuestion: _trainingEngine.replayQuestion,
        onReveal: _trainingEngine.revealAnswer,
        onFinish: _trainingEngine.finishEarly,
      ),
    );
  }

  Widget _buildFretboardSection({required bool compact}) {
    final c = context.gb;
    return Container(
      padding: EdgeInsets.only(top: compact ? 16 : 22),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 8,
            children: [
              Text(
                compact ? '指板' : '点任意位置试听；答题时点击即作答，同音高的位置都算对。',
                style: compact
                    ? context.text.titleSmall
                    : TextStyle(fontSize: 13, color: c.textMuted),
              ),
              const FretboardLegend(),
            ],
          ),
          SizedBox(height: compact ? 8 : 14),
          Semantics(
            label: '吉他指板',
            child: FretboardWidget(
              trainingEngine: _trainingEngine,
              tuning: _config.tuning,
              scaleType: _config.scale,
              selectedKey: _config.key,
              showDegrees: _config.showDegrees,
              showNoteNames: _config.showNoteNames,
              showFretNumbers: _config.showFretNumbers,
              showScaleNotes: _config.showScaleNotes,
              focusFretRange: _config.difficultyConfig.fretRange,
              onFretTapped: _onFretTapped,
            ),
          ),
          if (!_config.showScaleNotes && !_config.showFretNumbers)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '品号已关闭。指板上只剩品记，和你手里的琴一样。',
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation

  void _openStats() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatsScreen(
          streakManager: widget.streakManager,
          records: widget.streakManager.records,
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          audioEngine: _audioEngine,
          preferences: _prefs,
          onPreferencesChanged: _updatePreferences,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Input

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _showCompletion) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final state = _trainingEngine.state;
    final canStart =
        state == TrainingState.idle ||
        state == TrainingState.completed ||
        state == TrainingState.audioError;

    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      if (canStart) {
        _onStartTraining();
      } else {
        _trainingEngine.replayQuestion();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && _trainingEngine.isSessionActive) {
      _trainingEngine.finishEarly();
      return KeyEventResult.handled;
    }
    if (state != TrainingState.waitingAnswer) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.keyR) {
      _trainingEngine.replayRoot();
    } else if (key == LogicalKeyboardKey.keyT) {
      _trainingEngine.replayTarget();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _onStartTraining() async {
    if (!await _ensureAudioReady()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法开启声音，请检查设备音量或浏览器的声音权限后重试。')),
        );
      }
      return;
    }
    HapticManager.medium();
    _sessionRecorded = false;
    _applyConfigToEngine();
    await _trainingEngine.start();
  }

  Future<void> _onFretTapped(FretPosition position) async {
    // Taps while a question is being announced would cut it off.
    if (_trainingEngine.isAnnouncing) return;
    if (!await _ensureAudioReady()) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法开启声音，请检查浏览器的声音权限。')));
      }
      return;
    }
    if (_trainingEngine.state != TrainingState.waitingAnswer) {
      await _audioEngine.playNote(position.midi);
      return;
    }
    HapticManager.light();
    _trainingEngine.submitAnswer(position);
  }

  Future<bool> _ensureAudioReady() async {
    if (_audioEngine.isReady) return true;
    await _audioEngine.initialize();
    return _audioEngine.isReady;
  }

  // ---------------------------------------------------------------------------
  // State sync

  void _onAudioStateChange() {
    if (mounted) setState(() {});
  }

  void _onTrainingChanged() {
    if (_trainingEngine.state == TrainingState.completed && !_sessionRecorded) {
      _sessionRecorded = true;
      if (_trainingEngine.currentQuestion > 0) {
        _recordSession();
        if (mounted) setState(() => _showCompletion = true);
      }
    }
    // The settings lock follows the session; only rebuild when it flips.
    final active = _trainingEngine.isSessionActive;
    if (active != _wasSessionActive && mounted) {
      setState(() => _wasSessionActive = active);
    }
  }

  void _onConfigChanged(TrainingConfig next) {
    if (_trainingEngine.isSessionActive && next.affectsQuestions(_config)) {
      return;
    }
    setState(() => _config = next);
    _applyConfigToEngine();
    _config.writeTo(_prefs);
    widget.storage.savePreferences(_prefs);
  }

  Future<void> _recordSession() async {
    final tallies = _trainingEngine.intervalTallies;
    final record = PracticeRecord(
      date: DateTime.now(),
      totalAttempts: _trainingEngine.currentQuestion,
      correctAnswers: _trainingEngine.correctCount,
      durationSeconds: _trainingEngine.sessionDuration.inSeconds.toDouble(),
      keySignature: _config.key,
      scaleType: _config.scale.chineseName,
      bestStreak: _trainingEngine.bestStreak,
      difficulty: _config.difficulty,
      intervalResults: {
        for (final entry in tallies.entries)
          entry.key: (entry.value.firstTryCorrect, entry.value.total),
      },
    );
    await widget.streakManager.recordSession(record);
    if (mounted) setState(() {});
  }

  void _updatePreferences(UserPreferences prefs) {
    if (!mounted) return;
    setState(() {
      _config = _config.copyWith(
        labels: FretLabels.fromStorage(prefs.fretLabels),
        showFretNumbers: prefs.showFretNumbers,
      );
    });
    _audioEngine.setVolume(prefs.audioVolume);
    widget.themeMode?.value = switch (prefs.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    if (!_trainingEngine.isSessionActive) _applyConfigToEngine();
    widget.storage.savePreferences(prefs);
  }
}
