#!/usr/bin/env python3
"""
Author: Waldo
Generates the WaldosMissionPack cover/loading screen (Pictures/loading.jpg) by
rendering the "WALDO'S MISSION PACK" title and the current version number onto a
text-free base image with the bundled Stardos Stencil font.

The version is taken from the first positional argument (e.g. "4.8.0" or
"v4.8.0"); if omitted it is parsed from description.ext's onLoadName field. This
keeps the cover image in sync with the version automatically (see the
update-cover.yml workflow and deploy.sh).

Arguments:
  version   - str  - Version to render (optional; default: parsed from description.ext)
  --base    - path - Text-free background image (optional, default: loadingAssets/loading_base.jpg)
  --out     - path - Output image (optional, default: Pictures/loading.jpg)
  --desc    - path - description.ext to parse when no version arg is given (optional)
  --font    - path - Stencil font (optional, default: loadingAssets/StardosStencil-Bold.ttf)

Return Value:
  Writes the JPEG to --out. Exits non-zero on any unresolved input.

Example:
  python3 releaseVerificationAndDeployment/generateLoadingScreen.py
  python3 releaseVerificationAndDeployment/generateLoadingScreen.py 4.8.0
"""

import argparse
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

# --- Layout calibration (measured against the original 1920x1080 cover image) ---
TITLE_TEXT = "WALDO'S MISSION PACK"
TEXT_COLOR = (62, 118, 211)   # steel blue, sampled from the original text
TITLE_SIZE = 70               # px -> rendered title ~825x51 (original ~822x53)
TITLE_XY = (125, 375)         # top-left anchor of the visible glyphs
VERSION_SIZE = 190            # px -> rendered "4.7.2" ~428x137 (original ~424x141)
VERSION_XY = (292, 465)       # top-left anchor of the visible glyphs
JPEG_QUALITY = 92

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
ASSET_DIR = os.path.join(SCRIPT_DIR, "loadingAssets")

DEFAULT_BASE = os.path.join(ASSET_DIR, "loading_base.jpg")
DEFAULT_FONT = os.path.join(ASSET_DIR, "StardosStencil-Bold.ttf")
DEFAULT_OUT = os.path.join(PROJECT_ROOT, "Pictures", "loading.jpg")
DEFAULT_DESC = os.path.join(PROJECT_ROOT, "description.ext")


def parse_version_from_desc(desc_path):
    """Extract X.Y[.Z] from the onLoadName field of description.ext."""
    try:
        with open(desc_path, "r", encoding="utf-8", errors="replace") as fh:
            text = fh.read()
    except OSError as exc:
        sys.exit("ERROR: cannot read description.ext ({}): {}".format(desc_path, exc))
    match = re.search(r'onLoadName\s*=\s*"[^"]*v(\d+\.\d+(?:\.\d+)?)"', text)
    if not match:
        sys.exit("ERROR: could not parse a version from onLoadName in " + desc_path)
    return match.group(1)


def draw_line(draw, text, font, target_xy):
    """Draw text so the top-left of its visible glyphs sits at target_xy."""
    left, top, _, _ = draw.textbbox((0, 0), text, font=font)
    draw.text((target_xy[0] - left, target_xy[1] - top), text, font=font, fill=TEXT_COLOR)


def main():
    parser = argparse.ArgumentParser(description="Generate the WMP loading screen.")
    parser.add_argument("version", nargs="?", help="Version to render (default: from description.ext)")
    parser.add_argument("--base", default=DEFAULT_BASE)
    parser.add_argument("--out", default=DEFAULT_OUT)
    parser.add_argument("--desc", default=DEFAULT_DESC)
    parser.add_argument("--font", default=DEFAULT_FONT)
    args = parser.parse_args()

    version = args.version.lstrip("vV") if args.version else parse_version_from_desc(args.desc)

    for path, label in ((args.base, "base image"), (args.font, "font")):
        if not os.path.isfile(path):
            sys.exit("ERROR: {} not found: {}".format(label, path))

    image = Image.open(args.base).convert("RGB")
    draw = ImageDraw.Draw(image)
    draw_line(draw, TITLE_TEXT, ImageFont.truetype(args.font, TITLE_SIZE), TITLE_XY)
    draw_line(draw, version, ImageFont.truetype(args.font, VERSION_SIZE), VERSION_XY)

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    image.save(args.out, "JPEG", quality=JPEG_QUALITY)
    print("Wrote {} (version {})".format(args.out, version))


if __name__ == "__main__":
    main()
