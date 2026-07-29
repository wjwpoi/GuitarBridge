import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../engine/training_engine.dart';

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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStateIcon(state),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _stateTitle(state),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _stateMessage(state),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (state != TrainingState.idle)
                      Text(
                        '${engine.currentQuestion}/${engine.totalQuestions}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                if (state != TrainingState.idle) ...[
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: engine.progress,
                      minHeight: 5,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metric('正确', '${engine.correctCount}'),
                    _metric(
                      '准确率',
                      state == TrainingState.idle
                          ? '—'
                          : '${engine.accuracy.toStringAsFixed(0)}%',
                    ),
                    _metric('连击', '${engine.currentStreak}'),
                    _metric(
                      '尝试',
                      state == TrainingState.waitingAnswer
                          ? '${engine.failedAttempts + 1}'
                          : '—',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildActions(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStateIcon(TrainingState state) {
    final (icon, color) = switch (state) {
      TrainingState.idle => (Icons.headphones_rounded, AppTheme.primaryColor),
      TrainingState.configuring => (
        Icons.tune_rounded,
        AppTheme.secondaryColor,
      ),
      TrainingState.playingRoot => (
        Icons.radio_button_checked_rounded,
        AppTheme.primaryColor,
      ),
      TrainingState.audioError => (
        Icons.volume_off_rounded,
        AppTheme.wrongColor,
      ),
      TrainingState.waitingAnswer => (
        Icons.hearing_rounded,
        AppTheme.accentColor,
      ),
      TrainingState.showingResult =>
        engine.lastAnswerCorrect
            ? (Icons.check_rounded, AppTheme.correctColor)
            : (Icons.close_rounded, AppTheme.wrongColor),
      TrainingState.completed => (
        Icons.auto_awesome_rounded,
        AppTheme.accentColor,
      ),
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  String _stateTitle(TrainingState state) => switch (state) {
    TrainingState.idle => '准备开始',
    TrainingState.configuring => '正在准备题目',
    TrainingState.playingRoot => '听基准音',
    TrainingState.audioError => '声音没有可靠播放',
    TrainingState.waitingAnswer => '找到目标音',
    TrainingState.showingResult => engine.lastAnswerCorrect ? '判断正确' : '再听一次',
    TrainingState.completed => '本轮完成',
  };

  String _stateMessage(TrainingState state) => switch (state) {
    TrainingState.idle => '每题依次播放基准音与目标音，建议先使用清晰音色。',
    TrainingState.configuring => '正在按当前调性生成一个八度内的上行音程。',
    TrainingState.playingRoot => '先记住基准音，目标音会紧接着播放。',
    TrainingState.audioError => '本题已暂停，没有进入答题状态。请检查声音设备后重新开始。',
    TrainingState.waitingAnswer => '在指板任意位置选择目标音；相同 MIDI 音高都判定为正确。',
    TrainingState.showingResult =>
      engine.lastAnswerCorrect
          ? '很好，保持对两个音之间距离的记忆。'
          : engine.showCorrectPosition
          ? '正确音高已在指板上标出。'
          : '答案未推进，可以重播后继续尝试。',
    TrainingState.completed => '休息一下，或使用相同设置再练一轮。',
  };

  Widget _metric(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 74),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.subtleSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(TrainingState state) {
    if (state == TrainingState.idle ||
        state == TrainingState.completed ||
        state == TrainingState.audioError) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton.icon(
          onPressed: onStart,
          icon: Icon(
            state == TrainingState.completed
                ? Icons.refresh_rounded
                : state == TrainingState.audioError
                ? Icons.replay_rounded
                : Icons.play_arrow_rounded,
          ),
          label: Text(
            state == TrainingState.completed
                ? '再练一轮'
                : state == TrainingState.audioError
                ? '重新尝试'
                : '开始训练',
          ),
        ),
      );
    }

    if (state == TrainingState.waitingAnswer) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: onReplayRoot,
            icon: const Icon(Icons.radio_button_checked_rounded, size: 18),
            label: const Text('重播基准音'),
          ),
          OutlinedButton.icon(
            onPressed: onReplayTarget,
            icon: const Icon(Icons.volume_up_rounded, size: 18),
            label: const Text('重播目标音'),
          ),
        ],
      );
    }

    return const SizedBox(height: 48);
  }
}
