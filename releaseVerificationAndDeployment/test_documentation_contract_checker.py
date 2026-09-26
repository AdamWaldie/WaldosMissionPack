"""Regression tests for the SQF documentation header contract."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from documentation_contract_checker import SCRIPT_REQUIRED, audit_file


class ScriptHeaderTests(unittest.TestCase):
    def audit_text(self, contents: str) -> list[str]:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "example.sqf"
            path.write_text(contents, encoding="utf-8")
            return audit_file(path, SCRIPT_REQUIRED)

    def test_complete_opening_block_passes(self) -> None:
        contents = """/*
 * Author: WaldoTheWarfighter
 * Purpose: Example only.
 * Locality and authority: Server only. Repeated calls are safe; JIP reads published state.
 * Arguments: None.
 * Return Value: Boolean.
 * Current callers: initServer.sqf.
 * Example: [] call Waldo_fnc_Example;
 * Result: Returns true after setup.
 */
true
"""
        self.assertEqual([], self.audit_text(contents))

    def test_later_comments_cannot_supply_missing_header_fields(self) -> None:
        contents = """/*
 * Author: WaldoTheWarfighter
 * Purpose: Example only.
 */
/*
 * Locality and authority: Server only.
 * Arguments: None.
 * Return Value: Boolean.
 * Current callers: initServer.sqf.
 * Example: [] call Waldo_fnc_Example;
 * Result: Returns true.
 */
true
"""
        findings = self.audit_text(contents)
        self.assertIn("missing `Arguments:`", findings)
        self.assertIn("missing locality/authority", findings)

    def test_script_needs_an_opening_block(self) -> None:
        self.assertEqual(["missing opening documentation block"], self.audit_text("true"))

    def test_ai_author_is_rejected(self) -> None:
        contents = """/*
 * Author: Codex
 * Locality and authority: Server only.
 * Arguments: None.
 * Return Value: Boolean.
 * Current callers: initServer.sqf.
 * Example: [] call Waldo_fnc_Example;
 * Result: Returns true.
 */
true
"""
        self.assertIn("AI/tool names cannot be listed as authors", self.audit_text(contents))


if __name__ == "__main__":
    unittest.main()
