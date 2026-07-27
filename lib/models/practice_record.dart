/// 练习记录（对应原 Swift 的 PracticeRecord）
class PracticeRecord {
  final int? id;
  final DateTime date;
  final int totalAttempts;
  final int correctAnswers;
  final double durationSeconds;
  final String keySignature;
  final String scaleType;
  final int bestStreak;

  const PracticeRecord({
    this.id,
    required this.date,
    required this.totalAttempts,
    required this.correctAnswers,
    required this.durationSeconds,
    required this.keySignature,
    required this.scaleType,
    required this.bestStreak,
  });

  double get accuracy =>
      totalAttempts > 0 ? correctAnswers / totalAttempts * 100 : 0;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date.toIso8601String(),
        'totalAttempts': totalAttempts,
        'correctAnswers': correctAnswers,
        'durationSeconds': durationSeconds,
        'keySignature': keySignature,
        'scaleType': scaleType,
        'bestStreak': bestStreak,
      };

  factory PracticeRecord.fromMap(Map<String, dynamic> map) => PracticeRecord(
        id: map['id'] as int?,
        date: DateTime.parse(map['date'] as String),
        totalAttempts: map['totalAttempts'] as int,
        correctAnswers: map['correctAnswers'] as int,
        durationSeconds: (map['durationSeconds'] as num).toDouble(),
        keySignature: map['keySignature'] as String,
        scaleType: map['scaleType'] as String,
        bestStreak: map['bestStreak'] as int,
      );
}

/// 连续练习（对应原 Swift 的 PracticeStreak）
class PracticeStreak {
  final int? id;
  final DateTime date;

  const PracticeStreak({this.id, required this.date});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date.toIso8601String(),
      };

  factory PracticeStreak.fromMap(Map<String, dynamic> map) => PracticeStreak(
        id: map['id'] as int?,
        date: DateTime.parse(map['date'] as String),
      );
}

/// 用户偏好设置
class UserPreferences {
  bool showNoteNames;
  bool showFretNumbers;
  bool showDegrees;
  String selectedTuning;
  String selectedKey;
  String selectedScale;
  String difficulty;
  bool hasCompletedOnboarding;

  UserPreferences({
    this.showNoteNames = true,
    this.showFretNumbers = true,
    this.showDegrees = false,
    this.selectedTuning = '标准 (EADGBE)',
    this.selectedKey = 'C',
    this.selectedScale = '自然大调',
    this.difficulty = 'easy',
    this.hasCompletedOnboarding = false,
  });

  Map<String, dynamic> toJson() => {
        'showNoteNames': showNoteNames,
        'showFretNumbers': showFretNumbers,
        'showDegrees': showDegrees,
        'selectedTuning': selectedTuning,
        'selectedKey': selectedKey,
        'selectedScale': selectedScale,
        'difficulty': difficulty,
        'hasCompletedOnboarding': hasCompletedOnboarding,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        showNoteNames: json['showNoteNames'] as bool? ?? true,
        showFretNumbers: json['showFretNumbers'] as bool? ?? true,
        showDegrees: json['showDegrees'] as bool? ?? false,
        selectedTuning: json['selectedTuning'] as String? ?? '标准 (EADGBE)',
        selectedKey: json['selectedKey'] as String? ?? 'C',
        selectedScale: json['selectedScale'] as String? ?? '自然大调',
        difficulty: json['difficulty'] as String? ?? 'easy',
        hasCompletedOnboarding:
            json['hasCompletedOnboarding'] as bool? ?? false,
      );
}
