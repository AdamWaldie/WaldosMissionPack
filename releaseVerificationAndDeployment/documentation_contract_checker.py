#!/usr/bin/env python3
"""Enforce WMP's beginner-first, detail-preserving documentation contract."""

from __future__ import annotations

import argparse
import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT_REQUIRED = (
    "Author:",
    "Locality and authority:",
    "Arguments:",
    "Return Value:",
    "Example:",
    "Result:",
    "Current caller",
)
CONFIG_REQUIRED = (
    "Author:",
    "Arguments:",
    "Return Value:",
    "Example:",
    "Result:",
    "Current caller",
    "HOW TO READ THE DATA BELOW:",
)
AI_AUTHOR = re.compile(r"^\s*\*\s*Author:\s*(?:Claude|ChatGPT|Codex|OpenAI)\b", re.I | re.M)
ATTRIBUTION_HEADING = re.compile(r"^#{1,6}\s+Attributions?\s*$", re.I | re.M)


def changed_sqf(base: str) -> list[Path]:
    commands = (
        ["git", "-c", f"safe.directory={ROOT.as_posix()}", "diff", "--name-only", "--diff-filter=ACMR", f"{base}...HEAD"],
        ["git", "-c", f"safe.directory={ROOT.as_posix()}", "diff", "--name-only", "--diff-filter=ACMR"],
    )
    names: set[str] = set()
    for command in commands:
        result = subprocess.run(command, cwd=ROOT, text=True, capture_output=True, check=False)
        if result.returncode == 0:
            names.update(result.stdout.splitlines())
    paths: list[Path] = []
    for raw in sorted(names):
        path = ROOT / raw
        if raw.startswith("MissionScripts/") and path.suffix.lower() == ".sqf" and path.is_file():
            paths.append(path)
    return paths


def audit_file(path: Path, required: tuple[str, ...]) -> list[str]:
    text = path.read_text(encoding="utf-8", errors="replace")
    findings = [f"missing `{field}`" for field in required if field.lower() not in text.lower()]
    author = re.search(r"^\s*\*\s*Author:\s*(.+?)\s*$", text, re.I | re.M)
    if author is None or not author.group(1).strip():
        findings.append("missing a named human author")
    elif AI_AUTHOR.search(text):
        findings.append("AI/tool names cannot be listed as authors")
    return findings


def audit(base: str | None) -> tuple[int, list[str]]:
    findings: list[str] = []
    checked = 0

    for path in sorted((ROOT / "MissionConfig").glob("*.sqf")):
        checked += 1
        for finding in audit_file(path, CONFIG_REQUIRED):
            findings.append(f"{path.relative_to(ROOT)}: {finding}")

    scripts = changed_sqf(base) if base else []
    for path in scripts:
        checked += 1
        for finding in audit_file(path, SCRIPT_REQUIRED):
            findings.append(f"{path.relative_to(ROOT)}: {finding}")

    for path in sorted((ROOT / "wiki").glob("*.md")):
        text = path.read_text(encoding="utf-8", errors="replace")
        if ATTRIBUTION_HEADING.search(text):
            findings.append(f"{path.relative_to(ROOT)}: remove the Attribution section")

    return checked, findings


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--changed-base",
        default=None,
        help=(
            "Optional Git base revision. Produces the strict script-header remediation audit in "
            "addition to the blocking MissionConfig/wiki contract."
        ),
    )
    args = parser.parse_args()
    checked, findings = audit(args.changed_base)
    print(f"Checked documentation contracts for {checked} file(s)")
    for finding in findings:
        print(f"ERROR: {finding}")
    if findings:
        print(f"Documentation contract validation FAILED: {len(findings)} error(s)")
        return 1
    print("Documentation contract validation PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
