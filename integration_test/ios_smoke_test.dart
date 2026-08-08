import 'package:flutter/material.dart';
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
    await tester.pump(const Duration(milliseconds: 900));

    final trainingState = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          const {
            '准备开始',
            '正在准备题目',
            '听基准音',
            '找到目标音',
            '声音没有可靠播放',
          }.contains(widget.data),
    );
    expect(trainingState, findsWidgets);
  });
}
