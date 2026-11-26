#!/usr/bin/env python3
"""Run the real Week 12 reference flow, preserving independent checkpoints.
Use the installed T18 kit and the lab’s mapped FIR netlist.
"""

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from tempfile import TemporaryDirectory
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / 'tcl'
KIT = Path('/tools/cad/CBDK/CBDK_TSMC018_Arm_f1.0')
ICC2 = Path('/usr/local/bin/icc2')
LM = Path('/cad/synopsys/synthesis/2026.03/fusioncompiler/bin/icc2_lm_shell')
SETUP = Path('/cad/synopsys/TSRI/primetime.sh')
NET_SHA = '2708b81c7da6322d80766e4661b84c57ee6b3c8337d5134b22ce2d6a769a6cdf'
SDC_SHA = '9ed792c5214cd52998de0eec8322efd0428caa2bb43eb0547cd2dfc427623aed'
DB_SHA = '06e2cdcdd52458ae9037eb3ac6cd5bb8f1d880444f2104f71965fb79ed522947'
EXPERIMENT_FOLDERS = {
    'floor60': '1_A_create_floorplans',
    'floor50': '1_A_create_floorplans',
    'ordinary': '3_C_place_cells',
    'ordinary_report': '3_C_place_cells',
    'congestion': '3_C_place_cells',
    'congestion_report': '3_C_place_cells',
    'hold_baseline': '4_D_repair_hold',
    'hold_optimized': '4_D_repair_hold'
}


def stage_path(out, name):
    """Resolve the output directory for a named ICC2 stage."""
    if name == 'library':
        return out / '0_build_reference_library'
    if name == 'rails_only':
        return out / '2_B_build_cell_rails'
    if name == 'reopen':
        return out / '5_reopen_checkpoint'
    return out / EXPERIMENT_FOLDERS.get(name, '') / name


def sha(p):
    """Return the SHA-256 digest of a file."""
    return hashlib.sha256(p.read_bytes()).hexdigest()


def require(p, digest=None):
    """Require a readable nonempty input and verify its digest when supplied."""
    if not p.is_file() or not os.access(p, os.R_OK) or (not p.stat().st_size):
        raise RuntimeError(f'Missing or unreadable file: {p}')
    if digest and sha(p) != digest:
        raise RuntimeError(f'Input checksum mismatch: {p}')


def run_stage(out, name, script, marker, env, source=None, files=(), lm=False):
    """Run one ICC2 stage and record its output status."""
    d = stage_path(out, name)
    d.parent.mkdir(parents=True, exist_ok=True)

    # Refuse to overwrite an existing stage directory.
    d.mkdir()
    status = {
        'stage': name,
        'state': 'FAILED_OR_INCOMPLETE',
        'timing_model': 'ZERO_INTERCONNECT_DELAY_EXPECTED; CHECK LOG',
        'acceptance': 'NOT_REVIEWED'
    }
    try:
        if source:
            s = stage_path(out, source)
            prerequisite_status = s / 'status.json'
            if (
                not prerequisite_status.is_file()
                or json.loads(prerequisite_status.read_text())['state'] != 'EXECUTED_REVIEW_REQUIRED'
            ):
                raise RuntimeError(f'Prerequisite stage incomplete: {s}')

            # Work on a copy so the prerequisite checkpoint is preserved.
            shutil.copytree(s / 'fir3.dlib', d / 'fir3.dlib')
        t = d / script
        shutil.copy2(SCRIPTS / script, t)
        cmd = [str(ICC2), '-f', str(t)]
        if lm:
            cmd = [
                'bash',
                '-c',
                'source "$1" >/dev/null || exit 1; exec "$2" -f "$3"',
                'w12',
                str(SETUP),
                str(LM),
                str(t)
            ]
        with (d / 'icc2.log').open('w') as log:
            rc = subprocess.run(
                cmd,
                cwd=d,
                env=env,
                stdout=log,
                stderr=subprocess.STDOUT,
                timeout=600
            ).returncode
        txt = (d / 'icc2.log').read_text(errors='replace')
        if rc or marker not in txt.splitlines() or re.search(
            '^\\s*(?:Error:|Fatal:|W12_FAIL\\b)',
            txt,
            re.M
        ):
            raise RuntimeError(f'Tool execution failed; inspect {d}/icc2.log')
        for f in files:
            q = d / f
            if not q.exists() or (q.is_file() and (not q.stat().st_size)):
                raise RuntimeError(f'Missing artifact: {q}')

        # TIM-102 confirms that the tool used zero interconnect delay.
        if 'TIM-102' in txt:
            status['timing_model'] = 'ZERO_INTERCONNECT_DELAY_CONFIRMED'
        status['state'] = 'EXECUTED_REVIEW_REQUIRED'
        print(f"{name}: {status['state']} — {d}/icc2.log", flush=True)
    finally:
        (d / 'status.json').write_text(json.dumps(status, indent=2) + '\n')
    return d



def publish_reference_library(built_ndm, destination):
    """Publish a validated NDM while preserving the previous copy on failure."""
    if not built_ndm.is_dir():
        raise RuntimeError(f'Missing built reference library: {built_ndm}')
    if destination.is_symlink() or (destination.exists() and not destination.is_dir()):
        raise RuntimeError(f'Expected a reference library directory: {destination}')
    destination.parent.mkdir(parents=True, exist_ok=True)

    # Stage the new library on the destination filesystem before replacing the old one.
    with TemporaryDirectory(dir=destination.parent) as staging:
        new_library = Path(staging) / 'new.ndm'
        previous_library = Path(staging) / 'previous.ndm'
        shutil.move(str(built_ndm), new_library)
        if destination.exists():
            destination.rename(previous_library)
        try:
            new_library.rename(destination)
        except OSError:
            if previous_library.exists():
                previous_library.rename(destination)
            raise


def main():
    """Parse command-line arguments and run the requested lab workflow."""
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('stage', choices=['library', 'floor', 'rails', 'place', 'hold', 'reopen', 'all'])
    ap.add_argument('--out', type=Path, required=True)
    ap.add_argument('--netlist', type=Path)
    ap.add_argument('--ndm', type=Path, help='Authorized existing reference library (optional)')
    ap.add_argument('--sdc', type=Path, default=ROOT / 'input/week11_10ns_io_fixed.sdc')
    a = ap.parse_args()

    out = a.out.resolve()
    out.mkdir(parents=True, exist_ok=True)

    env = os.environ.copy()
    tech = KIT / 'CIC/ICC/tsmc18_CIC.tf'
    db = KIT / 'CIC/SynopsysDC/db/typical.db'
    lef = KIT / 'CIC/SOCE/lef/tsmc18_6lm_cic.lef'
    require(tech)
    require(db, DB_SHA)
    require(lef)
    require(a.sdc.resolve(), SDC_SHA)
    if not os.access(ICC2, os.X_OK):
        raise RuntimeError(f'University launcher not executable: {ICC2}')
    env.update(W12_TECH=str(tech), W12_DB=str(db), W12_LEF=str(lef), W12_SDC=str(a.sdc.resolve()))

    published_ndm = ROOT / 'input/t18_typical.dnm'
    if a.stage in ('library', 'all') and a.ndm is None:
        require(SETUP)
        if not os.access(LM, os.X_OK):
            raise RuntimeError(f'Library Manager unavailable: {LM}')
        build_dir = run_stage(
            out,
            'library',
            '0_build_reference_library.tcl',
            'W12_NDM_CREATED',
            env,
            files=('t18_typical.ndm',),
            lm=True
        )
        publish_reference_library(build_dir / 't18_typical.ndm', published_ndm)
    if a.stage == 'library':
        return
    if a.stage in ('floor', 'all'):
        if a.netlist is None:
            raise RuntimeError('--netlist is required for floor/all; use exact instructor-authorized reference')
        net = a.netlist.resolve()
        require(net, NET_SHA)
        ndm = (a.ndm or published_ndm).resolve()
        if not ndm.is_dir() or not os.access(ndm, os.R_OK | os.X_OK):
            raise RuntimeError(f'NDM unavailable: {ndm}')
        env.update(W12_NETLIST=str(net), W12_NDM=str(ndm))
        for name, u in [('floor60', '0.60'), ('floor50', '0.50')]:
            run_stage(
                out,
                name,
                '1_A_create_floorplan.tcl',
                'W12_IMPORT_FLOORPLAN_COMPLETED',
                dict(env, W12_UTIL=u),
                files=('fir3.dlib', 'floorplan.def')
            )
        (stage_path(out, 'floor60').parent / 'inputs.json').write_text(json.dumps(
            {
                'netlist': str(net),
                'netlist_sha256': NET_SHA,
                'sdc': str(a.sdc.resolve()),
                'sdc_sha256': SDC_SHA,
                'db_sha256': DB_SHA,
                'tech_sha256': sha(tech),
                'lef_sha256': sha(lef),
                'ndm': str(ndm),
                'mode': 'TEACHING; NO VALIDATED RC MODEL',
            },
            indent=2
        ) + '\n')
    if a.stage in ('rails', 'all'):
        run_stage(
            out,
            'rails_only',
            '2_B_build_cell_rails.tcl',
            'W12_RAILS_COMPLETED',
            env,
            source='floor60',
            files=('fir3.dlib', 'pg_rails.def')
        )

    # Both placement strategies start from the same floorplan.
    if a.stage in ('place', 'all'):
        for v in ('ordinary', 'congestion'):
            run_stage(
                out,
                v,
                '3_C_place_cells_with_mesh.tcl',
                'W12_PG_PLACE_COMPLETED',
                dict(env, W12_VARIANT=v),
                source='floor50',
                files=('fir3.dlib', 'powerplan.def', 'global_placement.def', 'placed.def')
            )
            run_stage(
                out,
                v + '_report',
                '3_C_report_routing_congestion.tcl',
                'W12_CONGESTION_COMPLETED',
                env,
                source=v,
                files=('fir3.dlib',)
            )
    if a.stage in ('hold', 'all'):
        for v in ('baseline', 'optimized'):
            run_stage(
                out,
                'hold_' + v,
                '4_D_repair_hold_timing.tcl',
                'W12_HOLD_EXPERIMENT_COMPLETED',
                dict(env, W12_VARIANT=v),
                source='ordinary',
                files=('fir3.dlib', 'final.def', 'final.v')
            )
    if a.stage in ('reopen', 'all'):
        run_stage(
            out,
            'reopen',
            '5_reopen_checkpoint.tcl',
            'W12_REOPEN_COMPLETED',
            env,
            source='hold_optimized',
            files=('fir3.dlib',)
        )


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError, subprocess.TimeoutExpired) as e:
        print(f'ERROR: {e}', file=sys.stderr)
        sys.exit(1)
