import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// A section of a page: separated by a hairline rule and whitespace, not a
/// card. Only overlays (dialogs, sheets, the round summary) get a frame.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const Panel({super.key, required this.child, this.padding, this.color});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border(top: BorderSide(color: context.gb.hairline)),
      ),
      padding: padding ?? EdgeInsets.symmetric(vertical: compact ? 20 : 28),
      child: child,
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

/// The GuitarBridge wordmark: set in the serif, nothing else.
class Wordmark extends StatelessWidget {
  final bool compact;

  const Wordmark({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      'GuitarBridge',
      style: AppTheme.serifStyle(
        size: compact ? 19 : 22,
        color: context.gb.textPrimary,
        height: 1.2,
      ),
    );
  }
}
