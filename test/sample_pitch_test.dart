import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/engine/audio_engine.dart';
import 'package:guitar_bridge/engine/sample_config.dart';

// Inspect the actual bundled PCM, independently of its file name. A strong
// autocorrelation peak is required, so a second harmonic cannot pass as root.
double measuredRootFrequency(ByteData wav, int midi) {
  expect(String.fromCharCodes(wav.buffer.asUint8List(0, 4)), 'RIFF');
  expect(wav.getUint16(20, Endian.little), 1); // PCM
  expect(wav.getUint16(22, Endian.little), 1); // mono
  expect(wav.getUint16(34, Endian.little), 24);
  final sampleRate = wav.getUint32(24, Endian.little);
  var dataOffset = 12;
  while (String.fromCharCodes(wav.buffer.asUint8List(dataOffset, 4)) !=
      'data') {
    final size = wav.getUint32(dataOffset + 4, Endian.little);
    dataOffset += 8 + size + (size % 2);
  }
  dataOffset += 8;
  const stride = 1;
  final samples = <double>[];
  for (
    var frame = (sampleRate * 0.12).round();
    frame < (sampleRate * 0.60).round();
    frame += stride
  ) {
    final offset = dataOffset + frame * 3;
    var value =
        wav.getUint8(offset) |
        (wav.getUint8(offset + 1) << 8) |
        (wav.getUint8(offset + 2) << 16);
    if ((value & 0x800000) != 0) value -= 0x1000000;
    samples.add(value / 0x800000);
  }
  final mean = samples.reduce((a, b) => a + b) / samples.length;
  for (var i = 0; i < samples.length; i++) {
    samples[i] -= mean;
  }
  final rate = sampleRate / stride;
  final expected = 440 * pow(2, (midi - 69) / 12);
  final firstLag = (rate / (expected * 1.05)).floor();
  final lastLag = (rate / (expected * 0.95)).ceil();
  final correlations = <int, double>{};
  for (var lag = firstLag; lag <= lastLag; lag++) {
    var dot = 0.0;
    var leftEnergy = 0.0;
    var rightEnergy = 0.0;
    for (var i = 0; i < samples.length - lag; i++) {
      final left = samples[i];
      final right = samples[i + lag];
      dot += left * right;
      leftEnergy += left * left;
      rightEnergy += right * right;
    }
    correlations[lag] = dot / sqrt(leftEnergy * rightEnergy);
  }
  final best = correlations.keys.reduce(
    (a, b) => correlations[a]! > correlations[b]! ? a : b,
  );
  expect(
    correlations[best],
    greaterThan(0.90),
    reason: 'MIDI $midi must match a fundamental, not only a harmonic',
  );
  final left = correlations[best - 1];
  final right = correlations[best + 1];
  var peak = best.toDouble();
  if (left != null && right != null) {
    peak += 0.5 * (left - right) / (left - 2 * correlations[best]! + right);
  }
  return rate / peak;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final measured = <int, double>{};

  test('every bundled sample has its declared sounding MIDI root', () async {
    for (final midi in SampleConfig.rootMidis) {
      final path = SampleConfig.samplePathForRoot(ToneMode.clean, midi);
      final wav = await rootBundle.load(path);
      final actual = measuredRootFrequency(wav, midi);
      measured[midi] = actual;
      final expected = 440 * pow(2, (midi - 69) / 12);
      final cents = 1200 * log(actual / expected) / ln2;
      expect(cents.abs(), lessThan(35), reason: '$path has wrong root pitch');
    }
  });

  test('recording plus playback rate yields the requested pitch', () async {
    for (final midi in [38, 40, 64, 69, 86, 88]) {
      final root = SampleConfig.nearestSampleMidi(midi);
      final actualRoot =
          measured[root] ??
          measuredRootFrequency(
            await rootBundle.load(
              SampleConfig.samplePath(ToneMode.clean, midi),
            ),
            root,
          );
      final output = actualRoot * SampleConfig.playbackSpeedForMidi(midi);
      final expected = 440 * pow(2, (midi - 69) / 12);
      expect(
        (1200 * log(output / expected) / ln2).abs(),
        lessThan(35),
        reason: 'MIDI $midi has incorrect audible output',
      );
    }
  });
}
