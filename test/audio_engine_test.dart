import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_bridge/engine/audio_engine.dart';

void main() {
  group('AudioEngine - Pitch baseline', () {
    test('uses A4 as the 440 Hz reference', () {
      expect(AudioEngine.frequencyForMidi(69), closeTo(440.0, 0.000001));
    });

    test('maps middle C to the standard equal-temperament frequency', () {
      expect(AudioEngine.frequencyForMidi(60), closeTo(261.625565, 0.000001));
    });

    test('one octave doubles the generated frequency', () {
      final lower = AudioEngine.frequencyForMidi(57);
      final upper = AudioEngine.frequencyForMidi(69);
      expect(upper / lower, closeTo(2.0, 0.000001));
    });

    test('tone modes map to pitch-preserving waveforms', () {
      expect(AudioEngine.waveformForTone(ToneMode.clean).name, 'sin');
      expect(AudioEngine.waveformForTone(ToneMode.overdrive).name, 'fSaw');
      expect(AudioEngine.waveformForTone(ToneMode.distortion).name, 'fSquare');
    });
  });
}
