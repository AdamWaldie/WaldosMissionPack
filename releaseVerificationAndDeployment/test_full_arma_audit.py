import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PARSER_PATH = ROOT / "releaseVerificationAndDeployment" / "parse_full_arma_audit.py"
SPEC = importlib.util.spec_from_file_location("full_audit_parser", PARSER_PATH)
PARSER = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(PARSER)


class FullAuditTests(unittest.TestCase):
    def test_manifest_covers_every_pr(self):
        manifest_path = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "audit_manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        covered = {pr for suite in manifest["suites"] for pr in suite["prs"]}
        self.assertEqual(covered, set(range(21, 33)))

    def test_manifest_case_ids_are_unique(self):
        manifest_path = ROOT / "releaseVerificationAndDeployment" / "fullArmaAudit" / "audit_manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        cases = [case for suite in manifest["suites"] for case in suite["cases"]]
        self.assertEqual(len(cases), len(set(cases)))

    def test_parser_extracts_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            rpt = Path(directory) / "test.rpt"
            rpt.write_text('12:00 "WMP FULL AUDIT FAIL: [\'FAIL\',\'case/id\',\'bad\',1,2,true,false]"\n', encoding="utf-8")
            records = PARSER.parse(rpt)
            self.assertEqual(records[0]["kind"], "FAIL")


if __name__ == "__main__":
    unittest.main()
