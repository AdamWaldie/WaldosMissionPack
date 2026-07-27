#!/usr/bin/env python3
"""Validate the structure, navigation, and local links of the WMP wiki."""

from __future__ import annotations

import re
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
WIKI = ROOT / "wiki"
USAGE_NOTE = "> **Use this page when:**"
FOOTER_MARKER = "<!-- WMP-WIKI-NAV -->"
ABSOLUTE_WIKI = "https://github.com/AdamWaldie/WaldosMissionPack/wiki/"
LINK = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")


def content_outside_fences(text: str) -> list[str]:
    lines: list[str] = []
    fenced = False
    for line in text.splitlines():
        if line.lstrip().startswith("```"):
            fenced = not fenced
            continue
        if not fenced:
            lines.append(line)
    return lines


def local_page_target(raw_target: str) -> str | None:
    target = raw_target.strip().strip("<>").split(maxsplit=1)[0]
    target = unquote(target.split("#", 1)[0])
    if not target or target.startswith(("#", "http://", "https://", "mailto:")):
        return None
    if "/" in target or "\\" in target:
        return None
    if target.endswith(".md"):
        target = target[:-3]
    return target


def audit() -> tuple[int, list[str]]:
    findings: list[str] = []
    pages = sorted(WIKI.glob("*.md"))
    content_pages = [page for page in pages if page.name != "_Sidebar.md"]
    available = {page.stem for page in content_pages}

    for page in content_pages:
        text = page.read_text(encoding="utf-8")
        lines = content_outside_fences(text)
        headings = [line for line in lines if line.startswith("# ")]

        if not text.startswith("# "):
            findings.append(f"{page.name}: page must begin with one H1 title")
        if len(headings) != 1:
            findings.append(f"{page.name}: expected one H1, found {len(headings)}")
        if USAGE_NOTE not in "\n".join(text.splitlines()[:8]):
            findings.append(f"{page.name}: missing an early 'Use this page when' summary")
        if text.count(FOOTER_MARKER) != 1:
            findings.append(f"{page.name}: expected one standard navigation footer")
        if text.count("```") % 2:
            findings.append(f"{page.name}: unbalanced fenced code block")
        if ABSOLUTE_WIKI in text:
            findings.append(f"{page.name}: use a local link instead of an absolute WMP wiki link")
        if re.search(r"!\[\s*(?:alt text|image|screenshot)\s*\]", text, re.IGNORECASE):
            findings.append(f"{page.name}: image needs descriptive alternative text")

        for match in LINK.finditer(text):
            target = local_page_target(match.group(1))
            if target is not None and target not in available:
                findings.append(f"{page.name}: unresolved local wiki page: {target}")

    sidebar = (WIKI / "_Sidebar.md").read_text(encoding="utf-8")
    if "[Bomb Defusal](Bomb-Defusal)" not in sidebar:
        findings.append("_Sidebar.md: Bomb Defusal must remain directly discoverable")
    if ABSOLUTE_WIKI in sidebar:
        findings.append("_Sidebar.md: use local links for wiki navigation")
    for match in LINK.finditer(sidebar):
        target = local_page_target(match.group(1))
        if target is not None and target not in available:
            findings.append(f"_Sidebar.md: unresolved local wiki page: {target}")

    return len(content_pages), findings


def main() -> int:
    checked, findings = audit()
    print(f"Checked {checked} wiki content page(s)")
    for finding in findings:
        print(f"ERROR: {finding}")
    if findings:
        print(f"Wiki structure validation FAILED: {len(findings)} error(s)")
        return 1
    print("Wiki structure validation PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
