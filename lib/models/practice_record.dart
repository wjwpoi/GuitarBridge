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

  /// First-try results per interval: semitones → (firstTryCorrect, total).
  /// Empty for records written before per-interval tracking existed.
  final Map<int, (int, int)> intervalResults;

  /// Difficulty key used for the session, null for legacy records.
  final String? difficulty;

  const PracticeRecord({
    this.id,
    required this.date,
    required this.totalAttempts,
    required this.correctAnswers,
    required this.durationSeconds,
    required this.keySignature,
    required this.scaleType,
    required this.bestStreak,
    this.intervalResults = const {},
    this.difficulty,
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
    if (intervalResults.isNotEmpty)
      'intervalResults': {
        for (final entry in intervalResults.entries)
          '${entry.key}': [entry.value.$1, entry.value.$2],
      },
    if (difficulty != null) 'difficulty': difficulty,
  };

  static Map<int, (int, int)> _parseIntervalResults(Object? raw) {
    if (raw is! Map) return const {};
    final result = <int, (int, int)>{};
    for (final entry in raw.entries) {
      final semitones = int.tryParse('${entry.key}');
      final value = entry.value;
      if (semitones == null || value is! List || value.length != 2) continue;
      final correct = value[0];
      final total = value[1];
      if (correct is! num || total is! num) continue;
      result[semitones] = (correct.toInt(), total.toInt());
    }
    return result;
  }

  factory PracticeRecord.fromMap(Map<String, dynamic> map) => PracticeRecord(
    id: map['id'] as int?,
    date: DateTime.parse(map['date'] as String),
    totalAttempts: map['totalAttempts'] as int,
    correctAnswers: map['correctAnswers'] as int,
    durationSeconds: (map['durationSeconds'] as num).toDouble(),
    keySignature: map['keySignature'] as String,
    scaleType: map['scaleType'] as String,
    bestStreak: map['bestStreak'] as int,
    intervalResults: _parseIntervalResults(map['intervalResults']),
    difficulty: map['difficulty'] as String?,
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
  int questionsPerSession;
  double audioVolume;
  String toneMode;
  bool hasCompletedOnboarding;

  /// 0 = never reveal, 1-5 = max wrong attempts before showing correct answer.
  int maxFailedAttempts;

  UserPreferences({
    this.showNoteNames = true,
    this.showFretNumbers = true,
    this.showDegrees = false,
    this.selectedTuning = '标准 (EADGBE)',
    this.selectedKey = 'C',
    this.selectedScale = '自然大调',
    this.difficulty = 'easy',
    this.questionsPerSession = 10,
    this.audioVolume = 0.8,
    this.toneMode = 'clean',
    this.hasCompletedOnboarding = false,
    this.maxFailedAttempts = 3,
  });

  Map<String, dynamic> toJson() => {
    'showNoteNames': showNoteNames,
    'showFretNumbers': showFretNumbers,
    'showDegrees': showDegrees,
    'selectedTuning': selectedTuning,
    'selectedKey': selectedKey,
    'selectedScale': selectedScale,
    'difficulty': difficulty,
    'questionsPerSession': questionsPerSession,
    'audioVolume': audioVolume,
    'toneMode': toneMode,
    'hasCompletedOnboarding': hasCompletedOnboarding,
    'maxFailedAttempts': maxFailedAttempts,
  };

  factory UserPreferences.fromJson(
    Map<String, dynamic> json,
  ) => UserPreferences(
    showNoteNames: json['showNoteNames'] as bool? ?? true,
    showFretNumbers: json['showFretNumbers'] as bool? ?? true,
    showDegrees: json['showDegrees'] as bool? ?? false,
    selectedTuning: json['selectedTuning'] as String? ?? '标准 (EADGBE)',
    selectedKey: json['selectedKey'] as String? ?? 'C',
    selectedScale: json['selectedScale'] as String? ?? '自然大调',
    difficulty: json['difficulty'] as String? ?? 'easy',
    questionsPerSession: (json['questionsPerSession'] as num?)?.toInt() ?? 10,
    audioVolume: (json['audioVolume'] as num?)?.toDouble() ?? 0.8,
    toneMode: json['toneMode'] as String? ?? 'clean',
    hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
    maxFailedAttempts: (json['maxFailedAttempts'] as num?)?.toInt() ?? 3,
  );
}
