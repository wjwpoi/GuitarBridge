import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'engine/audio_engine.dart';
import 'services/storage_service.dart';
import 'services/streak_manager.dart';
import 'ui/screens/onboarding_screen.dart';
import 'models/practice_record.dart';
import 'core/theme.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化服务
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  final streakManager = StreakManager(storage);
  final audioEngine = AudioEngine();

  // 加载数据
  await streakManager.loadData();
  await audioEngine.initialize();

  final userPrefs = await storage.getPreferences();

  runApp(
    GuitarBridgeApp(
      audioEngine: audioEngine,
      storage: storage,
      streakManager: streakManager,
      userPreferences: userPrefs,
    ),
  );
}

class GuitarBridgeApp extends StatefulWidget {
  final AudioEngine audioEngine;
  final StorageService storage;
  final StreakManager streakManager;
  final UserPreferences userPreferences;

  const GuitarBridgeApp({
    super.key,
    required this.audioEngine,
    required this.storage,
    required this.streakManager,
    required this.userPreferences,
  });

  @override
  State<GuitarBridgeApp> createState() => _GuitarBridgeAppState();
}

class _GuitarBridgeAppState extends State<GuitarBridgeApp> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = !widget.userPreferences.hasCompletedOnboarding;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuitarBridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.trainingTheme('clean'),
      home: _showOnboarding
          ? OnboardingScreen(onComplete: _onOnboardingComplete)
          : HomeScreen(
              audioEngine: widget.audioEngine,
              storage: widget.storage,
              streakManager: widget.streakManager,
              initialPreferences: widget.userPreferences,
            ),
    );
  }

  void _onOnboardingComplete() async {
    widget.userPreferences.hasCompletedOnboarding = true;
    await widget.storage.savePreferences(widget.userPreferences);
    if (mounted) setState(() => _showOnboarding = false);
  }

  @override
  void dispose() {
    widget.audioEngine.dispose();
    super.dispose();
  }
}
