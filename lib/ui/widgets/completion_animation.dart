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

  /// Whether the next round will weight weak intervals.
  final bool adaptive;

  const CompletionAnimationWidget({
    super.key,
    required this.correctCount,
    required this.totalQuestions,
    required this.streak,
    required this.onDismiss,
    this.onRestart,
    this.intervalTallies = const {},
    this.averageResponseSeconds = 0,
    this.adaptive = false,
  });

  double get accuracy =>
      totalQuestions > 0 ? correctCount / totalQuestions * 100 : 0;

  String get _headline => accuracy >= 90
      ? '耳朵很准'
      : accuracy >= 70
      ? '不错的一轮'
      : accuracy >= 40
      ? '在进步'
      : '慢慢来';

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final weakest = IntervalBreakdown.weakest(intervalTallies);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Material(
        color: Colors.black.withAlpha((90 * t).round()),
        child: Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: child,
          ),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('本轮结束', style: context.text.labelMedium),
                      const SizedBox(height: 6),
                      Text(_headline, style: context.text.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        '首次即答对 $correctCount / $totalQuestions 题',
                        style: context.text.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _stat(
                            context,
                            '${accuracy.toStringAsFixed(0)}%',
                            '正确率',
                            emphasize: true,
                          ),
                          _stat(context, '$streak', '最佳连击'),
                          _stat(
                            context,
                            averageResponseSeconds == 0
                                ? '—'
                                : '${averageResponseSeconds.toStringAsFixed(1)}s',
                            '平均反应',
                          ),
                        ],
                      ),
                      if (intervalTallies.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text('各音程首答表现', style: context.text.labelMedium),
                        const SizedBox(height: 8),
                        IntervalBreakdown(tallies: intervalTallies),
                        if (weakest != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            '${adaptive ? '下一轮会多安排一些' : '建议多练'}'
                            '${IntervalBreakdown.nameFor(weakest)}。'
                            '练习时可以先在心里唱出基准音，再数音阶级数。',
                            style: context.text.bodySmall?.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 24),
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
                              child: FilledButton(
                                onPressed: onRestart,
                                child: const Text('再练一轮'),
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

  Widget _stat(
    BuildContext context,
    String value,
    String label, {
    bool emphasize = false,
  }) {
    final c = context.gb;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.serif,
              fontSize: 28,
              height: 1.1,
              color: emphasize ? c.accent : c.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: context.text.bodySmall),
        ],
      ),
    );
  }
}
