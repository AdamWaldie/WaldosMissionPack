#!/usr/bin/env python3
"""
Unit tests for claude_skill_validator.py.

Run from this directory: python3 -m unittest -v test_claude_skill_validator.py
"""

import shutil
import tempfile
import unittest
from pathlib import Path

import claude_skill_validator as validator


def _write_skill(root: Path, frontmatter: str, extra_files=None):
    root.mkdir(parents=True, exist_ok=True)
    (root / "SKILL.md").write_text(f"---\n{frontmatter}\n---\n\n# Body\n", encoding="utf-8")
    for rel_path, content in (extra_files or {}).items():
        target = root / rel_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")


class ClaudeSkillValidatorTests(unittest.TestCase):
    def setUp(self):
        self.tmp_dir = Path(tempfile.mkdtemp(prefix="wmp_skill_validator_test_"))
        self.addCleanup(shutil.rmtree, self.tmp_dir, ignore_errors=True)
        self.skill_dir = self.tmp_dir / "example-skill"

    def test_valid_skill_passes(self):
        _write_skill(
            self.skill_dir,
            'name: example-skill\ndescription: A short, valid description under the length cap.',
        )
        ok, message = validator.validate_skill(self.skill_dir)
        self.assertTrue(ok, message)

    def test_description_over_1024_chars_fails(self):
        _write_skill(
            self.skill_dir,
            "name: example-skill\ndescription: " + ("x" * 1025),
        )
        ok, message = validator.validate_skill(self.skill_dir)
        self.assertFalse(ok)
        self.assertIn("1024", message)

    def test_description_at_exactly_1024_chars_passes(self):
        _write_skill(
            self.skill_dir,
            "name: example-skill\ndescription: " + ("x" * 1024),
        )
        ok, message = validator.validate_skill(self.skill_dir)
        self.assertTrue(ok, message)

    def test_unquoted_colon_in_description_is_reported_clearly(self):
        # Regression test: a bare "key: value" style clause inside an unquoted
        # description breaks YAML parsing ("mapping values are not allowed
        # here") instead of tripping the length check — this is exactly the
        # bug this validator exists to catch before it reaches claude.ai.
        _write_skill(
            self.skill_dir,
            "name: example-skill\ndescription: Covers systems: loadout, radios, and more.",
        )
        ok, message = validator.validate_skill(self.skill_dir)
        self.assertFalse(ok)
        self.assertIn("YAML", message)

    def test_disallowed_frontmatter_key_fails(self):
        _write_skill(
            self.skill_dir,
            "name: example-skill\ndescription: Valid description.\nauthor: someone",
        )
        ok, message = validator.validate_skill(self.skill_dir)
        self.assertFalse(ok)
        self.assertIn("author", message)

    def test_name_with_uppercase_fails(self):
        _write_skill(
            self.skill_dir,
            "name: Example-Skill\ndescription: Valid description.",
        )
        ok, message = validator.validate_skill(self.skill_dir)
        self.assertFalse(ok)
        self.assertIn("kebab-case", message)

    def test_missing_skill_md_fails(self):
        self.skill_dir.mkdir(parents=True)
        ok, message = validator.validate_skill(self.skill_dir)
        self.assertFalse(ok)
        self.assertIn("not found", message)

    def test_multiple_skill_md_files_fail(self):
        _write_skill(
            self.skill_dir,
            "name: example-skill\ndescription: Valid description.",
            extra_files={"references/SKILL.md": "---\nname: nested\ndescription: nested\n---\n"},
        )
        ok, message = validator.validate_skill(self.skill_dir)
        self.assertFalse(ok)
        self.assertIn("exactly one", message)

    def test_real_repo_skill_is_valid(self):
        # End-to-end guard: the actual shipped skill must always pass.
        ok, message = validator.validate_skill(validator.SKILL_DIR)
        self.assertTrue(ok, message)


if __name__ == "__main__":
    unittest.main()
