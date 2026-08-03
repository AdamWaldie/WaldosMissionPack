import tempfile
import unittest
from pathlib import Path

from build_interaction_ui_qa import remove_generated_tree
from interaction_ui_checker import EXPECTED, audit, strip_comments


ROOT = Path(__file__).resolve().parents[1]


class QaBootstrapTests(unittest.TestCase):
    def test_generated_tree_cleanup_handles_readonly_files(self):
        root = Path(tempfile.mkdtemp()) / "qa"
        root.mkdir()
        generated = root / "generated.sqf"
        generated.write_text("test", encoding="utf-8")
        generated.chmod(0o444)
        remove_generated_tree(root)
        self.assertFalse(root.exists())

    def test_scripted_bootstrap_loads_structured_text_fitter(self):
        bootstrap = (
            ROOT
            / "releaseVerificationAndDeployment"
            / "interactionEquipmentQA"
            / "InteractionEquipmentQA.VR"
            / "scriptedBootstrap.sqf"
        ).read_text(encoding="utf-8")
        self.assertIn(
            '["Waldo_fnc_MiniGameEquipmentFitStructuredText", "MissionScripts\\InteractionsMinigames\\Core\\equipmentFitStructuredText.sqf"]',
            bootstrap,
        )

    def test_automated_matrix_waits_for_real_display_cleanup(self):
        client = (
            ROOT
            / "releaseVerificationAndDeployment"
            / "interactionEquipmentQA"
            / "InteractionEquipmentQA.VR"
            / "initPlayerLocal.sqf"
        ).read_text(encoding="utf-8")
        self.assertIn('"CLEANUP", "DISPLAY_CLOSE_TIMEOUT"', client)
        self.assertIn('isNull (uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull])', client)
        self.assertNotIn('closeDisplay', client)

    def test_radio_target_band_uses_external_colour_independent_legend(self):
        source = (
            ROOT
            / "MissionScripts"
            / "InteractionsMinigames"
            / "Challenges"
            / "challengeRadioTune.sqf"
        ).read_text(encoding="utf-8")
        self.assertIn('_targetBand ctrlSetText ""', source)
        self.assertIn('BAND = TARGET // LINE = CURRENT', source)


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
        equipment = temp / "MissionScripts" / "InteractionsMinigames" / "Equipment"
        integration = temp / "MissionScripts" / "InteractionsMinigames" / "Integration"
        challenges.mkdir(parents=True)
        core.mkdir(parents=True)
        themes.mkdir(parents=True)
        equipment.mkdir(parents=True)
        integration.mkdir(parents=True)
        for name in EXPECTED:
            (challenges / name).write_text(challenge_body, encoding="utf-8")
        (temp / "MissionScripts" / "WaldosFunctions.sqf").write_text(
            "class MiniGameChallengeUI {}; class MiniGameEquipmentFitStructuredText {};",
            encoding="utf-8",
        )
        for relative in (
            core / "challengeHelp.sqf",
            equipment / "equipmentBriefing.sqf",
            integration / "equipmentPicker.sqf",
            integration / "miniGameInteractionNotifyClient.sqf",
        ):
            relative.write_text(
                'private _x = "RscStructuredText"; call Waldo_fnc_MiniGameEquipmentFitStructuredText;',
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

    def test_invalid_runtime_style_command_is_rejected(self):
        root = self.make_tree(
            'call Waldo_fnc_MiniGameChallengeUI; '
            'call Waldo_fnc_MiniGameEquipmentCreateControl; '
            '_control ctrlSetStyle 1;'
        )
        findings = audit(root)
        self.assertTrue(any("ctrlSetStyle" in item for item in findings))

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

    def test_unfitted_structured_text_is_rejected(self):
        root = self.make_tree(
            'call Waldo_fnc_MiniGameChallengeUI; '
            'call Waldo_fnc_MiniGameEquipmentCreateControl; '
            'private _type = "RscStructuredText";'
        )
        findings = audit(root)
        self.assertTrue(any("structured text has no bounded fitting path" in item for item in findings))

    def test_equipment_safezone_dimension_mixing_is_rejected(self):
        root = self.make_tree(
            'call Waldo_fnc_MiniGameChallengeUI; '
            'call Waldo_fnc_MiniGameEquipmentCreateControl;'
        )
        decorator = root / "MissionScripts" / "InteractionsMinigames" / "Equipment" / "decorator.sqf"
        decorator.write_text("private _width = 0.2 * safeZoneW;", encoding="utf-8")
        findings = audit(root)
        self.assertTrue(any("mixes raw safe-zone dimensions" in item for item in findings))


if __name__ == "__main__":
    unittest.main()
