import 'package:flutter/material.dart';
import '../../engine/audio_engine.dart';
import '../../models/practice_record.dart';

/// 设置页面（对应原 Swift SettingsView.swift）
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
        padding: const EdgeInsets.all(16),
        children: [
          // 音量
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '音量',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Slider(
                    value: _volume,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    label: '${(_volume * 100).toInt()}%',
                    activeColor: Colors.cyan,
                    onChanged: (v) {
                      setState(() => _volume = v);
                      widget.preferences.audioVolume = v;
                      widget.audioEngine.setVolume(v);
                      widget.onPreferencesChanged(widget.preferences);
                    },
                  ),
                ],
              ),
            ),
          ),

          // 每轮题目数
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '每轮题目数',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [5, 10, 15, 20, 30, 50].map((n) {
                      return ChoiceChip(
                        label: Text('$n'),
                        selected: _questionsPerSession == n,
                        onSelected: (_) {
                          setState(() => _questionsPerSession = n);
                          widget.preferences.questionsPerSession = n;
                          widget.onPreferencesChanged(widget.preferences);
                        },
                        selectedColor: Colors.cyan.withAlpha(100),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // 显示选项
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      '显示音名',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    value: prefs.showNoteNames,
                    activeColor: Colors.cyan,
                    onChanged: (v) {
                      setState(() => prefs.showNoteNames = v);
                      widget.onPreferencesChanged(prefs);
                    },
                  ),
                  SwitchListTile(
                    title: const Text(
                      '显示品号',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    value: prefs.showFretNumbers,
                    activeColor: Colors.cyan,
                    onChanged: (v) {
                      setState(() => prefs.showFretNumbers = v);
                      widget.onPreferencesChanged(prefs);
                    },
                  ),
                  SwitchListTile(
                    title: const Text(
                      '显示级数',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    value: prefs.showDegrees,
                    activeColor: Colors.cyan,
                    onChanged: (v) {
                      setState(() => prefs.showDegrees = v);
                      widget.onPreferencesChanged(prefs);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 关于
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GuitarBridge v3.0.0',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '相对音准训练工具 - Flutter 跨平台版',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '核心逻辑：调性建立 → 物理锚点 → 听觉挑战 → 寻址判定\n'
                    '技术栈：Flutter + Dart + flutter_soloud\n'
                    '支持平台：iOS / Android / Windows / macOS / Linux',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
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
