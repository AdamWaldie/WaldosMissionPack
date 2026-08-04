#!/usr/bin/env python3
"""
Author: WaldoTheWarfighter
Rewrites the version number inside description.ext's onLoadName field in place,
preserving everything else in the field (the "Mission Pack v" prefix and any
trailing text) and the rest of the file untouched. Used by deploy.yml/deploy.sh
so a release's tag is the single source of truth for the shipped version - no
manual description.ext edit is required before tagging.

Arguments:
  version - str  - Version to write (e.g. "4.8.1" or "v4.8.1"; a leading "v" is
                    stripped, matching generateLoadingScreen.py's own parsing)
  --desc  - path - description.ext to edit (optional, default: ../description.ext)

Return Value:
  Exits non-zero if onLoadName's version substring cannot be found, or writes
  the updated file otherwise. Prints nothing on success (silent, script-friendly).

Example:
  python3 releaseVerificationAndDeployment/set_description_version.py 4.8.1
  python3 releaseVerificationAndDeployment/set_description_version.py v4.8.1-rc1
"""

import argparse
import os
import re
import sys

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
DEFAULT_DESC = os.path.join(PROJECT_ROOT, "description.ext")

VERSION_PATTERN = re.compile(r'(onLoadName\s*=\s*"[^"]*v)(\d+\.\d+(?:\.\d+)?)("[^;]*;)')


def main():
    parser = argparse.ArgumentParser(description="Set the version rendered in description.ext's onLoadName.")
    parser.add_argument("version", help='Version to write, e.g. "4.8.1" or "v4.8.1"')
    parser.add_argument("--desc", default=DEFAULT_DESC)
    args = parser.parse_args()

    version = args.version.lstrip("vV").split("-", 1)[0]  # strip leading "v" and any prerelease suffix

    try:
        with open(args.desc, "r", encoding="utf-8", errors="replace") as fh:
            text = fh.read()
    except OSError as exc:
        sys.exit("ERROR: cannot read description.ext ({}): {}".format(args.desc, exc))

    new_text, count = VERSION_PATTERN.subn(r"\g<1>" + version + r"\g<3>", text, count=1)
    if count == 0:
        sys.exit("ERROR: could not find a version to replace in onLoadName in " + args.desc)

    if new_text != text:
        with open(args.desc, "w", encoding="utf-8") as fh:
            fh.write(new_text)


if __name__ == "__main__":
    main()
