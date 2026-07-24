#!/usr/bin/env python3
"""Build the disposable PR21-32 Arma audit mission from the current worktree."""

from __future__ import annotations

import argparse
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit"
TEMPLATE = AUDIT / "FullArmaAudit.VR"
FUNCTION = re.compile(
    r'class\s+([A-Za-z0-9_]+)\s*\{\s*file\s*=\s*"([^"]+\.sqf)"', re.IGNORECASE
)
VERSION = re.compile(r'onLoadName\s*=\s*"[^"]*?v([0-9]+\.[0-9]+\.[0-9]+)"')


def build(destination: Path, suite: str) -> Path:
    if destination.exists():
        shutil.rmtree(destination)
    shutil.copytree(TEMPLATE, destination)
    shutil.copytree(ROOT / "MissionScripts", destination / "MissionScripts")
    shutil.copytree(ROOT / "Pictures", destination / "Pictures")
    shutil.copy2(ROOT / "economyConfig.sqf", destination / "economyConfig.sqf")
    shutil.copy2(AUDIT / "audit_manifest.json", destination / "audit_manifest.json")
    with (AUDIT / "audit_manifest.json").open(encoding="utf-8") as handle:
        manifest = json.load(handle)
    valid = {"all", *(entry["id"] for entry in manifest["suites"])}
    if suite not in valid:
        raise ValueError(f"Unknown suite {suite!r}; expected one of {sorted(valid)}")
    functions_text = (ROOT / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
    functions = FUNCTION.findall(functions_text)
    missing = []
    for _, relative in functions:
        if not (ROOT / Path(relative.replace("\\", "/"))).is_file():
            missing.append(relative)
    if missing:
        raise FileNotFoundError(f"CfgFunctions references missing files: {missing}")
    sqf_entries = ",\n".join(
        f'    ["Waldo_fnc_{name}", "{relative}"]' for name, relative in functions
    )
    (destination / "generatedFunctions.sqf").write_text(
        "private _root = missionNamespace getVariable [\"Waldo_QA_Root\", \"\"];\n"
        "{\n"
        "    _x params [\"_name\", \"_relative\"];\n"
        "    missionNamespace setVariable [_name, compile preprocessFileLineNumbers (_root + _relative)];\n"
        "} forEach [\n"
        f"{sqf_entries}\n"
        "];\n",
        encoding="utf-8",
    )
    description = (ROOT / "description.ext").read_text(encoding="utf-8")
    version_match = VERSION.search(description)
    version = version_match.group(1) if version_match else "UNKNOWN"
    (destination / "auditBootstrap.sqf").write_text(
        f'Waldo_QA_BootSuite = "{suite}";\n'
        f'Waldo_QA_ExpectedVersion = "{version}";\n',
        encoding="utf-8",
    )
    bootstrap = destination / "scriptedBootstrap.sqf"
    bootstrap.write_text(
        f'Waldo_QA_BootSuite = "{suite}";\n'
        f'Waldo_QA_ExpectedVersion = "{version}";\n'
        + bootstrap.read_text(encoding="utf-8"),
        encoding="utf-8",
    )
    return destination


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--destination", required=True, type=Path)
    parser.add_argument(
        "--suite", choices=("all", "core", "economy", "ew", "party", "interactions"), default="all"
    )
    args = parser.parse_args()
    print(build(args.destination.resolve(), args.suite))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
