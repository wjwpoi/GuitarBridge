import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../engine/training_engine.dart';
import '../../models/note.dart';

/// First-try accuracy per interval as thin bars, weakest emphasised.
class IntervalBreakdown extends StatelessWidget {
  final Map<int, IntervalTally> tallies;

  /// Hide intervals with fewer attempts than this.
  final int minAttempts;

  const IntervalBreakdown({
    super.key,
    required this.tallies,
    this.minAttempts = 1,
  });

  static IntervalType _type(int semitones) => IntervalType.values.firstWhere(
    (candidate) => candidate.semitones == semitones,
    orElse: () => IntervalType.unison,
  );

  static String nameFor(int semitones) => _type(semitones).chineseName;

  static String abbreviationFor(int semitones) => _type(semitones).abbreviation;

  /// The interval with the lowest first-try accuracy, if any was missed.
  static int? weakest(Map<int, IntervalTally> tallies, {int minAttempts = 1}) {
    int? result;
    double? lowest;
    for (final entry in tallies.entries) {
      if (entry.value.total < minAttempts) continue;
      if (entry.value.firstTryCorrect == entry.value.total) continue;
      if (lowest == null || entry.value.accuracy < lowest) {
        lowest = entry.value.accuracy;
        result = entry.key;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final entries =
        tallies.entries
            .where((entry) => entry.value.total >= minAttempts)
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) {
      return Text('还没有足够的数据。', style: context.text.bodySmall);
    }
    final weakestInterval = weakest(tallies, minAttempts: minAttempts);
    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _IntervalRow(
              semitones: entry.key,
              tally: entry.value,
              isWeakest: entry.key == weakestInterval,
            ),
          ),
      ],
    );
  }
}

class _IntervalRow extends StatelessWidget {
  final int semitones;
  final IntervalTally tally;
  final bool isWeakest;

  const _IntervalRow({
    required this.semitones,
    required this.tally,
    required this.isWeakest,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final ratio = tally.total == 0 ? 0.0 : tally.firstTryCorrect / tally.total;
    final color = ratio >= 0.8
        ? c.correct
        : ratio >= 0.5
        ? c.textSecondary
        : c.wrong;
    return Semantics(
      label:
          '${IntervalBreakdown.nameFor(semitones)} ${tally.firstTryCorrect} / ${tally.total}',
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              IntervalBreakdown.nameFor(semitones),
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 13,
                fontWeight: isWeakest ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              IntervalBreakdown.abbreviationFor(semitones),
              style: TextStyle(color: c.textMuted, fontSize: 11.5),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  color: color,
                  backgroundColor: c.surfaceMuted,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${tally.firstTryCorrect}/${tally.total}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
