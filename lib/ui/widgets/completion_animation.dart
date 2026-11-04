import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../engine/training_engine.dart';
import 'interval_breakdown.dart';

/// Session summary shown over the workspace when a round ends.
class CompletionAnimationWidget extends StatelessWidget {
  /// Questions answered correctly on the first attempt.
  final int correctCount;
  final int totalQuestions;
  final int streak;
  final VoidCallback onDismiss;
  final VoidCallback? onRestart;
  final Map<int, IntervalTally> intervalTallies;
  final double averageResponseSeconds;

  const CompletionAnimationWidget({
    super.key,
    required this.correctCount,
    required this.totalQuestions,
    required this.streak,
    required this.onDismiss,
    this.onRestart,
    this.intervalTallies = const {},
    this.averageResponseSeconds = 0,
  });

  double get accuracy =>
      totalQuestions > 0 ? correctCount / totalQuestions * 100 : 0;

  @override
  Widget build(BuildContext context) {
    final accent = accuracy >= 90
        ? AppTheme.correctColor
        : accuracy >= 70
        ? AppTheme.accentColor
        : AppTheme.secondaryColor;
    final icon = accuracy >= 90
        ? Icons.emoji_events
        : accuracy >= 70
        ? Icons.star
        : Icons.music_note;
    final weakest = IntervalBreakdown.weakest(intervalTallies);

    return Material(
      color: AppTheme.textPrimary.withAlpha(70),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: accent.withAlpha(22),
                              shape: BoxShape.circle,
                              border: Border.all(color: accent.withAlpha(90)),
                            ),
                            child: Icon(icon, size: 28, color: accent),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '训练完成！',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '首次即答对 $correctCount / $totalQuestions 题',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _stat(
                            '${accuracy.toStringAsFixed(0)}%',
                            '正确率',
                            accent,
                          ),
                          _stat('$streak', '最佳连击', AppTheme.textPrimary),
                          _stat(
                            averageResponseSeconds == 0
                                ? '—'
                                : '${averageResponseSeconds.toStringAsFixed(1)}s',
                            '平均反应',
                            AppTheme.textPrimary,
                          ),
                        ],
                      ),
                      if (intervalTallies.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          '各音程首答表现',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        IntervalBreakdown(tallies: intervalTallies),
                        if (weakest != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withAlpha(22),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '建议多练：${IntervalBreakdown.nameFor(weakest)}。'
                              '可以先唱出基准音，再在心里数音阶级数找到目标音。',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onDismiss,
                              child: const Text('完成'),
                            ),
                          ),
                          if (onRestart != null) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: onRestart,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('再练一轮'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              height: 1.1,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
