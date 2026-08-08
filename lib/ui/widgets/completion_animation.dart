import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// A calm completion sheet that keeps the same visual language as the
/// training workspace instead of switching to a separate dark overlay.
class CompletionAnimationWidget extends StatelessWidget {
  final int correctCount;
  final int totalQuestions;
  final int streak;
  final VoidCallback onDismiss;

  const CompletionAnimationWidget({
    super.key,
    required this.correctCount,
    required this.totalQuestions,
    required this.streak,
    required this.onDismiss,
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor.withAlpha(238),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: accent.withAlpha(18),
                        shape: BoxShape.circle,
                        border: Border.all(color: accent.withAlpha(80)),
                      ),
                      child: Icon(icon, size: 38, color: accent),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      '训练完成！',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${accuracy.toStringAsFixed(0)}% 准确率',
                      style: TextStyle(
                        fontSize: 34,
                        height: 1,
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      '$correctCount / $totalQuestions 道正确',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '最佳连击: $streak',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onDismiss,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('完成'),
                      ),
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
}
