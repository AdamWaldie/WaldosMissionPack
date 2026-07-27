#!/usr/bin/env python3
"""Reject missing or case-mismatched local assets referenced by wiki Markdown."""

from __future__ import annotations

import re
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
WIKI = ROOT / "wiki"
IMAGE = re.compile(r"!\[[^\]]*\]\(([^)]+)\)")
REMOTE_PREFIXES = ("http://", "https://", "data:", "#", "../raw/", "/raw/")


def has_exact_case(root: Path, relative: Path) -> bool:
    current = root
    for part in relative.parts:
        if not current.is_dir() or part not in {entry.name for entry in current.iterdir()}:
            return False
        current /= part
    return current.is_file()


def local_asset(target: str) -> str | None:
    value = target.strip().strip("<>")
    if value.lower().startswith(REMOTE_PREFIXES):
        return None
    # Markdown may append a quoted title after the URL.
    return unquote(value.split(maxsplit=1)[0])


def audit() -> tuple[int, list[str]]:
    checked = 0
    findings: list[str] = []
    for page in sorted(WIKI.glob("*.md")):
        for match in IMAGE.finditer(page.read_text(encoding="utf-8")):
            target = local_asset(match.group(1))
            if target is None:
                continue
            checked += 1
            relative = Path(*target.replace("\\", "/").split("/"))
            resolved = (page.parent / relative).resolve()
            try:
                wiki_relative = resolved.relative_to(WIKI.resolve())
            except ValueError:
                findings.append(f"{page.name}: asset escapes wiki tree: {target}")
                continue
            if not has_exact_case(WIKI, wiki_relative):
                findings.append(f"{page.name}: missing or case-mismatched asset: {target}")
    return checked, findings


def main() -> int:
    checked, findings = audit()
    print(f"Checked {checked} local wiki image reference(s)")
    for finding in findings:
        print(f"ERROR: {finding}")
    if findings:
        print(f"Wiki asset validation FAILED: {len(findings)} error(s)")
        return 1
    print("Wiki asset validation PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
