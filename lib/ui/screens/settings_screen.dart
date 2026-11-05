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

  UserPreferences get _prefs => widget.preferences;

  @override
  void initState() {
    super.initState();
    _volume = widget.audioEngine.volume;
  }

  void _update(void Function(UserPreferences prefs) change) {
    setState(() => change(_prefs));
    widget.onPreferencesChanged(_prefs);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _GroupLabel('外观'),
                  _Group(
                    children: [
                      _Row(
                        title: '主题',
                        trailing: SegmentedButton<String>(
                          showSelectedIcon: false,
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                          segments: const [
                            ButtonSegment(value: 'system', label: Text('跟随系统')),
                            ButtonSegment(value: 'light', label: Text('浅色')),
                            ButtonSegment(value: 'dark', label: Text('深色')),
                          ],
                          selected: {_prefs.themeMode},
                          onSelectionChanged: (value) =>
                              _update((p) => p.themeMode = value.first),
                        ),
                      ),
                    ],
                  ),
                  const _GroupLabel('声音'),
                  _Group(
                    children: [
                      _Row(
                        title: '音量',
                        trailing: Text(
                          '${(_volume * 100).round()}%',
                          style: context.text.bodyMedium?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        below: Slider(
                          value: _volume,
                          divisions: 20,
                          onChanged: (value) {
                            setState(() => _volume = value);
                            widget.audioEngine.setVolume(value);
                            _update((p) => p.audioVolume = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const _GroupLabel('训练'),
                  _Group(
                    children: [
                      _Row(
                        title: '智能出题',
                        subtitle: '根据最近 30 轮的表现，多安排还不熟的音程；每个音程至少出现一次。',
                        trailing: Switch(
                          value: _prefs.adaptiveTraining,
                          onChanged: (value) =>
                              _update((p) => p.adaptiveTraining = value),
                        ),
                      ),
                      _Row(
                        title: '每轮题目数',
                        below: _Choices<int>(
                          values: const [5, 10, 15, 20, 30, 50],
                          selected: _prefs.questionsPerSession,
                          label: (value) => '$value',
                          onSelected: (value) =>
                              _update((p) => p.questionsPerSession = value),
                        ),
                      ),
                      _Row(
                        title: '答错几次后显示答案',
                        below: _Choices<int>(
                          values: const [1, 2, 3, 4, 5, 0],
                          selected: _prefs.maxFailedAttempts,
                          label: (value) => value == 0 ? '不自动显示' : '$value 次',
                          onSelected: (value) =>
                              _update((p) => p.maxFailedAttempts = value),
                        ),
                      ),
                    ],
                  ),
                  const _GroupLabel('指板显示'),
                  _Group(
                    children: [
                      _Row(
                        title: '显示音名',
                        trailing: Switch(
                          value: _prefs.showNoteNames,
                          onChanged: (value) =>
                              _update((p) => p.showNoteNames = value),
                        ),
                      ),
                      _Row(
                        title: '显示级数',
                        subtitle: '以主音为 1，标出 b3、5、b7 等',
                        trailing: Switch(
                          value: _prefs.showDegrees,
                          onChanged: (value) =>
                              _update((p) => p.showDegrees = value),
                        ),
                      ),
                      _Row(
                        title: '显示品号',
                        trailing: Switch(
                          value: _prefs.showFretNumbers,
                          onChanged: (value) =>
                              _update((p) => p.showFretNumbers = value),
                        ),
                      ),
                    ],
                  ),
                  const _GroupLabel('说明'),
                  _Group(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '先播放基准音（指板上标出），再播放一个八度内的上行目标音，'
                              '在指板上点击任意同音高的位置作答。'
                              '正确率与连击只统计第一次就答对的题；没答对的音程会在本轮稍后再出现。',
                              style: context.text.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '快捷键：Space 开始或重听两音 · R 基准音 · T 目标音 · Esc 结束本轮',
                              style: context.text.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'GuitarBridge v3.1 · 真实吉他采样 CC0 · 字体 Noto Sans SC / Noto Serif SC（SIL OFL）',
                              style: context.text.bodySmall?.copyWith(
                                color: c.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _GroupLabel extends StatelessWidget {
  final String text;

  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(text, style: context.text.labelMedium),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 20),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? below;

  const _Row({required this.title, this.subtitle, this.trailing, this.below});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 16, below == null ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.bodyLarge),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: context.text.bodySmall),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          if (below != null) ...[const SizedBox(height: 10), below!],
        ],
      ),
    );
  }
}

class _Choices<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T value) label;
  final ValueChanged<T> onSelected;

  const _Choices({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final value in values)
          Semantics(
            button: true,
            selected: value == selected,
            child: InkWell(
              onTap: () => onSelected(value),
              borderRadius: BorderRadius.circular(AppTheme.controlRadius),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: value == selected ? c.ink : c.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                ),
                child: Text(
                  label(value),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: value == selected ? c.onInk : c.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
