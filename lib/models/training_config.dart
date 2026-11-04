import '../core/constants.dart';
import 'note.dart';
import 'practice_record.dart';
import 'scale.dart';
import 'tuning.dart';

/// The user-selected training setup plus fretboard display toggles.
///
/// Immutable so the home screen can hold one value, hand it to every widget
/// that needs it and persist it in one place.
class TrainingConfig {
  final String key;
  final ScaleType scale;
  final Tuning tuning;
  final String difficulty;
  final bool showNoteNames;
  final bool showDegrees;
  final bool showFretNumbers;

  const TrainingConfig({
    this.key = 'C',
    this.scale = ScaleType.major,
    this.tuning = Tuning.standard,
    this.difficulty = 'easy',
    this.showNoteNames = true,
    this.showDegrees = false,
    this.showFretNumbers = true,
  });

  static const keys = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  static const difficultyKeys = ['easy', 'medium', 'hard'];

  static String difficultyLabel(String value) => switch (value) {
    'medium' => '进阶',
    'hard' => '完整指板',
    _ => '入门',
  };

  static String difficultyDescription(String value) => switch (value) {
    'medium' => '0–12 品 · 二度到六度与八度',
    'hard' => '0–22 品 · 全部音程',
    _ => '0–5 品 · 三度、四度、五度、八度',
  };

  factory TrainingConfig.fromPreferences(UserPreferences prefs) {
    return TrainingConfig(
      key: keys.contains(prefs.selectedKey) ? prefs.selectedKey : 'C',
      scale: ScaleType.values.firstWhere(
        (scale) => scale.chineseName == prefs.selectedScale,
        orElse: () => ScaleType.major,
      ),
      tuning: Tuning.all.firstWhere(
        (tuning) => tuning.name == prefs.selectedTuning,
        orElse: () => Tuning.standard,
      ),
      difficulty: AppConstants.difficulties.containsKey(prefs.difficulty)
          ? prefs.difficulty
          : 'easy',
      showNoteNames: prefs.showNoteNames,
      showDegrees: prefs.showDegrees,
      showFretNumbers: prefs.showFretNumbers,
    );
  }

  DifficultyConfig get difficultyConfig =>
      AppConstants.difficulties[difficulty] ??
      AppConstants.difficulties['easy']!;

  KeySignature get keySignature => KeySignature(
    NoteName.values.firstWhere(
      (note) => note.sharpName == key || note.flatName == key,
      orElse: () => NoteName.c,
    ),
    scale,
  );

  /// Copies the values into the persisted preferences object.
  void writeTo(UserPreferences prefs) {
    prefs
      ..selectedKey = key
      ..selectedScale = scale.chineseName
      ..selectedTuning = tuning.name
      ..difficulty = difficulty
      ..showNoteNames = showNoteNames
      ..showDegrees = showDegrees
      ..showFretNumbers = showFretNumbers;
  }

  /// Whether a change from [other] alters which questions can be generated.
  bool affectsQuestions(TrainingConfig other) =>
      key != other.key ||
      scale != other.scale ||
      tuning != other.tuning ||
      difficulty != other.difficulty;

  TrainingConfig copyWith({
    String? key,
    ScaleType? scale,
    Tuning? tuning,
    String? difficulty,
    bool? showNoteNames,
    bool? showDegrees,
    bool? showFretNumbers,
  }) {
    return TrainingConfig(
      key: key ?? this.key,
      scale: scale ?? this.scale,
      tuning: tuning ?? this.tuning,
      difficulty: difficulty ?? this.difficulty,
      showNoteNames: showNoteNames ?? this.showNoteNames,
      showDegrees: showDegrees ?? this.showDegrees,
      showFretNumbers: showFretNumbers ?? this.showFretNumbers,
    );
  }
}
