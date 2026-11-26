#!/usr/bin/env python3
"""Run the offline lab models or discover the lab tools and technology kit."""

import argparse
import json
import os
import sys
from pathlib import Path

from gen_offline_reports import report
from run_icc2 import ICC2, KIT

ROOT = Path(__file__).resolve().parents[1]


def dump(p, o):
    """Write a JSON report to disk."""
    p.write_text(json.dumps(o, indent=2) + '\n')


def preflight():
    """Print tool and technology kit discovery information."""
    print('ICC2 launcher:', ICC2, 'executable:', os.access(ICC2, os.X_OK))
    print('Known T18 typical.db:', (KIT / 'CIC/SynopsysDC/db/typical.db').is_file())
    if KIT.is_dir():
        print('Candidate kit files (names only; authorization/compatibility NOT established):')
        count = 0
        for base, dirs, files in os.walk(KIT):
            for n in sorted(dirs + files):
                if n.lower().endswith(('.ndm', '.tf', '.lef', '.tluplus', '.tlup', '.map')):
                    print(Path(base) / n)
                    count += 1
                    if count >= 200:
                        print('Listing capped at 200.')
                        return
    else:
        print('Kit root unavailable in this environment.')
    print('Preflight discovery is not a license or implementation test.')


def main():
    """Parse command-line arguments and run the requested lab workflow."""
    p = argparse.ArgumentParser()
    p.add_argument('--mode', choices=['offline', 'preflight'], default='offline')
    p.add_argument('--lab', choices=['A', 'B', 'C', 'D', 'all'], default='all')
    p.add_argument('--out')
    a = p.parse_args()

    if a.mode == 'preflight':
        preflight()
        return 0

    # Offline exercises read the student fixtures without launching ICC2.
    out = Path(a.out).resolve() if a.out else ROOT / 'output' / '6_gen_offline_reports'
    out.mkdir(parents=True, exist_ok=True)
    for lab in 'ABCD' if a.lab == 'all' else a.lab:
        r = report(lab, ROOT / 'student_work')
        dump(out / f'lab_{lab}.json', r)
        print(f"Lab {lab}: {r['evidence']} -> {out}/lab_{lab}.json")
    dump(
        out / 'status.json',
        {
            'evidence': 'MODEL_ONLY / ILLUSTRATIVE',
            'real_tool_output': 'UNAVAILABLE',
            'signoff': False,
            'note': 'Execution completed; student candidates may intentionally fail audit.',
        },
    )
    return 0


if __name__ == '__main__':
    sys.exit(main())
