import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/engine/audio_engine.dart';
import 'package:guitar_bridge/engine/sample_config.dart';

void main() {
  group('SampleConfig', () {
    test('selects the closest real-guitar sample root', () {
      expect(SampleConfig.nearestSampleMidi(40), 52);
      expect(SampleConfig.nearestSampleMidi(64), 64);
      expect(SampleConfig.nearestSampleMidi(88), 88);
    });

    test('calculates equal-temperament playback speed', () {
      expect(SampleConfig.playbackSpeedForMidi(64), closeTo(1.0, 0.000001));
      expect(SampleConfig.playbackSpeedForMidi(52), closeTo(1.0, 0.000001));
      expect(SampleConfig.playbackSpeedForMidi(40), closeTo(0.5, 0.000001));
    });

    test('always resolves to a bundled sample path', () {
      expect(
        SampleConfig.samplePath(ToneMode.overdrive, 40),
        'assets/samples/guitar/52_v100_rr1.wav',
      );
    });
  });
}
