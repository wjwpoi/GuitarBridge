#!/usr/bin/env python3
"""Builds the bundled, subsetted Chinese UI fonts.

Flutter web otherwise downloads CJK fallback fonts from fonts.gstatic.com at
runtime, which is slow or blocked in mainland China. We ship static-weight
subsets of Noto Sans SC / Noto Serif SC (SIL OFL 1.1) that contain exactly
the characters used by the app, plus ASCII and common punctuation.

Usage (after changing any user-visible Chinese text):

    pip install fonttools
    python3 tool/subset_fonts.py --sans NotoSansSC[wght].ttf \
        --serif NotoSerifSC[wght].ttf

The variable source fonts come from https://github.com/google/fonts
(ofl/notosanssc, ofl/notoserifsc). `test/font_coverage_test.dart` fails when
lib/ uses a character missing from assets/fonts/glyphs.txt.
"""

import argparse
import pathlib
import re

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "fonts"

# Weights actually used by the theme.
SANS_WEIGHTS = {"Regular": 400, "Medium": 500, "SemiBold": 600}
SERIF_WEIGHTS = {"SemiBold": 600}

EXTRA = (
    "，。、；：？！“”‘’（）《》【】「」…—–·～・"
    "→←↑↓↗×✓♯♭°％＋－"
    "0123456789"
)


def collect_characters() -> str:
    chars = set(chr(c) for c in range(0x20, 0x7F))
    chars.update(EXTRA)
    for path in (ROOT / "lib").rglob("*.dart"):
        for ch in path.read_text(encoding="utf-8"):
            if ord(ch) > 0x7F and not ch.isspace():
                chars.add(ch)
    # Drop characters the source fonts cannot render anyway (e.g. emoji).
    return "".join(sorted(chars))


def build(source: pathlib.Path, family: str, weights: dict, text: str) -> None:
    for style, weight in weights.items():
        font = TTFont(source)
        static = instancer.instantiateVariableFont(font, {"wght": weight})
        options = subset.Options()
        options.layout_features = ["*"]
        options.name_IDs = ["*"]
        options.notdef_outline = True
        options.drop_tables += ["BASE", "STAT"]
        subsetter = subset.Subsetter(options)
        subsetter.populate(text=text)
        subsetter.subset(static)
        target = OUT / f"{family}-{style}.ttf"
        static.save(target)
        print(f"{target.relative_to(ROOT)}: {target.stat().st_size // 1024} KB")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sans", required=True, type=pathlib.Path)
    parser.add_argument("--serif", required=True, type=pathlib.Path)
    args = parser.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)
    text = collect_characters()
    cmap = TTFont(args.sans).getBestCmap()
    covered = "".join(ch for ch in text if ord(ch) in cmap)
    missing = sorted(set(text) - set(covered))
    if missing:
        print("not in source font (ignored):", " ".join(missing))

    build(args.sans, "NotoSansSC", SANS_WEIGHTS, covered)
    build(args.serif, "NotoSerifSC", SERIF_WEIGHTS, covered)
    (OUT / "glyphs.txt").write_text(
        re.sub(r"\s", "", covered) + "\n", encoding="utf-8"
    )
    print(f"{len(covered)} characters")


if __name__ == "__main__":
    main()
