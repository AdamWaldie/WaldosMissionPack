import tempfile
import unittest
from pathlib import Path

import performance_audit


class PerformanceAuditTests(unittest.TestCase):
    def test_comments_and_strings_do_not_create_findings(self):
        source = '''
        // while {true} do { allPlayers; remoteExec ["bad", 2]; };
        private _text = "while {true} do { allMissionObjects; };";
        /* while {true} do { uiSleep 0.1; allUnits; }; */
        '''
        self.assertEqual(performance_audit.audit_source(source, "sample.sqf"), [])

    def test_tight_unbounded_loop_is_high_severity(self):
        source = "Waldo_fnc_Test = { while {true} do { call Waldo_fnc_Work; }; };"
        findings = performance_audit.audit_source(source, "sample.sqf")
        categories = {(item.category, item.severity) for item in findings}
        self.assertIn(("unbounded_scheduler", "high"), categories)
        self.assertIn(("tight_loop", "high"), categories)

    def test_recurring_scan_and_broadcast_are_attributed(self):
        source = '''
        Waldo_fnc_Test = {
            while {missionNamespace getVariable ["Running", false]} do {
                { _x setVariable ["Ready", true, true]; } forEach allPlayers;
                uiSleep 0.25;
            };
        };
        '''
        findings = performance_audit.audit_source(source, "MissionScripts/Test.sqf")
        keyed = {(item.category, item.function) for item in findings}
        self.assertIn(("recurring_world_scan", "Waldo_fnc_Test"), keyed)
        self.assertIn(("recurring_broadcast", "Waldo_fnc_Test"), keyed)

    def test_finite_algorithm_loop_is_not_treated_as_scheduler(self):
        source = "while {(count _deck) > 0} do { _deck deleteAt 0; };"
        self.assertEqual(performance_audit.audit_source(source, "cards.sqf"), [])

    def test_symbolic_sleep_prevents_tight_loop_finding(self):
        source = "Waldo_fnc_Test = { while {true} do { sleep Waldo_CFG_TICK; }; };"
        findings = performance_audit.audit_source(source, "sample.sqf")
        self.assertNotIn("tight_loop", {item.category for item in findings})

    def test_refresh_call_in_fast_loop_is_reported(self):
        source = '''
        Waldo_fnc_Open = {
            while {!isNull _display} do {
                [_display] call Waldo_fnc_RefreshPanel;
                uiSleep 0.1;
            };
        };
        '''
        findings = performance_audit.audit_source(source, "sample.sqf")
        self.assertIn("high_frequency_ui_refresh", {item.category for item in findings})

    def test_baseline_rejects_expansion(self):
        finding = performance_audit.Finding(
            "recurring_broadcast", "high", "a.sqf", "Waldo_fnc_A", 2, (2, 3), "test"
        )
        with tempfile.TemporaryDirectory() as directory:
            baseline = Path(directory) / "baseline.json"
            baseline.write_text(
                '{"accepted":[{"key":"recurring_broadcast|a.sqf|Waldo_fnc_A|test",'
                '"max_count":1,"reason":"state is change-gated"}]}'
            )
            self.assertEqual(performance_audit.evaluate([finding], baseline), [finding])

    def test_baseline_rejects_placeholder_reason(self):
        finding = performance_audit.Finding(
            "recurring_broadcast", "high", "a.sqf", "Waldo_fnc_A", 1, (2,), "test"
        )
        with tempfile.TemporaryDirectory() as directory:
            baseline = Path(directory) / "baseline.json"
            baseline.write_text(
                '{"accepted":[{"key":"recurring_broadcast|a.sqf|Waldo_fnc_A|test",'
                '"max_count":1,"reason":"REVIEW REQUIRED: explain this."}]}'
            )
            self.assertEqual(performance_audit.evaluate([finding], baseline), [finding])


if __name__ == "__main__":
    unittest.main()
