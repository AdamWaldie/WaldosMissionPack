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


def _should_exclude(rel_path: Path) -> bool:
    if any(part in EXCLUDE_DIRS for part in rel_path.parts):
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
            zf.write(file_path, rel_path)

    print(f"Wrote claude.ai-upload-ready skill package: {output_path}")


def main():
    version_tag = sys.argv[1] if len(sys.argv) > 1 else None
    output_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else Path.cwd()

    name = "mission-pack-config"
    filename = f"{name}-{version_tag}.zip" if version_tag else f"{name}.zip"
    package(SKILL_DIR, output_dir / filename)


if __name__ == "__main__":
    main()
