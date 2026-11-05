import 'dart:math';

import '../models/practice_record.dart';
import 'training_engine.dart';

/// Cross-session adaptive question planning.
///
/// History is reduced to a smoothed error estimate per interval
/// (`(misses + 1) / (attempts + 2)`), so an interval that was never practised
/// starts at 50 % and one answered correctly many times trends towards 0.
/// Every available interval keeps at least one question per session; the
/// remaining questions are shared out in proportion to those estimates.
class AdaptivePlanner {
  AdaptivePlanner._();

  /// Records considered, newest first.
  static const int historyWindow = 30;

  /// Keeps mastered intervals in rotation instead of letting them vanish.
  static const double baseWeight = 0.15;

  /// Sums first-try results per interval over the newest [historyWindow]
  /// records.
  static Map<int, IntervalTally> historyFrom(
    Iterable<PracticeRecord> records, {
    int window = historyWindow,
  }) {
    final sorted = records.toList()..sort((a, b) => b.date.compareTo(a.date));
    final result = <int, IntervalTally>{};
    for (final record in sorted.take(window)) {
      for (final entry in record.intervalResults.entries) {
        final tally = IntervalTally(entry.value.$1, entry.value.$2);
        result.update(
          entry.key,
          (existing) => existing + tally,
          ifAbsent: () => tally,
        );
      }
    }
    return result;
  }

  /// Smoothed miss rate in 0..1.
  static double errorEstimate(IntervalTally? tally) {
    final total = tally?.total ?? 0;
    final misses = total - (tally?.firstTryCorrect ?? 0);
    return (misses + 1) / (total + 2);
  }

  /// Weight per interval for [allowedIntervals].
  static Map<int, double> weightsFor(
    Iterable<int> allowedIntervals,
    Map<int, IntervalTally> history,
  ) {
    return {
      for (final interval in allowedIntervals)
        interval: baseWeight + errorEstimate(history[interval]),
    };
  }

  /// Splits [count] questions across [intervals].
  ///
  /// Without [weights] the split is balanced (sizes differ by at most one).
  /// With weights, each interval first gets one question when [count] allows,
  /// then the rest follow the weights using the largest-remainder method.
  static Map<int, int> allocate(
    List<int> intervals,
    int count,
    Map<int, double>? weights,
    Random random,
  ) {
    final result = {for (final interval in intervals) interval: 0};
    if (intervals.isEmpty || count <= 0) return result;

    final order = [...intervals]..shuffle(random);
    if (weights == null) {
      for (var i = 0; i < count; i++) {
        result.update(order[i % order.length], (value) => value + 1);
      }
      return result;
    }

    double weightOf(int interval) => max(0.0001, weights[interval] ?? 0.5);
    var remaining = count;
    if (count >= intervals.length) {
      for (final interval in intervals) {
        result[interval] = 1;
      }
      remaining -= intervals.length;
    } else {
      // Too few questions to cover everything: take the weakest first.
      order.sort((a, b) => weightOf(b).compareTo(weightOf(a)));
      for (final interval in order.take(count)) {
        result[interval] = 1;
      }
      return result;
    }

    final total = intervals.fold<double>(0, (sum, i) => sum + weightOf(i));
    final shares = {
      for (final interval in intervals)
        interval: remaining * weightOf(interval) / total,
    };
    var assigned = 0;
    for (final entry in shares.entries) {
      final whole = entry.value.floor();
      result.update(entry.key, (value) => value + whole);
      assigned += whole;
    }
    final byRemainder = [...order]
      ..sort(
        (a, b) => (shares[b]! - shares[b]!.floor()).compareTo(
          shares[a]! - shares[a]!.floor(),
        ),
      );
    for (final interval in byRemainder.take(remaining - assigned)) {
      result.update(interval, (value) => value + 1);
    }
    return result;
  }

  /// Up to [limit] practised intervals that clearly need work, weakest first.
  static List<int> focusIntervals(
    Iterable<int> allowedIntervals,
    Map<int, IntervalTally> history, {
    int limit = 2,
  }) {
    final candidates =
        allowedIntervals
            .where((interval) => (history[interval]?.total ?? 0) >= 2)
            .where((interval) => errorEstimate(history[interval]) > 0.3)
            .toList()
          ..sort(
            (a, b) =>
                errorEstimate(history[b]).compareTo(errorEstimate(history[a])),
          );
    return candidates.take(limit).toList();
  }
}
