#!/usr/bin/env python3
"""Run Design Compiler for the configured clock periods and save run evidence."""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
CONFIG_PATH = ROOT / 'config' / 'lab_config.json'


def sha256(path):
    """Return the SHA-256 hex digest of a file, reading it in chunks."""
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def export_env(cfg, period, outdir):
    """Return an environment containing the selected DC run configuration."""
    env = os.environ.copy()
    values = {
        'W10_RTL_FILES': '|'.join(str((ROOT/x).resolve()) for x in cfg['rtl_files']),
        'W10_TOP': cfg['top'], 'W10_LIB_DB': cfg['lib_db'],
        'W10_CLK_PORT': cfg['clk_port'],
        'W10_INPUT_PORTS': '|'.join(cfg['input_ports']),
        'W10_OUTPUT_PORTS': '|'.join(cfg['output_ports']),
        'W10_PERIOD_NS': str(period),
        'W10_INPUT_MAX_NS': str(cfg['input_max_ns']),
        'W10_INPUT_MIN_NS': str(cfg['input_min_ns']),
        'W10_OUTPUT_MAX_NS': str(cfg['output_max_ns']),
        'W10_OUTPUT_MIN_NS': str(cfg['output_min_ns']),
        'W10_OUTDIR': str(outdir),
        'W10_COMPILE_COMMAND': cfg['compile_command'],
    }
    env.update(values)
    return env


def tool_path(name):
    """Resolve a DC launcher name, using site defaults where applicable."""
    if name == 'auto':
        # Prefer site wrapper: user already reached design_vision> by running dc.
        return shutil.which('dc') or '/tools/cad/synopsys/synthesis/2026.03/bin/dc_shell'
    if name == 'dc_shell':
        return shutil.which('dc_shell') or '/tools/cad/synopsys/synthesis/2026.03/bin/dc_shell'
    return shutil.which(name) or name


def run_dc(cfg, tool, seconds):
    """Attempt the configured synthesis runs and return a success flag and status message.

    Save tool logs and a manifest, requiring completion markers and nonempty
    reports before reporting success. Completed runs still need report review.
    """
    if not Path(cfg['lib_db']).is_file():
        return False, f'Authorized T18 .db not found/readable at {cfg["lib_db"]}.'
    resolved = tool_path(tool)
    if not shutil.which(resolved) and not (Path(resolved).is_file() and os.access(resolved, os.X_OK)):
        return False, f'Design Compiler launcher absent: {resolved}.'

    session_root = ROOT/'results'
    session_root.mkdir(parents=True, exist_ok=True)
    manifest = {
        'start_time': dt.datetime.now().isoformat(timespec='seconds'),
        'tool_command': resolved,
        'config_sha256': sha256(CONFIG_PATH),
        'rtl_sha256': {x:sha256(ROOT/x) for x in cfg['rtl_files']},
        'library_path': cfg['lib_db'],
        'periods_ns': cfg['clock_periods_ns'],
        'requested_compile_command': cfg['compile_command'],
        'report_files_required': ['mapped.v', 'area.rpt', 'refs.rpt', 'setup.rpt', 'hold.rpt', 'timing_coverage.rpt', 'violations.rpt'],
        'timing_caveat': 'Run completion is not a timing PASS; check_timing alone does not prove complete coverage.',
        'status': 'NOT_COMPLETED',
    }
    logs=[]

    for period in cfg['clock_periods_ns']:
        label = (str(period).replace('.', 'p'))+'ns_period'
        outdir = session_root/label
        outdir.mkdir(parents=True, exist_ok=True)
        for name in [*manifest['report_files_required'], 'tool.log']:
            (outdir/name).unlink(missing_ok=True)
    (session_root/'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')

    for period in cfg['clock_periods_ns']:
        label = (str(period).replace('.', 'p'))+'ns_period'
        outdir = session_root/label
        command = [resolved, '-f', 'scripts/run_dc.tcl']

        try:
            result = subprocess.run(command, cwd=ROOT, env=export_env(cfg, period, outdir),
                                    capture_output=True, text=True, timeout=seconds, check=False)
            full_log = result.stdout + ('\n[STDERR]\n'+result.stderr if result.stderr else '')
            code = result.returncode
        except subprocess.TimeoutExpired as exc:
            full_log = 'TIMEOUT: DC launcher exceeded %ds; no evidence of a completed synthesis.\n' % seconds
            full_log += (exc.stdout or b'').decode(errors='replace') if isinstance(exc.stdout, bytes) else (exc.stdout or '')
            code = 124

        logpath = outdir/'tool.log'
        logpath.write_text(full_log, encoding='utf-8')
        needed = ('mapped.v','area.rpt','refs.rpt','setup.rpt','hold.rpt','timing_coverage.rpt','violations.rpt')
        valid_outputs = all((outdir/f).is_file() and (outdir/f).stat().st_size > 0 for f in needed)
        done = code == 0 and 'W10_DC_RUN_COMPLETED' in full_log and valid_outputs
        logs.append({'period_ns': period, 'exit_code': code,
                     'completed_with_required_files': done, 'tool_log': str(logpath.relative_to(ROOT))})
        if not done:
            manifest['runs'] = logs
            manifest['status'] = 'FAILED_OR_LICENSE_BLOCKED'
            (session_root/'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
            return False, f'No verified synthesis for {period} ns. Actual tool output saved: {logpath.relative_to(ROOT)}'

    manifest['runs'] = logs
    manifest['status'] = 'TOOL_COMMANDS_COMPLETED_REPORT_REVIEW_REQUIRED'
    (session_root/'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    return True, (f'All configured DC runs completed and generated the required files in '
                  f'{session_root.relative_to(ROOT)}. Review report warnings/coverage before claiming timing PASS.')


def main():
    """Run the configured synthesis workflow and return its command-line exit code."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tool', default='auto',
                        help='auto (site dc wrapper), dc_shell, or exact executable path')
    parser.add_argument('--timeout', type=int, default=120, help='maximum seconds per real DC run (30-900)')
    args = parser.parse_args()
    if args.timeout < 30 or args.timeout > 900:
        parser.error('--timeout must be between 30 and 900')

    try:
        cfg = json.loads(CONFIG_PATH.read_text(encoding='utf-8'))
    except (OSError, ValueError) as exc:
        print('CONFIGURATION LOAD FAILED:', exc, file=sys.stderr)
        return 2

    try:
        ok, msg = run_dc(cfg, args.tool, args.timeout)
    except (OSError, KeyError, TypeError, ValueError) as exc:
        print('SYNTHESIS RUN FAILED:', exc, file=sys.stderr)
        return 3
    print(msg)
    return 0 if ok else 3


if __name__ == '__main__':
    sys.exit(main())
