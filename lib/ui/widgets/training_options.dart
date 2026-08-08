import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../engine/audio_engine.dart';

/// Compact, responsive configuration panel for the training workspace.
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '训练设置',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '即时生效',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth < 300
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 12,
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
            const SizedBox(height: 20),
            const Text('显示内容', style: _sectionLabelStyle),
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
                  icon: Icons.numbers_rounded,
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
            const SizedBox(height: 20),
            const Text('音色预设', style: _sectionLabelStyle),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildToneChip(ToneMode.clean, '清晰', Icons.graphic_eq_rounded),
                _buildToneChip(
                  ToneMode.overdrive,
                  '过载',
                  Icons.multitrack_audio_rounded,
                ),
                _buildToneChip(ToneMode.distortion, '失真', Icons.bolt_rounded),
              ],
            ),
            const SizedBox(height: 9),
            const Text(
              '三种音色都保留清晰基频；数字键 1/2/3 可快速切换。',
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

  static const _sectionLabelStyle = TextStyle(
    color: AppTheme.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

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
        icon: const Icon(Icons.expand_more_rounded, size: 18),
        dropdownColor: AppTheme.raisedSurfaceColor,
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
        size: 16,
        color: selected ? AppTheme.primaryColor : AppTheme.textMuted,
      ),
      label: Text(label),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildToneChip(ToneMode mode, String label, IconData icon) {
    final selected = currentToneMode == mode;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? AppTheme.primaryColor : AppTheme.textMuted,
      ),
      label: Text(label),
      onSelected: (_) => onToneModeChanged(mode),
    );
  }
}
