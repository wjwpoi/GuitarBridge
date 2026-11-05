#!/usr/bin/env python3
"""Builds the bundled clean-guitar sample set.

Source: Karoryfer Samples "Black And Green Guitars" (CC0-1.0), green guitar
(Gretsch Anniversary), ordinary plucks ("twang"), mezzo-forte layer, round
robins 1 and 2 — one recording per semitone from E2 (MIDI 40) to D6 (MIDI 86).

    git clone --filter=blob:none --no-checkout \\
        https://github.com/sfzinstruments/karoryfer.black-and-green-guitars src
    (cd src && git checkout HEAD -- Samples/green/ord)
    pip install numpy soundfile          # ffmpeg with libvorbis on PATH
    python3 tool/prepare_guitar_samples.py src/Samples/green/ord

Karoryfer names notes one octave higher than scientific pitch notation
(the guitar's low E2 is called "e3"); the previous repackaged set copied the
names verbatim and therefore sounded an octave low. Every output file is
pitch-checked against its MIDI number before it is written.

For each file the script trims leading silence, normalises loudness, keeps
up to [KEEP_SECONDS] of natural decay with a cosine fade, measures the
remaining tuning offset in cents and writes:

* assets/samples/guitar/<midi>_rr<n>.ogg
* lib/engine/sample_tuning.g.dart (per-file cents corrections)
"""

import math
import pathlib
import re
import subprocess
import sys
import tempfile

import numpy as np
import soundfile as sf

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "samples" / "guitar"
DART = ROOT / "lib" / "engine" / "sample_tuning.g.dart"

LOWEST, HIGHEST = 40, 86
ROUND_ROBINS = (1, 2)
KEEP_SECONDS = 3.0
FADE_SECONDS = 0.6
TARGET_RMS_DB = -15.0
PEAK_CEILING_DB = -1.0
VORBIS_QUALITY = "4"

PITCH_CLASS = {
    "c": 0, "db": 1, "d": 2, "eb": 3, "e": 4, "f": 5,
    "gb": 6, "g": 7, "ab": 8, "a": 9, "bb": 10, "b": 11,
}


def karoryfer_midi(name: str) -> int:
    match = re.match(r"twang_([a-g]b?)(\d)_", name)
    if not match:
        raise ValueError(name)
    # Karoryfer's "e3" is the guitar's low E2 (MIDI 40).
    return 12 * int(match.group(2)) + PITCH_CLASS[match.group(1)]


def measure_cents(x: np.ndarray, sr: int, midi: int) -> float:
    """Tuning offset of the lowest strong partial, in cents."""
    start = int(0.25 * sr)
    seg = x[start : start + int(1.0 * sr)]
    if len(seg) < sr // 4:
        seg = x[: int(1.0 * sr)]
    seg = (seg - seg.mean()) * np.hanning(len(seg))
    n = 1 << 20
    spectrum = np.abs(np.fft.rfft(seg, n))
    freqs = np.fft.rfftfreq(n, 1 / sr)
    expected = 440.0 * 2 ** ((midi - 69) / 12)
    candidates = []
    for harmonic in range(1, 5):
        lo = np.searchsorted(freqs, harmonic * expected * 2 ** (-60 / 1200))
        hi = np.searchsorted(freqs, harmonic * expected * 2 ** (60 / 1200))
        if hi <= lo + 2:
            continue
        i = lo + int(np.argmax(spectrum[lo:hi]))
        a, b, c = spectrum[i - 1], spectrum[i], spectrum[i + 1]
        offset = 0.5 * (a - c) / (a - 2 * b + c) if (a - 2 * b + c) else 0.0
        peak = freqs[i] + offset * (freqs[1] - freqs[0])
        candidates.append((harmonic, b, peak))
    strongest = max(magnitude for _, magnitude, _ in candidates)
    harmonic, _, peak = next(
        c for c in candidates if c[1] >= 0.25 * strongest
    )
    return 1200 * math.log2(peak / (harmonic * expected))


def process(source: pathlib.Path, midi: int, rr: int) -> float:
    x, sr = sf.read(source, always_2d=False)
    if x.ndim > 1:
        x = x.mean(axis=1)
    threshold = 0.02 * np.max(np.abs(x))
    onset = max(0, int(np.argmax(np.abs(x) > threshold)) - int(0.004 * sr))
    x = x[onset : onset + int(KEEP_SECONDS * sr)]

    fade = min(int(FADE_SECONDS * sr), len(x))
    x[-fade:] *= 0.5 * (1 + np.cos(np.linspace(0, math.pi, fade)))
    x[: int(0.002 * sr)] *= np.linspace(0, 1, int(0.002 * sr))

    body = x[: int(0.4 * sr)]
    rms = math.sqrt(float(np.mean(body**2)))
    x *= 10 ** (TARGET_RMS_DB / 20) / rms
    peak = float(np.max(np.abs(x)))
    ceiling = 10 ** (PEAK_CEILING_DB / 20)
    if peak > ceiling:
        x *= ceiling / peak

    cents = measure_cents(x, sr, midi)
    if abs(cents) > 45:
        raise SystemExit(f"{source.name}: {cents:+.1f} cents from MIDI {midi}")

    target = OUT / f"{midi}_rr{rr}.ogg"
    with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
        sf.write(tmp.name, x.astype(np.float32), sr, subtype="PCM_16")
        subprocess.run(
            [
                "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                "-i", tmp.name, "-ac", "1", "-c:a", "libvorbis",
                "-q:a", VORBIS_QUALITY, "-map_metadata", "-1", str(target),
            ],
            check=True,
        )
    return cents


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    source_dir = pathlib.Path(sys.argv[1])
    files = {}
    for path in source_dir.glob("twang_*_mf_rr*.wav"):
        rr = int(re.search(r"_rr(\d)\.wav$", path.name).group(1))
        if rr in ROUND_ROBINS:
            files[(karoryfer_midi(path.name), rr)] = path

    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.glob("*"):
        old.unlink()

    tuning = {}
    for midi in range(LOWEST, HIGHEST + 1):
        for rr in ROUND_ROBINS:
            source = files.get((midi, rr))
            if source is None:
                raise SystemExit(f"missing MIDI {midi} rr{rr}")
            tuning[(midi, rr)] = process(source, midi, rr)
            print(f"{midi:3d} rr{rr}: {tuning[(midi, rr)]:+6.1f} cents")

    lines = [
        "// GENERATED by tool/prepare_guitar_samples.py. Do not edit.",
        "",
        "/// Measured tuning offset of each bundled recording, in cents.",
        "/// Key: `midi * 10 + roundRobin`.",
        "const Map<int, double> sampleTuningCents = <int, double>{",
    ]
    for (midi, rr), cents in sorted(tuning.items()):
        lines.append(f"  {midi * 10 + rr}: {cents:.1f},")
    lines.append("};")
    DART.write_text("\n".join(lines) + "\n", encoding="utf-8")
    total = sum(p.stat().st_size for p in OUT.glob("*.ogg"))
    print(f"{len(tuning)} files, {total / 1048576:.1f} MB")


if __name__ == "__main__":
    main()
