import 'tuning.dart';

/// How a submitted fretboard answer is evaluated.
enum AnswerMode { exactPosition, pitchClass }

/// A concrete location on the fretboard.
class FretPosition {
  final int stringIndex;
  final int fret;
  final int midi;

  const FretPosition({
    required this.stringIndex,
    required this.fret,
    required this.midi,
  });

  factory FretPosition.fromTuning({
    required Tuning tuning,
    required int stringIndex,
    required int fret,
  }) {
    return FretPosition(
      stringIndex: stringIndex,
      fret: fret,
      midi: tuning.noteAt(stringIndex, fret),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FretPosition &&
      other.stringIndex == stringIndex &&
      other.fret == fret &&
      other.midi == midi;

  @override
  int get hashCode => Object.hash(stringIndex, fret, midi);

  @override
  String toString() =>
      'FretPosition(string=$stringIndex, fret=$fret, midi=$midi)';
}

/// One immutable training prompt.
class TrainingQuestion {
  final FretPosition root;
  final FretPosition target;
  final int intervalSemitones;

  const TrainingQuestion({
    required this.root,
    required this.target,
    required this.intervalSemitones,
  });

  String get id =>
      '${root.stringIndex}:${root.fret}-${target.stringIndex}:${target.fret}';
}
