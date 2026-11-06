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

/// The one-line setup strip of the workspace: key and scale, tuning and
/// difficulty as text menus, then the fretboard label tabs and the fret
/// number toggle. On phones it collapses to one button that opens a sheet.
class SetupStrip extends StatelessWidget {
  final TrainingConfig config;
  final ValueChanged<TrainingConfig> onChanged;
  final bool locked;
  final bool compact;

  const SetupStrip({
    super.key,
    required this.config,
    required this.onChanged,
    this.locked = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final decoration = BoxDecoration(
      border: Border.symmetric(horizontal: BorderSide(color: c.hairline)),
    );
    if (compact) {
      return Container(
        height: 52,
        decoration: decoration,
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => _openSheet(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                child: Row(
                  children: [
                    Text(
                      '${config.key} ${config.scale.chineseName}',
                      style: AppTheme.serifStyle(
                        size: 15,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        '${TrainingConfig.difficultyLabel(config.difficulty)} · ${config.labels.label}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.5, color: c.textMuted),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: c.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (locked)
              Text('调性已锁定', style: TextStyle(fontSize: 12, color: c.textMuted)),
          ],
        ),
      );
    }

    final divider = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text('/', style: TextStyle(color: c.strongLine, fontSize: 15)),
    );
    return Container(
      height: 56,
      decoration: decoration,
      child: Row(
        children: [
          _MenuText<String>(
            tooltip: '调性',
            enabled: !locked,
            value: config.key,
            items: {for (final key in TrainingConfig.keys) key: key},
            onSelected: (value) => onChanged(config.copyWith(key: value)),
            child: Text(
              config.key,
              style: AppTheme.serifStyle(size: 17, color: c.textPrimary),
            ),
          ),
          _MenuText<ScaleType>(
            tooltip: '音阶',
            enabled: !locked,
            value: config.scale,
            items: {
              for (final scale in ScaleType.values) scale: scale.chineseName,
            },
            onSelected: (value) => onChanged(config.copyWith(scale: value)),
            child: Text(
              config.scale.chineseName,
              style: AppTheme.serifStyle(size: 17, color: c.textPrimary),
            ),
          ),
          divider,
          _MenuText<Tuning>(
            tooltip: '调弦',
            enabled: !locked,
            value: config.tuning,
            items: {for (final tuning in Tuning.all) tuning: tuning.name},
            onSelected: (value) => onChanged(config.copyWith(tuning: value)),
            child: Text(
              config.tuning.name,
              style: TextStyle(fontSize: 15, color: c.textSecondary),
            ),
          ),
          divider,
          _MenuText<String>(
            tooltip: '难度',
            enabled: !locked,
            value: config.difficulty,
            items: {
              for (final key in TrainingConfig.difficultyKeys)
                key:
                    '${TrainingConfig.difficultyLabel(key)}  ${TrainingConfig.difficultyDescription(key)}',
            },
            onSelected: (value) =>
                onChanged(config.copyWith(difficulty: value)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  TrainingConfig.difficultyLabel(config.difficulty),
                  style: TextStyle(fontSize: 15, color: c.textSecondary),
                ),
                const SizedBox(width: 8),
                Text(
                  '${config.difficultyConfig.fretRange.$1}–${config.difficultyConfig.fretRange.$2} 品',
                  style: AppTheme.monoStyle(size: 13, color: c.textMuted),
                ),
              ],
            ),
          ),
          if (locked) ...[
            const SizedBox(width: 16),
            Text(
              '本轮进行中，调性已锁定',
              style: TextStyle(fontSize: 13, color: c.textMuted),
            ),
          ],
          const Spacer(),
          LabelTabs(config: config, onChanged: onChanged),
          Container(
            width: 1,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: c.hairline,
          ),
          _FretNumberToggle(config: config, onChanged: onChanged),
        ],
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.gb.canvas,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: _SheetBody(
          initial: config,
          locked: locked,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SheetBody extends StatefulWidget {
  final TrainingConfig initial;
  final bool locked;
  final ValueChanged<TrainingConfig> onChanged;

  const _SheetBody({
    required this.initial,
    required this.locked,
    required this.onChanged,
  });

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  late TrainingConfig _config = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('训练设置', style: context.text.titleLarge),
        if (widget.locked) ...[
          const SizedBox(height: 4),
          Text('本轮进行中，调性、调弦和难度已锁定。', style: context.text.bodySmall),
        ],
        const SizedBox(height: 16),
        TrainingOptionsWidget(
          config: _config,
          locked: widget.locked,
          onChanged: (next) {
            setState(() => _config = next);
            widget.onChanged(next);
          },
        ),
      ],
    );
  }
}

/// A piece of text that opens a menu of choices.
class _MenuText<T> extends StatelessWidget {
  final String tooltip;
  final bool enabled;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onSelected;
  final Widget child;

  const _MenuText({
    required this.tooltip,
    required this.enabled,
    required this.value,
    required this.items,
    required this.onSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return PopupMenuButton<T>(
      tooltip: enabled ? tooltip : '$tooltip（本轮结束后可修改）',
      enabled: enabled,
      initialValue: value,
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final entry in items.entries)
          PopupMenuItem<T>(value: entry.key, child: Text(entry.value)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            if (enabled) ...[
              const SizedBox(width: 6),
              Icon(Icons.expand_more_rounded, size: 16, color: c.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}

/// 音名 / 级数 / 仅品记 as underlined text tabs.
class LabelTabs extends StatelessWidget {
  final TrainingConfig config;
  final ValueChanged<TrainingConfig> onChanged;

  const LabelTabs({super.key, required this.config, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return Semantics(
      label: '指板标记',
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final mode in FretLabels.values)
            Tooltip(
              message: switch (mode) {
                FretLabels.noteNames => '在调内音上显示音名',
                FretLabels.degrees => '在调内音上显示相对主音的级数',
                FretLabels.hidden => '不标出调内音，只保留品记圆点（更难）',
              },
              waitDuration: const Duration(milliseconds: 500),
              child: Semantics(
                button: true,
                selected: config.labels == mode,
                label: '指板标记：${mode.label}',
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => onChanged(config.copyWith(labels: mode)),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 4, top: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: config.labels == mode
                                ? c.textPrimary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        mode.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: config.labels == mode
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: config.labels == mode
                              ? c.textPrimary
                              : c.textMuted,
                        ),
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

class _FretNumberToggle extends StatelessWidget {
  final TrainingConfig config;
  final ValueChanged<TrainingConfig> onChanged;

  const _FretNumberToggle({required this.config, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return Tooltip(
      message: '显示指板下方的品位编号',
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: () => onChanged(
          config.copyWith(showFretNumbers: !config.showFretNumbers),
        ),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: config.showFretNumbers,
                  onChanged: (value) => onChanged(
                    config.copyWith(showFretNumbers: value ?? false),
                  ),
                  activeColor: c.textPrimary,
                  checkColor: c.canvas,
                  side: BorderSide(color: c.strongLine, width: 1.4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '品号',
                style: TextStyle(fontSize: 14, color: c.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
