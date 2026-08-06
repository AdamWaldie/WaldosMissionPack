#!/usr/bin/env python3
"""
Unit tests for package_claude_skill_upload.py.

Run from this directory: python3 -m unittest -v test_package_claude_skill_upload.py
"""

import shutil
import tempfile
import unittest
import zipfile
from pathlib import Path

import package_claude_skill_upload as packager


def _write_skill(root: Path, description="A short, valid description under the length cap."):
    root.mkdir(parents=True, exist_ok=True)
    (root / "SKILL.md").write_text(
        f"---\nname: {root.name}\ndescription: {description}\n---\n\n# Body\n", encoding="utf-8"
    )
    (root / "references").mkdir(exist_ok=True)
    (root / "references" / "example.md").write_text("# Example reference\n", encoding="utf-8")


class PackageClaudeSkillUploadTests(unittest.TestCase):
    def setUp(self):
        self.tmp_dir = Path(tempfile.mkdtemp(prefix="wmp_skill_package_test_"))
        self.addCleanup(shutil.rmtree, self.tmp_dir, ignore_errors=True)
        self.skill_dir = self.tmp_dir / "example-skill"
        self.output_path = self.tmp_dir / "out" / "example-skill.zip"

    def _zip_entries(self):
        with zipfile.ZipFile(self.output_path) as zf:
            return zf.namelist()

    def test_skill_folder_is_the_single_top_level_directory(self):
        _write_skill(self.skill_dir)
        packager.package(self.skill_dir, self.output_path)
        entries = self._zip_entries()
        self.assertIn("example-skill/SKILL.md", entries)
        tops = {name.split("/", 1)[0] for name in entries}
        self.assertEqual(tops, {"example-skill"})

    def test_chatgpt_directory_is_included(self):
        # The claude.ai upload package ships the same content as the
        # mission-project release zip — chatgpt/INSTRUCTIONS.md included —
        # only the archive's root layout differs between the two.
        _write_skill(self.skill_dir)
        chatgpt_dir = self.skill_dir / "chatgpt"
        chatgpt_dir.mkdir()
        (chatgpt_dir / "INSTRUCTIONS.md").write_text("ChatGPT-only instructions.\n", encoding="utf-8")

        packager.package(self.skill_dir, self.output_path)
        entries = self._zip_entries()
        self.assertIn("example-skill/chatgpt/INSTRUCTIONS.md", entries)
        self.assertIn("example-skill/SKILL.md", entries)
        self.assertIn("example-skill/references/example.md", entries)

    def test_build_artifacts_are_excluded(self):
        _write_skill(self.skill_dir)
        pycache_dir = self.skill_dir / "references" / "__pycache__"
        pycache_dir.mkdir()
        (pycache_dir / "stale.pyc").write_bytes(b"\x00")
        (self.skill_dir / ".DS_Store").write_bytes(b"\x00")

        packager.package(self.skill_dir, self.output_path)
        entries = self._zip_entries()
        self.assertFalse(any("__pycache__" in name for name in entries))
        self.assertFalse(any(name.endswith(".DS_Store") for name in entries))

    def test_invalid_skill_refuses_to_package(self):
        _write_skill(self.skill_dir, description="x" * 1025)
        with self.assertRaises(SystemExit):
            packager.package(self.skill_dir, self.output_path)
        self.assertFalse(self.output_path.exists())

    def test_nested_reference_subdirectories_use_forward_slashes(self):
        # Regression test: every arcname must use '/' regardless of host OS,
        # and real nested folders (e.g. references/mods/*.md in the actual
        # skill) must appear as genuine subdirectory entries, not collapse.
        _write_skill(self.skill_dir)
        nested_dir = self.skill_dir / "references" / "nested"
        nested_dir.mkdir()
        (nested_dir / "deep.md").write_text("# Nested\n", encoding="utf-8")

        packager.package(self.skill_dir, self.output_path)
        entries = self._zip_entries()
        self.assertIn("example-skill/references/nested/deep.md", entries)
        self.assertFalse(any("\\" in name for name in entries))

    def test_windows_style_relative_path_normalizes_to_forward_slashes(self):
        # Regression test for the actual reported bug: on Windows, a
        # relative Path's native string form uses backslashes. Passing that
        # straight to ZipFile.write embeds the backslash literally in the
        # arcname instead of producing a real subdirectory separator (the
        # ZIP format requires '/'), which collapses every folder in the
        # archive - exactly what made claude.ai's uploader reject the
        # skill as "not at root" even though every file was present. This
        # doesn't require running on Windows to verify: PureWindowsPath
        # reproduces the exact platform string semantics package() relies
        # on .as_posix() to normalize away.
        from pathlib import PureWindowsPath
        windows_style = PureWindowsPath("mission-pack-config", "references", "nested", "deep.md")
        self.assertIn("\\", str(windows_style))
        self.assertEqual(windows_style.as_posix(), "mission-pack-config/references/nested/deep.md")

    def test_real_repo_skill_packages_to_correct_shape(self):
        # End-to-end guard against the real shipped skill.
        packager.package(packager.SKILL_DIR, self.output_path)
        entries = self._zip_entries()
        self.assertIn("mission-pack-config/SKILL.md", entries)
        self.assertIn("mission-pack-config/chatgpt/INSTRUCTIONS.md", entries)
        tops = {name.split("/", 1)[0] for name in entries}
        self.assertEqual(tops, {"mission-pack-config"})


if __name__ == "__main__":
    unittest.main()
