#!/usr/bin/env python3
"""Stage the canonical ongoing full-pack PR audit from the WMP release file set."""

from __future__ import annotations

import argparse
import json
import os
import re
import runpy
import shutil
import stat
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIT_ROOT = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit"
TEMPLATE = AUDIT_ROOT / "FullArmaAudit.VR"
RANGE_TEMPLATE = AUDIT_ROOT / "WMP_FPA.VR"
CONFIG = ROOT / "releaseVerificationAndDeployment" / "config.json"
VERSION = re.compile(r'onLoadName\s*=\s*"[^"]*?v([0-9]+\.[0-9]+\.[0-9]+)"')
IDENTITY = {
    "onLoadName": "WMP FULL PACK PR AUDIT",
    "onLoadMission": "Ongoing full-pack pull request audit",
    "onLoadIntro": "Ongoing full-pack pull request audit",
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
    "auditAcreConfig.sqf",
    "extendedFeatureStationsServer.sqf",
    "extendedFeatureStationsClient.sqf",
    "functionStations.sqf",
    "partyFixtureServer.sqf",
)


def remove_staged_mission(path: Path) -> None:
    """Remove a prior Windows stage even when copied source folders are read-only."""
    if not path.exists():
        return

    def clear_read_only(function, target, _error):
        os.chmod(target, stat.S_IWRITE)
        function(target)

    shutil.rmtree(path, onexc=clear_read_only)


def audit_fixtures() -> list[dict]:
    """Load the canonical fixture catalogue without generating the Eden mission."""
    namespace = runpy.run_path(
        str(ROOT / "releaseVerificationAndDeployment" / "generate_full_arma_audit_mission.py")
    )
    return list(namespace["FIXTURES"])


def nested_loadout_fixture() -> str:
    """Return a nested Eden Entities tree consumed only by MissionSQM scraping.

    The launched audit retains the proven version-12 playable shell, but the
    release description includes mission.sqm as configuration. This additional
    tree makes the real scraper traverse two organiser folders before it reaches
    the five playable inventories, without changing which units the engine spawns.
    """
    namespace = runpy.run_path(
        str(ROOT / "releaseVerificationAndDeployment" / "generate_full_arma_audit_mission.py")
    )
    loadouts = namespace["LOADOUTS"]
    unit_block = namespace["unit_block"]
    units = "\n".join(unit_block(index, loadout) for index, loadout in enumerate(loadouts))
    return f'''    class Entities
    {{
        items=1;
        class Item0
        {{
            dataType="Layer";
            name="WMP Audit Loadouts";
            class Entities
            {{
                items=1;
                class Item0
                {{
                    dataType="Layer";
                    name="Nested Playable Roles";
                    class Entities
                    {{
                        items={len(loadouts)};
{units}
                    }};
                }};
            }};
        }};
    }};
'''


def legacy_playable_units_with_loadouts(source: bytes) -> bytes:
    """Give the five engine-spawned legacy slots the same authored QA loadouts.

    The nested Eden tree remains the scraper fixture. These init loadouts make the
    people a tester actually controls visibly match that fixture instead of inheriting
    the default B_Soldier_F MX inventory.
    """
    namespace = runpy.run_path(
        str(ROOT / "releaseVerificationAndDeployment" / "generate_full_arma_audit_mission.py")
    )
    loadouts = namespace["LOADOUTS"]
    text = source.decode("utf-8")
    for index, loadout in enumerate(loadouts):
        commands = [
            "removeAllWeapons this",
            "removeAllItems this",
            "removeAllAssignedItems this",
            "removeUniform this",
            "removeVest this",
            "removeBackpack this",
            "removeHeadgear this",
            f'this forceAddUniform "{loadout["uniform"]}"',
            f'this addVest "{loadout["vest"]}"',
            f'this addBackpack "{loadout["backpack"]}"',
            f'this addHeadgear "{loadout["headgear"]}"',
            f'this addWeapon "{loadout["primary"]}"',
            f'this addPrimaryWeaponItem "{loadout["primary_mag"]}"',
        ]
        for attachment in ("optics", "muzzle", "flashlight"):
            if loadout.get(attachment):
                commands.append(f'this addPrimaryWeaponItem "{loadout[attachment]}"')
        if loadout.get("secondary"):
            commands.extend(
                [
                    f'this addWeapon "{loadout["secondary"]}"',
                    f'this addSecondaryWeaponItem "{loadout["secondary_mag"]}"',
                ]
            )
        commands.extend(
            [
                f'this addWeapon "{loadout["handgun"]}"',
                f'this addHandgunItem "{loadout["handgun_mag"]}"',
                f'this addWeapon "{loadout["binocular"]}"',
                f'this addMagazines ["{loadout["primary_mag"]}",2]',
                f'this addMagazine "{loadout["handgun_mag"]}"',
                'this addMagazine "SmokeShell"',
            ]
        )
        commands.extend(f'this addItem "{item}"' for item in loadout["items"])
        commands.extend(
            f'this linkItem "{item}"'
            for item in ("ItemMap", "ItemCompass", "ItemWatch", "ItemRadio", "ItemGPS", "NVGoggles")
        )
        init = "; ".join(commands).replace('"', '""') + ";"
        player = "PLAYER COMMANDER" if index == 0 else "PLAY CDG"
        leader = " leader=1;" if index == 0 else ""
        old = (
            f'class Item{index} {{position[]={{{index * 2},0,0}}; id={index}; side="WEST"; '
            f'vehicle="B_Soldier_F"; player="{player}";{leader} skill=0.6;}};'
        )
        new = (
            f'class Item{index} {{position[]={{{index * 2},0,0}}; id={index}; side="WEST"; '
            f'vehicle="{loadout["type"]}"; player="{player}";{leader} init="{init}"; skill=0.6;}};'
        )
        if old not in text:
            raise ValueError(f"Legacy playable slot {index} was not found in the known-good shell")
        text = text.replace(old, new, 1)
    return text.encode("utf-8")


def legacy_mission_with_fixtures(source: bytes, fixtures: list[dict], loadout_fixture: str) -> bytes:
    """Add static feature objects to the known-good version-12 mission.

    The runtime range still configures these objects through public WMP APIs,
    but players now see the complete physical range as soon as the mission
    world loads instead of watching it appear a few seconds later.
    """
    text = source.decode("utf-8")
    if 'text="qa_' in text:
        raise ValueError("Legacy mission already contains audit fixtures; refusing to append duplicates")
    text = legacy_playable_units_with_loadouts(source).decode("utf-8")
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
            # Legacy mission.sqm stores world position as X, elevation, Y.
            # Writing X, Y, Z put the intended northing into altitude and collapsed
            # the whole range onto the same east-west line.
            "            position[]={{{x},{z},{y}}};\n"
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
    marker_block = '''
    class Markers
    {
        items=1;
        class Item0
        {
            position[]={250,0,-12};
            name="respawn_west";
            text="Audit Base Respawn";
            type="mil_start";
            colorName="ColorWEST";
        };
    };
'''
    closing = text.rfind("\n};")
    if closing < 0:
        raise ValueError("Legacy mission is missing its Mission closing brace")
    return (text[:closing] + block + marker_block + loadout_fixture + text[closing:]).encode("utf-8")


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
    # The audit must exercise MenuPosition and group-owned rally respawns rather
    # than inheriting a symbolic/default release setting that can leave respawn
    # unavailable if this multiplayer audit is accidentally launched through
    # the single-player-only playMission command.
    result, count = re.subn(r"respawn\s*=\s*[^;]+", "respawn = 3", result, count=1)
    if count != 1:
        raise ValueError("Release description is missing respawn mode")
    result, count = re.subn(r"respawnDelay\s*=\s*[^;]+", "respawnDelay = 1", result, count=1)
    if count != 1:
        raise ValueError("Release description is missing respawn delay")
    return result


def wrap_entry_point(path: Path, pre_hook: str, post_hook: str) -> None:
    source = path.read_text(encoding="utf-8")
    path.write_text(
        f'// Full-pack PR audit pre-configuration.\ncall compile preprocessFileLineNumbers "{pre_hook}";\n\n'
        + source.rstrip()
        + f'\n\n// Full-pack PR audit continuation.\n[] execVM "{post_hook}";\n',
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
    mission_sqm = legacy_mission_with_fixtures(
        (TEMPLATE / "mission.sqm").read_bytes(), fixtures, nested_loadout_fixture()
    )
    if not mission_sqm.lstrip().startswith(b"version=12;"):
        raise ValueError("Full-pack PR audit must retain its known-good legacy mission.sqm")

    remove_staged_mission(destination)
    destination.mkdir(parents=True)
    copy_release(destination)
    shutil.copy2(destination / "acreConfig.sqf", destination / "releaseAcreConfig.sqf")

    (destination / "mission.sqm").write_bytes(mission_sqm)
    description_path = destination / "description.ext"
    description_path.write_text(
        audit_description(description_path.read_text(encoding="utf-8")), encoding="utf-8"
    )
    for name, content in template_content.items():
        (destination / name).write_text(content, encoding="utf-8")
    for name, content in range_content.items():
        (destination / name).write_text(content, encoding="utf-8")
    (destination / "acreConfig.sqf").write_text(
        range_content["auditAcreConfig.sqf"], encoding="utf-8"
    )

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
        "nestedPlayableLoadoutFixture": True,
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
