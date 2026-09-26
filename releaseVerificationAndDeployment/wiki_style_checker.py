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
IMAGE = re.compile(r"!\[[^\]]*\]\(([^)]+)\)")

# These entries in the feature index are navigation hubs or general references,
# not one-feature guides. Every other indexed entry must resolve to its own page.
INDEX_HUBS = {
    "Feature-Catalogue",
    "Feature-Setup-and-Activation",
    "Mission-Configuration-Reference",
    "Waldos-Economy-Systems",
    "Waldos-Mini-Games",
    "Optional-Feature-Systems",
    "Optional-Feature-Extensions",
}

REQUIRED_STANDALONE = {
    "ACE-Vehicle-Services", "ACE-Cargo-And-Object-Handling", "Quartermaster", "Base-Services",
    "Supply-Transfers", "Physical-Cargo", "Field-Resupply", "Tactical-Display",
    "Treatment-Feedback", "Hazardous-Environments", "Tree-Felling",
    "Emergency-Dismount", "Explosive-Breaching", "Object-Scaling", "WMP-HUD",
    "EMP-Burst", "Signal-Trackers",
}

# These are player-facing feature guides with independent setup paths. Add a new
# feature here when it enters Feature-Tutorials.md; the checker then requires a
# navigable page with setup, reference, and fault-finding sections. Hub and
# reference pages are deliberately outside this list.
FEATURE_GUIDES = {
    "ACE-Vehicle-Services", "ACE-Cargo-And-Object-Handling",
    "ACE-Corpse-Traps",
    "Base-Services",
    "Improved-AI-Helicopter-Landings",
    "Mobile-Command-Post-With-Integrated-Logistics-System",
    "Physical-Cargo",
    "Quartermaster",
    "Radio-Jamming",
    "Supply-Transfers",
    "Field-Resupply",
    "Tactical-Display",
    "Treatment-Feedback",
    "Hazardous-Environments",
    "Tree-Felling",
    "Emergency-Dismount",
    "Explosive-Breaching",
    "Object-Scaling",
    "UI-Visual-Themes",
}

GUIDE_SECTIONS = {
    "setup": re.compile(r"^## (?:Before|Enable|Set |Start |Place |Try |The quickest|Change an object|Setup|Quick|Create a first|Scale one)", re.I | re.M),
    "reference": re.compile(r"^## (?:Script|Settings|Parameters|Choose|Change crate|Mission-wide|Mission extensions|The jamming model|Configuration|Set handling|WMP-created|Supported Throwables|Seats covered|Calls and settings|Change access|Change the result|Choose the safety|Choose the cards|Change the player|Configure another|Limits and placement)", re.I | re.M),
    "limits": re.compile(r"^## (?:If |During play and troubleshooting|Engine boundaries|Carrying cargo away|Limitations|Runtime and troubleshooting|Salvage and troubleshooting|Remove or diagnose)", re.I | re.M),
    "related": re.compile(r"^## See also\s*$", re.I | re.M),
}
INDEXED_LIMITS = re.compile(
    r"^## (?:If |Troubleshooting|Diagnostics|Limitations|Known Limitations|"
    r"Notes and limitations|Runtime|Salvage|Remove or diagnose|During play|"
    r"Engine boundaries|Safety model|Beginner troubleshooting)",
    re.I | re.M,
)

# These were real mission-maker instructions or screenshots from prior pack
# layouts. Their return is a documentation regression, even if links still work.
STALE_SETUP = {
    "Set the classnames in `initServer.sqf`": "crate classes belong in MissionConfig/logisticsConfig.sqf",
    "Waldo_Jamming_DisableResult\", \"DEACTIVATE": "jammer disable mode is DISABLE or DESTROY",
    "Mission Pack v4.8.0": "remove an obsolete mission-title example",
    "https://i.imgur.com/0CdEY8U.png": "remove the obsolete initServer crate screenshot",
    'Extend `Waldo_Paradrop_BoardingPointClasses` in `init.sqf`': "edit the air-operations config instead",
    'set `Waldo_EmergencyDismount_Enable` to `true` in `MissionConfig\\environmentConfig.sqf`': "emergency dismount belongs in interfaceConfig.sqf",
    '`Waldo_SafeStart_Radius` defaults to 75 m': "SafeStart radius now defaults to 150 m",
    '`Waldo_SafeStart_Confine` | `true`': "SafeStart confinement is off by default",
    '`MissionConfig/missionSystemsConfig.sqf` if your mission requires a different allowed range': "object scaling limits belong in logisticsConfig.sqf",
}


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
    index = (WIKI / "Feature-Tutorials.md").read_text(encoding="utf-8")
    indexed_targets = [
        local_page_target(match.group(1))
        for line in index.splitlines()
        if line.startswith("| [")
        for match in LINK.finditer(line)
    ]
    indexed_targets = [target for target in indexed_targets if target is not None]
    indexed_features = set(indexed_targets) - INDEX_HUBS
    for target in sorted(set(indexed_targets)):
        if indexed_targets.count(target) > 1:
            findings.append(f"Feature-Tutorials.md: {target} is used for more than one feature entry")
    for target in sorted(REQUIRED_STANDALONE):
        if target not in indexed_features or target not in available:
            findings.append(f"Feature-Tutorials.md: {target} needs a dedicated, indexed feature page")

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
        for image in IMAGE.finditer(text):
            target = image.group(1)
            if target.startswith(("http://", "https://")) and not (
                page.name == "Home.md" and target.endswith("/Pictures/loading.jpg?raw=true")
            ):
                findings.append(f"{page.name}: use a reviewed repository-owned image, not an external screenshot: {target}")

        for stale, reason in STALE_SETUP.items():
            if stale in text:
                findings.append(f"{page.name}: stale setup: {reason}")

        if page.stem in indexed_features:
            first_section = re.split(r"^## ", text, maxsplit=1, flags=re.M)[0]
            overview = first_section.split(USAGE_NOTE, 1)[-1].strip()
            if len(overview) < 100:
                findings.append(f"{page.name}: add a plain-English overview before setup")
            if not GUIDE_SECTIONS["related"].search(text):
                findings.append(f"{page.name}: indexed feature needs a See also section")
            related = text.split("## See also", 1)[-1].split(FOOTER_MARKER, 1)[0]
            if related == text or not LINK.search(related):
                findings.append(f"{page.name}: See also needs a relevant local page link")
            if not INDEXED_LIMITS.search(text):
                findings.append(f"{page.name}: indexed feature needs troubleshooting or engine limits")

        if page.stem in FEATURE_GUIDES:
            if page.stem not in indexed_targets:
                findings.append(f"{page.name}: dedicated feature guide is missing from Feature-Tutorials.md")
            for section, pattern in GUIDE_SECTIONS.items():
                if not pattern.search(text):
                    findings.append(f"{page.name}: missing {section} section required by the Wiki Page Standard")

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
