#!/usr/bin/env python3
"""Parse structured WMP FULL AUDIT RPT records into JSON and Markdown."""

from __future__ import annotations

import argparse
import ast
import json
import re
from pathlib import Path

LINE = re.compile(r'WMP FULL AUDIT (PASS|FAIL|CASE|BOOT|COMPLETE):\s*(\[.*\])')


def parse(path: Path) -> list[dict[str, object]]:
    records: list[dict[str, object]] = []
    for number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        match = LINE.search(line)
        if not match:
            continue
        try:
            payload = ast.literal_eval(match.group(2).replace("true", "True").replace("false", "False"))
        except (SyntaxError, ValueError):
            payload = ["PARSE_ERROR", match.group(2)]
        records.append({"line": number, "kind": match.group(1), "payload": payload})
    return records


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("rpt", type=Path)
    parser.add_argument("--json", dest="json_path", type=Path, required=True)
    parser.add_argument("--markdown", type=Path, required=True)
    args = parser.parse_args()
    records = parse(args.rpt)
    failures = [r for r in records if r["kind"] == "FAIL"]
    args.json_path.parent.mkdir(parents=True, exist_ok=True)
    args.json_path.write_text(json.dumps({"records": records, "failures": failures}, indent=2), encoding="utf-8")
    lines = ["# WMP Full Arma Audit Results", "", f"- Records: {len(records)}", f"- Failures: {len(failures)}", ""]
    lines += ["## Failures", ""] + ([f"- `{r['payload']}`" for r in failures] or ["None."])
    args.markdown.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"records={len(records)} failures={len(failures)}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
