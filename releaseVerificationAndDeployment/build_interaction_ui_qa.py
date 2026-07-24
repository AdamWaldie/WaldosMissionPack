#!/usr/bin/env python3
"""Assemble the interaction-equipment VR test mission without modifying source files."""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = (
    ROOT
    / "releaseVerificationAndDeployment"
    / "interactionEquipmentQA"
    / "InteractionEquipmentQA.VR"
)


def build(
    destination: Path,
    mode: str,
    challenge: str = "wirecut",
    difficulty: str = "standard",
    all_difficulties: bool = False,
    autotest_config: Path | None = None,
) -> Path:
    if destination.exists():
        shutil.rmtree(destination)
    shutil.copytree(TEMPLATE, destination)
    shutil.copytree(ROOT / "MissionScripts", destination / "MissionScripts")
    shutil.copy2(ROOT / "economyConfig.sqf", destination / "economyConfig.sqf")
    (destination / "init.sqf").write_text(
        f'Waldo_MG_QA_Mode = "{mode.upper()}";\n'
        f'Waldo_MG_QA_Challenge = "{challenge.lower()}";\n'
        f'Waldo_MG_QA_Difficulty = "{difficulty.lower()}";\n'
        f'Waldo_MG_QA_AllDifficulties = {str(all_difficulties).lower()};\n',
        encoding="utf-8",
    )
    if autotest_config is not None:
        autotest_config.parent.mkdir(parents=True, exist_ok=True)
        container = destination.parent.name.lower()
        if container in {"missions", "autotest"}:
            mission_path = str(Path(container) / destination.name)
        else:
            mission_path = str(destination)
        mission_path = mission_path.replace('"', '""')
        autotest_config.write_text(
            "class TestMissions\n"
            "{\n"
            "    class InteractionEquipmentUI\n"
            "    {\n"
            '        campaign = "";\n'
            f'        mission = "{mission_path}";\n'
            "    };\n"
            "};\n",
            encoding="utf-8",
        )
    return destination


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--destination", type=Path, required=True)
    parser.add_argument(
        "--mode", choices=("interactive", "active", "automated"), default="interactive"
    )
    parser.add_argument(
        "--challenge",
        choices=(
            "wirecut",
            "minesweeper",
            "keypad",
            "lockpick",
            "circuit",
            "repair",
            "radiotune",
            "pressure",
            "sequence",
            "commandinput",
        ),
        default="wirecut",
    )
    parser.add_argument(
        "--difficulty",
        choices=("easy", "standard", "hard", "expert"),
        default="standard",
    )
    parser.add_argument("--all-difficulties", action="store_true")
    parser.add_argument("--autotest-config", type=Path)
    args = parser.parse_args()
    result = build(
        args.destination.resolve(),
        args.mode,
        args.challenge,
        args.difficulty,
        args.all_difficulties,
        args.autotest_config.resolve() if args.autotest_config else None,
    )
    print(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
