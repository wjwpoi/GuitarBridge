
/// 全局常量（对应原 Swift Constants.swift）
class AppConstants {
  AppConstants._();

  // === 指板物理规格 ===
  /// Fender 标准弦长 25.5 英寸 -> 品间距公式系数
  static const double fretSpacingFactor = 17.817;

  /// 默认最大品位
  static const int maxFret = 22;

  /// 弦数
  static const int stringCount = 6;

  // === 训练配置 ===
  static const int defaultQuestionsPerSession = 10;
  static const int minQuestions = 5;
  static const int maxQuestions = 50;

  // === 音频配置 ===
  static const double defaultVolume = 0.8;
  static const int crossfadeSteps = 30;
  static const Duration crossfadeDuration = Duration(milliseconds: 150);

  // === MIDI 范围 ===
  /// 标准吉他最低音 E2
  static const int guitarLowestMidi = 40;
  /// 标准吉他最高音 (24品 1弦) E6
  static const int guitarHighestMidi = 88;

  // === 难度配置 ===
  static const Map<String, DifficultyConfig> difficulties = {
    'easy': DifficultyConfig(
      fretRange: (0, 5),
      stringRange: (0, 5),
      allowedIntervals: [0, 3, 4, 5, 7], // P1, m3, M3, P4, P5
      showHint: true,
    ),
    'medium': DifficultyConfig(
      fretRange: (0, 12),
      stringRange: (0, 5),
      allowedIntervals: [0, 1, 2, 3, 4, 5, 7, 8, 9], // 增加大/小二度、六度
      showHint: false,
    ),
    'hard': DifficultyConfig(
      fretRange: (0, 22),
      stringRange: (0, 5),
      allowedIntervals: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
      showHint: false,
    ),
  };
}

class DifficultyConfig {
  final (int, int) fretRange;
  final (int, int) stringRange;
  final List<int> allowedIntervals;
  final bool showHint;

  const DifficultyConfig({
    required this.fretRange,
    required this.stringRange,
    required this.allowedIntervals,
    required this.showHint,
  });
}
