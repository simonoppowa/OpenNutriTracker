#!/usr/bin/env python3
"""Pad the logo PNGs into launcher-icon sources for iOS.

The two 1024px logo PNGs under assets/icon/ are a tight crop of the artwork
(~5% margin top and bottom, ~11% at the sides). That is right for the two
places the app shows them — the Settings > About dialog and the
`DynamicOntLogo` fallback — and wrong for a launcher icon, where the artwork
needs room inside the mask (#1151).

Android gets that room from `adaptive_icon_foreground_inset` in pubspec.yaml,
which flutter_launcher_icons applies as an <inset> around the foreground. iOS
has no such knob: the PNG named by `image_path_ios` goes into the asset
catalog as-is, so the padding has to be in the file. Re-padding the shared
logo PNGs would shrink the in-app logo, hence these separate copies.

Each output is the input's opaque bounding box scaled so the composition is
--fill percent of the 1024px canvas tall, centred on a transparent canvas of
the same size. Height is the constraint because the spoon makes the artwork
taller than it is wide, and both its extremes sit on the vertical centreline,
where every mask touches the edge. The light icon is later flattened onto
white by `remove_alpha_ios`; the dark and tinted ones keep their alpha, as
Apple requires, so the canvas here must stay transparent.

The colour *under* the transparency matters too. flutter_launcher_icons
downscales with a straight (non-premultiplied) box average, so whatever RGB
sits in fully transparent pixels bleeds into every anti-aliased edge of the
smaller dark and tinted icons. Pillow's resize leaves black there, which
turned the white spoon tip grey at 40px; the logo PNGs carry white, and so
does the output here.

Run it from the repo root after the logo PNGs change, then regenerate the
icon sets:

    python3 tools/icons/pad_ios_launcher_icon.py
    dart run flutter_launcher_icons
"""

import argparse
import sys
from pathlib import Path

from PIL import Image

CANVAS = 1024
SOURCES = {
    "assets/icon/ont_logo_square_color_back_1024x1024.png":
        "assets/icon/ont_launcher_ios_color_back_1024x1024.png",
    "assets/icon/ont_logo_square_color_white_1024x1024.png":
        "assets/icon/ont_launcher_ios_color_white_1024x1024.png",
}


def pad(src: Path, dst: Path, fill: float) -> tuple[int, int]:
    image = Image.open(src).convert("RGBA")
    if image.size != (CANVAS, CANVAS):
        sys.exit(f"{src}: expected {CANVAS}x{CANVAS}, got {image.size[0]}x{image.size[1]}")
    bbox = image.getbbox()
    if bbox is None:
        sys.exit(f"{src}: image is fully transparent")
    art = image.crop(bbox)
    target_h = round(CANVAS * fill / 100)
    target_w = round(art.width * target_h / art.height)
    art = art.resize((target_w, target_h), Image.LANCZOS)
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.alpha_composite(art, ((CANVAS - target_w) // 2, (CANVAS - target_h) // 2))
    # White under the transparency, not black (see the module docstring).
    alpha = canvas.getchannel("A")
    white = Image.new("RGB", (CANVAS, CANVAS), (255, 255, 255))
    rgb = Image.composite(canvas.convert("RGB"), white, alpha.point(lambda a: 255 if a else 0))
    canvas = Image.merge("RGBA", (*rgb.split(), alpha))
    canvas.save(dst, optimize=True)
    return target_w, target_h


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--fill",
        type=float,
        default=80.0,
        help="composition height as a percentage of the canvas (default: 80)",
    )
    args = parser.parse_args()
    if not 0 < args.fill <= 100:
        parser.error("--fill must be in (0, 100]")
    for src, dst in SOURCES.items():
        w, h = pad(Path(src), Path(dst), args.fill)
        print(f"{dst}: artwork {w}x{h} on {CANVAS}x{CANVAS}")


if __name__ == "__main__":
    main()
