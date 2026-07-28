#!/usr/bin/env python3
"""Static performance regression audit for WaldosMissionPack SQF.

The scanner deliberately reports opportunities rather than runtime timings.  It
removes comments and string contents before examining recurring ``while``
blocks, then attributes each finding to the nearest named SQF function.  A
checked-in baseline documents intentional high-severity findings; CI fails only
when a new or expanded high-severity finding is introduced.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_BASELINE = Path(__file__).with_name("performance_baseline.json")
FUNCTION_RE = re.compile(r"(?m)^\s*([A-Za-z][A-Za-z0-9_]*)\s*=\s*\{")
WHILE_RE = re.compile(r"\bwhile\s*\{")
DELAY_RE = re.compile(r"\b(?:uiSleep|sleep)\b(?:\s+([0-9]+(?:\.[0-9]+)?))?")
WORLD_SCAN_RE = re.compile(
    r"\b(allPlayers|allUnits|allMissionObjects|vehicles|nearObjects|nearestObjects)\b"
)
BROADCAST_RE = re.compile(r"\bsetVariable\s*\[[^;\]]*,[^;\]]*,\s*true\s*\]")
REMOTE_RE = re.compile(r"\bremoteExec(?:Call)?\s*\[")
REDRAW_RE = re.compile(
    r"\b(?:ctrlSetText|ctrlSetStructuredText|ctrlSetPosition|ctrlCommit|"
    r"ctrlSetBackgroundColor|lbAdd|lnbAddRow|tvAdd)\b"
)
REFRESH_CALL_RE = re.compile(r"\bcall\s+([A-Za-z][A-Za-z0-9_]*(?:refresh|Refresh)[A-Za-z0-9_]*)\b")
START_GUARD_RE = re.compile(r"\b(?:isNil\s+[^;]*(?:Started|LoopStarted)|getVariable\s*\[[^\]]*(?:Started|LoopStarted))")


@dataclass(frozen=True)
class Finding:
    category: str
    severity: str
    path: str
    function: str
    count: int
    lines: tuple[int, ...]
    detail: str

    @property
    def key(self) -> str:
        detail_key = re.sub(r"[^a-z0-9]+", "_", self.detail.lower()).strip("_")
        return f"{self.category}|{self.path}|{self.function}|{detail_key}"


def strip_comments_and_strings(source: str) -> str:
    """Replace comments and string contents with spaces while preserving lines."""
    output: list[str] = []
    index = 0
    state = "code"
    while index < len(source):
        char = source[index]
        nxt = source[index + 1] if index + 1 < len(source) else ""
        if state == "code":
            if char == "/" and nxt == "/":
                output.extend("  ")
                index += 2
                state = "line_comment"
                continue
            if char == "/" and nxt == "*":
                output.extend("  ")
                index += 2
                state = "block_comment"
                continue
            if char == '"':
                output.append(" ")
                index += 1
                state = "string"
                continue
            output.append(char)
        elif state == "line_comment":
            if char == "\n":
                output.append(char)
                state = "code"
            else:
                output.append(" ")
        elif state == "block_comment":
            if char == "*" and nxt == "/":
                output.extend("  ")
                index += 2
                state = "code"
                continue
            output.append("\n" if char == "\n" else " ")
        else:  # SQF strings escape a quote by doubling it.
            if char == '"' and nxt == '"':
                output.extend("  ")
                index += 2
                continue
            if char == '"':
                output.append(" ")
                state = "code"
            else:
                output.append("\n" if char == "\n" else " ")
        index += 1
    return "".join(output)


def matching_brace(source: str, opening: int) -> int | None:
    depth = 0
    for index in range(opening, len(source)):
        if source[index] == "{":
            depth += 1
        elif source[index] == "}":
            depth -= 1
            if depth == 0:
                return index
    return None


def enclosing_function(functions: list[tuple[int, str]], offset: int) -> str:
    name = "<file>"
    for function_offset, function_name in functions:
        if function_offset > offset:
            break
        name = function_name
    return name


def line_number(source: str, offset: int) -> int:
    return source.count("\n", 0, offset) + 1


def audit_source(source: str, relative_path: str) -> list[Finding]:
    clean = strip_comments_and_strings(source)
    functions = [(match.start(), match.group(1)) for match in FUNCTION_RE.finditer(clean)]
    grouped: dict[tuple[str, str, str, str], list[int]] = {}

    def add(category: str, severity: str, function: str, line: int, detail: str) -> None:
        grouped.setdefault((category, severity, function, detail), []).append(line)

    for loop_match in WHILE_RE.finditer(clean):
        condition_open = clean.find("{", loop_match.start())
        condition_close = matching_brace(clean, condition_open)
        if condition_close is None:
            continue
        body_open = clean.find("{", condition_close + 1)
        if body_open < 0 or clean[condition_close + 1 : body_open].strip() != "do":
            continue
        body_close = matching_brace(clean, body_open)
        if body_close is None:
            continue

        condition = clean[condition_open + 1 : condition_close].strip()
        body = clean[body_open + 1 : body_close]
        function = enclosing_function(functions, loop_match.start())
        loop_line = line_number(clean, loop_match.start())
        delay_matches = list(DELAY_RE.finditer(body))
        numeric_delays = [float(match.group(1)) for match in delay_matches if match.group(1)]
        has_delay = len(delay_matches) > 0
        minimum_delay = min(numeric_delays) if numeric_delays else None

        if condition == "true":
            add(
                "unbounded_scheduler",
                "high" if not has_delay else "medium",
                function,
                loop_line,
                "while {true} scheduler" + (" without a delay" if not has_delay else ""),
            )

        if not has_delay and condition == "true":
            add(
                "tight_loop",
                "high",
                function,
                loop_line,
                "unbounded loop has no sleep or uiSleep",
            )

        recurring = has_delay or condition == "true"
        if not recurring:
            continue

        function_start = 0
        for candidate_offset, candidate_name in functions:
            if candidate_offset > loop_match.start():
                break
            if candidate_name == function:
                function_start = candidate_offset
        guard_context = clean[function_start : loop_match.start()]
        if not START_GUARD_RE.search(guard_context):
            add(
                "missing_scheduler_guard",
                "medium",
                function,
                loop_line,
                "recurring loop has no nearby single-start guard",
            )

        for match in WORLD_SCAN_RE.finditer(body):
            severity = "high" if minimum_delay is not None and minimum_delay < 1 else "medium"
            add(
                "recurring_world_scan",
                severity,
                function,
                line_number(clean, body_open + 1 + match.start()),
                f"recurring {match.group(1)} scan",
            )
        for pattern, category, detail in (
            (BROADCAST_RE, "recurring_broadcast", "broadcast setVariable in recurring loop"),
            (REMOTE_RE, "recurring_remote_exec", "remoteExec in recurring loop"),
        ):
            for match in pattern.finditer(body):
                add(
                    category,
                    "high",
                    function,
                    line_number(clean, body_open + 1 + match.start()),
                    detail,
                )
        if minimum_delay is not None and minimum_delay <= 0.25:
            redraws = list(REDRAW_RE.finditer(body))
            for match in redraws:
                add(
                    "high_frequency_ui_redraw",
                    "medium",
                    function,
                    line_number(clean, body_open + 1 + match.start()),
                    f"control redraw at a {minimum_delay:g}s loop interval",
                )
            for match in REFRESH_CALL_RE.finditer(body):
                add(
                    "high_frequency_ui_refresh",
                    "medium",
                    function,
                    line_number(clean, body_open + 1 + match.start()),
                    f"{match.group(1)} called at a {minimum_delay:g}s loop interval",
                )

    findings = []
    for (category, severity, function, detail), lines in grouped.items():
        findings.append(
            Finding(
                category=category,
                severity=severity,
                path=relative_path.replace("\\", "/"),
                function=function,
                count=len(lines),
                lines=tuple(sorted(set(lines))),
                detail=detail,
            )
        )
    return sorted(findings, key=lambda item: (item.path, item.function, item.category, item.detail))


def audit_tree(root: Path) -> list[Finding]:
    findings: list[Finding] = []
    for path in sorted((root / "MissionScripts").rglob("*.sqf")):
        relative = path.relative_to(root).as_posix()
        findings.extend(audit_source(path.read_text(encoding="utf-8", errors="replace"), relative))
    return findings


def load_baseline(path: Path) -> dict[str, dict[str, object]]:
    if not path.exists():
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    return {entry["key"]: entry for entry in data.get("accepted", [])}


def evaluate(findings: list[Finding], baseline_path: Path) -> list[Finding]:
    baseline = load_baseline(baseline_path)
    failures: list[Finding] = []
    for finding in findings:
        if finding.severity != "high":
            continue
        accepted = baseline.get(finding.key)
        reason = "" if accepted is None else str(accepted.get("reason", "")).strip()
        if (
            accepted is None
            or finding.count > int(accepted.get("max_count", 0))
            or not reason
            or reason.startswith("REVIEW REQUIRED")
        ):
            failures.append(finding)
    return failures


def write_baseline(findings: list[Finding], path: Path) -> None:
    existing = load_baseline(path)
    accepted = []
    for finding in findings:
        if finding.severity != "high":
            continue
        prior = existing.get(finding.key, {})
        accepted.append(
            {
                "key": finding.key,
                "max_count": finding.count,
                "reason": prior.get(
                    "reason",
                    "REVIEW REQUIRED: document why this recurring pattern is intentional.",
                ),
            }
        )
    payload = {
        "schema": 1,
        "description": "Accepted high-severity static findings. Every entry requires a review reason.",
        "accepted": accepted,
    }
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--baseline", type=Path, default=DEFAULT_BASELINE)
    parser.add_argument("--write-baseline", action="store_true")
    parser.add_argument("--json", action="store_true", help="emit findings as JSON")
    args = parser.parse_args()

    findings = audit_tree(args.root.resolve())
    if args.write_baseline:
        write_baseline(findings, args.baseline)
        print(f"Wrote {args.baseline} with accepted high-severity findings.")
        return 0

    failures = evaluate(findings, args.baseline)
    if args.json:
        print(json.dumps([asdict(finding) | {"key": finding.key} for finding in findings], indent=2))
    else:
        counts = {severity: sum(item.severity == severity for item in findings) for severity in ("high", "medium")}
        print(
            "Static performance audit: "
            f"{len(findings)} findings ({counts['high']} high, {counts['medium']} medium)."
        )
        for finding in failures:
            print(
                f"ERROR {finding.key}: {finding.detail}; count={finding.count}, "
                f"lines={','.join(map(str, finding.lines))}"
            )
    if failures:
        print(f"Performance regression check failed with {len(failures)} unaccepted high finding(s).")
        return 1
    print("Performance regression check passed; no new high-severity recurring patterns.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
