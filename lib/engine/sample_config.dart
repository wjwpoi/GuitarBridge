import 'dart:math' as math;

import 'sample_tuning.g.dart';

/// Real-guitar multisample layout used by the audio engine.
///
/// One clean recording per semitone from E2 (MIDI 40, open low E) to D6
/// (MIDI 86, 22nd fret on the high E string), two round robins each, taken
/// from Karoryfer Samples' CC0 "Black And Green Guitars" (green Gretsch,
/// ordinary pluck, mezzo-forte). Files are produced by
/// `tool/prepare_guitar_samples.py`; see docs/REAL_GUITAR_SAMPLES.md.
class SampleConfig {
  SampleConfig._();

  static const String sampleDirectory = 'assets/samples/guitar';
  static const int lowestMidi = 40;
  static const int highestMidi = 86;
  static const int roundRobins = 2;

  /// Every recorded pitch. Notes are never pitch-shifted by more than the
  /// small tuning correction unless they fall outside this range.
  static final List<int> rootMidis = List<int>.unmodifiable([
    for (var midi = lowestMidi; midi <= highestMidi; midi++) midi,
  ]);

  static List<String> get requiredSamples => [
    for (final midi in rootMidis)
      for (var rr = 1; rr <= roundRobins; rr++) samplePathForRoot(midi, rr),
  ];

  /// Closest recorded pitch (identity inside the guitar range).
  static int nearestSampleMidi(int targetMidi) =>
      targetMidi.clamp(lowestMidi, highestMidi).toInt();

  static String samplePath(int midiNote, {int roundRobin = 1}) =>
      samplePathForRoot(nearestSampleMidi(midiNote), roundRobin);

  static String samplePathForRoot(int rootMidi, [int roundRobin = 1]) =>
      '$sampleDirectory/${rootMidi}_rr$roundRobin.ogg';

  /// Measured detuning of one recording, in cents (positive = sharp).
  static double tuningCents(int rootMidi, int roundRobin) =>
      sampleTuningCents[rootMidi * 10 + roundRobin] ?? 0;

  /// Playback-rate ratio that lands the recording exactly on [midiNote] in
  /// twelve-tone equal temperament (A4 = 440 Hz).
  static double playbackSpeedForMidi(int midiNote, {int roundRobin = 1}) {
    final rootMidi = nearestSampleMidi(midiNote);
    final cents =
        (midiNote - rootMidi) * 100 - tuningCents(rootMidi, roundRobin);
    return math.pow(2.0, cents / 1200).toDouble();
  }
}
