import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/engine/audio_engine.dart';
import 'package:guitar_bridge/main.dart';
import 'package:guitar_bridge/services/storage_service.dart';
import 'package:guitar_bridge/services/streak_manager.dart';
import 'package:guitar_bridge/ui/widgets/fretboard_widget.dart';
import 'package:guitar_bridge/ui/widgets/training_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors integration_test/ios_smoke_test.dart without a device, so a UI
/// change that breaks the simulator smoke test fails here first.
void main() {
  testWidgets('first launch goes from onboarding to the workspace', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      GuitarBridgeApp(
        audioEngine: AudioEngine(),
        storage: storage,
        streakManager: StreakManager(storage),
        userPreferences: await storage.getPreferences(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('开始练习'));
    await tester.pumpAndSettle();

    expect(find.text('GuitarBridge'), findsOneWidget);
    expect(find.byType(TrainingStatusWidget), findsOneWidget);
    expect(find.byType(FretboardWidget), findsOneWidget);
    expect(find.text('指板'), findsOneWidget);
    // Audio is not started in unit tests, so the button asks to enable it.
    // On a device main() starts audio first and the label is '开始训练'.
    expect(find.text('开启声音并开始'), findsOneWidget);
  });
}
