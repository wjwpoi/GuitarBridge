import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../engine/audio_engine.dart';
import '../../models/practice_record.dart';

class SettingsScreen extends StatefulWidget {
  final AudioEngine audioEngine;
  final UserPreferences preferences;
  final ValueChanged<UserPreferences> onPreferencesChanged;

  const SettingsScreen({
    super.key,
    required this.audioEngine,
    required this.preferences,
    required this.onPreferencesChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _volume;
  late int _questionsPerSession;

  @override
  void initState() {
    super.initState();
    _volume = widget.audioEngine.volume;
    _questionsPerSession = widget.preferences.questionsPerSession;
  }

  @override
  Widget build(BuildContext context) {
    final prefs = widget.preferences;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SettingsSection(
                    icon: Icons.volume_up_rounded,
                    title: '声音',
                    description: '调整训练与指板试听的整体音量。',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              '音量',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(_volume * 100).round()}%',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _volume,
                          min: 0,
                          max: 1,
                          divisions: 20,
                          onChanged: (value) {
                            setState(() => _volume = value);
                            prefs.audioVolume = value;
                            widget.audioEngine.setVolume(value);
                            widget.onPreferencesChanged(prefs);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingsSection(
                    icon: Icons.all_inclusive_rounded,
                    title: '训练节奏',
                    description: '控制单轮长度与答案揭示时机。',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SettingLabel('每轮题目数'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final count in [5, 10, 15, 20, 30, 50])
                              ChoiceChip(
                                label: Text('$count'),
                                selected: _questionsPerSession == count,
                                onSelected: (_) {
                                  setState(() => _questionsPerSession = count);
                                  prefs.questionsPerSession = count;
                                  widget.onPreferencesChanged(prefs);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const _SettingLabel('答错几次后显示答案'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final count in [0, 1, 2, 3, 4, 5])
                              ChoiceChip(
                                label: Text(count == 0 ? '永不' : '$count 次'),
                                selected: prefs.maxFailedAttempts == count,
                                onSelected: (_) {
                                  setState(
                                    () => prefs.maxFailedAttempts = count,
                                  );
                                  widget.onPreferencesChanged(prefs);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingsSection(
                    icon: Icons.visibility_rounded,
                    title: '指板显示',
                    description: '这些选项在所有平台使用相同的呈现方式。',
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('显示音名'),
                          subtitle: const Text('在节点中显示 C、D、E 等音名'),
                          value: prefs.showNoteNames,
                          onChanged: (value) {
                            setState(() => prefs.showNoteNames = value);
                            widget.onPreferencesChanged(prefs);
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('显示级数'),
                          subtitle: const Text('用 I、II、III 表示调内关系'),
                          value: prefs.showDegrees,
                          onChanged: (value) {
                            setState(() => prefs.showDegrees = value);
                            widget.onPreferencesChanged(prefs);
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('显示品号'),
                          subtitle: const Text('显示等宽指板顶部的品位编号'),
                          value: prefs.showFretNumbers,
                          onChanged: (value) {
                            setState(() => prefs.showFretNumbers = value);
                            widget.onPreferencesChanged(prefs);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _SettingsSection(
                    icon: Icons.info_outline_rounded,
                    title: '关于 GuitarBridge',
                    description: 'v3.0.0 · Flutter 跨平台版',
                    child: Text(
                      '当前训练规则：播放基准音与一个八度内的上行目标音；'
                      '在等宽指板上选择任意同音高位置。\n\n'
                      '支持 Windows、macOS、Linux、iOS、Android 与 Web。',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withAlpha(55),
                    ),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _SettingLabel extends StatelessWidget {
  final String text;

  const _SettingLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
