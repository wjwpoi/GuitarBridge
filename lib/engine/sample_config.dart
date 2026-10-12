import 'dart:math' as math;

import 'tone_mode.dart';

/// Real-guitar multisample layout used by the audio engine.
///
/// The bundled samples are the CC0 String Studio / Karoryfer electric-guitar
/// recordings. The original file numbers are one octave above the measured
/// pitches: files 52 through 88 contain MIDI 40 through 76. Keep those source
/// names for provenance, but use the sounding pitch for all playback ratios.
class SampleConfig {
  SampleConfig._();

  static const String sampleDirectory = 'assets/samples/guitar';
  static const int fileNumberOffset = 12;

  /// Root pitches available in the bundled real-guitar recordings.
  static const List<int> rootMidis = <int>[
    40,
    42,
    44,
    46,
    48,
    50,
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
      '$sampleDirectory/${rootMidi + fileNumberOffset}_v100_rr1.wav';

  /// Playback-rate ratio needed to retune a recorded root to the target note.
  static double playbackSpeedForMidi(int midiNote) {
    final rootMidi = nearestSampleMidi(midiNote);
    return math.pow(2.0, (midiNote - rootMidi) / 12.0).toDouble();
  }

  /// Kept for compatibility with the previous octave-folding API.
  static int octaveShift(int targetMidi) =>
      (targetMidi - nearestSampleMidi(targetMidi)) ~/ 12;
}
