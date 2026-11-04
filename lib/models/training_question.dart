import 'note.dart';
import 'tuning.dart';

/// How a submitted fretboard answer is evaluated.
///
/// [exactPitch] is the default for ear training because audio can identify a
/// MIDI pitch, but it cannot encode which of several equivalent fretboard
/// positions produced that pitch.
enum AnswerMode { exactPitch, exactPosition, pitchClass }

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

  /// The named interval for this prompt. Questions are always ascending and
  /// at most one octave, so the semitone count maps to exactly one name.
  IntervalType get interval => IntervalType.values.firstWhere(
    (candidate) => candidate.semitones == intervalSemitones,
  );

  String get id =>
      '${root.stringIndex}:${root.fret}-${target.stringIndex}:${target.fret}';
}

/// Direction hint for a wrong attempt, relative to the target pitch.
enum PitchDirection { tooLow, tooHigh, samePitchClassWrongOctave }

/// The final result of one question in a session.
///
/// [firstTryCorrect] is what accuracy and streaks are based on: a pitch found
/// after several audible attempts is useful practice, but it is not evidence
/// that the interval was recognised by ear.
class QuestionOutcome {
  final TrainingQuestion question;
  final int attempts;
  final bool firstTryCorrect;
  final bool solved;
  final bool revealed;

  /// Seconds between the answer prompt and the first attempt.
  final double? firstResponseSeconds;

  const QuestionOutcome({
    required this.question,
    required this.attempts,
    required this.firstTryCorrect,
    required this.solved,
    required this.revealed,
    this.firstResponseSeconds,
  });

  int get intervalSemitones => question.intervalSemitones;
}
