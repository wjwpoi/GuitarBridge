import 'package:flutter/material.dart';

import '../../core/guitar_math.dart';
import '../../core/theme.dart';
import '../../engine/training_engine.dart';
import '../../models/training_question.dart';

/// The training "stage": what is happening now, what to do next and how the
/// session is going. Rebuilds itself from [engine].
class TrainingStatusWidget extends StatelessWidget {
  final TrainingEngine engine;
  final VoidCallback onStart;
  final VoidCallback onReplayRoot;
  final VoidCallback onReplayTarget;
  final VoidCallback? onReplayQuestion;
  final VoidCallback? onReveal;
  final VoidCallback? onFinish;

  /// Shows keyboard hints next to the buttons (desktop / web with keyboard).
  final bool showShortcuts;

  /// Label for the start button when audio still needs a user gesture.
  final String? startLabel;

  const TrainingStatusWidget({
    super.key,
    required this.engine,
    required this.onStart,
    required this.onReplayRoot,
    required this.onReplayTarget,
    this.onReplayQuestion,
    this.onReveal,
    this.onFinish,
    this.showShortcuts = false,
    this.startLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final state = engine.state;
        final visuals = _visuals(state);
        final compact = MediaQuery.sizeOf(context).width < 600;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 4,
                child:
                    engine.isSessionActive || state == TrainingState.completed
                    ? LinearProgressIndicator(
                        value: engine.progress,
                        backgroundColor: AppTheme.raisedSurfaceColor,
                        color: visuals.color,
                      )
                    : ColoredBox(color: visuals.color.withAlpha(90)),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 22,
                  compact ? 14 : 18,
                  compact ? 16 : 22,
                  compact ? 14 : 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeadline(context, state, visuals, compact),
                    if (engine.activeQuestion != null) ...[
                      SizedBox(height: compact ? 12 : 16),
                      _QuestionStrip(engine: engine),
                    ],
                    SizedBox(height: compact ? 12 : 16),
                    _buildActions(state, compact),
                    // On phones the metrics give way to the fretboard while a
                    // question is open; they come back on the result screen.
                    if (state == TrainingState.completed ||
                        (engine.isSessionActive && !compact)) ...[
                      SizedBox(height: compact ? 12 : 16),
                      const Divider(height: 1),
                      SizedBox(height: compact ? 10 : 12),
                      _buildMetrics(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeadline(
    BuildContext context,
    TrainingState state,
    _Visuals visuals,
    bool compact,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: compact ? 40 : 46,
          height: compact ? 40 : 46,
          decoration: BoxDecoration(
            color: visuals.color.withAlpha(22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: visuals.color.withAlpha(90)),
          ),
          child: Icon(visuals.icon, color: visuals.color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title(state),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: compact ? 19 : 22,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Text(
                  _message(state),
                  key: ValueKey(_message(state)),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _messageColor(state),
                    fontWeight: _hasFeedback(state)
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (engine.isSessionActive || state == TrainingState.completed)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _QuestionCount(
              current:
                  (engine.currentQuestion +
                          (state == TrainingState.completed ||
                                  state == TrainingState.showingResult
                              ? 0
                              : 1))
                      .clamp(0, engine.totalQuestions)
                      .toInt(),
              total: engine.totalQuestions,
            ),
          ),
      ],
    );
  }

  bool _hasFeedback(TrainingState state) =>
      state == TrainingState.waitingAnswer && engine.failedAttempts > 0;

  Color _messageColor(TrainingState state) {
    if (_hasFeedback(state)) return AppTheme.wrongColor;
    return AppTheme.textSecondary;
  }

  Widget _buildMetrics() {
    final answered = engine.currentQuestion;
    return Row(
      children: [
        Expanded(child: _metric('首答正确', '${engine.correctCount}/$answered')),
        Expanded(
          child: _metric(
            '正确率',
            answered == 0 ? '—' : '${engine.accuracy.toStringAsFixed(0)}%',
          ),
        ),
        Expanded(child: _metric('连击', '${engine.currentStreak}')),
        Expanded(
          child: _metric(
            '平均反应',
            engine.averageResponseTime == 0
                ? '—'
                : '${engine.averageResponseTime.toStringAsFixed(1)}s',
          ),
        ),
      ],
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  _Visuals _visuals(TrainingState state) => switch (state) {
    TrainingState.idle => const _Visuals(
      Icons.headphones_rounded,
      AppTheme.secondaryColor,
    ),
    TrainingState.configuring => const _Visuals(
      Icons.tune_rounded,
      AppTheme.secondaryColor,
    ),
    TrainingState.playingRoot => const _Visuals(
      Icons.graphic_eq_rounded,
      AppTheme.primaryColor,
    ),
    TrainingState.audioError => const _Visuals(
      Icons.volume_off_rounded,
      AppTheme.wrongColor,
    ),
    TrainingState.waitingAnswer =>
      engine.failedAttempts > 0
          ? const _Visuals(Icons.hearing_rounded, AppTheme.wrongColor)
          : const _Visuals(Icons.hearing_rounded, AppTheme.accentColor),
    TrainingState.showingResult =>
      engine.lastAnswerCorrect
          ? const _Visuals(Icons.check_rounded, AppTheme.correctColor)
          : const _Visuals(Icons.lightbulb_rounded, AppTheme.accentColor),
    TrainingState.completed => const _Visuals(
      Icons.auto_awesome_rounded,
      AppTheme.accentColor,
    ),
  };

  String _title(TrainingState state) => switch (state) {
    TrainingState.idle => '准备开始',
    TrainingState.configuring => '正在准备题目',
    TrainingState.playingRoot => '仔细听',
    TrainingState.audioError => '声音没有正常播放',
    TrainingState.waitingAnswer => engine.failedAttempts > 0 ? '再试一次' : '找到目标音',
    TrainingState.showingResult =>
      engine.lastAnswerCorrect
          ? (engine.failedAttempts == 0 ? '答对了！' : '找到了')
          : '答案在这里',
    TrainingState.completed => '本轮完成',
  };

  String _message(TrainingState state) {
    final question = engine.activeQuestion;
    switch (state) {
      case TrainingState.idle:
        return '先听基准音（指板上会标出），再听目标音，然后在指板上点出目标音。';
      case TrainingState.configuring:
        return '正在按当前调性生成题目…';
      case TrainingState.playingRoot:
        return '基准音 → 目标音，记住两个音之间的距离。';
      case TrainingState.audioError:
        return '本题已暂停。请检查设备音量或浏览器声音权限，然后重新开始。';
      case TrainingState.waitingAnswer:
        if (engine.failedAttempts == 0) {
          return '目标音比基准音高。点击指板上任意同音高的位置作答。';
        }
        final remaining = engine.attemptsRemaining;
        final hint = switch (engine.lastDirection) {
          PitchDirection.tooLow => '偏低了，往更高的音找',
          PitchDirection.tooHigh => '偏高了，往更低的音找',
          PitchDirection.samePitchClassWrongOctave => '音名对了，但八度不对',
          null => '不对',
        };
        return remaining == null ? '$hint。' : '$hint。还可以再试 $remaining 次。';
      case TrainingState.showingResult:
        if (question == null) return '';
        final interval = question.interval;
        final pair =
            '${GuitarMath.noteLabel(question.root.midi)} → '
            '${GuitarMath.noteLabel(question.target.midi)}';
        if (engine.lastAnswerCorrect) {
          return '$pair 是${interval.chineseName}（${interval.abbreviation}）。';
        }
        return '目标音是 ${GuitarMath.noteLabel(question.target.midi)}，'
            '与基准音相差${interval.chineseName}（${interval.abbreviation}）。'
            '所有同音位置已标出。';
      case TrainingState.completed:
        return '查看本轮各音程的表现，或用相同设置再练一轮。';
    }
  }

  Widget _buildActions(TrainingState state, bool compact) {
    if (state == TrainingState.idle ||
        state == TrainingState.completed ||
        state == TrainingState.audioError) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.icon(
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
                  : startLabel ?? '开始训练',
            ),
          ),
          if (showShortcuts) const _KeyHint(keys: '空格'),
        ],
      );
    }

    final waiting = state == TrainingState.waitingAnswer;
    if (compact) {
      const dense = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
      return Row(
        children: [
          if (onReplayQuestion != null) ...[
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(padding: dense),
                onPressed: waiting && !engine.isReplaying
                    ? onReplayQuestion
                    : null,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('重听'),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(padding: dense),
              onPressed: waiting ? onReplayRoot : null,
              child: const Text('基准音'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(padding: dense),
              onPressed: waiting ? onReplayTarget : null,
              child: const Text('目标音'),
            ),
          ),
          if (onReveal != null || onFinish != null)
            PopupMenuButton<String>(
              tooltip: '更多',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'reveal') onReveal?.call();
                if (value == 'finish') onFinish?.call();
              },
              itemBuilder: (context) => [
                if (onReveal != null)
                  PopupMenuItem(
                    value: 'reveal',
                    enabled: waiting,
                    child: const Text('看答案'),
                  ),
                if (onFinish != null)
                  const PopupMenuItem(value: 'finish', child: Text('结束本轮')),
              ],
            ),
        ],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (onReplayQuestion != null)
          FilledButton.icon(
            onPressed: waiting && !engine.isReplaying ? onReplayQuestion : null,
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: Text(showShortcuts ? '重听两音 · 空格' : '重听两音'),
          ),
        OutlinedButton.icon(
          onPressed: waiting ? onReplayRoot : null,
          icon: const Icon(Icons.radio_button_checked_rounded, size: 16),
          label: Text(showShortcuts ? '基准音 · R' : '基准音'),
        ),
        OutlinedButton.icon(
          onPressed: waiting ? onReplayTarget : null,
          icon: const Icon(Icons.volume_up_rounded, size: 16),
          label: Text(showShortcuts ? '目标音 · T' : '目标音'),
        ),
        if (onReveal != null)
          TextButton.icon(
            onPressed: waiting ? onReveal : null,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
            icon: const Icon(Icons.visibility_rounded, size: 16),
            label: const Text('看答案'),
          ),
        if (onFinish != null)
          TextButton(
            onPressed: onFinish,
            style: TextButton.styleFrom(foregroundColor: AppTheme.textMuted),
            child: Text(showShortcuts ? '结束本轮 · Esc' : '结束本轮'),
          ),
      ],
    );
  }
}

class _Visuals {
  final IconData icon;
  final Color color;
  const _Visuals(this.icon, this.color);
}

/// Root → target summary with the interval revealed after the answer.
class _QuestionStrip extends StatelessWidget {
  final TrainingEngine engine;

  const _QuestionStrip({required this.engine});

  @override
  Widget build(BuildContext context) {
    final question = engine.activeQuestion!;
    final resolved = engine.state == TrainingState.showingResult;
    final targetColor = resolved ? AppTheme.correctColor : AppTheme.accentColor;
    final maxAttempts = engine.maxFailedAttempts;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.subtleSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineColor),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _NotePill(
            label: '基准',
            value: GuitarMath.noteLabel(question.root.midi),
            color: AppTheme.primaryColor,
            filled: true,
          ),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: AppTheme.textMuted,
          ),
          _NotePill(
            label: '目标',
            value: resolved ? GuitarMath.noteLabel(question.target.midi) : '?',
            color: targetColor,
            filled: resolved,
          ),
          if (resolved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${question.interval.chineseName} · ${question.interval.abbreviation}',
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else if (maxAttempts > 0)
            Semantics(
              label: '剩余尝试 ${engine.attemptsRemaining} 次',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < maxAttempts; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < engine.failedAttempts
                            ? AppTheme.wrongColor
                            : AppTheme.outlineColor,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NotePill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool filled;

  const _NotePill({
    required this.label,
    required this.value,
    required this.color,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minWidth: 42),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: filled ? color : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 1.4),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: filled ? Colors.white : color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _KeyHint extends StatelessWidget {
  final String keys;

  const _KeyHint({required this.keys});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.outlineColor),
      ),
      child: Text(
        keys,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuestionCount extends StatelessWidget {
  final int current;
  final int total;

  const _QuestionCount({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$current/$total',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          '题目',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}
