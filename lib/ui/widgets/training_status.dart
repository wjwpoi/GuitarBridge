import 'package:flutter/material.dart';

import '../../core/guitar_math.dart';
import '../../core/theme.dart';
import '../../engine/training_engine.dart';
import '../../models/training_question.dart';
import 'common.dart';

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

  /// Shown under the idle message, e.g. which intervals adaptive mode favours.
  final String? planNote;

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
    this.planNote,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final c = context.gb;
        final state = engine.state;
        final compact = MediaQuery.sizeOf(context).width < 600;
        final showProgress =
            engine.isSessionActive || state == TrainingState.completed;
        final pad = compact ? 18.0 : 26.0;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 2,
                child: showProgress
                    ? TweenAnimationBuilder<double>(
                        tween: Tween(end: engine.progress),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.transparent,
                          color: c.accent,
                        ),
                      )
                    : null,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  pad,
                  compact ? 16 : 22,
                  pad,
                  compact ? 16 : 22,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildEyebrow(context, state),
                    const SizedBox(height: 8),
                    Text(
                      _title(state),
                      style: context.text.headlineSmall?.copyWith(
                        fontSize: compact ? 20 : 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.topLeft,
                        children: [...previous, if (current != null) current],
                      ),
                      child: Text(
                        _message(state),
                        key: ValueKey(_message(state)),
                        style: context.text.bodyMedium?.copyWith(
                          color: _hasFeedback(state) ? c.wrong : null,
                        ),
                      ),
                    ),
                    if (state == TrainingState.idle && planNote != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        planNote!,
                        style: context.text.bodySmall?.copyWith(
                          color: c.accent,
                        ),
                      ),
                    ],
                    if (engine.activeQuestion != null) ...[
                      SizedBox(height: compact ? 16 : 20),
                      _QuestionStrip(engine: engine),
                    ],
                    SizedBox(height: compact ? 16 : 22),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final showMetrics =
                            state == TrainingState.completed ||
                            (engine.isSessionActive && !compact);
                        final actions = _buildActions(context, state, compact);
                        if (!showMetrics) return actions;
                        // Wide cards keep the metrics beside the actions so
                        // the fretboard stays above the fold.
                        if (constraints.maxWidth >= 920) {
                          return Row(
                            children: [
                              Expanded(child: actions),
                              const SizedBox(width: 24),
                              _buildMetrics(context),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            actions,
                            SizedBox(height: compact ? 16 : 20),
                            const Divider(),
                            const SizedBox(height: 14),
                            _buildMetrics(context),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEyebrow(BuildContext context, TrainingState state) {
    final c = context.gb;
    final color = switch (state) {
      TrainingState.playingRoot || TrainingState.configuring => c.ink,
      TrainingState.waitingAnswer =>
        engine.failedAttempts > 0 ? c.wrong : c.accent,
      TrainingState.showingResult =>
        engine.lastAnswerCorrect ? c.correct : c.accent,
      TrainingState.audioError => c.wrong,
      _ => c.textMuted,
    };
    final number =
        (engine.currentQuestion +
                (state == TrainingState.showingResult ? 0 : 1))
            .clamp(1, engine.totalQuestions);
    final label = switch (state) {
      TrainingState.idle => '相对音准 · 指板定位',
      TrainingState.completed => '本轮结束',
      TrainingState.audioError => '音频',
      _ => '第 $number 题 · 共 ${engine.totalQuestions} 题',
    };
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: context.text.labelMedium)),
        if (state == TrainingState.waitingAnswer &&
            engine.maxFailedAttempts > 0)
          Semantics(
            label: '剩余尝试 ${engine.attemptsRemaining} 次',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < engine.maxFailedAttempts; i++)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < engine.failedAttempts ? c.wrong : c.strongLine,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  bool _hasFeedback(TrainingState state) =>
      state == TrainingState.waitingAnswer && engine.failedAttempts > 0;

  Widget _buildMetrics(BuildContext context) {
    final answered = engine.currentQuestion;
    final items = <(String, String)>[
      ('首答正确', '${engine.correctCount}/$answered'),
      ('正确率', answered == 0 ? '—' : '${engine.accuracy.toStringAsFixed(0)}%'),
      ('连击', '${engine.currentStreak}'),
      (
        '平均反应',
        engine.averageResponseTime == 0
            ? '—'
            : '${engine.averageResponseTime.toStringAsFixed(1)}s',
      ),
    ];
    return Wrap(
      spacing: 32,
      runSpacing: 10,
      children: [
        for (final (label, value) in items)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: context.text.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(label, style: context.text.bodySmall),
            ],
          ),
      ],
    );
  }

  String _title(TrainingState state) => switch (state) {
    TrainingState.idle => '听两个音，在指板上找到第二个',
    TrainingState.configuring => '正在准备题目',
    TrainingState.playingRoot => '仔细听',
    TrainingState.audioError => '声音没有正常播放',
    TrainingState.waitingAnswer => engine.failedAttempts > 0 ? '再试一次' : '找到目标音',
    TrainingState.showingResult =>
      engine.lastAnswerCorrect
          ? (engine.failedAttempts == 0 ? '答对了' : '找到了')
          : '答案在这里',
    TrainingState.completed => '这一轮练完了',
  };

  String _message(TrainingState state) {
    final question = engine.activeQuestion;
    switch (state) {
      case TrainingState.idle:
        return '先播放基准音并在指板上标出，再播放比它高的目标音。点击任意同音高的位置作答。';
      case TrainingState.configuring:
        return '正在按当前调性生成题目…';
      case TrainingState.playingRoot:
        return '基准音之后是目标音，留意两个音之间的距离。';
      case TrainingState.audioError:
        return '本题已暂停。请检查设备音量或浏览器的声音权限，然后重新开始。';
      case TrainingState.waitingAnswer:
        if (engine.failedAttempts == 0) {
          return '目标音比基准音高，点击指板上任意同音高的位置。';
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
          return '$pair 是${interval.chineseName}。';
        }
        return '目标音是 ${GuitarMath.noteLabel(question.target.midi)}，'
            '与基准音相差${interval.chineseName}，所有同音位置已标出。';
      case TrainingState.completed:
        return '可以查看各音程的表现，或用相同设置再练一轮。';
    }
  }

  Widget _buildActions(
    BuildContext context,
    TrainingState state,
    bool compact,
  ) {
    if (state == TrainingState.idle ||
        state == TrainingState.completed ||
        state == TrainingState.audioError) {
      return Row(
        children: [
          FilledButton(
            onPressed: onStart,
            child: Text(
              state == TrainingState.completed
                  ? '再练一轮'
                  : state == TrainingState.audioError
                  ? '重新尝试'
                  : startLabel ?? '开始训练',
            ),
          ),
          if (showShortcuts) ...[
            const SizedBox(width: 12),
            const KeyCap('Space'),
          ],
        ],
      );
    }

    final waiting = state == TrainingState.waitingAnswer;
    if (compact) {
      const dense = EdgeInsets.symmetric(horizontal: 10, vertical: 10);
      return Row(
        children: [
          if (onReplayQuestion != null) ...[
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(padding: dense),
                onPressed: waiting && !engine.isReplaying
                    ? onReplayQuestion
                    : null,
                child: const Text('重听'),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(padding: dense),
              onPressed: waiting ? onReplayRoot : null,
              child: const Text('基准音'),
            ),
          ),
          const SizedBox(width: 8),
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
              icon: const Icon(Icons.more_horiz_rounded),
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

    Widget withKey(String text, String key) => showShortcuts
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text(text), const SizedBox(width: 8), KeyCap(key)],
          )
        : Text(text);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (onReplayQuestion != null)
          FilledButton(
            onPressed: waiting && !engine.isReplaying ? onReplayQuestion : null,
            child: showShortcuts
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('重听两音'),
                      SizedBox(width: 8),
                      _OnAccentKey(),
                    ],
                  )
                : const Text('重听两音'),
          ),
        OutlinedButton(
          onPressed: waiting ? onReplayRoot : null,
          child: withKey('基准音', 'R'),
        ),
        OutlinedButton(
          onPressed: waiting ? onReplayTarget : null,
          child: withKey('目标音', 'T'),
        ),
        const SizedBox(width: 4),
        if (onReveal != null)
          TextButton(
            onPressed: waiting ? onReveal : null,
            child: const Text('看答案'),
          ),
        if (onFinish != null)
          TextButton(onPressed: onFinish, child: withKey('结束本轮', 'Esc')),
      ],
    );
  }
}

/// Key hint drawn on the filled accent button.
class _OnAccentKey extends StatelessWidget {
  const _OnAccentKey();

  @override
  Widget build(BuildContext context) {
    final color = DefaultTextStyle.of(context).style.color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withAlpha(110)),
      ),
      child: Text(
        'Space',
        style: TextStyle(color: color.withAlpha(210), fontSize: 10.5),
      ),
    );
  }
}

/// Root → target summary with the interval revealed after the answer.
class _QuestionStrip extends StatelessWidget {
  final TrainingEngine engine;

  const _QuestionStrip({required this.engine});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final question = engine.activeQuestion!;
    final resolved = engine.state == TrainingState.showingResult;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _NotePill(
          caption: '基准',
          value: GuitarMath.noteLabel(question.root.midi),
          fill: c.ink,
          foreground: c.onInk,
          border: c.ink,
        ),
        Icon(Icons.east_rounded, size: 16, color: c.textMuted),
        _NotePill(
          caption: '目标',
          value: resolved ? GuitarMath.noteLabel(question.target.midi) : '?',
          fill: resolved ? c.correct : Colors.transparent,
          foreground: resolved ? c.surface : c.textMuted,
          border: resolved ? c.correct : c.strongLine,
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: resolved ? 1 : 0,
          child: Text(
            '${question.interval.chineseName}  ${question.interval.abbreviation}',
            style: context.text.titleSmall?.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _NotePill extends StatelessWidget {
  final String caption;
  final String value;
  final Color fill;
  final Color foreground;
  final Color border;

  const _NotePill({
    required this.caption,
    required this.value,
    required this.fill,
    required this.foreground,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(caption, style: context.text.bodySmall),
        const SizedBox(width: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
