import 'package:flutter/material.dart';

import '../../core/guitar_math.dart';
import '../../core/theme.dart';
import '../../engine/training_engine.dart';
import '../../models/training_question.dart';

/// An interval the adaptive planner will favour, with its recent first-try
/// accuracy (0–100).
typedef FocusInterval = ({String name, double accuracy});

/// The question area: what is asked now, what just happened, and how the
/// round is going. Laid out with type and rules, not a card.
class TrainingStatusWidget extends StatelessWidget {
  final TrainingEngine engine;
  final VoidCallback onStart;
  final VoidCallback onReplayRoot;
  final VoidCallback onReplayTarget;
  final VoidCallback? onReplayQuestion;
  final VoidCallback? onReveal;
  final VoidCallback? onFinish;

  /// Shows key hints inside the buttons (desktop / web with a keyboard).
  final bool showShortcuts;

  /// Label for the start button when audio still needs a user gesture.
  final String? startLabel;

  /// Intervals the next round will favour, shown before it starts.
  final List<FocusInterval> focus;

  /// Whether the board shows only inlays (changes the idle explanation).
  final bool inlayOnly;

  /// Phones render the action buttons in a bottom bar instead.
  final bool showActions;

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
    this.focus = const [],
    this.inlayOnly = false,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final compact = constraints.maxWidth < 600;
          final main = _buildMain(context, compact);
          final aside = _buildAside(context, compact);
          if (wide && aside != null) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: main),
                const SizedBox(width: 56),
                SizedBox(width: 340, child: aside),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              main,
              if (aside != null && !compact) ...[
                const SizedBox(height: 28),
                aside,
              ],
            ],
          );
        },
      ),
    );
  }

  bool get _idle => engine.state == TrainingState.idle;
  bool get _completed => engine.state == TrainingState.completed;
  bool get _audioError => engine.state == TrainingState.audioError;

  // ---------------------------------------------------------------------------
  // Main column

  Widget _buildMain(BuildContext context, bool compact) {
    if (_idle) return _buildIdle(context, compact);
    if (_completed) return _buildCompleted(context, compact);
    if (_audioError) return _buildAudioError(context, compact);
    return _buildQuestion(context, compact);
  }

  Widget _buildIdle(BuildContext context, bool compact) {
    final c = context.gb;
    final reveal = engine.maxFailedAttempts == 0
        ? '答错不揭晓'
        : '答错 ${engine.maxFailedAttempts} 次后揭晓';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '听两个音，\n在指板上找到第二个。',
          style: AppTheme.serifStyle(
            size: compact ? 28 : 40,
            color: c.textPrimary,
            height: 1.3,
          ),
        ),
        SizedBox(height: compact ? 14 : 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            inlayOnly
                ? '先响的是基准音，它会在指板上亮起；紧接着是一个八度以内、比它高的音。'
                      '点出它，任何同音高的位置都算对。现在只有品记可看，靠 3、5、7、9、12 品定位。'
                : '先响的是基准音，它会在指板上亮起；紧接着是一个八度以内、比它高的音。'
                      '点出它，任何同音高的位置都算对。',
            style: context.text.bodyLarge?.copyWith(
              color: c.textSecondary,
              height: 1.75,
              fontSize: compact ? 14.5 : 15.5,
            ),
          ),
        ),
        if (compact && focus.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            '这一轮会多安排${focus.map((f) => f.name).join('和')}。',
            style: TextStyle(fontSize: 13.5, color: c.textSecondary),
          ),
        ],
        SizedBox(height: compact ? 20 : 28),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _PrimaryButton(
              label: startLabel ?? '开始训练',
              hint: showShortcuts ? 'Space' : null,
              onPressed: onStart,
            ),
            Text(
              '${engine.questionsPerSession} 题 · $reveal',
              style: TextStyle(fontSize: 14, color: c.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompleted(BuildContext context, bool compact) {
    final c = context.gb;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('本轮结束', style: AppTheme.monoStyle(color: c.textMuted)),
        const SizedBox(height: 14),
        Text(
          conclusion(engine.correctCount, engine.totalQuestions),
          style: AppTheme.serifStyle(
            size: compact ? 26 : 34,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: '再练一轮',
          hint: showShortcuts ? 'Space' : null,
          onPressed: onStart,
        ),
      ],
    );
  }

  Widget _buildAudioError(BuildContext context, bool compact) {
    final c = context.gb;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '声音没有正常播放',
          style: AppTheme.serifStyle(size: compact ? 24 : 30, color: c.wrong),
        ),
        const SizedBox(height: 10),
        Text(
          '这一题已暂停。检查设备音量或浏览器的声音权限，然后重试。',
          style: context.text.bodyLarge?.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: 22),
        _PrimaryButton(label: '重新开始', onPressed: onStart),
      ],
    );
  }

  Widget _buildQuestion(BuildContext context, bool compact) {
    final c = context.gb;
    final question = engine.activeQuestion;
    final resolved = engine.state == TrainingState.showingResult;
    final number = (engine.currentQuestion + (resolved ? 0 : 1))
        .clamp(1, engine.totalQuestions)
        .toInt();
    final noteSize = compact ? 48.0 : 64.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '第 ${number.toString().padLeft(2, '0')} 题 · 共 ${engine.totalQuestions} 题',
              style: AppTheme.monoStyle(color: c.textMuted),
            ),
            if (compact) ...[
              const Spacer(),
              _Ledger(engine: engine, size: 10, gap: 4),
            ],
          ],
        ),
        SizedBox(height: compact ? 14 : 18),
        if (question != null)
          _NoteRow(question: question, resolved: resolved, noteSize: noteSize)
        else
          SizedBox(height: noteSize + 20),
        SizedBox(height: compact ? 14 : 18),
        _Feedback(engine: engine),
        if (showActions) ...[
          SizedBox(height: compact ? 16 : 22),
          resolved
              ? _NextQuestionHint(engine: engine)
              : TrainingActions(
                  engine: engine,
                  showShortcuts: showShortcuts,
                  onReplayRoot: onReplayRoot,
                  onReplayTarget: onReplayTarget,
                  onReplayQuestion: onReplayQuestion,
                  onReveal: onReveal,
                  onFinish: onFinish,
                ),
        ],
      ],
    );
  }

  /// "十题里，七题一次听对。"
  static String conclusion(int correct, int total) {
    String n(int value) {
      const digits = ['零', '一', '两', '三', '四', '五', '六', '七', '八', '九', '十'];
      if (value >= 0 && value <= 10) return digits[value];
      return '$value';
    }

    final totalWord = total == 2 ? '二' : n(total);
    if (correct == total) return '$totalWord题全部一次听对。';
    if (correct == 0) return '$totalWord题里，没有一题一次听对。';
    return '$totalWord题里，${n(correct)}题一次听对。';
  }

  // ---------------------------------------------------------------------------
  // Aside

  Widget? _buildAside(BuildContext context, bool compact) {
    final c = context.gb;
    if (_idle) {
      if (focus.isEmpty) return null;
      return _AsideFrame(
        children: [
          Text('这一轮会多安排', style: TextStyle(fontSize: 13, color: c.textMuted)),
          const SizedBox(height: 12),
          for (final item in focus) ...[
            _LeaderRow(
              label: Text(
                item.name,
                style: AppTheme.serifStyle(size: 19, color: c.textPrimary),
              ),
              value: Text(
                '首答 ${item.accuracy.round()}%',
                style: AppTheme.monoStyle(size: 13, color: c.wrong),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          Text(
            '依据最近 30 轮。其它音程照常各出至少一题。',
            style: TextStyle(fontSize: 12.5, height: 1.6, color: c.textMuted),
          ),
        ],
      );
    }
    if (_audioError || compact) return null;
    final answered = engine.currentQuestion;
    return _AsideFrame(
      bordered: false,
      children: [
        Row(
          children: [
            Text('本轮', style: TextStyle(fontSize: 13, color: c.textMuted)),
            const Spacer(),
            Text(
              '■ 首答对  □ 重试后对  ／ 未答出',
              style: AppTheme.monoStyle(size: 11.5, color: c.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Ledger(engine: engine, size: 28, gap: 6),
        const SizedBox(height: 18),
        _LeaderRow(
          label: Text('首答正确', style: TextStyle(color: c.textSecondary)),
          value: Text(
            '${engine.correctCount} / $answered',
            style: AppTheme.monoStyle(size: 14, color: c.textPrimary),
          ),
        ),
        const SizedBox(height: 10),
        _LeaderRow(
          label: Text('连击', style: TextStyle(color: c.textSecondary)),
          value: Text(
            '${engine.currentStreak}',
            style: AppTheme.monoStyle(size: 14, color: c.textPrimary),
          ),
        ),
        const SizedBox(height: 10),
        _LeaderRow(
          label: Text('平均反应', style: TextStyle(color: c.textSecondary)),
          value: Text(
            engine.averageResponseTime == 0
                ? '—'
                : '${engine.averageResponseTime.toStringAsFixed(1)} s',
            style: AppTheme.monoStyle(size: 14, color: c.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _AsideFrame extends StatelessWidget {
  final List<Widget> children;
  final bool bordered;

  const _AsideFrame({required this.children, this.bordered = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: bordered ? const EdgeInsets.only(left: 28) : EdgeInsets.zero,
      decoration: bordered
          ? BoxDecoration(
              border: Border(left: BorderSide(color: context.gb.hairline)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Label ........ value, with a dotted leader like a printed table.
class _LeaderRow extends StatelessWidget {
  final Widget label;
  final Widget value;

  const _LeaderRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(fontSize: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          label,
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: CustomPaint(
                size: const Size.fromHeight(1),
                painter: _DottedLinePainter(context.gb.strongLine),
              ),
            ),
          ),
          const SizedBox(width: 10),
          value,
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double x = 0; x < size.width; x += 4) {
      canvas.drawCircle(Offset(x + 0.5, 0.5), 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter old) => old.color != color;
}

/// One square per question: filled = first try, outlined = solved after a
/// retry, slashed = missed, accent = current, hairline = still to come.
class _Ledger extends StatelessWidget {
  final TrainingEngine engine;
  final double size;
  final double gap;

  const _Ledger({required this.engine, required this.size, required this.gap});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final outcomes = engine.outcomes;
    final total = engine.totalQuestions;
    final current = engine.isSessionActive && outcomes.length < total
        ? outcomes.length
        : null;
    final firstTry = outcomes.where((o) => o.firstTryCorrect).length;
    return Semantics(
      label: '本轮计分：已答 ${outcomes.length} 题，首答正确 $firstTry 题',
      excludeSemantics: true,
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var i = 0; i < total; i++)
            _LedgerCell(
              size: size,
              outcome: i < outcomes.length ? outcomes[i] : null,
              current: i == current,
              number: i + 1,
              colors: c,
            ),
        ],
      ),
    );
  }
}

class _LedgerCell extends StatelessWidget {
  final double size;
  final QuestionOutcome? outcome;
  final bool current;
  final int number;
  final GbColors colors;

  const _LedgerCell({
    required this.size,
    required this.outcome,
    required this.current,
    required this.number,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final o = outcome;
    final radius = BorderRadius.circular(size > 14 ? 3 : 2);
    Color? fill;
    Border border;
    Widget? child;
    if (o != null && o.firstTryCorrect) {
      fill = c.ink;
      border = Border.all(color: c.ink, width: 0);
    } else if (o != null && o.solved) {
      border = Border.all(color: c.ink, width: size > 14 ? 2 : 1.5);
    } else if (o != null) {
      border = Border.all(color: c.wrong, width: 1.5);
      child = CustomPaint(painter: _SlashPainter(c.wrong));
    } else if (current) {
      border = Border.all(color: c.accent, width: 1.5);
      if (size > 14) {
        child = Center(
          child: Text(
            '$number',
            style: AppTheme.monoStyle(size: 10, color: c.accent),
          ),
        );
      }
    } else {
      border = Border.all(color: c.controlLine);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        border: border,
        borderRadius: radius,
      ),
      child: child,
    );
  }
}

class _SlashPainter extends CustomPainter {
  final Color color;

  _SlashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.75),
      Offset(size.width * 0.72, size.height * 0.25),
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SlashPainter old) => old.color != color;
}

/// 基准 D4 → 目标 ____ (or the answer and the interval once resolved).
class _NoteRow extends StatelessWidget {
  final TrainingQuestion question;
  final bool resolved;
  final double noteSize;

  const _NoteRow({
    required this.question,
    required this.resolved,
    required this.noteSize,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    Widget labelled(String label, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: c.textMuted)),
        const SizedBox(height: 6),
        child,
      ],
    );
    final note = AppTheme.serifStyle(
      size: noteSize,
      color: c.textPrimary,
      height: 1,
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: noteSize * 0.34,
      runSpacing: 12,
      children: [
        labelled(
          '基准',
          Text(GuitarMath.noteLabel(question.root.midi), style: note),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: noteSize * 0.22),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: noteSize * 0.45,
            color: c.strongLine,
          ),
        ),
        labelled(
          '目标',
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: resolved
                ? Text(
                    GuitarMath.noteLabel(question.target.midi),
                    key: const ValueKey('answer'),
                    style: note.copyWith(color: c.correct),
                  )
                : Semantics(
                    key: const ValueKey('blank'),
                    label: '目标音未知',
                    child: SizedBox(
                      width: noteSize * 1.75,
                      height: noteSize,
                      child: CustomPaint(painter: _DashPainter(c.accent)),
                    ),
                  ),
          ),
        ),
        if (resolved)
          Container(
            margin: EdgeInsets.only(bottom: noteSize * 0.08),
            padding: const EdgeInsets.only(left: 22),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c.hairline)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.interval.chineseName,
                  style: AppTheme.serifStyle(
                    size: noteSize * 0.47,
                    color: c.textPrimary,
                    italic: true,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${question.interval.abbreviation} · ${question.intervalSemitones} 个半音',
                  style: AppTheme.monoStyle(size: 13, color: c.textMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;

  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    final y = size.height - 1;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, y), Offset(x + 6, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => old.color != color;
}

/// One concrete sentence about what is happening or what just happened.
class _Feedback extends StatelessWidget {
  final TrainingEngine engine;

  const _Feedback({required this.engine});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final question = engine.activeQuestion;
    final base = TextStyle(fontSize: 15, height: 1.6, color: c.textSecondary);
    late final Widget content;
    switch (engine.state) {
      case TrainingState.configuring:
        content = Text('正在准备题目…', style: base);
      case TrainingState.playingRoot:
        content = Text('仔细听：先基准音，再目标音。', style: base);
      case TrainingState.waitingAnswer:
        if (engine.failedAttempts == 0) {
          content = Text('目标在基准音之上，八度以内。点出它，同音高的位置都算对。', style: base);
        } else {
          final tried = engine.userAnswerMidi == null
              ? '这个音'
              : GuitarMath.noteLabel(engine.userAnswerMidi!);
          final hint = switch (engine.lastDirection) {
            PitchDirection.tooLow => '$tried 偏低。目标在它之上，再往高处找。',
            PitchDirection.tooHigh => '$tried 偏高。目标在它之下，往低处找。',
            PitchDirection.samePitchClassWrongOctave => '$tried 音名对了，但差了一个八度。',
            null => '$tried 不对。',
          };
          final remaining = engine.attemptsRemaining;
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5, right: 8),
                child: Icon(Icons.close_rounded, size: 15, color: c.wrong),
              ),
              Flexible(
                child: Text(
                  remaining == null ? hint : '$hint还可以试 $remaining 次。',
                  style: base.copyWith(color: c.wrong),
                ),
              ),
            ],
          );
        }
      case TrainingState.showingResult:
        if (question == null) {
          content = const SizedBox.shrink();
          break;
        }
        final target = GuitarMath.noteLabel(question.target.midi);
        final count = engine.currentTuning
            .findNotePositions(question.target.midi)
            .length;
        final where = count > 1 ? '$count 个绿色位置都是 $target，记住离你最近的那一个。' : '';
        final lead = engine.lastAnswerCorrect
            ? (engine.failedAttempts == 0 ? '一次听对。' : '第二次找到。这题不计入首答正确。')
            : '答案是 $target。';
        content = Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: lead,
                style: base.copyWith(color: c.textBody),
              ),
              TextSpan(text: where),
            ],
          ),
          style: base,
        );
      default:
        content = const SizedBox.shrink();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, if (current != null) current],
      ),
      child: KeyedSubtree(
        key: ValueKey('${engine.state}-${engine.failedAttempts}'),
        child: content,
      ),
    );
  }
}

class _NextQuestionHint extends StatelessWidget {
  final TrainingEngine engine;

  const _NextQuestionHint({required this.engine});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final hold = engine.showCorrectPosition && !engine.lastAnswerCorrect
        ? TrainingEngine.revealResultHold
        : TrainingEngine.correctResultHold;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 2,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(engine.currentQuestion),
              tween: Tween(begin: 0, end: 1),
              duration: hold,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                color: c.ink,
                backgroundColor: c.hairline,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            engine.currentQuestion >= engine.totalQuestions
                ? '这一轮马上结束'
                : '下一题马上开始',
            style: TextStyle(fontSize: 14, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Replay / reveal / finish controls. Used inline on desktop and in the
/// bottom bar on phones.
class TrainingActions extends StatelessWidget {
  final TrainingEngine engine;
  final bool showShortcuts;
  final bool bar;
  final VoidCallback onReplayRoot;
  final VoidCallback onReplayTarget;
  final VoidCallback? onReplayQuestion;
  final VoidCallback? onReveal;
  final VoidCallback? onFinish;

  const TrainingActions({
    super.key,
    required this.engine,
    required this.onReplayRoot,
    required this.onReplayTarget,
    this.onReplayQuestion,
    this.onReveal,
    this.onFinish,
    this.showShortcuts = false,
    this.bar = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) => bar ? _buildBar(context) : _buildInline(context),
    );
  }

  bool get _waiting => engine.state == TrainingState.waitingAnswer;

  Widget _buildBar(BuildContext context) {
    final c = context.gb;
    const height = 48.0;
    return Row(
      children: [
        if (onReplayQuestion != null) ...[
          Expanded(
            flex: 6,
            child: SizedBox(
              height: height,
              child: FilledButton(
                onPressed: _waiting && !engine.isReplaying
                    ? onReplayQuestion
                    : null,
                style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text('重听两音'),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          flex: 5,
          child: SizedBox(
            height: height,
            child: OutlinedButton(
              onPressed: _waiting ? onReplayRoot : null,
              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('基准音'),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: SizedBox(
            height: height,
            child: OutlinedButton(
              onPressed: _waiting ? onReplayTarget : null,
              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('目标音'),
            ),
          ),
        ),
        if (onReveal != null || onFinish != null)
          PopupMenuButton<String>(
            tooltip: '更多',
            icon: Icon(Icons.more_horiz_rounded, color: c.textSecondary),
            onSelected: (value) {
              if (value == 'reveal') onReveal?.call();
              if (value == 'finish') onFinish?.call();
            },
            itemBuilder: (context) => [
              if (onReveal != null)
                PopupMenuItem(
                  value: 'reveal',
                  enabled: _waiting,
                  child: const Text('看答案'),
                ),
              if (onFinish != null)
                const PopupMenuItem(value: 'finish', child: Text('结束本轮')),
            ],
          ),
      ],
    );
  }

  Widget _buildInline(BuildContext context) {
    final c = context.gb;
    Widget withKey(String text, String key, {Color? keyColor}) => showShortcuts
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text),
              const SizedBox(width: 10),
              Text(
                key,
                style: AppTheme.monoStyle(
                  size: 11.5,
                  color: keyColor ?? c.textMuted,
                ),
              ),
            ],
          )
        : Text(text);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (onReplayQuestion != null)
          FilledButton(
            onPressed: _waiting && !engine.isReplaying
                ? onReplayQuestion
                : null,
            child: withKey(
              '重听两音',
              'Space',
              keyColor: c.onAccent.withAlpha(190),
            ),
          ),
        OutlinedButton(
          onPressed: _waiting ? onReplayRoot : null,
          child: withKey('基准音', 'R'),
        ),
        OutlinedButton(
          onPressed: _waiting ? onReplayTarget : null,
          child: withKey('目标音', 'T'),
        ),
        const SizedBox(width: 12),
        if (onReveal != null)
          TextButton(
            onPressed: _waiting ? onReveal : null,
            child: Text(
              '看答案',
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: c.strongLine,
              ),
            ),
          ),
        if (onFinish != null)
          TextButton(
            onPressed: engine.isSessionActive ? onFinish : null,
            child: withKey('结束本轮', 'Esc'),
          ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final String? hint;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          textStyle: const TextStyle(
            fontFamily: AppTheme.sans,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (hint != null) ...[
              const SizedBox(width: 14),
              Text(
                hint!,
                style: AppTheme.monoStyle(
                  size: 11.5,
                  color: c.onAccent.withAlpha(180),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
