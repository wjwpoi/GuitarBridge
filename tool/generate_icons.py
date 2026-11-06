#!/usr/bin/env python3
"""Regenerates every app icon from tool/icon_svg.py.

    pip install pillow            # plus Node with Playwright + Chromium
    python3 tool/generate_icons.py

Writes the web favicon (SVG + PNG), PWA icons (any + maskable), the Apple
touch icon, Android launcher mipmaps, the iOS and macOS icon sets and the
Windows .ico.
"""

import json
import pathlib
import subprocess
import tempfile

from PIL import Image

import icon_svg

ROOT = pathlib.Path(__file__).resolve().parent.parent


def main() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        svgs = {}
        for kind in ("rounded", "full", "small", "mac"):
            svgs[kind] = tmp / f"{kind}.svg"
            svgs[kind].write_text(icon_svg.svg(kind), encoding="utf-8")

        jobs = []

        def png(kind: str, size: int, out: pathlib.Path) -> None:
            out.parent.mkdir(parents=True, exist_ok=True)
            jobs.append({"svg": str(svgs[kind]), "size": size, "out": str(out)})

        web = ROOT / "web"
        (web / "favicon.svg").write_text(icon_svg.svg("small"), encoding="utf-8")
        png("small", 32, web / "favicon-32.png")
        png("small", 64, web / "guitarbridge-favicon.png")
        png("full", 180, web / "icons" / "apple-touch-icon.png")
        for size in (192, 512):
            png("rounded", size, web / "icons" / f"GuitarBridge-{size}.png")
            png("full", size, web / "icons" / f"GuitarBridge-maskable-{size}.png")

        res = ROOT / "android" / "app" / "src" / "main" / "res"
        for density, size in {
            "mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192,
        }.items():
            png("rounded", size, res / f"mipmap-{density}" / "ic_launcher.png")

        ios = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
        contents = json.loads((ios / "Contents.json").read_text())
        ios_files = set()
        for image in contents["images"]:
            points = float(image["size"].split("x")[0])
            scale = int(image["scale"].rstrip("x"))
            size = round(points * scale)
            ios_files.add(image["filename"])
            png("full", size, ios / image["filename"])

        mac = ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
        for size in (16, 32, 64, 128, 256, 512, 1024):
            png("small" if size <= 32 else "mac", size, mac / f"app_icon_{size}.png")

        ico_parts = {}
        for size in (16, 24, 32, 48, 64, 128, 256):
            ico_parts[size] = tmp / f"ico-{size}.png"
            png("small" if size <= 32 else "rounded", size, ico_parts[size])

        jobs_file = tmp / "jobs.json"
        jobs_file.write_text(json.dumps(jobs))
        subprocess.run(
            ["node", str(ROOT / "tool" / "render_svg.mjs"), str(jobs_file)],
            check=True,
        )

        # App Store icons must not have an alpha channel.
        for name in ios_files:
            path = ios / name
            Image.open(path).convert("RGB").save(path)

        frames = [Image.open(ico_parts[s]).convert("RGBA") for s in sorted(ico_parts)]
        frames[-1].save(
            ROOT / "windows" / "runner" / "resources" / "app_icon.ico",
            sizes=[(s, s) for s in sorted(ico_parts)],
            append_images=frames[:-1],
        )
    print(f"{len(jobs)} images written")


if __name__ == "__main__":
    main()
