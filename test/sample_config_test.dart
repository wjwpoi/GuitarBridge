import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/engine/audio_engine.dart';
import 'package:guitar_bridge/engine/sample_config.dart';

void main() {
  group('SampleConfig', () {
    test('selects sounding roots rather than the original file numbers', () {
      expect(SampleConfig.nearestSampleMidi(38), 40);
      expect(SampleConfig.nearestSampleMidi(40), 40);
      expect(SampleConfig.nearestSampleMidi(64), 64);
      expect(SampleConfig.nearestSampleMidi(88), 76);
    });

    test('calculates equal-temperament playback speed', () {
      expect(SampleConfig.playbackSpeedForMidi(64), closeTo(1.0, 0.000001));
      expect(SampleConfig.playbackSpeedForMidi(40), closeTo(1.0, 0.000001));
      expect(SampleConfig.playbackSpeedForMidi(88), closeTo(2.0, 0.000001));
    });

    test('all tone modes resolve to the same bundled recordings', () {
      for (final mode in ToneMode.values) {
        expect(
          SampleConfig.samplePath(mode, 40),
          'assets/samples/guitar/52_v100_rr1.wav',
        );
        expect(
          SampleConfig.samplePath(mode, 64),
          'assets/samples/guitar/76_v100_rr1.wav',
        );
        expect(SampleConfig.requiredSamples(mode), hasLength(19));
      }
    });
  });
}
