"""SVG sources for the GuitarBridge app icon (see tool/generate_icons.mjs).

The mark: a filled root note, an open target ring and the arc that bridges
them, on clay. Large sizes add three faint strings; small sizes drop them
and thicken the strokes so the mark survives at 16 px.
"""

CLAY = "#B5552F"
IVORY = "#FAF9F5"


def glyph(detail: bool) -> str:
    """The mark on a 512 x 512 canvas, centred on (256, 256).

    Two notes a step apart (root filled, target open) joined by a slur, the
    sheet-music sign for "play these two together"."""
    parts = []
    if detail:
        for y in (190, 270, 350):
            parts.append(
                f'<line x1="64" y1="{y}" x2="448" y2="{y}" stroke="{IVORY}" '
                f'stroke-opacity="0.28" stroke-width="7" stroke-linecap="round"/>'
            )
    r = 54 if detail else 66
    ring = 19 if detail else 27
    root = (152, 344) if detail else (150, 350)
    target = (360, 262) if detail else (362, 250)
    # Slur: a crescent from above the root to above the target, thickest in
    # the middle and tapering to points, like an engraved tie.
    gap = 20 if detail else 18
    sx, sy = root[0] - 6, root[1] - r - gap
    ex, ey = target[0] + 6, target[1] - r - gap
    lift = 96 if detail else 100
    thick = 30 if detail else 40
    c1 = (sx + 46, sy - lift)
    c2 = (ex - 46, ey - lift)
    i1 = (sx + 46, sy - lift + thick)
    i2 = (ex - 46, ey - lift + thick)
    parts.append(
        f'<path d="M{sx} {sy} C {c1[0]} {c1[1]}, {c2[0]} {c2[1]}, {ex} {ey} '
        f'C {i2[0]} {i2[1]}, {i1[0]} {i1[1]}, {sx} {sy} Z" fill="{IVORY}" '
        f'stroke="{IVORY}" stroke-width="4" stroke-linejoin="round"/>'
    )
    parts.append(f'<circle cx="{root[0]}" cy="{root[1]}" r="{r}" fill="{IVORY}"/>')
    parts.append(
        f'<circle cx="{target[0]}" cy="{target[1]}" r="{r - ring / 2}" '
        f'fill="none" stroke="{IVORY}" stroke-width="{ring}"/>'
    )
    return "\n  ".join(parts)


def svg(kind: str) -> str:
    """kind: 'rounded' (transparent corners), 'full' (full-bleed square,
    glyph inside the 80% maskable safe zone), 'small' (favicon, rounded),
    'mac' (rounded with the macOS icon-grid margin)."""
    detail = kind != "small"
    if kind == "full":
        bg = f'<rect width="512" height="512" fill="{CLAY}"/>'
        g = f'<g transform="translate(256 256) scale(0.86) translate(-256 -236)">{glyph(detail)}</g>'
    else:
        radius = {"small": 96, "mac": 92}.get(kind, 112)
        inset = {"small": 0, "mac": 50}.get(kind, 24)
        size = 512 - inset * 2
        bg = f'<rect x="{inset}" y="{inset}" width="{size}" height="{size}" rx="{radius}" fill="{CLAY}"/>'
        scale = {"small": 1.0, "mac": 0.76}.get(kind, 0.84)
        g = f'<g transform="translate(256 256) scale({scale}) translate(-256 -236)">{glyph(detail)}</g>'
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" '
        'width="512" height="512">\n  ' + bg + "\n  " + g + "\n</svg>\n"
    )


if __name__ == "__main__":
    import pathlib
    import sys

    out = pathlib.Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    for kind in ("rounded", "full", "small", "mac"):
        (out / f"icon-{kind}.svg").write_text(svg(kind), encoding="utf-8")
