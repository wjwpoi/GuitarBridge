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
    return LayoutBuilder(
      builder: (context, constraints) {
        final fields = <Widget>[
          _dropdown<String>(
            label: '调性',
            value: config.key,
            items: {for (final key in TrainingConfig.keys) key: key},
            onChanged: (value) => onChanged(config.copyWith(key: value)),
          ),
          _dropdown<ScaleType>(
            label: '音阶',
            value: config.scale,
            items: {
              for (final scale in ScaleType.values) scale: scale.chineseName,
            },
            onChanged: (value) => onChanged(config.copyWith(scale: value)),
          ),
          _dropdown<Tuning>(
            label: '调弦',
            value: config.tuning,
            items: {for (final tuning in Tuning.all) tuning: tuning.name},
            onChanged: (value) => onChanged(config.copyWith(tuning: value)),
          ),
          _dropdown<String>(
            label: '难度',
            value: config.difficulty,
            items: {
              for (final key in TrainingConfig.difficultyKeys)
                key: TrainingConfig.difficultyLabel(key),
            },
            onChanged: (value) => onChanged(config.copyWith(difficulty: value)),
          ),
        ];

        final toggles = Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _toggle(
              label: '音名',
              selected: config.showNoteNames,
              onTap: () => onChanged(
                config.copyWith(showNoteNames: !config.showNoteNames),
              ),
            ),
            _toggle(
              label: '级数',
              selected: config.showDegrees,
              onTap: () =>
                  onChanged(config.copyWith(showDegrees: !config.showDegrees)),
            ),
            _toggle(
              label: '品号',
              selected: config.showFretNumbers,
              onTap: () => onChanged(
                config.copyWith(showFretNumbers: !config.showFretNumbers),
              ),
            ),
          ],
        );

        if (inline) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 2, child: fields[0]),
              const SizedBox(width: 10),
              Expanded(flex: 3, child: fields[1]),
              const SizedBox(width: 10),
              Expanded(flex: 3, child: fields[2]),
              const SizedBox(width: 10),
              Expanded(flex: 3, child: fields[3]),
              const SizedBox(width: 16),
              toggles,
            ],
          );
        }

        final twoColumns = constraints.maxWidth >= 300;
        final fieldWidth = twoColumns
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final field in fields)
                  SizedBox(width: fieldWidth, child: field),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              TrainingConfig.difficultyDescription(config.difficulty),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 14),
            const Text(
              '指板显示',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            toggles,
          ],
        );
      },
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
      dropdownColor: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(14),
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
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

  Widget _toggle({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      toggled: selected,
      button: true,
      label: '显示$label',
      child: Material(
        color: selected
            ? AppTheme.secondaryColor.withAlpha(22)
            : AppTheme.subtleSurfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected ? AppTheme.secondaryColor : AppTheme.outlineColor,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 15,
                  color: selected
                      ? AppTheme.secondaryColor
                      : AppTheme.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppTheme.secondaryColor
                        : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
