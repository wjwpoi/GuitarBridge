import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/engine/sample_config.dart';
import 'package:guitar_bridge/models/tuning.dart';

void main() {
  group('SampleConfig', () {
    test('has one recording per semitone across the whole neck', () {
      expect(SampleConfig.rootMidis.first, 40); // open low E
      expect(SampleConfig.rootMidis.last, 86); // 22nd fret, high E
      expect(SampleConfig.rootMidis.length, 47);
      for (final tuning in [Tuning.standard, Tuning.dropD, Tuning.openG]) {
        for (var s = 0; s < tuning.stringCount; s++) {
          for (var fret = 0; fret <= 22; fret++) {
            final midi = tuning.noteAt(s, fret);
            if (midi < 40 || midi > 86) continue;
            expect(SampleConfig.nearestSampleMidi(midi), midi);
          }
        }
      }
    });

    test('clamps notes outside the recorded range', () {
      expect(SampleConfig.nearestSampleMidi(38), 40);
      expect(SampleConfig.nearestSampleMidi(90), 86);
    });

    test('playback speed only corrects the measured detuning', () {
      for (final midi in SampleConfig.rootMidis) {
        for (var rr = 1; rr <= SampleConfig.roundRobins; rr++) {
          final cents = SampleConfig.tuningCents(midi, rr);
          expect(cents.abs(), lessThan(45), reason: '$midi rr$rr');
          final speed = SampleConfig.playbackSpeedForMidi(midi, roundRobin: rr);
          expect(speed, closeTo(math.pow(2, -cents / 1200), 1e-9));
        }
      }
    });

    test('notes below the range are transposed from the lowest sample', () {
      final speed = SampleConfig.playbackSpeedForMidi(38);
      final cents = SampleConfig.tuningCents(40, 1);
      expect(speed, closeTo(math.pow(2, (-200 - cents) / 1200), 1e-9));
    });

    test('every referenced sample file is bundled', () {
      expect(SampleConfig.requiredSamples, hasLength(94));
      for (final path in SampleConfig.requiredSamples) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
      expect(
        SampleConfig.samplePath(64, roundRobin: 2),
        'assets/samples/guitar/64_rr2.ogg',
      );
    });
  });
}
