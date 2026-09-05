#!/usr/bin/env python3
"""Composite store screenshots: raw device captures in, captioned assets out.

Both stores' sets are captioned (#1072), so this step is shared rather than
owned by either platform's lane:

  * the iOS lane feeds it fresh simulator captures at 1290x2796 (6.9" iPhone)
    and 2064x2752 (13" iPad);
  * the Play set is already captured and committed at 1432x2856, so its
    second pass is this script run over the existing PNGs — no re-shoot;
  * Play's *tablet* slots stay empty by decision, and if that is ever
    revisited Play excludes non-core text there, which is what --no-captions
    is for.

Nothing here is iOS-specific and nothing imports from the app, deliberately.

Layout: an opaque canvas at the exact target size, a caption band across the
top, and the capture scaled to fit the remaining area, centred horizontally
and anchored to the bottom edge. Anchoring to the bottom keeps the app's
bottom navigation flush with the frame rather than floating in a margin.

The output is flattened to RGB with no alpha channel, which is what both
stores require: Apple wants "flattened, no transparency", Play wants 24-bit
PNG with no alpha. The raw captures arrive as RGBA from
`UIGraphicsImageRenderer`, so this conversion is load-bearing, not cosmetic.

Usage:

    python3 tools/screenshots/compose.py \\
        --raw   build/screenshots/raw/iphone \\
        --out   fastlane/metadata/ios/en-US/screenshots/iphone-6.9 \\
        --size  1290x2796 \\
        --captions tools/screenshots/captions.en-US.json

    # Play's second pass, over the set already in the repo:
    python3 tools/screenshots/compose.py \\
        --raw fastlane/metadata/android/en-US/images/phoneScreenshots \\
        --out build/screenshots/play-captioned \\
        --size 1432x2856 \\
        --captions tools/screenshots/captions.en-US.json

Requires Pillow.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:  # pragma: no cover - the message is the whole point
    sys.exit(
        "Pillow is not installed. `python3 -m pip install --upgrade pillow`, "
        "or in CI add a `pip install pillow` step before this one."
    )

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]


def parse_size(text: str) -> tuple[int, int]:
    try:
        width, height = (int(part) for part in text.lower().split("x", 1))
    except ValueError:
        raise argparse.ArgumentTypeError(
            f"--size wants WIDTHxHEIGHT, e.g. 1290x2796; got {text!r}"
        ) from None
    if width <= 0 or height <= 0:
        raise argparse.ArgumentTypeError(f"--size must be positive; got {text!r}")
    return width, height


def load_font(path: pathlib.Path, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size)


def wrap_to_lines(
    text: str,
    font: ImageFont.FreeTypeFont,
    draw: ImageDraw.ImageDraw,
    max_width: int,
    max_lines: int,
) -> list[str] | None:
    """Greedy word wrap. Returns None when the text will not fit."""
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = f"{current} {word}".strip()
        if draw.textlength(candidate, font=font) <= max_width:
            current = candidate
            continue
        if not current:
            # A single word wider than the band: no wrapping can save it.
            return None
        lines.append(current)
        current = word
        if len(lines) == max_lines:
            return None
    if current:
        lines.append(current)
    if len(lines) > max_lines:
        return None
    return lines


def fit_caption(
    text: str,
    font_path: pathlib.Path,
    draw: ImageDraw.ImageDraw,
    max_width: int,
    max_height: int,
    max_lines: int,
) -> tuple[ImageFont.FreeTypeFont, list[str]]:
    """Largest point size at which the caption fits the band.

    Binary search rather than a fixed size: the same style block has to serve
    a 1290px-wide iPhone and a 2064px-wide iPad, and captions from a
    three-word claim to a six-word one.
    """
    low, high = 8, max(9, max_height)
    best: tuple[ImageFont.FreeTypeFont, list[str]] | None = None
    while low <= high:
        mid = (low + high) // 2
        font = load_font(font_path, mid)
        lines = wrap_to_lines(text, font, draw, max_width, max_lines)
        if lines is None:
            high = mid - 1
            continue
        ascent, descent = font.getmetrics()
        line_height = int((ascent + descent) * 1.18)
        if line_height * len(lines) > max_height:
            high = mid - 1
            continue
        best = (font, lines)
        low = mid + 1
    if best is None:
        sys.exit(f"Caption does not fit at any size: {text!r}")
    return best


def compose_one(
    capture_path: pathlib.Path,
    out_path: pathlib.Path,
    size: tuple[int, int],
    caption: str | None,
    style: dict,
) -> None:
    width, height = size
    canvas = Image.new("RGB", (width, height), style["background"])
    draw = ImageDraw.Draw(canvas)

    band_height = int(height * style["band_fraction"]) if caption else 0
    gap = int(height * style.get("capture_gap_fraction", 0.0)) if caption else 0

    if caption:
        side_padding = int(width * style.get("side_padding_fraction", 0.08))
        font_path = REPO_ROOT / style["font"]
        if not font_path.is_file():
            sys.exit(f"Caption font not found: {font_path}")
        font, lines = fit_caption(
            caption,
            font_path,
            draw,
            max_width=width - 2 * side_padding,
            # Leave a little air top and bottom inside the band.
            max_height=int(band_height * 0.62),
            max_lines=int(style.get("max_lines", 2)),
        )
        ascent, descent = font.getmetrics()
        line_height = int((ascent + descent) * 1.18)
        block_height = line_height * len(lines)
        y = (band_height - block_height) // 2
        for line in lines:
            line_width = draw.textlength(line, font=font)
            draw.text(
                ((width - line_width) / 2, y),
                line,
                font=font,
                fill=style["text"],
            )
            y += line_height

    with Image.open(capture_path) as raw:
        capture = raw.convert("RGB")
        available_height = height - band_height - gap
        scale = min(width / capture.width, available_height / capture.height)
        target = (
            max(1, int(capture.width * scale)),
            max(1, int(capture.height * scale)),
        )
        resized = capture.resize(target, Image.LANCZOS)

    canvas.paste(
        resized,
        ((width - resized.width) // 2, height - resized.height),
    )

    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out_path, format="PNG")
    print(f"  {out_path.name:24s} {width}x{height}  caption={caption!r}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--raw", required=True, type=pathlib.Path)
    parser.add_argument("--out", required=True, type=pathlib.Path)
    parser.add_argument("--size", required=True, type=parse_size)
    parser.add_argument(
        "--captions",
        type=pathlib.Path,
        default=REPO_ROOT / "tools" / "screenshots" / "captions.en-US.json",
    )
    parser.add_argument(
        "--no-captions",
        action="store_true",
        help="Emit uncaptioned assets — Play's tablet slots exclude non-core "
        "text, so a tablet set would need this.",
    )
    args = parser.parse_args()

    captures = sorted(args.raw.glob("*.png"))
    if not captures:
        sys.exit(f"No captures found in {args.raw}")

    config = json.loads(args.captions.read_text(encoding="utf-8"))
    captions = config["captions"]
    style = config["style"]

    if not args.no_captions:
        missing = [c.stem for c in captures if c.stem not in captions]
        if missing:
            sys.exit(
                "No caption for: "
                + ", ".join(missing)
                + f"\nAdd it to {args.captions}, or pass --no-captions."
            )
        band = style["band_fraction"]
        if band > 0.20:
            sys.exit(
                f"band_fraction is {band:.2f}; Play allows a tagline on at "
                "most 20% of the image."
            )

    print(f"Composing {len(captures)} screenshot(s) -> {args.out}")
    for capture in captures:
        compose_one(
            capture,
            args.out / capture.name,
            args.size,
            None if args.no_captions else captions[capture.stem],
            style,
        )


if __name__ == "__main__":
    main()
