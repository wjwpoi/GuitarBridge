import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// A hairline-bordered surface with consistent padding.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const Panel({super.key, required this.child, this.padding, this.color});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding ?? EdgeInsets.all(compact ? 16 : 24),
        child: child,
      ),
    );
  }
}

/// Small muted label above a group of content.
class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: context.text.labelMedium?.copyWith(color: context.gb.textMuted),
    );
    if (trailing == null) return label;
    return Row(
      children: [
        Expanded(child: label),
        trailing!,
      ],
    );
  }
}

/// A colored dot followed by a label, used for legends and status.
class Dot extends StatelessWidget {
  final Color color;
  final String? label;
  final double size;

  const Dot({super.key, required this.color, this.label, this.size = 8});

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    if (label == null) return dot;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: 6),
        Text(label!, style: context.text.bodySmall),
      ],
    );
  }
}

/// Keyboard key hint, e.g. `Space`.
class KeyCap extends StatelessWidget {
  final String label;

  const KeyCap(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: c.strongLine),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c.textMuted,
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
    );
  }
}

/// The GuitarBridge wordmark.
class Wordmark extends StatelessWidget {
  final bool compact;

  const Wordmark({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size.square(compact ? 22 : 24),
          painter: _MarkPainter(c.accent, c.textPrimary),
        ),
        const SizedBox(width: 10),
        Text(
          'GuitarBridge',
          style: TextStyle(
            fontFamily: AppTheme.serif,
            fontSize: compact ? 18 : 20,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

/// Six strings with two notes bridged by an arc.
class _MarkPainter extends CustomPainter {
  final Color accent;
  final Color ink;

  _MarkPainter(this.accent, this.ink);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final line = Paint()
      ..color = ink.withAlpha(90)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 4; i++) {
      final y = w * (0.22 + i * 0.19);
      canvas.drawLine(Offset(0, y), Offset(w, y), line);
    }
    final dot = Paint()..color = ink;
    canvas.drawCircle(Offset(w * 0.24, w * 0.79), w * 0.11, dot);
    canvas.drawCircle(
      Offset(w * 0.76, w * 0.22),
      w * 0.11,
      Paint()..color = accent,
    );
    final arc = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(w * 0.24, w * 0.66)
      ..quadraticBezierTo(w * 0.3, w * 0.2, w * 0.64, w * 0.22);
    canvas.drawPath(path, arc);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) =>
      old.accent != accent || old.ink != ink;
}
