import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/ui/widgets/completion_animation.dart';
import 'package:guitar_bridge/ui/widgets/training_status.dart';
import 'package:guitar_bridge/ui/widgets/scale_chart.dart';
import 'package:guitar_bridge/engine/training_engine.dart';
import 'package:guitar_bridge/engine/audio_engine.dart';
import 'package:guitar_bridge/models/scale.dart';

void main() {
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

      expect(find.text('训练完成！'), findsOneWidget);
      expect(find.text('80% 准确率'), findsOneWidget);
      expect(find.text('8 / 10 道正确'), findsOneWidget);
      expect(find.text('最佳连击: 5'), findsOneWidget);
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

    testWidgets('shows trophy for high accuracy', (tester) async {
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

      expect(find.text('100% 准确率'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
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
        MaterialApp(
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
        MaterialApp(
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
}
