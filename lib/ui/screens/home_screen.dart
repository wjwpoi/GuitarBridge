import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
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

  const HomeScreen({
    super.key,
    required this.audioEngine,
    required this.storage,
    required this.streakManager,
    required this.initialPreferences,
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

  void _applyConfigToEngine() {
    _trainingEngine
      ..configure(engine: _audioEngine, tuning: _config.tuning)
      ..answerMode = AnswerMode.exactPitch
      ..maxFailedAttempts = _prefs.maxFailedAttempts
      ..currentKey = _config.key
      ..scaleType = _config.scale
      ..difficulty = _config.difficultyConfig
      ..questionsPerSession = _prefs.questionsPerSession;
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
                  final padding = width < 600 ? 12.0 : 24.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(padding, 14, padding, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppTheme.contentMaxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(compact: width < 600),
                            if (_audioEngine.state ==
                                AudioEngineState.error) ...[
                              const SizedBox(height: 12),
                              _buildAudioError(),
                            ],
                            const SizedBox(height: 14),
                            ...isWide
                                ? _buildWideWorkspace()
                                : _buildNarrowWorkspace(),
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

  List<Widget> _buildWideWorkspace() {
    return [
      _buildToolbar(),
      const SizedBox(height: 14),
      _buildStatus(),
      const SizedBox(height: 14),
      _buildFretboardCard(),
    ];
  }

  List<Widget> _buildNarrowWorkspace() {
    return [
      _buildStatus(),
      const SizedBox(height: 10),
      _buildFretboardCard(),
      const SizedBox(height: 10),
      _buildCollapsedOptions(),
    ];
  }

  Widget _buildHeader({required bool compact}) {
    final streakDays = widget.streakManager.currentStreak;
    return Row(
      children: [
        Container(
          width: compact ? 38 : 44,
          height: compact ? 38 : 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.music_note_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GuitarBridge',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: compact ? 17 : 19),
              ),
              Text(
                compact ? '听音程，找指板' : '听音程，在指板上找到它',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        if (streakDays > 0)
          Tooltip(
            message: '已连续练习 $streakDays 天',
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(18),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 15,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$streakDays 天',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        IconButton(
          tooltip: '练习统计',
          icon: const Icon(Icons.insights_rounded),
          onPressed: _openStats,
        ),
        IconButton(
          tooltip: '设置',
          icon: const Icon(Icons.settings_rounded),
          onPressed: _openSettings,
        ),
      ],
    );
  }

  Widget _buildAudioError() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppTheme.wrongColor.withAlpha(16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.wrongColor.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.wrongColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _audioEngine.error ?? '音频初始化失败',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(onPressed: _ensureAudioReady, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final locked = _trainingEngine.isSessionActive;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TrainingOptionsWidget(
              inline: true,
              config: _config,
              locked: locked,
              onChanged: _onConfigChanged,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ScaleChartWidget(
                    embedded: true,
                    selectedKey: _config.key,
                    scaleType: _config.scale,
                  ),
                ),
                Text(
                  locked
                      ? '训练中已锁定调性设置，结束本轮后可修改'
                      : TrainingConfig.difficultyDescription(
                          _config.difficulty,
                        ),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedOptions() {
    final locked = _trainingEngine.isSessionActive;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.tune_rounded, color: AppTheme.secondaryColor),
        title: const Text('训练设置'),
        subtitle: Text(
          '${_config.key} ${_config.scale.chineseName} · '
          '${TrainingConfig.difficultyLabel(_config.difficulty)}'
          '${locked ? ' · 训练中已锁定' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          TrainingOptionsWidget(
            config: _config,
            locked: locked,
            onChanged: _onConfigChanged,
          ),
          const SizedBox(height: 14),
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
        onStart: _onStartTraining,
        onReplayRoot: _trainingEngine.replayRoot,
        onReplayTarget: _trainingEngine.replayTarget,
        onReplayQuestion: _trainingEngine.replayQuestion,
        onReveal: _trainingEngine.revealAnswer,
        onFinish: _trainingEngine.finishEarly,
      ),
    );
  }

  Widget _buildFretboardCard() {
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isNarrow ? 10 : 18,
          isNarrow ? 12 : 14,
          isNarrow ? 10 : 18,
          isNarrow ? 12 : 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('指板', style: Theme.of(context).textTheme.titleMedium),
                const _LegendDot(color: AppTheme.primaryColor, label: '基准音'),
                const _LegendDot(color: AppTheme.wrongColor, label: '已尝试'),
                const _LegendDot(color: AppTheme.correctColor, label: '答案'),
                Text(
                  isNarrow ? '点音符试听或作答' : '点击任意音符试听；答题时点击即作答',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                focusFretRange: _config.difficultyConfig.fretRange,
                onFretTapped: _onFretTapped,
              ),
            ),
          ],
        ),
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
    if (state != TrainingState.waitingAnswer) {
      if (key == LogicalKeyboardKey.escape && _trainingEngine.isSessionActive) {
        _trainingEngine.finishEarly();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.keyR) {
      _trainingEngine.replayRoot();
    } else if (key == LogicalKeyboardKey.keyT) {
      _trainingEngine.replayTarget();
    } else if (key == LogicalKeyboardKey.escape) {
      _trainingEngine.finishEarly();
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
        showDegrees: prefs.showDegrees,
        showNoteNames: prefs.showNoteNames,
        showFretNumbers: prefs.showFretNumbers,
      );
    });
    _audioEngine.setVolume(prefs.audioVolume);
    if (!_trainingEngine.isSessionActive) {
      _trainingEngine
        ..questionsPerSession = prefs.questionsPerSession
        ..maxFailedAttempts = prefs.maxFailedAttempts;
    }
    widget.storage.savePreferences(prefs);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
