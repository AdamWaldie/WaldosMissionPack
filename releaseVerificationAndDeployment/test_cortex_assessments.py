"""Review annotations must never turn a failed physical assertion into a pass."""
import unittest
from report_cortex_audit import summarize, attach_assessments, render_markdown

class AssessmentTests(unittest.TestCase):
    def test_review_preserves_failure(self):
        report = summarize({'server.rpt': 'WMP CORTEX QA|advance-deadline|FAIL|travel=80'})
        attach_assessments(report, {'advance-deadline': {'category': 'partial_success', 'reason': 'Movement occurred; completion unproved', 'evidence': 'server.rpt:1 travel=80'}})
        self.assertEqual(report['status'], 'FAIL')
        self.assertEqual(report['cases'][0]['result'], 'FAIL')
        self.assertIn('partial_success', '\n'.join(render_markdown(report)))

    def test_unrecorded_case_rejected(self):
        with self.assertRaises(ValueError):
            attach_assessments(summarize({}), {'missing': {}})

    def test_evidence_required(self):
        report = summarize({'rpt': 'WMP CORTEX QA|case|FAIL|'})
        with self.assertRaises(ValueError):
            attach_assessments(report, {'case': {'category': 'test_problem', 'reason': 'Suspected timeout'}})

    def test_unreviewed_failure_is_not_classified_as_broken_feature(self):
        report = summarize({'server.rpt': 'WMP CORTEX QA|arrival|FAIL|travel=80'})
        rendered = '\n'.join(render_markdown(report))
        self.assertIn('functional failure: 0', rendered)
        self.assertIn('Failed case IDs awaiting evidence review: 1', rendered)
        self.assertEqual(report['status'], 'FAIL')

    def test_partial_review_reduces_unreviewed_count_without_hiding_failure(self):
        report = summarize({'server.rpt': 'WMP CORTEX QA|arrival|FAIL|travel=80'})
        attach_assessments(report, {'arrival': {'category': 'partial_success',
            'reason': 'Moved but did not reach the destination', 'evidence': 'server.rpt:1 travel=80'}})
        rendered = '\n'.join(render_markdown(report))
        self.assertIn('partial success: 1', rendered)
        self.assertIn('Failed case IDs awaiting evidence review: 0', rendered)
        self.assertIn('Failed checks:', rendered)
