import 'dart:math' as math;

import 'audio_engine.dart';

/// Real-guitar multisample layout used by the audio engine.
///
/// The bundled samples are the CC0 String Studio / Karoryfer electric-guitar
/// recordings. They are velocity-normalized single-note WAVs whose root notes
/// are encoded in the file name (MIDI 52 through 88, every two semitones).
class SampleConfig {
  SampleConfig._();

  static const String sampleDirectory = 'assets/samples/guitar';

  /// Root pitches available in the bundled real-guitar recordings.
  static const List<int> rootMidis = <int>[
    52,
    54,
    56,
    58,
    60,
    62,
    64,
    66,
    68,
    70,
    72,
    74,
    76,
    78,
    80,
    82,
    84,
    86,
    88,
  ];

  static List<String> requiredSamples(ToneMode mode) => rootMidis
      .map((rootMidi) => samplePathForRoot(mode, rootMidi))
      .toList(growable: false);

  /// Selects the closest recorded root for a target MIDI note.
  static int nearestSampleMidi(int targetMidi) {
    var nearest = rootMidis.first;
    var nearestDistance = (targetMidi - nearest).abs();
    for (final rootMidi in rootMidis.skip(1)) {
      final distance = (targetMidi - rootMidi).abs();
      if (distance < nearestDistance) {
        nearest = rootMidi;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  static String samplePath(ToneMode mode, int midiNote) =>
      samplePathForRoot(mode, nearestSampleMidi(midiNote));

  static String samplePathForRoot(ToneMode mode, int rootMidi) =>
      '$sampleDirectory/${rootMidi}_v100_rr1.wav';

  /// Playback-rate ratio needed to retune a recorded root to the target note.
  static double playbackSpeedForMidi(int midiNote) {
    final rootMidi = nearestSampleMidi(midiNote);
    return math.pow(2.0, (midiNote - rootMidi) / 12.0).toDouble();
  }

  /// Kept for compatibility with the previous octave-folding API.
  static int octaveShift(int targetMidi) =>
      (targetMidi - nearestSampleMidi(targetMidi)) ~/ 12;
}
