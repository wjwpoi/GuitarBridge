import 'package:flutter/material.dart';
import '../../engine/training_engine.dart';

/// 训练状态面板（对应原 Swift TrainingStatusView.swift）
/// 显示进度、准确率、连击、重播按钮
class TrainingStatusWidget extends StatelessWidget {
  final TrainingEngine engine;
  final VoidCallback onStart;
  final VoidCallback onReplayRoot;
  final VoidCallback onReplayTarget;

  const TrainingStatusWidget({
    super.key,
    required this.engine,
    required this.onStart,
    required this.onReplayRoot,
    required this.onReplayTarget,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final state = engine.state;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 进度条
                if (state != TrainingState.idle) ...[
                  _buildProgressBar(),
                  const SizedBox(height: 12),
                ],

                // 统计数据行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('进度', '${engine.currentQuestion}/${engine.totalQuestions}'),
                    _buildStat('正确', '${engine.correctCount}'),
                    _buildStat(
                      '准确率',
                      state == TrainingState.idle
                          ? '--'
                          : '${engine.accuracy.toStringAsFixed(0)}%',
                    ),
                    _buildStat('连击', '${engine.currentStreak}'),
                  ],
                ),

                const SizedBox(height: 12),

                // 操作按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state == TrainingState.idle)
                      _buildActionButton('开始训练', Icons.play_arrow, onStart, isPrimary: true),

                    if (state == TrainingState.completed)
                      _buildActionButton('再来一轮', Icons.refresh, onStart, isPrimary: true),

                    if (state == TrainingState.waitingAnswer) ...[
                      _buildActionButton(null, Icons.replay, onReplayRoot,
                          tooltip: '重播基准音'),
                      const SizedBox(width: 12),
                      _buildActionButton(null, Icons.volume_up, onReplayTarget,
                          tooltip: '重播目标音'),
                    ],
                  ],
                ),

                // 提示信息
                if (state == TrainingState.showingResult)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      engine.lastAnswerCorrect ? '✓ 正确！' : '✗ 错误',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: engine.lastAnswerCorrect
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),

                if (state == TrainingState.completed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '训练完成！最佳连击: ${engine.bestStreak}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.cyan,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: engine.progress,
        minHeight: 6,
        backgroundColor: Colors.grey.withAlpha(60),
        valueColor: const AlwaysStoppedAnimation(Colors.cyan),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String? label,
    IconData icon,
    VoidCallback onPressed, {
    bool isPrimary = false,
    String? tooltip,
  }) {
    final button = isPrimary
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label ?? ''),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          )
        : IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
            tooltip: tooltip,
            color: Colors.cyan,
          );

    return button;
  }
}
