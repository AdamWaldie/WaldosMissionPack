#!/usr/bin/env python3
"""Package the ACRE test shell with the current WMP release and service/logistics fixtures."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "releaseVerificationAndDeployment/serverTestMissions/WMP_ACRE2_Respawn_Test.VR"
CONFIG = ROOT / "releaseVerificationAndDeployment/config.json"


def authored_logistics_loadout() -> str:
    """Expose the four legacy radio-test slots' shared NATO kit to WMP's SQM scraper.

    The version-12 Groups below remain the only engine-spawned playable slots. This
    Eden inventory record gives the mission-derived quartermaster a real authored
    pool, as in the full-pack audit's legacy-shell fixture.
    """
    return '''    class Entities
    {
        items=1;
        class Item0
        {
            dataType="Group";
            side="West";
            class Entities
            {
                items=1;
                class Item0
                {
                    dataType="Object";
                    side="West";
                    class Attributes
                    {
                        name="acre_test_logistics_loadout";
                        isPlayable=1;
                        class Inventory
                        {
                            class primaryWeapon {name="arifle_MX_F"; class primaryMuzzleMag {name="30Rnd_65x39_caseless_mag"; ammoLeft=30;};};
                            class handgun {name="hgun_P07_F"; class primaryMuzzleMag {name="16Rnd_9x21_Mag"; ammoLeft=16;};};
                            class binocular {name="Binocular";};
                            class uniform
                            {
                                typeName="U_B_CombatUniform_mcam";
                                isBackpack=0;
                                class MagazineCargo
                                {
                                    items=4;
                                    class Item0 {name="30Rnd_65x39_caseless_mag"; count=1; ammoLeft=30;};
                                    class Item1 {name="16Rnd_9x21_Mag"; count=1; ammoLeft=16;};
                                    class Item2 {name="HandGrenade"; count=1; ammoLeft=1;};
                                    class Item3 {name="DemoCharge_Remote_Mag"; count=1; ammoLeft=1;};
                                };
                                class ItemCargo {items=1; class Item0 {name="ACE_fieldDressing"; count=1;};};
                            };
                            class vest {typeName="V_PlateCarrier1_rgr"; isBackpack=0;};
                            class backpack
                            {
                                typeName="B_AssaultPack_mcamo";
                                isBackpack=1;
                                class ItemCargo
                                {
                                    items=3;
                                    class Item0 {name="ACRE_PRC343"; count=1;};
                                    class Item1 {name="ACRE_PRC152"; count=1;};
                                    class Item2 {name="ACRE_PRC77"; count=1;};
                                };
                            };
                            map="ItemMap";
                            compass="ItemCompass";
                            watch="ItemWatch";
                            gps="ItemGPS";
                            headgear="H_HelmetB";
                        };
                    };
                    id=100;
                    type="B_Soldier_F";
                };
            };
            class Attributes {};
            id=101;
        };
    };
'''


def build(destination: Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    entries = json.loads(CONFIG.read_text(encoding="utf-8"))["build"]["include"]
    for relative in entries:
        source = ROOT / relative
        target = destination / relative
        if source.is_dir():
            shutil.copytree(source, target, dirs_exist_ok=True)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)

    for relative in ("mission.sqm", "MissionConfig/acreConfig.sqf",
                     "serviceLogisticsTestPreInit.sqf", "serviceLogisticsTestPreServer.sqf",
                     "serviceLogisticsTestServer.sqf", "TESTING.md"):
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(TEMPLATE / relative, target)

    mission = destination / "mission.sqm"
    source = mission.read_text(encoding="utf-8")
    end_of_mission = source.rfind("\n};")
    if end_of_mission < 0 or "class Entities" in source:
        raise ValueError("Expected the unmodified legacy test mission without Eden Entities")
    mission.write_text(source[:end_of_mission] + "\n" + authored_logistics_loadout()
                       + source[end_of_mission:], encoding="utf-8")

    description = destination / "description.ext"
    source = description.read_text(encoding="utf-8")
    for field, value in {
        "onLoadName": "WMP ACRE2 and Logistics Test",
        "onLoadMission": "ACRE lifecycle and service/logistics test area",
        "onLoadIntro": "Radio, base services, quartermaster, transfers and cargo",
    }.items():
        source, count = re.subn(rf'{field}\s*=\s*"[^"]*"', f'{field} = "{value}"', source, count=1)
        if count != 1:
            raise ValueError(f"Missing description field: {field}")
    source = re.sub(r"maxPlayers\s*=\s*\d+", "maxPlayers = 4", source, count=1)
    source = re.sub(r"respawn\s*=\s*[^;]+", "respawn = 3", source, count=1)
    source = re.sub(r"respawnDelay\s*=\s*[^;]+", "respawnDelay = 1", source, count=1)
    description.write_text(source, encoding="utf-8")

    for filename, pre, post in (
        ("init.sqf", "serviceLogisticsTestPreInit.sqf", None),
        ("initServer.sqf", "serviceLogisticsTestPreServer.sqf", "serviceLogisticsTestServer.sqf"),
    ):
        path = destination / filename
        content = f'call compile preprocessFileLineNumbers "{pre}";\n\n' + path.read_text(encoding="utf-8")
        if post:
            content += f'\n[] execVM "{post}";\n'
        path.write_text(content, encoding="utf-8")


def package(destination: Path, archive: Path) -> None:
    archive.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as output:
        for file in sorted(destination.rglob("*")):
            if file.is_file():
                output.write(file, f"{destination.name}/{file.relative_to(destination).as_posix()}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--destination", type=Path, required=True)
    parser.add_argument("--zip", type=Path)
    arguments = parser.parse_args()
    build(arguments.destination)
    if arguments.zip:
        package(arguments.destination, arguments.zip)
    print(arguments.destination)
    if arguments.zip:
        print(arguments.zip)


if __name__ == "__main__":
    main()
