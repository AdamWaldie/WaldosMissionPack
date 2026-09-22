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
