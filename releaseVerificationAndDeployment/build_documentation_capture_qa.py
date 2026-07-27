#!/usr/bin/env python3
"""Assemble a disposable Arma mission for deterministic documentation captures."""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "releaseVerificationAndDeployment" / "documentationCaptureQA" / "DocumentationCaptureQA.VR"
FUNCTION_RE = re.compile(r'class\s+([A-Za-z0-9_]+)\s*\{\s*file\s*=\s*"([^"]+\.sqf)"', re.MULTILINE)


def build(destination: Path, case: str, cases: list[str] | None = None) -> Path:
    if destination.exists():
        shutil.rmtree(destination)
    shutil.copytree(TEMPLATE, destination)
    shutil.copytree(ROOT / "MissionScripts", destination / "MissionScripts")
    shutil.copy2(ROOT / "economyConfig.sqf", destination / "economyConfig.sqf")
    source = (ROOT / "MissionScripts" / "WaldosFunctions.sqf").read_text(encoding="utf-8")
    functions = [(f"Waldo_fnc_{name}", path.replace("/", "\\")) for name, path in FUNCTION_RE.findall(source)]
    rows = ",\n".join(f'    ["{name}", "{path}"]' for name, path in functions)
    (destination / "functionBootstrap.sqf").write_text(f"[\n{rows}\n]\n", encoding="utf-8")
    selected = [item.lower() for item in (cases or [case])]
    sqf_cases = ", ".join(f'"{item}"' for item in selected)
    (destination / "captureConfig.sqf").write_text(
        f'Waldo_DocCapture_Case = "{selected[0]}";\nWaldo_DocCapture_Cases = [{sqf_cases}];\n', encoding="utf-8"
    )
    print(f"Staged {destination} with {len(functions)} registered functions for {selected}")
    return destination


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--destination", type=Path, required=True)
    parser.add_argument("--case", required=True)
    parser.add_argument("--cases", nargs="*")
    args = parser.parse_args()
    build(args.destination.resolve(), args.case, args.cases)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
