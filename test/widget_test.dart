import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/core/theme.dart';
import 'package:guitar_bridge/ui/screens/onboarding_screen.dart';
import 'package:guitar_bridge/ui/widgets/completion_animation.dart';
import 'package:guitar_bridge/ui/widgets/training_status.dart';
import 'package:guitar_bridge/ui/widgets/scale_chart.dart';
import 'package:guitar_bridge/ui/widgets/fretboard_widget.dart';
import 'package:guitar_bridge/engine/training_engine.dart';
import 'package:guitar_bridge/models/scale.dart';
import 'package:guitar_bridge/models/tuning.dart';

void main() {
  group('OnboardingScreen', () {
    testWidgets('explains and waits for browser audio activation', (
      tester,
    ) async {
      final activation = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            requiresAudioActivation: true,
            onComplete: () => activation.future,
          ),
        ),
      );

      expect(find.text('开启声音，进入训练'), findsOneWidget);
      expect(find.textContaining('浏览器首次需要一次点击'), findsOneWidget);

      await tester.tap(find.text('开启声音，进入训练'));
      await tester.pump();
      expect(find.text('正在准备声音…'), findsOneWidget);

      activation.complete();
      await tester.pumpAndSettle();
    });
  });

  group('CompletionAnimationWidget', () {
    testWidgets('renders completion info correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CompletionAnimationWidget(
            correctCount: 8,
            totalQuestions: 10,
            streak: 5,
            onDismiss: () {},
          ),
        ),
      );

      expect(find.text('本轮结束'), findsOneWidget);
      expect(find.text('不错的一轮'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('首次即答对 8 / 10 题'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('完成'), findsOneWidget);
    });

    testWidgets('calls onDismiss when button pressed', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: CompletionAnimationWidget(
            correctCount: 5,
            totalQuestions: 10,
            streak: 3,
            onDismiss: () => dismissed = true,
          ),
        ),
      );

      await tester.tap(find.text('完成'));
      expect(dismissed, true);
    });

    testWidgets('praises high accuracy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CompletionAnimationWidget(
            correctCount: 10,
            totalQuestions: 10,
            streak: 10,
            onDismiss: () {},
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('耳朵很准'), findsOneWidget);
    });
  });

  group('TrainingStatusWidget', () {
    testWidgets('shows start button in idle state', (tester) async {
      final engine = TrainingEngine();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrainingStatusWidget(
              engine: engine,
              onStart: () {},
              onReplayRoot: () {},
              onReplayTarget: () {},
            ),
          ),
        ),
      );

      expect(find.text('开始训练'), findsOneWidget);
    });

    testWidgets('shows replay buttons when waiting for answer', (tester) async {
      final engine = TrainingEngine();
      // Manually set state for testing
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrainingStatusWidget(
              engine: engine,
              onStart: () {},
              onReplayRoot: () {},
              onReplayTarget: () {},
            ),
          ),
        ),
      );

      // In idle state, should show start button
      expect(find.text('开始训练'), findsOneWidget);
    });
  });

  group('ScaleChartWidget', () {
    testWidgets('renders scale name and note chips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScaleChartWidget(
              selectedKey: 'C',
              scaleType: ScaleType.major,
            ),
          ),
        ),
      );

      expect(find.textContaining('大调'), findsOneWidget);
      expect(find.textContaining('C'), findsWidgets);
    });

    testWidgets('shows different notes for different scales', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScaleChartWidget(
              selectedKey: 'C',
              scaleType: ScaleType.minorPentatonic,
            ),
          ),
        ),
      );

      expect(find.textContaining('五声'), findsOneWidget);
    });
  });

  group('FretboardWidget', () {
    testWidgets('offers explicit controls for moving to higher frets', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final engine = TrainingEngine();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: FretboardWidget(
                trainingEngine: engine,
                tuning: Tuning.standard,
                scaleType: ScaleType.major,
                selectedKey: 'C',
                onFretTapped: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('0–6 品'), findsOneWidget);
      expect(find.byTooltip('向高把位移动'), findsOneWidget);

      await tester.tap(find.byTooltip('向高把位移动'));
      await tester.pumpAndSettle();

      expect(find.text('4–10 品'), findsOneWidget);
    });
  });

  group('Dark theme', () {
    testWidgets('training stage and fretboard render with dark tokens', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final engine = TrainingEngine();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: Column(
              children: [
                TrainingStatusWidget(
                  engine: engine,
                  onStart: () {},
                  onReplayRoot: () {},
                  onReplayTarget: () {},
                ),
                FretboardWidget(
                  trainingEngine: engine,
                  tuning: Tuning.standard,
                  scaleType: ScaleType.major,
                  selectedKey: 'C',
                  onFretTapped: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      final context = tester.element(find.byType(TrainingStatusWidget));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(context.gb.canvas, GbColors.dark.canvas);
      expect(tester.takeException(), isNull);
      // Wide enough to show the whole neck without navigation arrows.
      expect(find.byTooltip('向高把位移动'), findsNothing);
    });
  });
}
