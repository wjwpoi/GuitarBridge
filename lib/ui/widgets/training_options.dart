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

/// Note name / degree / fret number toggles as one quiet button group.
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
    final c = context.gb;
    final items = [
      (
        '音名',
        config.showNoteNames,
        () => onChanged(config.copyWith(showNoteNames: !config.showNoteNames)),
      ),
      (
        '级数',
        config.showDegrees,
        () => onChanged(config.copyWith(showDegrees: !config.showDegrees)),
      ),
      (
        '品号',
        config.showFretNumbers,
        () => onChanged(
          config.copyWith(showFretNumbers: !config.showFretNumbers),
        ),
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, selected, toggle) in items)
            Semantics(
              button: true,
              toggled: selected,
              label: '显示$label',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: toggle,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
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
        ],
      ),
    );
  }
}
