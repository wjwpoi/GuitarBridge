
/// ȫ�ֳ�������Ӧԭ Swift Constants.swift��
class AppConstants {
  AppConstants._();

  // === ָ��������� ===
  /// Fender ��׼�ҳ� 25.5 Ӣ�� -> Ʒ��๫ʽϵ��
  static const double fretSpacingFactor = 17.817;

  /// Ĭ�����Ʒλ
  static const int maxFret = 22;

  /// ����
  static const int stringCount = 6;

  // === ѵ������ ===
  static const int defaultQuestionsPerSession = 10;
  static const int minQuestions = 5;
  static const int maxQuestions = 50;

  // === ��Ƶ���� ===
  static const double defaultVolume = 0.8;
  static const int crossfadeSteps = 30;
  static const Duration crossfadeDuration = Duration(milliseconds: 150);

  // === MIDI ��Χ ===
  /// ��׼��������� E2
  static const int guitarLowestMidi = 40;
  /// ��׼��������� (24Ʒ 1��) E6
  static const int guitarHighestMidi = 88;

  // === �Ѷ����� ===
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
      allowedIntervals: [0, 1, 2, 3, 4, 5, 7, 8, 9], // ���Ӵ�/С���ȡ�����
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
