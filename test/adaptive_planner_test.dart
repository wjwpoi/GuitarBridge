import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/core/constants.dart';
import 'package:guitar_bridge/engine/adaptive_planner.dart';
import 'package:guitar_bridge/engine/training_audio_port.dart';
import 'package:guitar_bridge/engine/training_engine.dart';
import 'package:guitar_bridge/models/practice_record.dart';
import 'package:guitar_bridge/models/tuning.dart';

class _SilentAudio implements TrainingAudioPort {
  @override
  bool get isReady => true;
  @override
  Future<bool> playNote(int midiNote) async => true;
  @override
  Future<void> stopAll() async {}
}

PracticeRecord _record(DateTime date, Map<int, (int, int)> results) =>
    PracticeRecord(
      date: date,
      totalAttempts: 10,
      correctAnswers: 5,
      durationSeconds: 60,
      keySignature: 'C',
      scaleType: '自然大调',
      bestStreak: 2,
      intervalResults: results,
    );

void main() {
  group('AdaptivePlanner.historyFrom', () {
    test('sums the newest records only', () {
      final now = DateTime(2026, 11, 5);
      final records = [
        for (var i = 0; i < 40; i++)
          _record(now.subtract(Duration(days: i)), {
            7: i < 30 ? (1, 1) : (0, 1),
          }),
      ];
      final history = AdaptivePlanner.historyFrom(records);
      expect(history[7]!.total, AdaptivePlanner.historyWindow);
      expect(history[7]!.firstTryCorrect, AdaptivePlanner.historyWindow);
    });

    test('ignores legacy records without interval data', () {
      final history = AdaptivePlanner.historyFrom([
        _record(DateTime(2026), const {}),
      ]);
      expect(history, isEmpty);
    });
  });

  group('AdaptivePlanner weights', () {
    test('unseen intervals sit between mastered and weak ones', () {
      final history = {
        3: const IntervalTally(10, 10),
        4: const IntervalTally(0, 10),
      };
      final weights = AdaptivePlanner.weightsFor([3, 4, 5], history);
      expect(weights[3]!, lessThan(weights[5]!));
      expect(weights[5]!, lessThan(weights[4]!));
    });
  });

  group('AdaptivePlanner.allocate', () {
    test('without weights the split is balanced', () {
      final allocation = AdaptivePlanner.allocate(
        [3, 4, 5, 7],
        10,
        null,
        Random(1),
      );
      expect(allocation.values.reduce((a, b) => a + b), 10);
      final counts = allocation.values.toList();
      expect(counts.reduce(max) - counts.reduce(min), lessThanOrEqualTo(1));
    });

    test('weak intervals get more questions but none disappear', () {
      final allocation = AdaptivePlanner.allocate(
        [3, 4, 5, 7],
        20,
        {3: 0.2, 4: 0.2, 5: 0.2, 7: 1.1},
        Random(1),
      );
      expect(allocation.values.reduce((a, b) => a + b), 20);
      expect(allocation.values.every((count) => count >= 1), isTrue);
      expect(allocation[7]!, greaterThan(allocation[3]!));
      expect(allocation[7]!, greaterThanOrEqualTo(8));
    });

    test('short sessions prefer the weakest intervals', () {
      final allocation = AdaptivePlanner.allocate(
        [1, 2, 3, 4, 5, 7],
        3,
        {1: 1.0, 2: 0.9, 3: 0.2, 4: 0.2, 5: 0.8, 7: 0.2},
        Random(1),
      );
      expect(allocation.entries.where((e) => e.value > 0).map((e) => e.key), {
        1,
        2,
        5,
      });
    });
  });

  group('AdaptivePlanner.focusIntervals', () {
    test('lists practised weak intervals, weakest first', () {
      final focus = AdaptivePlanner.focusIntervals(
        [3, 4, 5, 7, 12],
        {
          3: const IntervalTally(9, 10),
          5: const IntervalTally(2, 8),
          7: const IntervalTally(1, 6),
          12: const IntervalTally(0, 1), // too few attempts to judge
        },
      );
      expect(focus, [7, 5]);
    });
  });

  group('TrainingEngine with interval weights', () {
    test('builds a session skewed towards the weighted interval', () async {
      final engine = TrainingEngine(random: Random(4), delay: (_) async {})
        ..configure(engine: _SilentAudio(), tuning: Tuning.standard)
        ..difficulty = AppConstants.difficulties['easy']!
        ..questionsPerSession = 20
        ..intervalWeights = {3: 0.2, 4: 0.2, 5: 1.2, 7: 0.2, 12: 0.2};
      await engine.start();
      final counts = <int, int>{};
      for (final interval in engine.questionPoolIntervals) {
        counts.update(interval, (v) => v + 1, ifAbsent: () => 1);
      }
      expect(counts.keys, containsAll(<int>[3, 4, 5, 7, 12]));
      expect(counts[5]!, greaterThan(counts[3]!));
      expect(engine.plannedAllocation[5], counts[5]);
    });
  });

  group('UserPreferences', () {
    test('theme mode and adaptive flag round-trip with safe defaults', () {
      final prefs = UserPreferences(themeMode: 'dark', adaptiveTraining: false);
      final restored = UserPreferences.fromJson(prefs.toJson());
      expect(restored.themeMode, 'dark');
      expect(restored.adaptiveTraining, isFalse);

      final legacy = UserPreferences.fromJson({'themeMode': 'neon'});
      expect(legacy.themeMode, 'system');
      expect(legacy.adaptiveTraining, isTrue);
    });
  });
}
