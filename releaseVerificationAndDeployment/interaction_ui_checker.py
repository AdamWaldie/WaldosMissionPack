#!/usr/bin/env python3
"""Static guardrails for Arma-native interaction-equipment displays."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INTERACTIONS = ROOT / "MissionScripts" / "InteractionsMinigames"
CHALLENGES = INTERACTIONS / "Challenges"
EXPECTED = {
    "challengeWireCut.sqf",
    "challengeMinesweeper.sqf",
    "challengeKeypad.sqf",
    "challengeLockpick.sqf",
    "challengeCircuit.sqf",
    "challengeRepair.sqf",
    "challengeRadioTune.sqf",
    "challengePressure.sqf",
    "challengeSequence.sqf",
    "challengeCommandInput.sqf",
}


def strip_comments(source: str) -> str:
    """Remove SQF comments while preserving quoted strings and line positions."""
    result: list[str] = []
    index = 0
    in_string = False
    while index < len(source):
        char = source[index]
        next_char = source[index + 1] if index + 1 < len(source) else ""
        if char == '"':
            result.append(char)
            if in_string and next_char == '"':
                result.append(next_char)
                index += 2
                continue
            in_string = not in_string
            index += 1
            continue
        if not in_string and char == "/" and next_char == "/":
            while index < len(source) and source[index] != "\n":
                result.append(" ")
                index += 1
            continue
        if not in_string and char == "/" and next_char == "*":
            result.extend((" ", " "))
            index += 2
            while index < len(source):
                if source[index : index + 2] == "*/":
                    result.extend((" ", " "))
                    index += 2
                    break
                result.append("\n" if source[index] == "\n" else " ")
                index += 1
            continue
        result.append(char)
        index += 1
    return "".join(result)


def audit(root: Path = ROOT) -> list[str]:
    interactions = root / "MissionScripts" / "InteractionsMinigames"
    challenges = interactions / "Challenges"
    errors: list[str] = []
    actual = {path.name for path in challenges.glob("challenge*.sqf")}
    missing = sorted(EXPECTED - actual)
    if missing:
        errors.append(f"Missing challenge files: {', '.join(missing)}")
    legacy = interactions / "Core" / "challengeUiLegacy.sqf"
    if legacy.exists():
        errors.append("Legacy challenge shell still exists")

    for path in sorted(challenges.glob("*.sqf")):
        source = strip_comments(path.read_text(encoding="utf-8"))
        relative = path.relative_to(root)
        lowered = source.lower()
        if "safezone" in lowered:
            errors.append(f"{relative}: challenge performs raw safe-zone layout arithmetic")
        if "ctrlcreate" in lowered:
            errors.append(f"{relative}: challenge bypasses MiniGameEquipmentCreateControl")
        if "displayaddeventhandler" in lowered:
            errors.append(f"{relative}: persistent display handler is not centrally registered")
        if "minigamechallengeui" not in lowered:
            errors.append(f"{relative}: challenge does not use the shared equipment shell")
        if "minigameequipmentcreatecontrol" not in lowered:
            errors.append(f"{relative}: challenge does not use equipment-grid controls")
        if (
            "rscstructuredtext" in lowered
            and "minigameequipmentfitstructuredtext" not in lowered
            and "ctrltextheight" not in lowered
        ):
            errors.append(
                f"{relative}: structured text has no bounded fitting path"
            )
        if r"\n" in source:
            errors.append(
                f"{relative}: literal \\n escape found; Arma controls render it as text"
            )
        for match in re.finditer(r"(?im)^.*ctrlsetangle.*$", source):
            line = match.group(0).strip()
            if path.name != "challengeRepair.sqf" or not re.search(
                r"_wrench\s+ctrlSetAngle", line, re.IGNORECASE
            ):
                errors.append(f"{relative}: unsupported rotation call: {line}")

    for path in sorted(interactions.rglob("*.sqf")):
        source = strip_comments(path.read_text(encoding="utf-8"))
        relative = path.relative_to(root)
        if "MiniGameChallengeUILegacy" in source:
            errors.append(f"{relative}: references removed legacy shell")
        if re.search(r"(?i)\bctrlSetStyle\b", source):
            errors.append(
                f"{relative}: ctrlSetStyle is not an Arma SQF runtime command; use a configured control class"
            )
        if "displayAddEventHandler" in source and path.name not in {
            "challengeUi.sqf",
            "equipmentAddDisplayHandler.sqf",
        }:
            errors.append(f"{relative}: unregistered display event handler")
        # Arma does not accept an if expression as an unparenthesized command
        # operand. These forms can evade lightweight delimiter validation but
        # fail only when the client compiles the script.
        for match in re.finditer(
            r"(?i)\b(ctrlSetText|ctrlSetTextColor|ctrlSetBackgroundColor|pushBack)\s+if\s*\(",
            source,
        ):
            line = source.count("\n", 0, match.start()) + 1
            errors.append(
                f"{relative}:{line}: parenthesize conditional command operand"
            )

    equipment = interactions / "Equipment"
    for path in sorted(equipment.glob("*.sqf")):
        source = strip_comments(path.read_text(encoding="utf-8"))
        relative = path.relative_to(root)
        if re.search(r"(?i)(safezone[wh]\s*[*/+-]|[*/+-]\s*safezone[wh])", source):
            errors.append(
                f"{relative}: equipment component mixes raw safe-zone dimensions with equipment coordinates"
            )

    for relative_path in (
        "Core/challengeHelp.sqf",
        "Equipment/equipmentBriefing.sqf",
        "Integration/equipmentPicker.sqf",
        "Integration/miniGameInteractionNotifyClient.sqf",
    ):
        path = interactions / relative_path
        if not path.exists():
            errors.append(f"InteractionsMinigames/{relative_path}: shared UI file is missing")
            continue
        source = strip_comments(path.read_text(encoding="utf-8")).lower()
        if (
            "rscstructuredtext" in source
            and "minigameequipmentfitstructuredtext" not in source
            and "ctrltextheight" not in source
        ):
            errors.append(
                f"InteractionsMinigames/{relative_path}: shared structured text bypasses fitting"
            )

    functions = (root / "MissionScripts" / "WaldosFunctions.sqf").read_text(
        encoding="utf-8"
    )
    if "MiniGameChallengeUILegacy" in strip_comments(functions):
        errors.append("WaldosFunctions.sqf still registers the legacy shell")
    if "MiniGameEquipmentFitStructuredText" not in functions:
        errors.append("WaldosFunctions.sqf does not register structured-text fitting")
    difficulty_helper = interactions / "Themes" / "equipmentDifficultyConfig.sqf"
    if not difficulty_helper.exists():
        errors.append("Canonical equipment difficulty helper is missing")
    else:
        difficulty_source = strip_comments(
            difficulty_helper.read_text(encoding="utf-8")
        ).lower()
        for name in ("easy", "standard", "hard", "expert"):
            if f'"{name}"' not in difficulty_source:
                errors.append(f"Difficulty helper does not define {name}")
        for challenge in EXPECTED:
            challenge_id = challenge.removeprefix("challenge").removesuffix(".sqf").lower()
            if challenge_id == "radiotune":
                expected_id = "radiotune"
            elif challenge_id == "wirecut":
                expected_id = "wirecut"
            else:
                expected_id = challenge_id
            if f'case "{expected_id}"' not in difficulty_source:
                errors.append(f"Difficulty helper does not define {expected_id}")
    setup_path = interactions / "Integration" / "miniGameInteractionSetup.sqf"
    if setup_path.exists() and "MiniGameEquipmentDifficultyConfig" not in setup_path.read_text(
        encoding="utf-8"
    ):
        errors.append("Interaction setup does not use canonical difficulty configs")
    qa_path = (
        root
        / "releaseVerificationAndDeployment"
        / "interactionEquipmentQA"
        / "InteractionEquipmentQA.VR"
        / "initPlayerLocal.sqf"
    )
    if qa_path.exists():
        qa_source = qa_path.read_text(encoding="utf-8")
        if "MiniGameEquipmentDifficultyConfig" not in qa_source:
            errors.append("Arma QA does not use canonical difficulty configs")
        if "Waldo_MG_QA_AllDifficulties" not in qa_source:
            errors.append("Arma QA does not expose the all-difficulties matrix")
    return errors


def main() -> int:
    errors = audit()
    print("Validating interaction-equipment UI architecture")
    print("------")
    print(f"Checked {len(list(CHALLENGES.glob('*.sqf')))} challenge files")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        print(f"Errors detected: {len(errors)}")
        return 1
    print("Errors detected: 0")
    print("Interaction-equipment UI validation PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
