#!/usr/bin/env python3
"""Filter a Git change list to files which belong in the main WMP release."""

import argparse
import json
from pathlib import Path, PurePosixPath


def load_allowed_roots(config_path):
    config = json.loads(config_path.read_text(encoding="utf-8"))
    return set(config["build"]["include"])


def releasable(path, allowed_roots):
    normalized = path.strip().replace("\\", "/")
    if not normalized:
        return False
    return PurePosixPath(normalized).parts[0] in allowed_roots


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--config", type=Path, required=True)
    args = parser.parse_args()
    allowed = load_allowed_roots(args.config)
    selected = [
        line.strip().replace("\\", "/")
        for line in args.input.read_text(encoding="utf-8").splitlines()
        if releasable(line, allowed) and Path(line.strip()).is_file()
    ]
    args.output.write_text("".join(f"{path}\n" for path in selected), encoding="utf-8")
    print(f"Selected {len(selected)} releasable changed files")


if __name__ == "__main__":
    main()
