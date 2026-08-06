#!/usr/bin/env python3
"""
Packages .claude/skills/mission-pack-config/ as a zip that claude.ai's own
"Upload skill" dialog will accept directly.

This is a DIFFERENT archive shape than the main
"Claude Mission Config Skill" release zip (built from config_claudeSkill.json,
include: [".claude", "LICENSE"]). That zip is meant to be unzipped into the
root of a mission project, so it deliberately keeps the ".claude/skills/
mission-pack-config/" path prefix intact. claude.ai's uploader instead wants
the skill folder ITSELF at the archive root — "<skill-name>/SKILL.md", not
"<anything>/<skill-name>/SKILL.md" — so a straight repack of the release zip
fails validation ("must contain a SKILL.md file").

This script produces that second, upload-ready shape as its own artifact.
Both are shipped: the release zip for dropping into a mission project /
Claude Code, this one for claude.ai's/the Skills API's direct upload path.

This package also deliberately contains LESS than the release zip: only
what a Claude skill itself actually is (SKILL.md plus its references/*
bundled resources, per Anthropic's own skill anatomy —
name+description frontmatter, instructions, reference files). ChatGPT's
Custom GPT entry point (chatgpt/INSTRUCTIONS.md) is a different product's
config, not part of the skill Claude loads or executes — including it here
would just be dead weight/clutter in something meant to be exactly "what
you'd want to take in as a skill." It still ships in the mission-project
release zip, where a mission maker reasonably wants both entry points
side by side.

Usage:
    python3 releaseVerificationAndDeployment/package_claude_skill_upload.py [version_tag] [output_dir]

If version_tag is omitted, the output is named "mission-pack-config.zip".
If output_dir is omitted, the file is written to the current directory.
"""

import sys
import zipfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILL_DIR = REPO_ROOT / ".claude" / "skills" / "mission-pack-config"

# Mirror package_skill.py's exclusions so this stays consistent with the
# general Anthropic skill-packaging convention (no build artifacts, no
# evals-only content shipped to end users).
EXCLUDE_DIRS = {"__pycache__", "node_modules"}
EXCLUDE_FILES = {".DS_Store"}
# Excluded only at the skill root (not if a reference file elsewhere happens
# to sit under a same-named directory) — mirrors package_skill.py's handling
# of "evals". "chatgpt" is Custom GPT instructions for an entirely different
# product; it isn't part of what Claude loads as this skill.
ROOT_EXCLUDE_DIRS = {"chatgpt"}


def _should_exclude(rel_path: Path) -> bool:
    # rel_path is relative to skill_dir.parent, so parts[0] is the skill
    # folder name and parts[1] (if present) is the first subdir under it.
    parts = rel_path.parts
    if any(part in EXCLUDE_DIRS for part in parts):
        return True
    if len(parts) > 1 and parts[1] in ROOT_EXCLUDE_DIRS:
        return True
    return rel_path.name in EXCLUDE_FILES


def package(skill_dir: Path, output_path: Path):
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        print(f"ERROR: SKILL.md not found in {skill_dir}")
        sys.exit(1)

    # Run the same validation claude.ai applies before packaging — fail the
    # build here rather than ship a zip that's guaranteed to be rejected on
    # upload. Import lazily so this script's own --help/usage still works
    # without PyYAML installed.
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import claude_skill_validator as validator

    ok, message = validator.validate_skill(skill_dir)
    print(f"Validating skill package: {message}")
    if not ok:
        print("ERROR: refusing to package an invalid skill. Fix the issue above first.")
        sys.exit(1)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for file_path in sorted(skill_dir.rglob("*")):
            if not file_path.is_file():
                continue
            # arcname is relative to the skill folder's PARENT, so the skill
            # folder name itself becomes the single top-level directory in
            # the zip — the shape claude.ai's uploader requires.
            rel_path = file_path.relative_to(skill_dir.parent)
            if _should_exclude(rel_path):
                continue
            # The ZIP format requires forward slashes as directory separators
            # regardless of host OS. On Windows, rel_path is a WindowsPath,
            # and passing it (or str(rel_path)) straight to ZipFile.write
            # writes arcnames with backslashes instead - the zip has no real
            # subdirectories at all, just filenames containing a literal "\"
            # character. Every real folder structure in the archive (the
            # skill's own "<name>/SKILL.md" root, "<name>/references/...")
            # silently collapses, which is exactly what a strict reader like
            # claude.ai's uploader rejects ("skill not at root" even though
            # every file is technically present). as_posix() forces forward
            # slashes on every platform, matching what this script already
            # verified correctly on Linux/macOS by coincidence of using the
            # native separator there.
            zf.write(file_path, rel_path.as_posix())

    print(f"Wrote claude.ai-upload-ready skill package: {output_path}")


def main():
    version_tag = sys.argv[1] if len(sys.argv) > 1 else None
    output_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else Path.cwd()

    name = "mission-pack-config"
    filename = f"{name}-{version_tag}.zip" if version_tag else f"{name}.zip"
    package(SKILL_DIR, output_dir / filename)


if __name__ == "__main__":
    main()
