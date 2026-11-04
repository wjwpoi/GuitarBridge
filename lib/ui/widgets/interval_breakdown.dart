import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../engine/training_engine.dart';
import '../../models/note.dart';

/// Horizontal bars of first-try accuracy per interval, weakest highlighted.
class IntervalBreakdown extends StatelessWidget {
  final Map<int, IntervalTally> tallies;

  /// Hide intervals with fewer attempts than this (stats screen noise).
  final int minAttempts;

  const IntervalBreakdown({
    super.key,
    required this.tallies,
    this.minAttempts = 1,
  });

  static String nameFor(int semitones) {
    final interval = IntervalType.values.firstWhere(
      (candidate) => candidate.semitones == semitones,
      orElse: () => IntervalType.unison,
    );
    return interval.chineseName;
  }

  static String abbreviationFor(int semitones) => IntervalType.values
      .firstWhere(
        (candidate) => candidate.semitones == semitones,
        orElse: () => IntervalType.unison,
      )
      .abbreviation;

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
      return const Text(
        '还没有足够的数据。',
        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
      );
    }
    final weakestInterval = weakest(tallies, minAttempts: minAttempts);
    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
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
    final ratio = tally.total == 0 ? 0.0 : tally.firstTryCorrect / tally.total;
    final color = ratio >= 0.8
        ? AppTheme.correctColor
        : ratio >= 0.5
        ? AppTheme.accentColor
        : AppTheme.wrongColor;
    return Semantics(
      label:
          '${IntervalBreakdown.nameFor(semitones)} ${tally.firstTryCorrect} / ${tally.total}',
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              IntervalBreakdown.nameFor(semitones),
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12.5,
                fontWeight: isWeakest ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              IntervalBreakdown.abbreviationFor(semitones),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                color: color,
                backgroundColor: AppTheme.raisedSurfaceColor,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '${tally.firstTryCorrect}/${tally.total}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
