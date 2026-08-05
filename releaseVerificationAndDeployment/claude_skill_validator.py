#!/usr/bin/env python3
"""
Validates .claude/skills/mission-pack-config/ against the same packaging
contract claude.ai's own "Upload skill" dialog enforces, so a bad SKILL.md
frontmatter (or a stray extra SKILL.md) fails CI instead of failing silently
on upload weeks later.

This mirrors the checks in Anthropic's skill-creator quick_validate.py:
  - exactly one SKILL.md, at <skill-folder>/SKILL.md
  - YAML frontmatter present and parseable
  - only 'name', 'description', 'license', 'allowed-tools', 'metadata',
    'compatibility' keys allowed
  - name: non-empty, kebab-case, <= 64 characters
  - description: non-empty, no angle brackets, <= 1024 characters
  - compatibility (if present): <= 500 characters

Run directly: python3 releaseVerificationAndDeployment/claude_skill_validator.py
Exits non-zero with a message on the first failure found.
"""

import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print(
        "ERROR: PyYAML is required to validate SKILL.md frontmatter "
        "(pip install -r releaseVerificationAndDeployment/requirements.txt)."
    )
    sys.exit(1)

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILL_DIR = REPO_ROOT / ".claude" / "skills" / "mission-pack-config"

ALLOWED_PROPERTIES = {"name", "description", "license", "allowed-tools", "metadata", "compatibility"}
MAX_NAME_LEN = 64
MAX_DESCRIPTION_LEN = 1024
MAX_COMPATIBILITY_LEN = 500


def validate_skill(skill_path: Path):
    """Returns (ok: bool, message: str)."""
    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        return False, f"SKILL.md not found at {skill_md}"

    skill_md_files = sorted(skill_path.rglob("SKILL.md"))
    if len(skill_md_files) > 1:
        extras = [str(p.relative_to(skill_path)) for p in skill_md_files if p != skill_md]
        return False, (
            f"Found {len(skill_md_files)} SKILL.md files under {skill_path}, but claude.ai's "
            f"uploader accepts exactly one, at <folder>/SKILL.md. Extra: {', '.join(extras)}"
        )

    content = skill_md.read_text(encoding="utf-8")
    if not content.startswith("---"):
        return False, "SKILL.md has no YAML frontmatter (must start with '---')"

    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return False, "SKILL.md frontmatter is not closed with a second '---' line"

    frontmatter_text = match.group(1)
    try:
        frontmatter = yaml.safe_load(frontmatter_text)
    except yaml.YAMLError as exc:
        return False, (
            f"SKILL.md frontmatter is not valid YAML: {exc}\n"
            "  A common cause: an unquoted ':' followed by a space inside the description "
            "(YAML reads that as a new mapping key). Use an em dash (—) or quote the string instead."
        )

    if not isinstance(frontmatter, dict):
        return False, "SKILL.md frontmatter must parse to a YAML mapping"

    unexpected = set(frontmatter.keys()) - ALLOWED_PROPERTIES
    if unexpected:
        return False, (
            f"SKILL.md frontmatter has unexpected key(s): {', '.join(sorted(unexpected))}. "
            f"Allowed: {', '.join(sorted(ALLOWED_PROPERTIES))}"
        )

    name = frontmatter.get("name", "")
    if not isinstance(name, str) or not name.strip():
        return False, "SKILL.md frontmatter is missing a non-empty 'name'"
    name = name.strip()
    if not re.match(r"^[a-z0-9-]+$", name) or name.startswith("-") or name.endswith("-") or "--" in name:
        return False, f"name '{name}' must be kebab-case (lowercase letters, digits, single hyphens)"
    if len(name) > MAX_NAME_LEN:
        return False, f"name is {len(name)} characters; claude.ai's cap is {MAX_NAME_LEN}"

    description = frontmatter.get("description", "")
    if not isinstance(description, str) or not description.strip():
        return False, "SKILL.md frontmatter is missing a non-empty 'description'"
    description = description.strip()
    if "<" in description or ">" in description:
        return False, "description cannot contain angle brackets ('<' or '>')"
    if len(description) > MAX_DESCRIPTION_LEN:
        return False, (
            f"description is {len(description)} characters; claude.ai's upload cap is "
            f"{MAX_DESCRIPTION_LEN}. Trim it — see SKILL.md's frontmatter."
        )

    compatibility = frontmatter.get("compatibility", "")
    if compatibility:
        if not isinstance(compatibility, str):
            return False, "compatibility must be a string"
        if len(compatibility) > MAX_COMPATIBILITY_LEN:
            return False, (
                f"compatibility is {len(compatibility)} characters; the cap is {MAX_COMPATIBILITY_LEN}"
            )

    return True, f"OK — name={len(name)}/{MAX_NAME_LEN} chars, description={len(description)}/{MAX_DESCRIPTION_LEN} chars"


def main():
    if not SKILL_DIR.exists():
        print(f"ERROR: skill directory not found: {SKILL_DIR}")
        sys.exit(1)

    ok, message = validate_skill(SKILL_DIR)
    print(message)
    if not ok:
        sys.exit(1)


if __name__ == "__main__":
    main()
