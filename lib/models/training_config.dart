import '../core/constants.dart';
import 'note.dart';
import 'practice_record.dart';
import 'scale.dart';
import 'tuning.dart';

/// What the fretboard shows on scale notes.
enum FretLabels {
  noteNames('names', '音名'),
  degrees('degrees', '级数'),

  /// No scale-note markers at all, only fret inlays like a real guitar.
  hidden('hidden', '仅品记');

  final String storageName;
  final String label;
  const FretLabels(this.storageName, this.label);

  static FretLabels fromStorage(String value) => FretLabels.values.firstWhere(
    (mode) => mode.storageName == value,
    orElse: () => FretLabels.noteNames,
  );
}

/// The user-selected training setup plus fretboard display toggles.
///
/// Immutable so the home screen can hold one value, hand it to every widget
/// that needs it and persist it in one place.
class TrainingConfig {
  final String key;
  final ScaleType scale;
  final Tuning tuning;
  final String difficulty;
  final FretLabels labels;
  final bool showFretNumbers;

  const TrainingConfig({
    this.key = 'C',
    this.scale = ScaleType.major,
    this.tuning = Tuning.standard,
    this.difficulty = 'easy',
    this.labels = FretLabels.noteNames,
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
      labels: FretLabels.fromStorage(prefs.fretLabels),
      showFretNumbers: prefs.showFretNumbers,
    );
  }

  bool get showNoteNames => labels == FretLabels.noteNames;
  bool get showDegrees => labels == FretLabels.degrees;
  bool get showScaleNotes => labels != FretLabels.hidden;

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
      ..fretLabels = labels.storageName
      ..showNoteNames = labels == FretLabels.noteNames
      ..showDegrees = labels == FretLabels.degrees
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
    FretLabels? labels,
    bool? showFretNumbers,
  }) {
    return TrainingConfig(
      key: key ?? this.key,
      scale: scale ?? this.scale,
      tuning: tuning ?? this.tuning,
      difficulty: difficulty ?? this.difficulty,
      labels: labels ?? this.labels,
      showFretNumbers: showFretNumbers ?? this.showFretNumbers,
    );
  }
}
