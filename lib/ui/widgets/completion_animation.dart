import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../engine/training_engine.dart';
import '../../models/training_question.dart';
import 'interval_breakdown.dart';
import 'training_status.dart';

/// The end-of-round sheet: one sentence of result, three numbers, every
/// question in order, and the intervals that need work.
class CompletionAnimationWidget extends StatelessWidget {
  /// Questions answered correctly on the first attempt.
  final int correctCount;
  final int totalQuestions;
  final int streak;
  final VoidCallback onDismiss;
  final VoidCallback? onRestart;
  final Map<int, IntervalTally> intervalTallies;
  final List<QuestionOutcome> outcomes;
  final double averageResponseSeconds;

  /// Date, key and difficulty, e.g. "11 月 6 日 21:40 · C 自然大调 · 进阶".
  final String? subtitle;

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
    this.outcomes = const [],
    this.averageResponseSeconds = 0,
    this.subtitle,
    this.adaptive = false,
  });

  double get accuracy =>
      totalQuestions > 0 ? correctCount / totalQuestions * 100 : 0;

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final weakest = IntervalBreakdown.weakest(intervalTallies);
    final compact = MediaQuery.sizeOf(context).width < 600;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Material(
        color: Colors.black.withAlpha((80 * t).round()),
        child: Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - t)),
            child: child,
          ),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                decoration: BoxDecoration(
                  color: c.canvas,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: c.controlLine),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(16),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  compact ? 22 : 36,
                  compact ? 26 : 36,
                  compact ? 22 : 36,
                  compact ? 22 : 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      subtitle ?? '本轮结束',
                      style: AppTheme.monoStyle(size: 12, color: c.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      TrainingStatusWidget.conclusion(
                        correctCount,
                        totalQuestions,
                      ),
                      style: AppTheme.serifStyle(
                        size: compact ? 24 : 28,
                        color: c.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _numbers(context),
                    if (outcomes.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _sequence(context),
                    ],
                    if (intervalTallies.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        '各音程',
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      IntervalBreakdown(tallies: intervalTallies),
                    ],
                    if (weakest != null) ...[
                      const SizedBox(height: 20),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: adaptive ? '下一轮会多出几道' : '建议多练'),
                            TextSpan(
                              text: IntervalBreakdown.nameFor(weakest),
                              style: AppTheme.serifStyle(
                                size: 14.5,
                                color: c.textPrimary,
                                height: 1.7,
                              ),
                            ),
                            const TextSpan(text: '。听的时候先在心里唱出基准音，再往上数音阶级数。'),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: c.textBody,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: onDismiss,
                          child: const Text('完成'),
                        ),
                        if (onRestart != null) ...[
                          const SizedBox(width: 10),
                          FilledButton(
                            onPressed: onRestart,
                            child: const Text('再练一轮'),
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
    );
  }

  Widget _numbers(BuildContext context) {
    final c = context.gb;
    Widget cell(
      String value,
      String label, {
      Color? color,
      bool first = false,
    }) => Expanded(
      child: Container(
        padding: EdgeInsets.fromLTRB(first ? 0 : 18, 14, 0, 14),
        decoration: first
            ? null
            : BoxDecoration(
                border: Border(left: BorderSide(color: c.hairline)),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTheme.serifStyle(
                size: 30,
                color: color ?? c.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12.5, color: c.textMuted)),
          ],
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: c.hairline)),
      ),
      child: Row(
        children: [
          cell(
            '${accuracy.toStringAsFixed(0)}%',
            '首答正确率',
            color: c.accent,
            first: true,
          ),
          cell('$streak', '最长连对'),
          cell(
            averageResponseSeconds == 0
                ? '—'
                : '${averageResponseSeconds.toStringAsFixed(1)}s',
            '平均反应',
          ),
        ],
      ),
    );
  }

  Widget _sequence(BuildContext context) {
    final c = context.gb;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('逐题', style: TextStyle(fontSize: 13, color: c.textSecondary)),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            // A fixed ten-column grid, so a short round keeps the same scale.
            const perRow = 10;
            final width = (constraints.maxWidth - 6 * (perRow - 1)) / perRow;
            return Wrap(
              spacing: 6,
              runSpacing: 10,
              children: [
                for (final (i, o) in outcomes.indexed)
                  SizedBox(
                    width: width,
                    child: Semantics(
                      label:
                          '第 ${i + 1} 题 ${o.question.interval.chineseName}，'
                          '${o.firstTryCorrect
                              ? '首答对'
                              : o.solved
                              ? '重试后对'
                              : '未答出'}',
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _OutcomeMark(outcome: o),
                          const SizedBox(height: 6),
                          Text(
                            o.question.interval.abbreviation,
                            textAlign: TextAlign.center,
                            style: AppTheme.monoStyle(
                              size: 10.5,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          '■ 首答对  □ 重试后对  ／ 未答出',
          style: AppTheme.monoStyle(size: 11.5, color: c.textMuted),
        ),
      ],
    );
  }
}

class _OutcomeMark extends StatelessWidget {
  final QuestionOutcome outcome;

  const _OutcomeMark({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final o = outcome;
    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: o.firstTryCorrect ? c.ink : null,
        borderRadius: BorderRadius.circular(3),
        border: o.firstTryCorrect
            ? null
            : Border.all(
                color: o.solved ? c.ink : c.wrong,
                width: o.solved ? 2 : 1.5,
              ),
      ),
      child: !o.firstTryCorrect && !o.solved
          ? CustomPaint(painter: _Slash(c.wrong))
          : null,
    );
  }
}

class _Slash extends CustomPainter {
  final Color color;

  _Slash(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    canvas.drawLine(
      Offset(cx - 5, size.height * 0.72),
      Offset(cx + 5, size.height * 0.28),
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _Slash old) => old.color != color;
}
