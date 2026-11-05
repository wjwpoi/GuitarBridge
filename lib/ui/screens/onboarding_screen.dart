import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onComplete;
  final bool requiresAudioActivation;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
    this.requiresAudioActivation = false,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final pad = constraints.maxWidth < 600 ? 24.0 : 56.0;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Wordmark(),
                        ),
                        SizedBox(height: wide ? 72 : 40),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: _buildHero(context)),
                              const SizedBox(width: 72),
                              Expanded(flex: 5, child: _buildSteps(context)),
                            ],
                          )
                        else ...[
                          _buildHero(context),
                          const SizedBox(height: 44),
                          _buildSteps(context),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final c = context.gb;
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '听见音程，\n在指板上找到它。',
          style: context.text.displaySmall?.copyWith(
            fontSize: compact ? 30 : 40,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            '每一题先播放基准音，再播放一个更高的音。你要做的，是在指板上点出第二个音。'
            '练得越多，耳朵和手指之间的距离就越短。',
            style: context.text.bodyLarge?.copyWith(
              color: c.textSecondary,
              height: 1.75,
            ),
          ),
        ),
        const SizedBox(height: 36),
        FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          onPressed: _isCompleting ? null : _complete,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isCompleting) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                _isCompleting
                    ? '正在准备声音…'
                    : widget.requiresAudioActivation
                    ? '开启声音，进入训练'
                    : '开始练习',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.requiresAudioActivation
              ? '浏览器首次需要一次点击来激活声音。建议佩戴耳机。'
              : '建议佩戴耳机。',
          style: context.text.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSteps(BuildContext context) {
    const steps = [
      ('听', '基准音会在指板上标出，紧接着播放一个八度以内、比它高的目标音。'),
      ('找', '点击指板上任意与目标音同音高的位置。答错会提示偏高还是偏低。'),
      ('记', '答案揭晓时会告诉你这是什么音程，并标出它在指板上的所有位置。'),
      ('练', '没答对的音程会在本轮再出现；智能出题会在之后多安排你的弱项。'),
    ];
    return Column(
      children: [
        for (final (i, (title, body)) in steps.indexed) ...[
          if (i > 0) const Divider(height: 40),
          _Step(index: i + 1, title: title, body: body),
        ],
      ],
    );
  }

  Future<void> _complete() async {
    setState(() => _isCompleting = true);
    try {
      await widget.onComplete();
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }
}

class _Step extends StatelessWidget {
  final int index;
  final String title;
  final String body;

  const _Step({required this.index, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Text(
            '0$index',
            style: TextStyle(
              color: c.textMuted,
              fontSize: 12,
              fontFeatures: const [FontFeature.tabularFigures()],
              height: 1.9,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleLarge),
              const SizedBox(height: 6),
              Text(body, style: context.text.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
