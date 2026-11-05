import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/scale.dart';
import '../../models/training_config.dart';
import '../../models/tuning.dart';

/// Training setup controls.
///
/// Stateless: the home screen owns the [TrainingConfig] and receives every
/// change through [onChanged]. While a session runs the question-affecting
/// fields are [locked] so the fretboard and the active question never
/// disagree about key, scale or tuning.
class TrainingOptionsWidget extends StatelessWidget {
  final TrainingConfig config;
  final ValueChanged<TrainingConfig> onChanged;
  final bool locked;

  /// Lays the dropdowns out in one row (desktop toolbar) instead of a grid.
  final bool inline;

  const TrainingOptionsWidget({
    super.key,
    required this.config,
    required this.onChanged,
    this.locked = false,
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      _dropdown<String>(
        context,
        label: '调性',
        value: config.key,
        items: {for (final key in TrainingConfig.keys) key: key},
        onChanged: (value) => onChanged(config.copyWith(key: value)),
      ),
      _dropdown<ScaleType>(
        context,
        label: '音阶',
        value: config.scale,
        items: {for (final scale in ScaleType.values) scale: scale.chineseName},
        onChanged: (value) => onChanged(config.copyWith(scale: value)),
      ),
      _dropdown<Tuning>(
        context,
        label: '调弦',
        value: config.tuning,
        items: {for (final tuning in Tuning.all) tuning: tuning.name},
        onChanged: (value) => onChanged(config.copyWith(tuning: value)),
      ),
      _dropdown<String>(
        context,
        label: '难度',
        value: config.difficulty,
        items: {
          for (final key in TrainingConfig.difficultyKeys)
            key: TrainingConfig.difficultyLabel(key),
        },
        onChanged: (value) => onChanged(config.copyWith(difficulty: value)),
      ),
    ];

    final toggles = DisplayToggles(config: config, onChanged: onChanged);

    if (inline) {
      return Row(
        children: [
          Expanded(flex: 2, child: fields[0]),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: fields[1]),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: fields[2]),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: fields[3]),
          const SizedBox(width: 20),
          toggles,
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = constraints.maxWidth >= 300
            ? (constraints.maxWidth - 8) / 2
            : constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final field in fields)
                  SizedBox(width: fieldWidth, child: field),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              TrainingConfig.difficultyDescription(config.difficulty),
              style: context.text.bodySmall,
            ),
            const SizedBox(height: 16),
            Text('指板显示', style: context.text.labelMedium),
            const SizedBox(height: 8),
            toggles,
          ],
        );
      },
    );
  }

  Widget _dropdown<T>(
    BuildContext context, {
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T> onChanged,
  }) {
    final c = context.gb;
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(labelText: label),
      icon: Icon(
        Icons.expand_more_rounded,
        size: 18,
        color: locked ? c.textMuted.withAlpha(120) : c.textMuted,
      ),
      dropdownColor: c.surface,
      borderRadius: BorderRadius.circular(12),
      style: TextStyle(
        fontFamily: AppTheme.sans,
        color: locked ? c.textMuted : c.textPrimary,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      items: [
        for (final entry in items.entries)
          DropdownMenuItem<T>(
            value: entry.key,
            child: Text(
              entry.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: locked
          ? null
          : (next) {
              if (next != null) onChanged(next);
            },
    );
  }
}

/// Fretboard display controls: one exclusive choice of what scale notes
/// show (names, degrees, or nothing but fret inlays) plus a fret-number
/// toggle.
class DisplayToggles extends StatelessWidget {
  final TrainingConfig config;
  final ValueChanged<TrainingConfig> onChanged;

  const DisplayToggles({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _SegmentGroup(
          children: [
            for (final mode in FretLabels.values)
              _Segment(
                label: mode.label,
                tooltip: switch (mode) {
                  FretLabels.noteNames => '在调内音上显示音名',
                  FretLabels.degrees => '在调内音上显示相对主音的级数',
                  FretLabels.hidden => '不标出调内音，只保留品记圆点（更难）',
                },
                semanticsLabel: '指板标记：${mode.label}',
                selected: config.labels == mode,
                onTap: () => onChanged(config.copyWith(labels: mode)),
              ),
          ],
        ),
        _SegmentGroup(
          children: [
            _Segment(
              label: '品号',
              tooltip: '显示指板上方的品位编号',
              semanticsLabel: '显示品号',
              selected: config.showFretNumbers,
              onTap: () => onChanged(
                config.copyWith(showFretNumbers: !config.showFretNumbers),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SegmentGroup extends StatelessWidget {
  final List<Widget> children;

  const _SegmentGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.gb.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final String tooltip;
  final String semanticsLabel;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.tooltip,
    required this.semanticsLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Semantics(
        button: true,
        selected: selected,
        label: semanticsLabel,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? c.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(14),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: selected ? c.textPrimary : c.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
