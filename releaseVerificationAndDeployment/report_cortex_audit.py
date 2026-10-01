"""Summarize real Cortex RPT evidence without treating missing completion as success."""
from pathlib import Path
import argparse
import json
import re

CASE = re.compile(r"WMP CORTEX QA\|([^|]+)\|(PASS|FAIL)\|([^\r\n]*)")
DONE = re.compile(r"WMP CORTEX QA (SERVER|CLIENT) COMPLETE: (\d+) finding")
SOURCE = re.compile(r"WMP CORTEX QA SOURCE\|fingerprint=([0-9a-f]{64})", re.I)
ERROR = re.compile(r"Error in expression|Error position:|Error Undefined variable|Error Missing", re.I)
FATAL_RUNTIME_ERROR = re.compile(
    r"DX11 - device removed - reason:|ErrorMessage:\s*DX11|Exception code:\s*[0-9A-F]+",
    re.I,
)

def summarize(logs):
    cases = []
    completed = {}
    errors = []
    runtime_errors = []
    runtime_error_kinds = set()
    source_fingerprints = {}
    evidence_logs = set()
    for name, content in logs.items():
        fingerprints = {match.group(1).lower() for match in SOURCE.finditer(content)}
        if fingerprints:
            source_fingerprints[name] = sorted(fingerprints)
        for number, line in enumerate(content.splitlines(), 1):
            match = CASE.search(line)
            if match:
                evidence_logs.add(name)
                cases.append(dict(case=match[1], result=match[2], detail=match[3].rstrip('"'), log=name, line=number))
            match = DONE.search(line)
            if match:
                evidence_logs.add(name)
                completed[match[1]] = max(completed.get(match[1], 0), int(match[2]))
            if ERROR.search(line):
                errors.append(dict(log=name, line=number, message=line))
            fatal = FATAL_RUNTIME_ERROR.search(line)
            if fatal:
                # A device-loss cascade can repeat hundreds of times. Preserve the first
                # occurrence of each fatal signature per process without flooding the report.
                kind = (name, fatal.group(0).lower())
                if kind not in runtime_error_kinds:
                    runtime_error_kinds.add(kind)
                    runtime_errors.append(dict(log=name, line=number, message=line))
    observed_fingerprints = sorted({value for values in source_fingerprints.values() for value in values})
    provenance_issues = []
    missing_source_logs = sorted(evidence_logs - set(source_fingerprints))
    if missing_source_logs:
        provenance_issues.append("Missing staged-source fingerprint in: " + ", ".join(missing_source_logs))
    if len(observed_fingerprints) > 1:
        provenance_issues.append("Conflicting staged-source fingerprints: " + ", ".join(observed_fingerprints))
    failed = (
        any(case['result'] == 'FAIL' for case in cases)
        or bool(errors)
        or bool(runtime_errors)
        or bool(provenance_issues)
        or any(completed.values())
    )
    complete = set(completed) == {'SERVER', 'CLIENT'} and bool(cases)
    return dict(
        status='FAIL' if failed else ('PASS' if complete else 'INCOMPLETE'),
        complete=complete,
        missing_completion=sorted({'SERVER', 'CLIENT'} - set(completed)),
        completed=completed,
        cases=cases,
        errors=errors,
        runtime_errors=runtime_errors,
        source_fingerprint=observed_fingerprints[0] if len(observed_fingerprints) == 1 else None,
        source_fingerprints=source_fingerprints,
        provenance_issues=provenance_issues,
    )

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
    lines[4:4] = [
        f"Staged-source fingerprint: `{report.get('source_fingerprint') or 'unverified'}`.",
        '',
    ]
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
    if report.get('runtime_errors'):
        lines += ['', 'Fatal runtime failures:', ''] + [
            f"- {error['log']}:{error['line']}: {error['message']}"
            for error in report['runtime_errors']
        ]
    if report.get('provenance_issues'):
        lines += ['', 'Source provenance failures:', ''] + [
            f"- {issue}" for issue in report['provenance_issues']
        ]
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
    print(
        f"Cortex audit: {report['status']}; {len(report['cases'])} checks, "
        f"{len(report['errors'])} SQF error lines, "
        f"{len(report['runtime_errors'])} fatal runtime failures; "
        f"run complete={report['complete']}. Report: {root/'cortex-results.md'}"
    )
    return 0 if report['status'] == 'PASS' else 1

if __name__ == '__main__':
    raise SystemExit(main())
