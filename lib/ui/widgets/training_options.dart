import 'package:flutter/material.dart';
import '../../engine/audio_engine.dart';

/// 训练选项面板（对应原 Swift TrainingOptionsView.swift）
/// 调性、音阶、调弦、难度选择
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
    '自然大调', '自然小调', '和声小调', '旋律小调',
    '大调五声', '小调五声', '蓝调音阶',
    '多利亚调式', '弗里吉亚调式', '利底亚调式',
    '混合利底亚', '洛克里亚调式',
  ];
  static const tunings = [
    '标准 (EADGBE)', '降半音 (Eb)', '降全音 (D)',
    'Drop D', 'DADGAD', 'Open G',
  ];
  static const difficulties = ['easy', 'medium', 'hard'];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：调性 + 音阶
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: '调性',
                    value: selectedKey,
                    items: keys,
                    onChanged: onKeyChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildDropdown(
                    label: '音阶',
                    value: selectedScale,
                    items: scales,
                    onChanged: onScaleChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 第二行：调弦 + 难度
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: '调弦',
                    value: selectedTuning,
                    items: tunings,
                    onChanged: onTuningChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdown(
                    label: '难度',
                    value: selectedDifficulty,
                    items: difficulties,
                    onChanged: onDifficultyChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 第三行：显示选项开关
            Row(
              children: [
                _buildToggle('级数', showDegrees, onToggleDegrees),
                const SizedBox(width: 12),
                _buildToggle('音名', showNoteNames, onToggleNoteNames),
                const SizedBox(width: 12),
                _buildToggle('品号', showFretNumbers, onToggleFretNumbers),
              ],
            ),
            const SizedBox(height: 8),

            // 第四行：音色切换
            Row(
              children: [
                const Text('音色', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 8),
                _buildToneButton(ToneMode.clean, '清音'),
                _buildToneButton(ToneMode.overdrive, '过载'),
                _buildToneButton(ToneMode.distortion, '失真'),
              ],
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
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          style: const TextStyle(fontSize: 13, color: Colors.white),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _buildToggle(String label, bool value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: value ? Colors.cyan : Colors.grey,
              )),
          Switch(
            value: value,
            onChanged: (_) => onTap(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildToneButton(ToneMode mode, String label) {
    final isActive = currentToneMode == mode;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isActive,
        onSelected: (_) => onToneModeChanged(mode),
        selectedColor: Colors.cyan.withAlpha(100),
        backgroundColor: Colors.grey.withAlpha(40),
      ),
    );
  }
}
