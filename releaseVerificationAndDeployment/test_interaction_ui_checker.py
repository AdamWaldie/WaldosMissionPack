import tempfile
import unittest
from pathlib import Path

from interaction_ui_checker import EXPECTED, audit, strip_comments


class CommentStripTests(unittest.TestCase):
    def test_comments_do_not_trigger_guardrails(self):
        source = '/* safeZoneW ctrlCreate */\nprivate _text = "safeZone string"; // ctrlCreate\n'
        stripped = strip_comments(source)
        self.assertNotIn("/* safeZoneW", stripped)
        self.assertIn('"safeZone string"', stripped)


class AuditFixtureTests(unittest.TestCase):
    def make_tree(self, challenge_body: str) -> Path:
        temp = Path(tempfile.mkdtemp())
        challenges = temp / "MissionScripts" / "InteractionsMinigames" / "Challenges"
        core = temp / "MissionScripts" / "InteractionsMinigames" / "Core"
        themes = temp / "MissionScripts" / "InteractionsMinigames" / "Themes"
        challenges.mkdir(parents=True)
        core.mkdir(parents=True)
        themes.mkdir(parents=True)
        for name in EXPECTED:
            (challenges / name).write_text(challenge_body, encoding="utf-8")
        (temp / "MissionScripts" / "WaldosFunctions.sqf").write_text(
            "class MiniGameChallengeUI {};",
            encoding="utf-8",
        )
        difficulty_cases = " ".join(
            f'case "{name}" {{}};'
            for name in (
                "wirecut",
                "minesweeper",
                "keypad",
                "lockpick",
                "circuit",
                "repair",
                "radiotune",
                "pressure",
                "sequence",
                "commandinput",
            )
        )
        (themes / "equipmentDifficultyConfig.sqf").write_text(
            'private _levels = ["easy", "standard", "hard", "expert"]; '
            + difficulty_cases,
            encoding="utf-8",
        )
        return temp

    def test_compliant_fixture(self):
        root = self.make_tree(
            'call Waldo_fnc_MiniGameChallengeUI; '
            'call Waldo_fnc_MiniGameEquipmentCreateControl;'
        )
        self.assertEqual([], audit(root))

    def test_raw_safezone_and_direct_control_are_rejected(self):
        root = self.make_tree(
            'call Waldo_fnc_MiniGameChallengeUI; '
            'call Waldo_fnc_MiniGameEquipmentCreateControl; '
            'private _x = safeZoneW; _display ctrlCreate ["RscText", -1];'
        )
        findings = audit(root)
        self.assertTrue(any("safe-zone" in finding for finding in findings))
        self.assertTrue(any("bypasses" in finding for finding in findings))

    def test_unparenthesized_conditional_command_operand_is_rejected(self):
        root = self.make_tree(
            'call Waldo_fnc_MiniGameChallengeUI; '
            'call Waldo_fnc_MiniGameEquipmentCreateControl; '
            '_control ctrlSetText if (_ready) then {"READY"} else {"WAIT"};'
        )
        findings = audit(root)
        self.assertTrue(any("conditional command operand" in item for item in findings))

    def test_literal_newline_escape_in_challenge_text_is_rejected(self):
        root = self.make_tree(
            'call Waldo_fnc_MiniGameChallengeUI; '
            'call Waldo_fnc_MiniGameEquipmentCreateControl; '
            '_control ctrlSetText "LINE ONE\\nLINE TWO";'
        )
        findings = audit(root)
        self.assertTrue(any("literal \\n escape" in item for item in findings))

    def test_missing_canonical_difficulty_helper_is_rejected(self):
        root = self.make_tree(
            'call Waldo_fnc_MiniGameChallengeUI; '
            'call Waldo_fnc_MiniGameEquipmentCreateControl;'
        )
        (
            root
            / "MissionScripts"
            / "InteractionsMinigames"
            / "Themes"
            / "equipmentDifficultyConfig.sqf"
        ).unlink()
        findings = audit(root)
        self.assertTrue(any("difficulty helper is missing" in item for item in findings))


if __name__ == "__main__":
    unittest.main()
