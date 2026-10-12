import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:guitar_bridge/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('iOS simulator launches the training workspace', (tester) async {
    app.main();
    // main() initializes SharedPreferences and the audio backend before it
    // calls runApp, so give those platform futures time to complete first.
    await Future<void>.delayed(const Duration(seconds: 5));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // A fresh simulator starts on onboarding. Existing simulator data is also
    // supported so this remains useful when the same device is reused locally.
    final onboardingButton = find.text('进入训练工作台');
    if (onboardingButton.evaluate().isNotEmpty) {
      await tester.tap(onboardingButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    expect(find.text('GuitarBridge'), findsOneWidget);
    expect(find.text('训练设置'), findsOneWidget);
    expect(find.text('等宽指板'), findsOneWidget);
    expect(find.text('开始训练'), findsOneWidget);

    await tester.tap(find.text('开始训练'));
    // Wait for both 900 ms cues, their gap, and the answer-state transition.
    // Idle or an audio error must fail this smoke test, not count as success.
    for (var attempt = 0; attempt < 40; attempt++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.text('找到目标音').evaluate().isNotEmpty) break;
    }
    expect(find.text('找到目标音'), findsOneWidget);
    expect(find.text('声音没有可靠播放'), findsNothing);
    expect(find.text('重播基准音'), findsOneWidget);
    expect(find.text('重播目标音'), findsOneWidget);
  });
}
