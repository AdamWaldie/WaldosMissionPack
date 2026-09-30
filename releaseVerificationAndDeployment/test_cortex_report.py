import unittest
from report_cortex_audit import summarize, render_markdown

class CortexReportTests(unittest.TestCase):
    def test_pass_requires_both_completion_markers(self):
        text='WMP CORTEX QA|case|PASS|\nWMP CORTEX QA SERVER COMPLETE: 0 finding(s) []'
        self.assertEqual('INCOMPLETE', summarize({'server.rpt':text})['status'])
        self.assertEqual('PASS', summarize({'server.rpt':text,'client.rpt':'WMP CORTEX QA CLIENT COMPLETE: 0 finding(s) []'})['status'])
    def test_later_pass_cannot_hide_failure(self):
        self.assertEqual('FAIL',summarize({'x.rpt':'WMP CORTEX QA|case|FAIL|\nWMP CORTEX QA|case|PASS|'})['status'])
    def test_sqf_error_overrides_clean_summaries(self):
        text='WMP CORTEX QA|case|PASS|\nWMP CORTEX QA SERVER COMPLETE: 0 finding(s) []\nWMP CORTEX QA CLIENT COMPLETE: 0 finding(s) []\nError in expression <test>'
        self.assertEqual('FAIL',summarize({'x.rpt':text})['status'])
    def test_empty_run_is_incomplete(self):
        self.assertEqual('INCOMPLETE',summarize({})['status'])

    def test_failure_does_not_imply_completion_and_details_are_visible(self):
        report=summarize({'server.rpt':'WMP CORTEX QA|arrival|FAIL|remaining=63 m | allowed=50 m\nWMP CORTEX QA SERVER COMPLETE: 1 finding(s) []'})
        self.assertEqual('FAIL',report['status'])
        self.assertFalse(report['complete'])
        self.assertEqual(['CLIENT'],report['missing_completion'])
        rendered='\n'.join(render_markdown(report))
        self.assertIn('Run complete: **no**',rendered)
        self.assertIn('remaining=63 m \\| allowed=50 m',rendered)

    def test_failure_summary_precedes_passing_check_table(self):
        report=summarize({'server.rpt':'WMP CORTEX QA|arrival|FAIL|remaining=20 m\nWMP CORTEX QA|firing|PASS|shots=4'})
        rendered='\n'.join(render_markdown(report))
        self.assertIn('Recorded checks: 2; failed checks: 1', rendered)
        self.assertLess(rendered.index('**arrival**'), rendered.index('| Case |'))
        self.assertIn('remaining=20 m', rendered)
