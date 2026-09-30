"""Summarize real Cortex RPT evidence without treating missing completion as success."""
from pathlib import Path
import argparse
import json
import re

CASE = re.compile(r"WMP CORTEX QA\|([^|]+)\|(PASS|FAIL)\|([^\r\n]*)")
DONE = re.compile(r"WMP CORTEX QA (SERVER|CLIENT) COMPLETE: (\d+) finding")
ERROR = re.compile(r"Error in expression|Error position:|Error Undefined variable|Error Missing", re.I)

def summarize(logs):
    cases = []
    completed = {}
    errors = []
    for name, content in logs.items():
        for number, line in enumerate(content.splitlines(), 1):
            match = CASE.search(line)
            if match:
                cases.append(dict(case=match[1], result=match[2], detail=match[3].rstrip('"'), log=name, line=number))
            match = DONE.search(line)
            if match:
                completed[match[1]] = max(completed.get(match[1], 0), int(match[2]))
            if ERROR.search(line):
                errors.append(dict(log=name, line=number, message=line))
    failed = any(case['result'] == 'FAIL' for case in cases) or bool(errors) or any(completed.values())
    complete = set(completed) == {'SERVER', 'CLIENT'} and bool(cases)
    return dict(status='FAIL' if failed else ('PASS' if complete else 'INCOMPLETE'), complete=complete, missing_completion=sorted({'SERVER', 'CLIENT'} - set(completed)), completed=completed, cases=cases, errors=errors)

def attach_assessments(report, assessments):
    """Attach evidence-backed review without changing assertion or run outcomes."""
    categories = {'functional_failure', 'partial_success', 'test_problem', 'unresolved'}
    known = {case['case'] for case in report['cases']}
    reviewed = []
    for case_id, review in assessments.items():
        if case_id not in known:
            raise ValueError(f'Assessment references an unrecorded case: {case_id}')
        if review.get('category') not in categories:
            raise ValueError(f'Invalid assessment category: {case_id}')
        if not all(isinstance(review.get(key), str) and review[key].strip() for key in ('reason', 'evidence')):
            raise ValueError(f'Assessment requires reason and evidence: {case_id}')
        reviewed.append(dict(case=case_id, **review))
    report['assessments'] = reviewed
    return report


def render_markdown(report):
    # RPT measurements may contain pipes; keep them inside their table cell.
    def cell(value):
        return str(value).replace('\\', '\\\\').replace('|', '\\|').replace('\n', ' ')
    lines = ['# Cortex audit results', '', f"Result: **{report['status']}**", '',
             'This result covers only the recorded cases. It does not establish untested combat scenarios, mouse operation or every UI layout.', '',
             f"Run complete: **{'yes' if report['complete'] else 'no'}**. Missing completion markers: {', '.join(report['missing_completion']) or 'none'}.", '',
             f"Completion markers: {report['completed']}", '', '| Case | Result | Measurements | Evidence |', '| --- | --- | --- | --- |']
    # Keep failures visible even when the final few checks happen to pass.
    failed_cases = [case for case in report['cases'] if case['result'] == 'FAIL']
    summary = [f"Recorded checks: {len(report['cases'])}; failed checks: {len(failed_cases)}. Passing subchecks do not establish a completed manoeuvre.", '']
    if failed_cases:
        summary += ['Failed checks:', '']
        summary += [f"- **{cell(case['case'])}**: {cell(case['detail']) or 'No measurement recorded'} ({cell(case['log'])}:{case['line']})" for case in failed_cases]
        summary += ['']
    lines[4:4] = summary
    assessments = report.get('assessments', [])
    reviewed_ids = {item['case'] for item in assessments}
    unreviewed = sorted({case['case'] for case in failed_cases} - reviewed_ids)
    counts = {category: sum(item['category'] == category for item in assessments)
              for category in ('functional_failure', 'partial_success', 'test_problem', 'unresolved')}
    lines[4:4] = [
        'Review coverage: ' + ', '.join(f"{category.replace('_', ' ')}: {count}" for category, count in counts.items()) + '.',
        f"Failed case IDs awaiting evidence review: {len(unreviewed)}. These are unresolved, not automatically confirmed feature failures.",
        '',
    ]
    if assessments:
        review_lines = ['Behaviour review (does not override recorded checks):', '',
                        '| Case | Assessment | Reason | Supporting evidence |', '| --- | --- | --- | --- |']
        review_lines += [f"| {cell(item['case'])} | {cell(item['category'])} | {cell(item['reason'])} | {cell(item['evidence'])} |" for item in assessments]
        lines[4:4] = review_lines + ['']
    lines[4:4] = ['A failed assertion is not automatically a broken feature. Review physical results to distinguish functional failure, partial success and a test problem. Unreviewed failures remain unresolved; deadlines alone do not establish a stall.', '']
    for case in report['cases']:
        lines.append(f"| {cell(case['case'])} | {case['result']} | {cell(case['detail']) or '—'} | {cell(case['log'])}:{case['line']} |")
    if report['errors']:
        lines += ['', 'SQF errors:', ''] + [f"- {error['log']}:{error['line']}: {error['message']}" for error in report['errors']]
    return lines

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('runtime', type=Path)
    parser.add_argument('--assessments', type=Path, help='JSON mapping recorded case IDs to category, reason and evidence')
    args = parser.parse_args()
    root = args.runtime.resolve()
    logs = {str(path.relative_to(root)): path.read_text(encoding='utf-8', errors='replace') for path in root.rglob('*.rpt')}
    report = summarize(logs)
    if args.assessments:
        attach_assessments(report, json.loads(args.assessments.read_text(encoding='utf-8')))
    (root/'cortex-results.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    lines = render_markdown(report)
    (root/'cortex-results.md').write_text('\n'.join(lines)+'\n', encoding='utf-8')
    print(f"Cortex audit: {report['status']}; {len(report['cases'])} checks, {len(report['errors'])} SQF error lines; run complete={report['complete']}. Report: {root/'cortex-results.md'}")
    return 0 if report['status'] == 'PASS' else 1

if __name__ == '__main__':
    raise SystemExit(main())
