#!/usr/bin/env python3
"""Package student work and available offline model reports."""

import argparse
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

p = argparse.ArgumentParser()
p.add_argument(
    '--permitted-report',
    action='append',
    default=[],
    help='Explicit instructor-authorized text report only'
)
a = p.parse_args()

# Include the worksheet artifacts and any generated offline reports.
files = [
    (ROOT / 'student_work' / name, 'student_work/' + name)
    for name in ('answers.md', 'placement.json', 'power_grid_edges.json')
]
for path in sorted((ROOT / 'output' / '6_gen_offline_reports').glob('*.json')):
    files.append((path, 'gen_offline_reports/' + path.name))

# Additional reports are opt-in and must be text files.
for i, x in enumerate(a.permitted_report):
    path = Path(x).resolve()
    if not path.is_file() or path.suffix.lower() not in ('.rpt', '.log', '.txt', '.json'):
        p.error('Only explicitly permitted text reports/logs')
    files.append((path, f'permitted_reports/{i + 1:02d}_{path.name}'))

with zipfile.ZipFile(ROOT / 'Week12_submission.zip', 'w', zipfile.ZIP_DEFLATED) as z:
    for path, name in files:
        z.write(path, name)
print(ROOT / 'Week12_submission.zip')
