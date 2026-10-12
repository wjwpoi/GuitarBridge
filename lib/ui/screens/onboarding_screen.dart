import 'package:flutter/material.dart';

import '../../core/theme.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            top: -180,
            right: -120,
            child: _AmbientOrb(size: 430, color: AppTheme.secondaryColor),
          ),
          const Positioned(
            bottom: -220,
            left: -180,
            child: _AmbientOrb(size: 480, color: AppTheme.primaryColor),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 600 ? 22 : 48,
                    vertical: 32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: _buildHero(context)),
                                const SizedBox(width: 64),
                                Expanded(child: _buildFeatureGrid()),
                              ],
                            )
                          : Column(
                              children: [
                                _buildHero(context),
                                const SizedBox(height: 40),
                                _buildFeatureGrid(),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withAlpha(40),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.music_note_rounded,
            color: Colors.white,
            size: 31,
          ),
        ),
        const SizedBox(height: 28),
        Text('听见音程，\n看懂指板。', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: const Text(
            'GuitarBridge 把相对音准训练和吉他指板连接起来。'
            '从清晰的上行音程开始，在等宽指板上找到你真正听见的音。',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              height: 1.65,
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HeroTag(icon: Icons.headphones_rounded, text: '相对音准'),
            _HeroTag(icon: Icons.grid_view_rounded, text: '等宽指板'),
            _HeroTag(icon: Icons.devices_rounded, text: '跨平台一致'),
          ],
        ),
        const SizedBox(height: 36),
        ElevatedButton.icon(
          onPressed: onComplete,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('进入训练工作台'),
        ),
        const SizedBox(height: 12),
        const Text(
          '首次建议佩戴耳机，并使用「清晰」音色。',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid() {
    return const Column(
      children: [
        _FeatureCard(
          index: '01',
          icon: Icons.hearing_rounded,
          title: '先听，再定位',
          description: '依次播放基准音和目标音，把听觉距离映射到指板。',
          accent: AppTheme.primaryColor,
        ),
        SizedBox(height: 12),
        _FeatureCard(
          index: '02',
          icon: Icons.straighten_rounded,
          title: '抽象等宽指板',
          description: '不模拟物理品距，让每一品都同样清楚、同样容易点击。',
          accent: AppTheme.secondaryColor,
        ),
        SizedBox(height: 12),
        _FeatureCard(
          index: '03',
          icon: Icons.query_stats_rounded,
          title: '可追踪的练习',
          description: '记录准确率、连续练习与答题趋势，观察真实进步。',
          accent: AppTheme.accentColor,
        ),
      ],
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withAlpha(28), color.withAlpha(0)],
          ),
        ),
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.primaryColor),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String index;
  final IconData icon;
  final String title;
  final String description;
  final Color accent;

  const _FeatureCard({
    required this.index,
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withAlpha(16),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: accent.withAlpha(70)),
              ),
              child: Icon(icon, color: accent, size: 21),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        index,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
