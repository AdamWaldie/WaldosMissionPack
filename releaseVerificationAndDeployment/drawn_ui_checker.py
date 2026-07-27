#!/usr/bin/env python3
"""Cross-pack guardrails for first-party dynamically drawn Arma interfaces."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "MissionScripts"
TRANSIENT = {
    "MissionFlowAndUi/safeStartHud.sqf",
    "MissionFlowAndUi/safeStartNotice.sqf",
    "MissionFlowAndUi/showUiNotification.sqf",
    "MissionInit/Jamming/jammingHud.sqf",
    "MissionInit/Jamming/jammingNotice.sqf",
    "EconomySystems/Core/notifyActorLocal.sqf",
    "InteractionsMinigames/Integration/miniGameInteractionNotifyClient.sqf",
}


def audit(root: Path = ROOT) -> tuple[list[str], list[str]]:
    scripts = root / "MissionScripts"
    findings: list[str] = []
    inventory: list[str] = []
    for path in sorted(scripts.rglob("*.sqf")):
        source = path.read_text(encoding="utf-8")
        relative = path.relative_to(scripts).as_posix()
        if "ctrlCreate" not in source and "createDisplay" not in source:
            continue
        inventory.append(relative)

        # 0..1 is not Arma's UI coordinate contract on every aspect ratio. A
        # display must use the full safe-zone rectangle and add its own inset.
        for forbidden in (
            "safeZoneX max 0",
            "safeZoneY max 0",
            "(safeZoneX + safeZoneW) min 1",
            "(safeZoneY + safeZoneH) min 1",
            "safezoneX max 0",
            "safezoneY max 0",
            "(safezoneX + safezoneW) min 1",
            "(safezoneY + safezoneH) min 1",
        ):
            if forbidden in source:
                findings.append(f"{relative}: clamps Arma safe-zone coordinates to 0..1")
                break

        if relative.startswith("EconomySystems/") and "createDisplay" in source:
            if "Waldo_fnc_EcoCore_createZeusPromptDisplay" not in source:
                findings.append(f"{relative}: Economy display bypasses shared prompt card")
            if "Waldo_fnc_EcoCore_fitPromptDisplay" not in source:
                findings.append(f"{relative}: Economy display bypasses shared safe fitter")
        if (
            relative.startswith("EconomySystems/")
            and "ctrlCreate" in source
            and "Waldo_fnc_EcoCore_getZeusDisplay" in source
            and "Waldo_fnc_EcoCore_createZeusPromptDisplay" not in source
        ):
            findings.append(f"{relative}: authoring controls are attached directly to Zeus instead of a modal child")
        if relative == "EconomySystems/Core/createZeusPromptDisplay.sqf":
            if 'private _disp = _parent createDisplay "RscDisplayEmpty"' not in source:
                findings.append(f"{relative}: authoring prompt does not own a modal child display")
            if "WaldoEcoCore_PromptParentDisplay" not in source or "else {_parent}" in source:
                findings.append(f"{relative}: authoring prompt can leak input into its parent display")
        if (
            relative.startswith("EconomySystems/")
            and "ctrlCreate" in source
            and "closeDisplay 1" in source
            and relative != "EconomySystems/Core/closePromptDisplayIfDedicated.sqf"
        ):
            findings.append(f"{relative}: Economy prompt can close its parent gameplay/Zeus display")

        if relative.startswith("MiniGames/engine/games/") and "createDisplay" in source:
            if "Waldo_MG_fnc_installEscapeGuardLocal" not in source:
                findings.append(f"{relative}: party display bypasses shared safe fitter")

        if relative in TRANSIENT:
            layout_source = source
            if relative == "MissionFlowAndUi/showUiNotification.sqf":
                layout_source += (scripts / "MissionFlowAndUi" / "reflowUiPanels.sqf").read_text(encoding="utf-8")
            if "safeZone" not in layout_source:
                findings.append(f"{relative}: transient panel has no safe-zone anchor")
            if "ctrlTextHeight" not in layout_source:
                findings.append(f"{relative}: transient panel does not measure its text")
            if "_padX" not in layout_source or "_padY" not in layout_source:
                findings.append(f"{relative}: transient panel has no protected text padding")

        if relative == "MissionFlowAndUi/showUiNotification.sqf":
            for required in ("Waldo_UiPanelQueue", "Waldo_fnc_ReflowUiPanels", "Waldo_fnc_ResolveUiPanelPlacement"):
                if required not in source:
                    findings.append(f"{relative}: shared notification arbitration is missing {required}")

    return findings, inventory


def main() -> int:
    findings, inventory = audit()
    print("Validating first-party drawn UI")
    print("------")
    print(f"Inventoried {len(inventory)} dynamically drawn UI scripts")
    if findings:
        for finding in findings:
            print(f"ERROR: {finding}")
        print(f"Errors detected: {len(findings)}")
        return 1
    print("Errors detected: 0")
    print("Drawn UI validation PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
