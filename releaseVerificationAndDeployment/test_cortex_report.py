import unittest
from report_cortex_audit import summarize, render_markdown

class CortexReportTests(unittest.TestCase):
    SOURCE = 'WMP CORTEX QA SOURCE|fingerprint=' + ('a' * 64) + '\n'

    def test_pass_requires_both_completion_markers(self):
        text=self.SOURCE+'WMP CORTEX QA|case|PASS|\nWMP CORTEX QA SERVER COMPLETE: 0 finding(s) []'
        self.assertEqual('INCOMPLETE', summarize({'server.rpt':text})['status'])
        self.assertEqual('PASS', summarize({'server.rpt':text,'client.rpt':self.SOURCE+'WMP CORTEX QA CLIENT COMPLETE: 0 finding(s) []'})['status'])
    def test_later_pass_cannot_hide_failure(self):
        self.assertEqual('FAIL',summarize({'x.rpt':'WMP CORTEX QA|case|FAIL|\nWMP CORTEX QA|case|PASS|'})['status'])
    def test_sqf_error_overrides_clean_summaries(self):
        text='WMP CORTEX QA|case|PASS|\nWMP CORTEX QA SERVER COMPLETE: 0 finding(s) []\nWMP CORTEX QA CLIENT COMPLETE: 0 finding(s) []\nError in expression <test>'
        self.assertEqual('FAIL',summarize({'x.rpt':text})['status'])
    def test_empty_run_is_incomplete(self):
        self.assertEqual('INCOMPLETE',summarize({})['status'])

    def test_device_hung_is_a_bounded_fatal_failure(self):
        report=summarize({'client.rpt':'\n'.join([
            'DX11 - device removed - reason: DXGI_ERROR_DEVICE_HUNG',
            'DX11 - device removed - reason: DXGI_ERROR_DEVICE_HUNG',
            'ErrorMessage: DX11 error : buffer Map failed : DXGI_ERROR_DEVICE_REMOVED',
        ])})
        self.assertEqual('FAIL',report['status'])
        self.assertFalse(report['complete'])
        self.assertEqual(2,len(report['runtime_errors']))
        rendered='\n'.join(render_markdown(report))
        self.assertIn('Fatal runtime failures:',rendered)
        self.assertIn('DXGI_ERROR_DEVICE_HUNG',rendered)

    def test_fatal_exception_without_completion_cannot_be_incomplete(self):
        report=summarize({'client.rpt':'Exception code: 0000DEAD'})
        self.assertEqual('FAIL',report['status'])
        self.assertEqual(1,len(report['runtime_errors']))

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

    def test_evidence_without_source_fingerprint_fails(self):
        report=summarize({'server.rpt':'WMP CORTEX QA|case|PASS|\nWMP CORTEX QA SERVER COMPLETE: 0 finding(s) []'})
        self.assertEqual('FAIL',report['status'])
        self.assertIn('server.rpt',report['provenance_issues'][0])
        self.assertIn('Source provenance failures:', '\n'.join(render_markdown(report)))

    def test_conflicting_source_fingerprints_fail(self):
        other='WMP CORTEX QA SOURCE|fingerprint='+('b'*64)+'\n'
        report=summarize({
            'server.rpt':self.SOURCE+'WMP CORTEX QA|case|PASS|\nWMP CORTEX QA SERVER COMPLETE: 0 finding(s) []',
            'client.rpt':other+'WMP CORTEX QA CLIENT COMPLETE: 0 finding(s) []',
        })
        self.assertEqual('FAIL',report['status'])
        self.assertIsNone(report['source_fingerprint'])
        self.assertIn('Conflicting staged-source fingerprints',report['provenance_issues'][0])

    def test_matching_source_fingerprint_is_reported(self):
        report=summarize({'server.rpt':self.SOURCE+'WMP CORTEX QA|case|PASS|'})
        self.assertEqual('a'*64,report['source_fingerprint'])
        self.assertEqual([],report['provenance_issues'])
        self.assertIn('`'+('a'*64)+'`','\n'.join(render_markdown(report)))
