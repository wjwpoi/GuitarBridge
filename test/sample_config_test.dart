import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/engine/audio_engine.dart';
import 'package:guitar_bridge/engine/sample_config.dart';

void main() {
  group('SampleConfig', () {
    test('folds target notes into the C4-B4 sample octave', () {
      expect(SampleConfig.nearestSampleMidi(40), 64); // E2 -> E4
      expect(SampleConfig.nearestSampleMidi(64), 64); // E4 -> E4
      expect(SampleConfig.nearestSampleMidi(88), 64); // E6 -> E4
    });

    test('calculates octave playback shifts', () {
      expect(SampleConfig.octaveShift(40), -2);
      expect(SampleConfig.octaveShift(64), 0);
      expect(SampleConfig.octaveShift(88), 2);
    });

    test('always resolves to a bundled sample path', () {
      expect(
        SampleConfig.samplePath(ToneMode.overdrive, 40),
        'assets/samples/overdrive/E4.wav',
      );
    });
  });
}
