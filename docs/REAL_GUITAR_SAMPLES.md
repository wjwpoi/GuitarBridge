# Real guitar samples

GuitarBridge bundles the high-velocity layer of the **String Studio — Electric
Guitar sample pack v4**, which is a repackaging of Karoryfer Samples' **Black
And Green Guitars** recordings.

- Source pack: <https://github.com/sfzinstruments/karoryfer.black-and-green-guitars/releases/download/v1.000/Karoryfer_Black_And_Green_Guitars_1000.zip>
- Repackaged samples and manifest: <https://huggingface.co/AEmotionStudio/stringstudio-electric-guitar-samples>
- License: CC0-1.0 (public-domain dedication)
- Format: mono, 48 kHz, 24-bit PCM WAV
- Sounding roots: MIDI 40–76 in two-semitone steps. The source file numbers
  (52–88) are one octave above their measured fundamentals; `SampleConfig`
  preserves those original names and maps them to their sounding roots.

`test/sample_pitch_test.dart` checks the actual bundled PCM fundamentals and
the resulting playback pitch, including notes below and above the sample range.

The application keeps the existing three tone choices. `清晰` plays the raw
recording, while `过载` and `失真` apply SoLoud's existing global wave-shaper
effect to that real recording. The nearest bundled root is selected for each
MIDI note and retuned with an equal-temperament playback-rate ratio.
