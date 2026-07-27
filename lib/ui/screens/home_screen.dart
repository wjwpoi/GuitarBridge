import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../models/scale.dart';
import '../../models/tuning.dart';
import '../../models/practice_record.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../engine/audio_engine.dart';
import '../../engine/training_engine.dart';
import '../../services/storage_service.dart';
import '../../services/streak_manager.dart';
import '../../services/haptic_manager.dart';
import '../widgets/training_options.dart';
import '../widgets/training_status.dart';
import '../widgets/fretboard_widget.dart';
import '../widgets/scale_chart.dart';
import '../widgets/completion_animation.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

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
  late TrainingEngine _trainingEngine;
  late AudioEngine _audioEngine;
  late String _selectedKey;
  late String _selectedScale;
  late String _selectedTuning;
  late String _selectedDifficulty;
  late ToneMode _currentToneMode;
  late bool _showDegrees;
  late bool _showNoteNames;
  late bool _showFretNumbers;
  bool _showCompletion = false;

  @override
  void initState() {
    super.initState();
    _audioEngine = widget.audioEngine;
    _trainingEngine = TrainingEngine();
    final prefs = widget.initialPreferences;
    _selectedKey = prefs.selectedKey;
    _selectedScale = prefs.selectedScale;
    _selectedTuning = prefs.selectedTuning;
    _selectedDifficulty = prefs.difficulty;
    _currentToneMode = _audioEngine.currentMode;
    _showDegrees = prefs.showDegrees;
    _showNoteNames = prefs.showNoteNames;
    _showFretNumbers = prefs.showFretNumbers;
    _configureEngine();
  }

  void _configureEngine() {
    final tuning = Tuning.all.firstWhere(
      (t) => t.name == _selectedTuning,
      orElse: () => Tuning.standard,
    );
    final scaleType = _scaleTypeFromName(_selectedScale);
    final difficulty = AppConstants.difficulties[_selectedDifficulty] ??
        AppConstants.difficulties['easy']!;
    _trainingEngine
      ..configure(engine: _audioEngine, tuning: tuning)
      ..currentKey = _selectedKey
      ..scaleType = scaleType
      ..difficulty = difficulty;
  }

  ScaleType _scaleTypeFromName(String name) {
    for (final s in ScaleType.values) {
      if (s.chineseName == name) return s;
    }
    return ScaleType.major;
  }

  @override
  void dispose() {
    _trainingEngine.removeListener(_checkCompletion);
    _trainingEngine.reset();
    _trainingEngine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TrainingOptionsWidget(
                    selectedKey: _selectedKey,
                    selectedScale: _selectedScale,
                    selectedTuning: _selectedTuning,
                    selectedDifficulty: _selectedDifficulty,
                    currentToneMode: _currentToneMode,
                    showDegrees: _showDegrees,
                    showNoteNames: _showNoteNames,
                    showFretNumbers: _showFretNumbers,
                    onKeyChanged: (v) {
                      setState(() => _selectedKey = v);
                      _trainingEngine.currentKey = v;
                    },
                    onScaleChanged: (v) {
                      setState(() => _selectedScale = v);
                      _trainingEngine.scaleType = _scaleTypeFromName(v);
                    },
                    onTuningChanged: (v) {
                      setState(() => _selectedTuning = v);
                      _configureEngine();
                    },
                    onDifficultyChanged: (v) {
                      setState(() => _selectedDifficulty = v);
                      _trainingEngine.difficulty = AppConstants.difficulties[v]!;
                    },
                    onToneModeChanged: (mode) {
                      _audioEngine.switchToneMode(mode);
                      setState(() => _currentToneMode = mode);
                    },
                    onToggleDegrees: () => setState(() => _showDegrees = !_showDegrees),
                    onToggleNoteNames: () => setState(() => _showNoteNames = !_showNoteNames),
                    onToggleFretNumbers: () => setState(() => _showFretNumbers = !_showFretNumbers),
                  ),
                  const SizedBox(height: 12),
                  ScaleChartWidget(
                    selectedKey: _selectedKey,
                    scaleType: _scaleTypeFromName(_selectedScale),
                  ),
                  const SizedBox(height: 12),
                  FretboardWidget(
                    trainingEngine: _trainingEngine,
                    tuning: Tuning.all.firstWhere(
                      (t) => t.name == _selectedTuning,
                      orElse: () => Tuning.standard,
                    ),
                    scaleType: _scaleTypeFromName(_selectedScale),
                    selectedKey: _selectedKey,
                    showDegrees: _showDegrees,
                    showNoteNames: _showNoteNames,
                    showFretNumbers: _showFretNumbers,
                    onFretTapped: _onFretTapped,
                  ),
                  const SizedBox(height: 12),
                  TrainingStatusWidget(
                    engine: _trainingEngine,
                    onStart: _onStartTraining,
                    onReplayRoot: _trainingEngine.replayRoot,
                    onReplayTarget: _trainingEngine.replayTarget,
                  ),
                ],
              ),
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
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('GuitarBridge'),
      backgroundColor: const Color(0xFF1E1E2E),
      actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart),
          tooltip: 'Statistics',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StatsScreen(
                  streakManager: widget.streakManager,
                  records: [],
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  audioEngine: _audioEngine,
                  preferences: widget.initialPreferences,
                  onPreferencesChanged: (prefs) {
                    widget.storage.savePreferences(prefs);
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _onStartTraining() async {
    HapticManager.medium();
    if (_trainingEngine.state == TrainingState.completed) {
      _trainingEngine.reset();
    }
    _configureEngine();
    await _trainingEngine.start();
  }

  void _onFretTapped(int midiNote) {
    if (_trainingEngine.state != TrainingState.waitingAnswer) return;
    HapticManager.light();
    _trainingEngine.submitAnswer(midiNote);
    _trainingEngine.addListener(_checkCompletion);
  }

  void _checkCompletion() {
    if (_trainingEngine.state == TrainingState.completed) {
      _trainingEngine.removeListener(_checkCompletion);
      _recordSession();
      setState(() => _showCompletion = true);
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
}
