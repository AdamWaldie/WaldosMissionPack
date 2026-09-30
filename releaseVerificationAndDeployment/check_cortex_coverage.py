"""Check executable Cortex coverage wiring without claiming behavioural acceptance."""
import argparse
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

def audit(root=ROOT):
    tools = root / "releaseVerificationAndDeployment"
    qa = tools / "cortexQA"
    data = json.loads((qa / "coverage.json").read_text(encoding="utf-8"))
    launcher = (tools / "launch_pr_review_audit.ps1").read_text(encoding="utf-8")
    server = (qa / "runServer.sqf").read_text(encoding="utf-8")
    settings = set(re.findall(r'^\s*\["(Waldo_[^"]+)"\s*,',
        (root / "MissionConfig/aiConfig.sqf").read_text(encoding="utf-8"), re.M))
    assigned = [key for case in data["cases"] for key in case["settings"]]
    errors = []
    if settings != set(assigned):
        errors.append(f"Setting coverage mismatch: missing={sorted(settings-set(assigned))}; obsolete={sorted(set(assigned)-settings)}")
    if len(assigned) != len(set(assigned)):
        errors.append("Settings assigned to multiple feature cases")
    ids = [case["id"] for case in data["cases"]]
    if len(ids) != len(set(ids)):
        errors.append("Duplicate feature case IDs")
    for case in data["cases"]:
        sources = case.get("executable_sources", [])
        if not sources:
            errors.append(f"{case['id']}: no executable source")
        for source in sources:
            if Path(source).name != source or not (qa / source).is_file():
                errors.append(f"{case['id']}: missing or invalid source {source}")
                continue
            # A source file by itself is not runnable: check staging and dispatch.
            pattern = r'cortexQA/' + re.escape(source) + r'"\) -Destination \(Join-Path \$missionRoot "([^"]+)"'
            match = re.search(pattern, launcher)
            if not match:
                errors.append(f"{case['id']}: {source} is not staged by the launcher")
            elif source not in ["runServer.sqf", "runClient.sqf"] and match[1] not in server:
                errors.append(f"{case['id']}: staged {source} has no server dispatch")
    pending = [case["id"] for case in data["cases"] if case.get("status") != "accepted"]
    return data, errors, pending

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--require-accepted", action="store_true")
    args = parser.parse_args()
    data, errors, pending = audit()
    print(f"Executable coverage: {len(data['cases'])} feature cases; {len(data['required_variants'])} required variant categories")
    for error in errors:
        print("ERROR: " + error)
    print("Incomplete behavioural acceptance: " + ", ".join(pending))
    print("Wiring checks do not prove physical behaviour or complete variant coverage.")
    return 1 if errors else (2 if args.require_accepted and pending else 0)

if __name__ == "__main__":
    raise SystemExit(main())
