import 'package:flutter/services.dart';

/// 触感反馈管理器（对应原 Swift HapticManager.swift）
class HapticManager {
  HapticManager._();

  /// 轻触感 - 按钮点击
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// 中等触感 - 选择、切换
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// 重触感 - 错误、警告
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// 成功 - 回答正确
  static void success() {
    HapticFeedback.mediumImpact();
    // 在 iOS 上，可以调用 UINotificationFeedbackGenerator
    // 在 Android 上，可以通过 Vibrator 实现不同模式
  }

  /// 错误 - 回答错误
  static void error() {
    HapticFeedback.heavyImpact();
  }

  /// 选择变化 - picker 滚动
  static void selection() {
    HapticFeedback.selectionClick();
  }
}
