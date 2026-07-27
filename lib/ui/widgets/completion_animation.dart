import 'package:flutter/material.dart';

/// 完成动画（对应原 Swift CompletionAnimationView.swift）
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
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 星级评分
            Icon(
              accuracy >= 90
                  ? Icons.emoji_events
                  : accuracy >= 70
                      ? Icons.star
                      : Icons.music_note,
              size: 80,
              color: accuracy >= 90
                  ? Colors.amber
                  : accuracy >= 70
                      ? Colors.cyan
                      : Colors.grey,
            ),
            const SizedBox(height: 24),

            Text(
              '训练完成！',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Text(
              '${accuracy.toStringAsFixed(0)}% 准确率',
              style: const TextStyle(fontSize: 36, color: Colors.cyan),
            ),
            const SizedBox(height: 8),

            Text(
              '$correctCount / $totalQuestions 道正确',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 4),

            Text(
              '最佳连击: $streak',
              style: const TextStyle(fontSize: 16, color: Colors.amber),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: onDismiss,
              icon: const Icon(Icons.check),
              label: const Text('完成'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
