#!/usr/bin/env python3
"""
Author: WaldoTheWarfighter
Rewrites the version number inside description.ext's onLoadName field in place while preserving
the rest of the mission title and file. The release workflow uses this helper so the release tag
is the single source of truth for the packaged version and generated loading screen.

Arguments:
  version - version to write, such as 4.8.1, v4.8.1 or v4.8.1RC.
  --desc  - optional description.ext path (default: repository description.ext).

Return Value:
  Exits zero after updating the file, or non-zero when the file/version field cannot be read.

Example:
  python3 releaseVerificationAndDeployment/set_description_version.py v4.8.1RC

Current callers:
  .github/workflows/deploy.yml and releaseVerificationAndDeployment/deploy.sh.
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
    parser = argparse.ArgumentParser(
        description="Set the version rendered in description.ext's onLoadName."
    )
    parser.add_argument("version", help='Version to write, e.g. "4.8.1" or "v4.8.1RC"')
    parser.add_argument("--desc", default=DEFAULT_DESC)
    args = parser.parse_args()

    # description.ext uses the numeric mission-pack version. The full tag, including RC/prerelease
    # text, remains available to package names and the cover generator invoked by deploy.sh.
    match = re.match(r"^[vV]?(\d+\.\d+(?:\.\d+)?)", args.version)
    if not match:
        sys.exit("ERROR: release version must start with X.Y or X.Y.Z: " + args.version)
    version = match.group(1)

    try:
        with open(args.desc, "r", encoding="utf-8", errors="replace") as handle:
            text = handle.read()
    except OSError as exc:
        sys.exit("ERROR: cannot read description.ext ({}): {}".format(args.desc, exc))

    new_text, count = VERSION_PATTERN.subn(r"\g<1>" + version + r"\g<3>", text, count=1)
    if count == 0:
        sys.exit("ERROR: could not find a version to replace in onLoadName in " + args.desc)
    if new_text != text:
        with open(args.desc, "w", encoding="utf-8") as handle:
            handle.write(new_text)


if __name__ == "__main__":
    main()
