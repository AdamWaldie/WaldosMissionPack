#!/usr/bin/env python3
"""Build the ongoing full-pack PR audit mission from the current worktree."""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import re
import shutil
import stat
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit"
TEMPLATE = AUDIT / "WMP_FPA.VR"
FUNCTION = re.compile(
    r'class\s+([A-Za-z0-9_]+)\s*\{\s*file\s*=\s*"([^"]+\.sqf)"', re.IGNORECASE
)
VERSION = re.compile(r'onLoadName\s*=\s*"[^"]*?v([0-9]+\.[0-9]+\.[0-9]+)"')
INCLUDE = re.compile(r'^\s*#include\s+"([^"]+)"', re.MULTILINE)
GENERATOR_PATH = ROOT / "releaseVerificationAndDeployment" / "generate_full_arma_audit_mission.py"
GENERATOR_SPEC = importlib.util.spec_from_file_location("generate_full_arma_audit_mission", GENERATOR_PATH)
GENERATOR = importlib.util.module_from_spec(GENERATOR_SPEC)
assert GENERATOR_SPEC and GENERATOR_SPEC.loader
GENERATOR_SPEC.loader.exec_module(GENERATOR)


def remove_staged_mission(path: Path) -> None:
    """Remove a previous Windows stage even when copied folders are read-only."""
    if not path.exists():
        return

    def clear_read_only(function, target, _error):
        os.chmod(target, stat.S_IWRITE)
        function(target)

    shutil.rmtree(path, onexc=clear_read_only)


def audit_description(source: str) -> str:
    """Keep the release config intact while giving the staged mission an honest identity."""
    replacements = {
        r'onLoadName\s*=\s*"[^"]*"': 'onLoadName = "WMP FULL PACK AUDIT"',
        r'onLoadMission\s*=\s*"[^"]*"': 'onLoadMission = "Ongoing full-pack pull request audit"',
        r'onLoadIntro\s*=\s*"[^"]*"': 'onLoadIntro = "Ongoing full-pack pull request audit"',
    }
    result = source
    for pattern, replacement in replacements.items():
        result, count = re.subn(pattern, replacement, result, count=1)
        if count != 1:
            raise ValueError(f"Audit description identity field is missing: {pattern}")
    result, count = re.subn(r"maxPlayers\s*=\s*\d+", "maxPlayers = 5", result, count=1)
    if count != 1:
        raise ValueError("Audit description Header.maxPlayers is missing")
    return "\n".join(line.rstrip() for line in result.splitlines()) + "\n"


def build(destination: Path, suite: str, mod_profile: str = "core", mode: str = "manual") -> Path:
    if mode not in {"manual", "automated"}:
        raise ValueError("Audit mode must be 'manual' or 'automated'")
    # Refresh the checked-in mission from this worktree first. This makes one command
    # sufficient for a human or coding agent and prevents a stale template from staging.
    GENERATOR.main()
    if destination.exists():
        remove_staged_mission(destination)
    shutil.copytree(TEMPLATE, destination)
    shutil.copytree(ROOT / "MissionScripts", destination / "MissionScripts", dirs_exist_ok=True)
    shutil.copytree(ROOT / "Pictures", destination / "Pictures", dirs_exist_ok=True)
    shutil.copy2(ROOT / "economyConfig.sqf", destination / "economyConfig.sqf")
    shutil.copy2(ROOT / "acreConfig.sqf", destination / "acreConfig.sqf")
    shutil.copy2(ROOT / "acreConfig.sqf", destination / "releaseAcreConfig.sqf")
    pack_source = destination / "WMPPackSource"
    pack_source.mkdir(exist_ok=True)
    for name in ("description.ext", "init.sqf", "initPlayerLocal.sqf", "initServer.sqf", "economyConfig.sqf", "acreConfig.sqf", "LICENSE", "README.md"):
        source = ROOT / name
        if source.is_file():
            shutil.copy2(source, pack_source / name)
    shutil.copy2(TEMPLATE / "auditAcreConfig.sqf", destination / "acreConfig.sqf")

    # Use the real description.ext and actual mission.sqm. The generated playable-unit
    # inventories are intentionally consumed by MissionSQM instead of a synthetic include.
    GENERATOR.write_active_pack(destination)
    release_description = (ROOT / "description.ext").read_text(encoding="utf-8")
    (destination / "description.ext").write_text(
        audit_description(release_description), encoding="utf-8"
    )
    insignias = ROOT / "UnitInsignias"
    if insignias.is_dir():
        shutil.copytree(insignias, destination / "UnitInsignias", dirs_exist_ok=True)
    shutil.copy2(AUDIT / "audit_manifest.json", destination / "audit_manifest.json")
    shutil.copy2(AUDIT / "fixture_manifest.json", destination / "fixture_manifest.json")
    shutil.copy2(AUDIT / "function_station_manifest.json", destination / "function_station_manifest.json")
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
    station_manifest = json.loads((destination / "function_station_manifest.json").read_text(encoding="utf-8"))
    if station_manifest.get("registeredFunctionCount") != len(functions):
        raise ValueError("Function-station manifest is stale or incomplete")
    mapped_names = [entry.get("name") for entry in station_manifest.get("functions", [])]
    expected_names = [f"Waldo_fnc_{name}" for name, _relative in functions]
    if len(mapped_names) != len(set(mapped_names)) or set(mapped_names) != set(expected_names):
        raise ValueError("Every registered function must map to exactly one audit station")
    runtime_entries = station_manifest.get("runtimeFunctions", [])
    runtime_names = [entry.get("name") for entry in runtime_entries]
    if len(runtime_names) != len(set(runtime_names)):
        raise ValueError("Runtime function station mappings contain duplicates")
    for entry in runtime_entries:
        if not (ROOT / entry.get("file", "")).is_file():
            raise FileNotFoundError(f"Runtime function source is missing: {entry}")
    if station_manifest.get("functionCount") != len(functions) + len(runtime_entries):
        raise ValueError("Combined function coverage count is stale")
    sqm = destination / "mission.sqm"
    sqm_bytes = sqm.read_bytes()
    if not sqm_bytes.lstrip().startswith(b"version=") or b"class Mission" not in sqm_bytes:
        raise ValueError("Audit mission.sqm must remain plain-text, editable and unbinarized")
    sqm_text = sqm_bytes.decode("utf-8")
    required_sqm_tokens = {
        "Eden version": "version=54;",
        "unbinarized flag": "binarizationWanted=0;",
        "modern entity tree": "class Entities",
        "curator": 'type="ModuleCurator_F"',
    }
    for label, token in required_sqm_tokens.items():
        if token not in sqm_text:
            raise ValueError(f"Audit mission is missing {label}: {token}")
    if sqm_text.count("class Inventory") != 5 or sqm_text.count("isPlayable=1;") != 4 or sqm_text.count("isPlayer=1;") != 1:
        raise ValueError("Audit mission must contain one player and four playable custom Eden inventories")
    if (destination / "auditLoadoutSQM.hpp").exists():
        raise ValueError("Synthetic loadout include is forbidden; the audit must scrape its actual mission.sqm")
    active_description = (destination / "description.ext").read_text(encoding="utf-8")
    expected_description = audit_description(release_description)
    if active_description != expected_description or '#include "mission.sqm"' not in active_description:
        raise ValueError("Audit description.ext must be the current pack and include the actual mission.sqm")
    source_files = {
        path.relative_to(ROOT / "MissionScripts")
        for path in (ROOT / "MissionScripts").rglob("*") if path.is_file()
    }
    staged_files = {
        path.relative_to(destination / "MissionScripts")
        for path in (destination / "MissionScripts").rglob("*") if path.is_file()
    }
    if source_files != staged_files:
        raise ValueError("Staged MissionScripts file set does not exactly match the worktree")
    changed_sources = [
        relative for relative in source_files
        if (ROOT / "MissionScripts" / relative).read_bytes()
        != (destination / "MissionScripts" / relative).read_bytes()
    ]
    if changed_sources:
        raise ValueError(f"Staged MissionScripts contain stale files: {changed_sources[:10]}")
    for include in INCLUDE.findall(active_description):
        include_path = destination / Path(include.replace("\\", "/"))
        if not include_path.is_file():
            raise FileNotFoundError(f"description.ext include is absent from staged mission: {include}")
    if any(destination.glob("*.pbo")):
        raise ValueError("Audit mission must be staged as an unpacked mission folder, not a PBO")
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
    required_patches = '["cba_main", "ace_main", "zen_main"'
    if mod_profile == "acre":
        required_patches += ', "acre_main"'
    elif mod_profile == "tfar":
        required_patches += ', "task_force_radio"'
    required_patches += "]"
    (destination / "auditBootstrap.sqf").write_text(
        f'Waldo_QA_BootSuite = "{suite}";\n'
        f'Waldo_QA_ExpectedVersion = "{version}";\n'
        f"Waldo_QA_RequiredPatches = {required_patches};\n"
        f"Waldo_QA_RunAutomation = {str(mode == 'automated').lower()};\n"
        f'Waldo_QA_Mode = "{mode.upper()}";\n',
        encoding="utf-8",
    )
    build_manifest = {
        "schema": 1,
        "mode": mode,
        "suite": suite,
        "modProfile": mod_profile,
        "packVersion": version,
        "registeredFunctions": len(functions),
        "runtimeFunctions": len(runtime_entries),
        "mappedFunctions": len(functions) + len(runtime_entries),
        "physicalFixtures": sqm_text.count('side="Empty"'),
        "playableLoadouts": sqm_text.count("class Inventory"),
        "unbinarized": True,
        "usesActualMissionSqm": True,
        "automationEnabled": mode == "automated",
    }
    (destination / "audit_build_manifest.json").write_text(
        json.dumps(build_manifest, indent=2) + "\n", encoding="utf-8"
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
    parser.add_argument("--mod-profile", choices=("core", "acre", "tfar"), default="core")
    parser.add_argument("--mode", choices=("manual", "automated"), default="manual")
    args = parser.parse_args()
    print(build(args.destination.resolve(), args.suite, args.mod_profile, args.mode))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
