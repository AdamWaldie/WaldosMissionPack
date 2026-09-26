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
    "Arguments:",
    "Return Value:",
    "Example:",
    "Result:",
)
SCRIPT_LOCALITY = re.compile(r"\bLocality\s*(?:and\s+authority|/\s*authority)(?:\s+and\s+repeat/JIP)?\s*:", re.I)
SCRIPT_CALLERS = re.compile(r"\b(?:Current\s+callers?|Called\s+by)\s*:", re.I)
CONFIG_REQUIRED = (
    "Author:",
    "Arguments:",
    "Return Value:",
    "Example:",
    "Result:",
    "Current caller",
    "HOW TO READ THE DATA BELOW:",
    "SETTING-BY-SETTING GUIDE",
)
SETTING_ROW = re.compile(r'^\s*\["((?:Waldo_|WALDO_|ACE_|ace_|Logi_)[^"]+)"\s*,', re.M)
ACRE_REQUIRED_KEYS = (
    "enabled",
    "strict",
    "prc343PresetPolicy",
    "namedDisplays",
    "notifyAssignmentProblems",
    "additionalRadioProfiles",
    "radioOverrides",
    "sides",
    "babel",
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
        result = subprocess.run(
            command, cwd=ROOT, text=True, encoding="utf-8", errors="replace",
            capture_output=True, check=False,
        )
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
    header = re.match(r"\s*/\*(.*?)\*/", text, re.S)
    if required is SCRIPT_REQUIRED and header is None:
        return ["missing opening documentation block"]
    scope = header.group(1) if required is SCRIPT_REQUIRED else text
    findings = [f"missing `{field}`" for field in required if field.lower() not in scope.lower()]
    if required is SCRIPT_REQUIRED:
        if not SCRIPT_LOCALITY.search(scope):
            findings.append("missing locality/authority")
        if not SCRIPT_CALLERS.search(scope):
            findings.append("missing current callers")
    author = re.search(r"^\s*\*\s*Author:\s*(.+?)\s*$", scope, re.I | re.M)
    if author is None or not author.group(1).strip():
        findings.append("missing a named human author")
    elif AI_AUTHOR.search(scope):
        findings.append("AI/tool names cannot be listed as authors")
    return findings


def audit(base: str | None, all_scripts: bool = False) -> tuple[int, list[str]]:
    findings: list[str] = []
    checked = 0

    config_reference = (ROOT / "wiki" / "Feature-Configuration-Files.md").read_text(
        encoding="utf-8", errors="replace"
    )
    for path in sorted((ROOT / "MissionConfig").glob("*.sqf")):
        checked += 1
        for finding in audit_file(path, CONFIG_REQUIRED):
            findings.append(f"{path.relative_to(ROOT)}: {finding}")
        text = path.read_text(encoding="utf-8", errors="replace")
        header = text.split("*/", 1)[0]
        for setting in SETTING_ROW.findall(text):
            if setting not in header:
                findings.append(
                    f"{path.relative_to(ROOT)}: setting `{setting}` is not named in its "
                    "SETTING-BY-SETTING GUIDE"
                )
            if f"`{setting}`" not in config_reference:
                findings.append(
                    f"{path.relative_to(ROOT)}: setting `{setting}` is missing from "
                    "wiki/Feature-Configuration-Files.md"
                )

    acre_config = (ROOT / "MissionConfig" / "acreConfig.sqf").read_text(
        encoding="utf-8", errors="replace"
    )
    for key in ACRE_REQUIRED_KEYS:
        if f'["{key}",' not in acre_config:
            findings.append(f"MissionConfig/acreConfig.sqf: missing top-level key `{key}`")
        if f"`{key}`" not in config_reference:
            findings.append(
                f"MissionConfig/acreConfig.sqf: key `{key}` is missing from "
                "wiki/Feature-Configuration-Files.md"
            )

    scripts = sorted((ROOT / "MissionScripts").rglob("*.sqf")) if all_scripts else (changed_sqf(base) if base else [])
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
    parser.add_argument(
        "--all-scripts",
        action="store_true",
        help="Audit every MissionScripts SQF header, including older files outside this branch.",
    )
    args = parser.parse_args()
    checked, findings = audit(args.changed_base, args.all_scripts)
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
