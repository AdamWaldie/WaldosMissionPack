#!/usr/bin/env python3
"""Reject undocumented drift between WMP Zeus modules and their script APIs."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = Path(__file__).with_name("zeus_script_parity.json")


def function_path(functions_source: str, function_name: str) -> Path | None:
    """Resolve a WMP CfgFunctions name to its checked-in implementation."""
    if not function_name.startswith("Waldo_fnc_"):
        return None
    short_name = function_name.removeprefix("Waldo_fnc_")
    match = re.search(
        rf"class\s+{re.escape(short_name)}\s*\{{[^}}]*?file\s*=\s*\"([^\"]+)\"",
        functions_source,
        re.DOTALL,
    )
    if not match:
        return None
    return Path(match.group(1).replace("\\", "/"))


def audit(root: Path = ROOT) -> list[str]:
    records = json.loads((root / "releaseVerificationAndDeployment" / MANIFEST.name).read_text(encoding="utf-8"))
    core_register = (root / "MissionScripts" / "ZenModules" / "Zen_initModules.sqf").read_text(encoding="utf-8")
    economy_register = (root / "MissionScripts" / "EconomySystems" / "Core" / "registerZenModules.sqf").read_text(encoding="utf-8")
    functions_source = (root / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
    all_source = "\n".join(path.read_text(encoding="utf-8") for path in (root / "MissionScripts").rglob("*.sqf"))
    findings: list[str] = []
    expected = {"core": 52, "economy": 19}
    for category, count in expected.items():
        actual = sum(record.get("category") == category for record in records)
        if actual != count:
            findings.append(f"{category}: manifest has {actual} modules, expected {count}")
    names: set[str] = set()
    for record in records:
        name = record.get("module", "")
        category = record.get("category", "")
        source = core_register if category == "core" else economy_register
        if name in names:
            findings.append(f"duplicate module manifest entry: {name}")
        names.add(name)
        if f'"{name}"' not in source:
            findings.append(f"{name}: registration not found in {category} module source")
        for key in ("handler", "script_api"):
            token = record.get(key, "")
            if not token or token not in all_source:
                findings.append(f"{name}: {key} {token!r} is not present in MissionScripts")
        handler = record.get("handler", "")
        script_api = record.get("script_api", "")
        handler_path = function_path(functions_source, handler)
        api_path = function_path(functions_source, script_api)
        if handler.startswith("Waldo_fnc_") and handler_path is None:
            findings.append(f"{name}: handler {handler!r} is not registered in CfgFunctions")
        if script_api.startswith("Waldo_fnc_") and api_path is None:
            findings.append(f"{name}: script API {script_api!r} is not registered in CfgFunctions")
        if handler_path is not None:
            handler_source = (root / handler_path).read_text(encoding="utf-8")
            via = record.get("via", "")
            if via:
                via_path = function_path(functions_source, via)
                if via_path is None:
                    findings.append(f"{name}: bridge {via!r} is not registered in CfgFunctions")
                elif via not in handler_source:
                    findings.append(f"{name}: handler does not call declared bridge {via!r}")
                else:
                    via_source = (root / via_path).read_text(encoding="utf-8")
                    if script_api not in via_source:
                        findings.append(f"{name}: bridge does not call declared script API {script_api!r}")
            elif handler != script_api and script_api not in handler_source:
                findings.append(f"{name}: handler does not call declared script API {script_api!r}")
        parity = record.get("parity", "")
        if parity not in {"full", "adapter", "intentional"}:
            findings.append(f"{name}: invalid parity classification {parity!r}")
        if parity != "full" and not record.get("notes", "").strip():
            findings.append(f"{name}: non-full parity requires an explicit justification")
        handler_short = handler.removeprefix("Waldo_fnc_")
        if handler_short in {"ZenJammerPlace", "ZenTracker"} and handler_path is not None:
            handler_source = (root / handler_path).read_text(encoding="utf-8")
            for token in record.get("required_tokens", []):
                if token not in handler_source:
                    findings.append(f"{name}: required parity control is missing: {token}")
    return findings


def main() -> int:
    findings = audit()
    print("Validating Zeus/script feature parity")
    print("------")
    print(f"Checked {sum(1 for _ in json.loads((ROOT / 'releaseVerificationAndDeployment' / MANIFEST.name).read_text(encoding='utf-8')))} registered Zeus modules")
    for finding in findings:
        print(f"ERROR: {finding}")
    print(f"Errors detected: {len(findings)}")
    if findings:
        return 1
    print("Zeus/script parity validation PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
