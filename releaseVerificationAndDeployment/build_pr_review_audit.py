#!/usr/bin/env python3
"""Stage the canonical PR review mission from the actual WMP release file set."""

from __future__ import annotations

import argparse
import json
import re
import runpy
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIT_ROOT = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit"
TEMPLATE = AUDIT_ROOT / "FullArmaAudit.VR"
RANGE_TEMPLATE = AUDIT_ROOT / "WMP_FPA.VR"
CONFIG = ROOT / "releaseVerificationAndDeployment" / "config.json"
VERSION = re.compile(r'onLoadName\s*=\s*"[^"]*?v([0-9]+\.[0-9]+\.[0-9]+)"')
IDENTITY = {
    "onLoadName": "WMP PR REVIEW AUDIT",
    "onLoadMission": "Current development build feature testbed",
    "onLoadIntro": "Current development build feature testbed",
}
AUDIT_FILES = (
    "auditCommon.sqf",
    "runClientAudit.sqf",
    "runServerAudit.sqf",
    "scriptedBootstrap.sqf",
)
RANGE_FILES = (
    "auditPreInit.sqf",
    "auditPreInitServer.sqf",
    "auditPreInitPlayerLocal.sqf",
    "auditInit.sqf",
    "auditInitServer.sqf",
    "auditInitPlayerLocal.sqf",
    "featureRangeServer.sqf",
    "featureRangeClient.sqf",
    "functionStations.sqf",
    "partyFixtureServer.sqf",
)


def audit_fixtures() -> list[dict]:
    """Load the canonical fixture catalogue without generating the Eden mission."""
    namespace = runpy.run_path(
        str(ROOT / "releaseVerificationAndDeployment" / "generate_full_arma_audit_mission.py")
    )
    return list(namespace["FIXTURES"])


def legacy_mission_with_fixtures(source: bytes, fixtures: list[dict]) -> bytes:
    """Add static feature objects to the known-good version-12 mission.

    The runtime range still configures these objects through public WMP APIs,
    but players now see the complete physical range as soon as the mission
    world loads instead of watching it appear a few seconds later.
    """
    text = source.decode("utf-8")
    if 'text="qa_' in text:
        raise ValueError("Legacy mission already contains audit fixtures; refusing to append duplicates")
    names = [fixture["name"] for fixture in fixtures]
    if len(names) != len(set(names)):
        raise ValueError("Audit fixture catalogue contains duplicate variable names")
    rows: list[str] = []
    for index, fixture in enumerate(fixtures):
        x, y, z = fixture["pos"]
        classname = fixture["class"]
        # Keep the legacy mission independent of optional mod object classes;
        # the real medical setup function will configure this base crate.
        if classname.startswith("ACE_"):
            classname = "B_supplyCrate_F"
        rows.append(
            "        class Item{index}\n"
            "        {{\n"
            "            position[]={{{x},{y},{z}}};\n"
            "            azimut={direction};\n"
            "            id={object_id};\n"
            '            side="EMPTY";\n'
            '            vehicle="{classname}";\n'
            '            text="{name}";\n'
            '            init="this allowDamage false; this enableSimulation false;";\n'
            "            skill=0.6;\n"
            "        }};".format(
                index=index,
                x=x,
                y=y,
                z=z,
                direction=fixture["dir"],
                object_id=100 + index,
                classname=classname,
                name=fixture["name"],
            )
        )
    block = (
        "\n    class Vehicles\n"
        "    {\n"
        f"        items={len(rows)};\n"
        + "\n".join(rows)
        + "\n    };\n"
    )
    closing = text.rfind("\n};")
    if closing < 0:
        raise ValueError("Legacy mission is missing its Mission closing brace")
    return (text[:closing] + block + text[closing:]).encode("utf-8")


def release_entries() -> tuple[str, ...]:
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    return tuple(config["build"]["include"])


def copy_release(destination: Path) -> None:
    for relative in release_entries():
        source = ROOT / relative
        target = destination / relative
        if not source.exists():
            raise FileNotFoundError(f"Configured release input is missing: {relative}")
        if source.is_dir():
            shutil.copytree(source, target)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)


def audit_description(source: str) -> str:
    result = source
    for field, value in IDENTITY.items():
        result, count = re.subn(
            rf'{field}\s*=\s*"[^"]*"', f'{field} = "{value}"', result, count=1
        )
        if count != 1:
            raise ValueError(f"Release description is missing {field}")
    result, count = re.subn(r"maxPlayers\s*=\s*\d+", "maxPlayers = 5", result, count=1)
    if count != 1:
        raise ValueError("Release description is missing Header.maxPlayers")
    return result


def wrap_entry_point(path: Path, pre_hook: str, post_hook: str) -> None:
    source = path.read_text(encoding="utf-8")
    path.write_text(
        f'// PR review audit pre-configuration.\ncall compile preprocessFileLineNumbers "{pre_hook}";\n\n'
        + source.rstrip()
        + f'\n\n// PR review audit continuation.\n[] execVM "{post_hook}";\n',
        encoding="utf-8",
    )


def build(destination: Path, suite: str, mode: str = "manual") -> Path:
    if mode not in {"manual", "automated"}:
        raise ValueError("Mode must be manual or automated")
    template_content = {
        name: (TEMPLATE / name).read_text(encoding="utf-8") for name in AUDIT_FILES
    }
    range_content = {
        name: (RANGE_TEMPLATE / name).read_text(encoding="utf-8") for name in RANGE_FILES
    }
    fixtures = audit_fixtures()
    mission_sqm = legacy_mission_with_fixtures((TEMPLATE / "mission.sqm").read_bytes(), fixtures)
    if not mission_sqm.lstrip().startswith(b"version=12;"):
        raise ValueError("PR review mission must retain its known-good legacy mission.sqm")

    if destination.exists():
        shutil.rmtree(destination)
    destination.mkdir(parents=True)
    copy_release(destination)

    (destination / "mission.sqm").write_bytes(mission_sqm)
    description_path = destination / "description.ext"
    description_path.write_text(
        audit_description(description_path.read_text(encoding="utf-8")), encoding="utf-8"
    )
    for name, content in template_content.items():
        (destination / name).write_text(content, encoding="utf-8")
    for name, content in range_content.items():
        (destination / name).write_text(content, encoding="utf-8")

    description = (ROOT / "description.ext").read_text(encoding="utf-8")
    version_match = VERSION.search(description)
    version = version_match.group(1) if version_match else "UNKNOWN"
    (destination / "auditBootstrap.sqf").write_text(
        f'Waldo_QA_BootSuite = "{suite}";\n'
        f'Waldo_QA_ExpectedVersion = "{version}";\n'
        f'Waldo_QA_RunAutomation = {str(mode == "automated").lower()};\n'
        f'Waldo_QA_Mode = "{mode.upper()}";\n'
        'Waldo_QA_RequiredPatches = ["cba_main", "ace_main", "zen_main", "acre_main"];\n',
        encoding="utf-8",
    )
    wrap_entry_point(destination / "init.sqf", "auditPreInit.sqf", "auditInit.sqf")
    wrap_entry_point(destination / "initServer.sqf", "auditPreInitServer.sqf", "auditInitServer.sqf")
    wrap_entry_point(destination / "initPlayerLocal.sqf", "auditPreInitPlayerLocal.sqf", "auditInitPlayerLocal.sqf")

    manifest = {
        "schema": 1,
        "suite": suite,
        "mode": mode,
        "packVersion": version,
        "releaseEntries": list(release_entries()),
        "missionFormat": 12,
        "fullPackStartup": True,
        "physicalRange": True,
        "physicalRangePreStaged": True,
        "staticFixtureCount": len(fixtures),
        "rangeScripts": list(RANGE_FILES),
    }
    (destination / "audit_build_manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    return destination


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--destination", required=True, type=Path)
    parser.add_argument(
        "--suite", choices=("all", "core", "economy", "ew", "party", "interactions"), default="all"
    )
    parser.add_argument("--mode", choices=("manual", "automated"), default="manual")
    args = parser.parse_args()
    print(build(args.destination.resolve(), args.suite, args.mode))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
