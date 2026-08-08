import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../engine/audio_engine.dart';

/// Configuration rail for the training workspace.
///
/// The controls are intentionally compact and use the same quiet surface as
/// the rest of the app. The widget owns no state; HomeScreen remains the
/// source of truth so desktop and mobile behave identically.
class TrainingOptionsWidget extends StatelessWidget {
  final String selectedKey;
  final String selectedScale;
  final String selectedTuning;
  final String selectedDifficulty;
  final ToneMode currentToneMode;
  final bool showDegrees;
  final bool showNoteNames;
  final bool showFretNumbers;
  final ValueChanged<String> onKeyChanged;
  final ValueChanged<String> onScaleChanged;
  final ValueChanged<String> onTuningChanged;
  final ValueChanged<String> onDifficultyChanged;
  final ValueChanged<ToneMode> onToneModeChanged;
  final VoidCallback onToggleDegrees;
  final VoidCallback onToggleNoteNames;
  final VoidCallback onToggleFretNumbers;

  const TrainingOptionsWidget({
    super.key,
    required this.selectedKey,
    required this.selectedScale,
    required this.selectedTuning,
    required this.selectedDifficulty,
    required this.currentToneMode,
    required this.showDegrees,
    required this.showNoteNames,
    required this.showFretNumbers,
    required this.onKeyChanged,
    required this.onScaleChanged,
    required this.onTuningChanged,
    required this.onDifficultyChanged,
    required this.onToneModeChanged,
    required this.onToggleDegrees,
    required this.onToggleNoteNames,
    required this.onToggleFretNumbers,
  });

  static const keys = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  static const scales = [
    '自然大调',
    '自然小调',
    '和声小调',
    '旋律小调',
    '大调五声',
    '小调五声',
    '蓝调音阶',
    '多利亚调式',
    '弗里吉亚调式',
    '利底亚调式',
    '混合利底亚',
    '洛克里亚调式',
  ];
  static const tunings = [
    '标准 (EADGBE)',
    '降半音 (Eb)',
    '降全音 (D)',
    'Drop D',
    'DADGAD',
    'Open G',
  ];
  static const difficulties = ['easy', 'medium', 'hard'];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelHeading(
              icon: Icons.tune_rounded,
              eyebrow: 'WORKSPACE',
              title: '训练设置',
              trailing: '即时生效',
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth < 300
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildDropdown(
                      label: '调性',
                      value: selectedKey,
                      items: keys,
                      width: fieldWidth,
                      onChanged: onKeyChanged,
                    ),
                    _buildDropdown(
                      label: '音阶',
                      value: selectedScale,
                      items: scales,
                      width: fieldWidth,
                      onChanged: onScaleChanged,
                    ),
                    _buildDropdown(
                      label: '调弦',
                      value: selectedTuning,
                      items: tunings,
                      width: fieldWidth,
                      onChanged: onTuningChanged,
                    ),
                    _buildDropdown(
                      label: '难度',
                      value: selectedDifficulty,
                      items: difficulties,
                      labels: const {
                        'easy': '入门',
                        'medium': '进阶',
                        'hard': '完整指板',
                      },
                      width: fieldWidth,
                      onChanged: onDifficultyChanged,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            const _SectionLabel('指板显示'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildToggleChip(
                  label: '音名',
                  icon: Icons.music_note_rounded,
                  selected: showNoteNames,
                  onTap: onToggleNoteNames,
                ),
                _buildToggleChip(
                  label: '级数',
                  icon: Icons.format_list_numbered_rounded,
                  selected: showDegrees,
                  onTap: onToggleDegrees,
                ),
                _buildToggleChip(
                  label: '品号',
                  icon: Icons.grid_4x4_rounded,
                  selected: showFretNumbers,
                  onTap: onToggleFretNumbers,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionLabel('反馈音色'),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 16) / 3;
                return Row(
                  children: [
                    _buildToneOption(
                      ToneMode.clean,
                      '清晰',
                      Icons.graphic_eq_rounded,
                      width,
                    ),
                    const SizedBox(width: 8),
                    _buildToneOption(
                      ToneMode.overdrive,
                      '过载',
                      Icons.multitrack_audio_rounded,
                      width,
                    ),
                    const SizedBox(width: 8),
                    _buildToneOption(
                      ToneMode.distortion,
                      '失真',
                      Icons.bolt_rounded,
                      width,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 9),
            const Text(
              '三种音色都保留清晰基频 · 数字键 1/2/3 可快速切换',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required double width,
    required ValueChanged<String> onChanged,
    Map<String, String> labels = const {},
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        dropdownColor: AppTheme.surfaceColor,
        items: [
          for (final item in items)
            DropdownMenuItem(
              value: item,
              child: Text(
                labels[item] ?? item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 15,
        color: selected ? AppTheme.primaryColor : AppTheme.textMuted,
      ),
      label: Text(label),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildToneOption(
    ToneMode mode,
    String label,
    IconData icon,
    double width,
  ) {
    final selected = currentToneMode == mode;
    final color = AppTheme.toneColor(mode.name);
    return SizedBox(
      width: width,
      child: Material(
        color: selected ? color.withAlpha(20) : AppTheme.subtleSurfaceColor,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: () => onToneModeChanged(mode),
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected ? color : AppTheme.outlineColor,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: selected ? color : AppTheme.textMuted,
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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

class _PanelHeading extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String trailing;

  const _PanelHeading({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withAlpha(14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppTheme.secondaryColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }
}
