import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../engine/audio_engine.dart';
import '../../engine/training_engine.dart';
import '../../models/practice_record.dart';
import '../../models/scale.dart';
import '../../models/training_question.dart';
import '../../models/tuning.dart';
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
  late final TrainingEngine _trainingEngine;
  late final AudioEngine _audioEngine;
  late String _selectedKey;
  late String _selectedScale;
  late String _selectedTuning;
  late String _selectedDifficulty;
  late ToneMode _currentToneMode;
  late bool _showDegrees;
  late bool _showNoteNames;
  late bool _showFretNumbers;
  bool _showCompletion = false;
  bool _sessionRecorded = false;

  @override
  void initState() {
    super.initState();
    _audioEngine = widget.audioEngine;
    _audioEngine.addListener(_onAudioStateChange);
    _trainingEngine = TrainingEngine();
    final prefs = widget.initialPreferences;
    _selectedKey = prefs.selectedKey;
    _selectedScale = prefs.selectedScale;
    _selectedTuning = prefs.selectedTuning;
    _selectedDifficulty = prefs.difficulty;
    _currentToneMode = _toneModeFromName(prefs.toneMode);
    _audioEngine.setVolume(prefs.audioVolume);
    _audioEngine.switchToneMode(_currentToneMode);
    _showDegrees = prefs.showDegrees;
    _showNoteNames = prefs.showNoteNames;
    _showFretNumbers = prefs.showFretNumbers;
    _configureEngine();
    _trainingEngine.addListener(_checkCompletion);
  }

  void _configureEngine() {
    final tuning = Tuning.all.firstWhere(
      (candidate) => candidate.name == _selectedTuning,
      orElse: () => Tuning.standard,
    );
    final scaleType = _scaleTypeFromName(_selectedScale);
    final difficulty =
        AppConstants.difficulties[_selectedDifficulty] ??
        AppConstants.difficulties['easy']!;
    _trainingEngine
      ..configure(engine: _audioEngine, tuning: tuning)
      ..answerMode = AnswerMode.exactPitch
      ..maxFailedAttempts = widget.initialPreferences.maxFailedAttempts
      ..currentKey = _selectedKey
      ..scaleType = scaleType
      ..difficulty = difficulty
      ..questionsPerSession = widget.initialPreferences.questionsPerSession;
  }

  ScaleType _scaleTypeFromName(String name) {
    for (final scale in ScaleType.values) {
      if (scale.chineseName == name) return scale;
    }
    return ScaleType.major;
  }

  ToneMode _toneModeFromName(String name) => switch (name) {
    'overdrive' => ToneMode.overdrive,
    'distortion' => ToneMode.distortion,
    _ => ToneMode.clean,
  };

  Tuning get _currentTuning => Tuning.all.firstWhere(
    (candidate) => candidate.name == _selectedTuning,
    orElse: () => Tuning.standard,
  );

  @override
  void dispose() {
    _audioEngine.removeListener(_onAudioStateChange);
    _trainingEngine.removeListener(_checkCompletion);
    _trainingEngine.reset();
    _trainingEngine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.space): () {
            if (_trainingEngine.state == TrainingState.idle ||
                _trainingEngine.state == TrainingState.completed ||
                _trainingEngine.state == TrainingState.audioError) {
              _onStartTraining();
            }
          },
          const SingleActivator(LogicalKeyboardKey.digit1): () =>
              _switchToneMode(ToneMode.clean),
          const SingleActivator(LogicalKeyboardKey.digit2): () =>
              _switchToneMode(ToneMode.overdrive),
          const SingleActivator(LogicalKeyboardKey.digit3): () =>
              _switchToneMode(ToneMode.distortion),
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 980;
                    final horizontalPadding = constraints.maxWidth < 600
                        ? 14.0
                        : 28.0;
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        18,
                        horizontalPadding,
                        36,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppTheme.contentMaxWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(context),
                              if (_audioEngine.state !=
                                  AudioEngineState.ready) ...[
                                const SizedBox(height: 16),
                                _buildAudioNotice(),
                              ],
                              const SizedBox(height: 22),
                              if (isWide)
                                _buildWideWorkspace()
                              else
                                _buildNarrowWorkspace(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_showCompletion)
                CompletionAnimationWidget(
                  correctCount: _trainingEngine.correctCount,
                  totalQuestions: _trainingEngine.totalQuestions,
                  streak: _trainingEngine.bestStreak,
                  onDismiss: () {
                    setState(() => _showCompletion = false);
                    _trainingEngine.reset();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.music_note_rounded,
            color: AppTheme.backgroundColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GuitarBridge',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 2),
              const Text(
                '把听见的音，放回指板',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _headerAction(
          icon: Icons.insights_rounded,
          tooltip: '练习统计',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StatsScreen(
                  streakManager: widget.streakManager,
                  records: widget.streakManager.records,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        _headerAction(
          icon: Icons.settings_rounded,
          tooltip: '设置',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  audioEngine: _audioEngine,
                  preferences: widget.initialPreferences,
                  onPreferencesChanged: _updatePreferences,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _headerAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineColor),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildAudioNotice() {
    final isError = _audioEngine.state == AudioEngineState.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isError ? AppTheme.wrongColor : AppTheme.secondaryColor)
            .withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isError ? AppTheme.wrongColor : AppTheme.secondaryColor)
              .withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          if (_audioEngine.state == AudioEngineState.loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.info_outline_rounded,
              color: isError ? AppTheme.wrongColor : AppTheme.secondaryColor,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isError
                  ? (_audioEngine.error ?? '音频初始化失败')
                  : _audioEngine.state == AudioEngineState.loading
                  ? '正在准备音频引擎…'
                  : '音频引擎尚未初始化',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          if (isError)
            TextButton(
              onPressed: _audioEngine.initialize,
              child: const Text('重试'),
            ),
        ],
      ),
    );
  }

  Widget _buildWideWorkspace() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 350,
          child: Column(
            children: [
              _buildOptions(),
              const SizedBox(height: 14),
              _buildGuideCard(),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(child: _buildTrainingWorkspace()),
      ],
    );
  }

  Widget _buildNarrowWorkspace() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatus(),
        const SizedBox(height: 14),
        _buildOptions(),
        const SizedBox(height: 14),
        _buildFretboardCard(),
        const SizedBox(height: 14),
        _buildScaleChart(),
      ],
    );
  }

  Widget _buildTrainingWorkspace() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatus(),
        const SizedBox(height: 14),
        _buildScaleChart(),
        const SizedBox(height: 14),
        _buildFretboardCard(),
      ],
    );
  }

  Widget _buildOptions() {
    return Semantics(
      label: '训练设置',
      child: TrainingOptionsWidget(
        selectedKey: _selectedKey,
        selectedScale: _selectedScale,
        selectedTuning: _selectedTuning,
        selectedDifficulty: _selectedDifficulty,
        currentToneMode: _currentToneMode,
        showDegrees: _showDegrees,
        showNoteNames: _showNoteNames,
        showFretNumbers: _showFretNumbers,
        onKeyChanged: (value) {
          setState(() => _selectedKey = value);
          _trainingEngine.currentKey = value;
          _persistCurrentPreferences();
        },
        onScaleChanged: (value) {
          setState(() => _selectedScale = value);
          _trainingEngine.scaleType = _scaleTypeFromName(value);
          _persistCurrentPreferences();
        },
        onTuningChanged: (value) {
          setState(() => _selectedTuning = value);
          _configureEngine();
          _persistCurrentPreferences();
        },
        onDifficultyChanged: (value) {
          setState(() => _selectedDifficulty = value);
          _trainingEngine.difficulty = AppConstants.difficulties[value]!;
          _persistCurrentPreferences();
        },
        onToneModeChanged: _switchToneMode,
        onToggleDegrees: () {
          setState(() => _showDegrees = !_showDegrees);
          _persistCurrentPreferences();
        },
        onToggleNoteNames: () {
          setState(() => _showNoteNames = !_showNoteNames);
          _persistCurrentPreferences();
        },
        onToggleFretNumbers: () {
          setState(() => _showFretNumbers = !_showFretNumbers);
          _persistCurrentPreferences();
        },
      ),
    );
  }

  Widget _buildStatus() {
    return Semantics(
      label: '训练状态与控制',
      child: TrainingStatusWidget(
        engine: _trainingEngine,
        onStart: _onStartTraining,
        onReplayRoot: _trainingEngine.replayRoot,
        onReplayTarget: _trainingEngine.replayTarget,
      ),
    );
  }

  Widget _buildScaleChart() {
    return ScaleChartWidget(
      selectedKey: _selectedKey,
      scaleType: _scaleTypeFromName(_selectedScale),
    );
  }

  Widget _buildFretboardCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.grid_view_rounded,
                  color: AppTheme.primaryColor,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '等宽指板',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const _LegendDot(color: AppTheme.primaryColor, label: '基准'),
                const SizedBox(width: 10),
                const _LegendDot(color: AppTheme.accentColor, label: '答案'),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              '每一品保持相同宽度。横向滚动浏览完整指板，同音高的不同位置均可作答。',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: '等宽吉他指板',
              child: FretboardWidget(
                trainingEngine: _trainingEngine,
                tuning: _currentTuning,
                scaleType: _scaleTypeFromName(_selectedScale),
                selectedKey: _selectedKey,
                showDegrees: _showDegrees,
                showNoteNames: _showNoteNames,
                showFretNumbers: _showFretNumbers,
                onFretTapped: _onFretTapped,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '本轮规则',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _guideLine(Icons.arrow_upward_rounded, '只生成一个八度内的上行音程'),
            const SizedBox(height: 9),
            _guideLine(Icons.alt_route_rounded, '同一音高可在任意弦位作答'),
            const SizedBox(height: 9),
            _guideLine(Icons.keyboard_rounded, '按空格即可开始下一轮训练'),
          ],
        ),
      ),
    );
  }

  Widget _guideLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  void _onAudioStateChange() {
    if (mounted) setState(() {});
  }

  void _switchToneMode(ToneMode mode) {
    if (_currentToneMode != mode) {
      setState(() => _currentToneMode = mode);
    }
    _audioEngine.switchToneMode(mode);
    _persistCurrentPreferences();
  }

  Future<void> _onStartTraining() async {
    if (!_audioEngine.isReady) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('音频尚未准备完成，请检查页面提示后重试。')));
      }
      return;
    }
    HapticManager.medium();
    if (_trainingEngine.state == TrainingState.completed) {
      _trainingEngine.reset();
    }
    _sessionRecorded = false;
    _configureEngine();
    await _trainingEngine.start();
  }

  void _onFretTapped(FretPosition position) {
    if (_trainingEngine.state != TrainingState.waitingAnswer) {
      _audioEngine.playNote(position.midi);
      return;
    }
    HapticManager.light();
    _trainingEngine.submitAnswer(position);
  }

  void _checkCompletion() {
    if (_trainingEngine.state == TrainingState.completed && !_sessionRecorded) {
      _sessionRecorded = true;
      _recordSession();
      if (mounted) setState(() => _showCompletion = true);
    }
  }

  Future<void> _recordSession() async {
    final record = PracticeRecord(
      date: DateTime.now(),
      totalAttempts: _trainingEngine.totalQuestions,
      correctAnswers: _trainingEngine.correctCount,
      durationSeconds: _trainingEngine.sessionDuration.inSeconds.toDouble(),
      keySignature: _selectedKey,
      scaleType: _selectedScale,
      bestStreak: _trainingEngine.bestStreak,
    );
    await widget.streakManager.recordSession(record);
  }

  void _persistCurrentPreferences() {
    final prefs = widget.initialPreferences;
    prefs
      ..showDegrees = _showDegrees
      ..showNoteNames = _showNoteNames
      ..showFretNumbers = _showFretNumbers
      ..selectedKey = _selectedKey
      ..selectedScale = _selectedScale
      ..selectedTuning = _selectedTuning
      ..difficulty = _selectedDifficulty
      ..toneMode = _currentToneMode.name;
    widget.storage.savePreferences(prefs);
  }

  void _updatePreferences(UserPreferences prefs) {
    if (!mounted) return;
    setState(() {
      _showDegrees = prefs.showDegrees;
      _showNoteNames = prefs.showNoteNames;
      _showFretNumbers = prefs.showFretNumbers;
      _currentToneMode = _toneModeFromName(prefs.toneMode);
    });
    _audioEngine.setVolume(prefs.audioVolume);
    _trainingEngine.questionsPerSession = prefs.questionsPerSession;
    _audioEngine.switchToneMode(_currentToneMode);
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
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}
