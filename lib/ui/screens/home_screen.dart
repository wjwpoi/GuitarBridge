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
import '../widgets/common.dart';
import '../widgets/completion_animation.dart';
import '../widgets/fretboard_widget.dart';
import '../widgets/interval_breakdown.dart';
import '../widgets/scale_chart.dart';
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
  static const double _wideBreakpoint = 1000;

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

  String? get _planNote {
    if (!_prefs.adaptiveTraining) return null;
    final focus = AdaptivePlanner.focusIntervals(
      _config.difficultyConfig.allowedIntervals,
      _history,
    );
    if (focus.isEmpty) return null;
    return '智能出题：本轮侧重 ${focus.map(IntervalBreakdown.nameFor).join('、')}';
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
    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isWide = width >= _wideBreakpoint;
                  final compact = width < 600;
                  final padding = compact ? 12.0 : 32.0;
                  final gap = compact ? 12.0 : 16.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      padding,
                      compact ? 8 : 18,
                      padding,
                      40,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppTheme.contentMaxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(compact: compact),
                            if (_audioEngine.state ==
                                AudioEngineState.error) ...[
                              SizedBox(height: gap),
                              _buildAudioError(),
                            ],
                            SizedBox(height: compact ? 8 : 20),
                            if (isWide) ...[
                              _buildToolbar(),
                              SizedBox(height: gap),
                              _buildStatus(),
                              SizedBox(height: gap),
                              _buildFretboardPanel(),
                            ] else ...[
                              _buildStatus(),
                              SizedBox(height: gap),
                              _buildFretboardPanel(),
                              SizedBox(height: gap),
                              _buildCollapsedOptions(),
                            ],
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
                  averageResponseSeconds: _trainingEngine.averageResponseTime,
                  adaptive: _prefs.adaptiveTraining,
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

  Widget _buildHeader({required bool compact}) {
    final c = context.gb;
    final streakDays = widget.streakManager.currentStreak;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Wordmark(compact: compact),
          const Spacer(),
          if (streakDays > 0)
            Tooltip(
              message: '已连续练习 $streakDays 天',
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$streakDays',
                        style: TextStyle(
                          color: c.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' 天连续'),
                    ],
                  ),
                  style: context.text.bodySmall?.copyWith(fontSize: 12.5),
                ),
              ),
            ),
          IconButton(
            tooltip: '练习统计',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: _openStats,
          ),
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.tune_rounded),
            onPressed: _openSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioError() {
    final c = context.gb;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: c.wrongSoft,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _audioEngine.error ?? '音频初始化失败',
              style: context.text.bodyMedium?.copyWith(color: c.wrong),
            ),
          ),
          TextButton(onPressed: _ensureAudioReady, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final locked = _trainingEngine.isSessionActive;
    return Panel(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TrainingOptionsWidget(
            inline: true,
            config: _config,
            locked: locked,
            onChanged: _onConfigChanged,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ScaleChartWidget(
                  embedded: true,
                  selectedKey: _config.key,
                  scaleType: _config.scale,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                locked
                    ? '训练中已锁定，结束本轮后可修改'
                    : TrainingConfig.difficultyDescription(_config.difficulty),
                style: context.text.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedOptions() {
    final locked = _trainingEngine.isSessionActive;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        title: Text('训练设置', style: context.text.titleSmall),
        subtitle: Text(
          '${_config.key} ${_config.scale.chineseName} · '
          '${TrainingConfig.difficultyLabel(_config.difficulty)}'
          '${locked ? ' · 训练中已锁定' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodySmall,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          TrainingOptionsWidget(
            config: _config,
            locked: locked,
            onChanged: _onConfigChanged,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: ScaleChartWidget(
              embedded: true,
              selectedKey: _config.key,
              scaleType: _config.scale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    final needsActivation =
        _audioEngine.state == AudioEngineState.uninitialized;
    return Semantics(
      label: '训练状态与控制',
      child: TrainingStatusWidget(
        engine: _trainingEngine,
        showShortcuts: _hasKeyboard && MediaQuery.sizeOf(context).width >= 700,
        startLabel: needsActivation ? '开启声音并开始' : null,
        planNote: _planNote,
        onStart: _onStartTraining,
        onReplayRoot: _trainingEngine.replayRoot,
        onReplayTarget: _trainingEngine.replayTarget,
        onReplayQuestion: _trainingEngine.replayQuestion,
        onReveal: _trainingEngine.revealAnswer,
        onFinish: _trainingEngine.finishEarly,
      ),
    );
  }

  Widget _buildFretboardPanel() {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Panel(
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 20,
        compact ? 14 : 18,
        compact ? 10 : 20,
        compact ? 10 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 0),
            child: Wrap(
              spacing: 20,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('指板', style: context.text.titleMedium),
                const FretboardLegend(),
                if (!compact)
                  Text('点击任意音符试听；答题时点击即作答', style: context.text.bodySmall),
              ],
            ),
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
