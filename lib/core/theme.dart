import 'package:flutter/material.dart';

/// 主题系统（对应原 Swift Theme.swift）
class AppTheme {
  AppTheme._();

  /// 音色模式对应的主题色
  static Color toneColor(String toneMode) {
    switch (toneMode.toLowerCase()) {
      case 'clean':
        return const Color(0xFF4FC3F7); // 清音蓝
      case 'overdrive':
        return const Color(0xFFFF7043); // 过载橙
      case 'distortion':
        return const Color(0xFFE53935); // 失真红
      default:
        return const Color(0xFF66BB6A); // 默认绿
    }
  }

  /// 主色调
  static const Color primaryColor = Color(0xFF1A237E); // 深靛蓝
  static const Color accentColor = Color(0xFF00BCD4); // 青
  static const Color correctColor = Color(0xFF4CAF50);
  static const Color wrongColor = Color(0xFFF44336);
  static const Color fretboardWood = Color(0xFF8D6E63);
  static const Color stringColor = Color(0xFFBDBDBD);
  static const Color fretMarkerColor = Color(0xFFE0E0E0);
  static const Color backgroundColor = Color(0xFF121212);

  /// 训练模式主题
  static ThemeData trainingTheme(String toneMode) {
    final tone = toneColor(toneMode);
    return ThemeData.dark().copyWith(
      colorScheme: ColorScheme.dark(
        primary: tone,
        secondary: tone.withAlpha(180),
        surface: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E2E),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF252536),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tone,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }
}
