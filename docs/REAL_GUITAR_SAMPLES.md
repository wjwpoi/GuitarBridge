# Real guitar samples

GuitarBridge bundles a clean electric guitar recorded by Karoryfer Samples for
**Black And Green Guitars**: the green guitar (Gretsch Anniversary hollowbody),
ordinary plucks, mezzo-forte layer.

- Source: <https://github.com/sfzinstruments/karoryfer.black-and-green-guitars>
  (`Samples/green/ord/twang_*_mf_rr1.wav` and `_rr2.wav`)
- License: CC0-1.0 (public-domain dedication)
- Coverage: every semitone from E2 (MIDI 40, open low E) to D6 (MIDI 86,
  22nd fret on the high E string), two round robins per note — 94 files
- Bundled format: mono 44.1 kHz Ogg Vorbis (q4), about 2.7 MB in total

## Processing

`tool/prepare_guitar_samples.py` produces the bundled files and
`lib/engine/sample_tuning.g.dart`:

1. Karoryfer note names are one octave above scientific pitch notation (the
   guitar's low E2 is called `e3`). They are converted with that offset and
   every file's pitch is measured; the build fails if a file is more than
   45 cents away from its MIDI number.
2. Leading silence is trimmed so every cue starts on its attack.
3. Loudness is normalised to −15 dBFS RMS over the first 400 ms with a −1 dBFS
   peak ceiling, so all notes sound equally loud.
4. Up to 3 s of natural decay is kept, ending with a 0.6 s cosine fade.
5. The remaining tuning offset of each recording (−12 to +15 cents) is stored
   and compensated at playback, so every note is exact equal temperament
   (A4 = 440 Hz).

At runtime each MIDI note plays its own recording; consecutive plays of the
same note alternate between the two takes.

## History

Before November 2026 the app used a repackaged subset (String Studio) of the
same recordings: 19 roots every two semitones, truncated to 2.5 s. That
package had copied Karoryfer's note names verbatim, so every note sounded one
octave lower than the fretboard showed, and notes below E3 were transposed
down as far as E1.
