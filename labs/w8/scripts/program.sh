#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

run_logged() {
    local logfile=$1
    shift

    printf '$'
    printf ' %q' "$@"
    printf '\n'
    {
        printf '$'
        printf ' %q' "$@"
        printf '\n\n'
        "$@"
    } >>"$logfile" 2>&1
}

command -v vivado >/dev/null 2>&1 || { echo '[FAIL] Vivado unavailable'; exit 1; }
for file in "$ROOT/artifacts/fir3_pynqz2.bit" "$ROOT/artifacts/fir3_pynqz2.ltx"; do
    [[ -s "$file" ]] || { echo "[FAIL] Build first; missing $file"; exit 1; }
done
[[ -s "$ROOT/logs/vivado_build.log" ]] && grep -Fq '[RESULT] WEEK8_BOARD_HANDOFF_ACCEPTED' "$ROOT/logs/vivado_build.log" || {
    echo '[FAIL] No accepted Week 8 build log'
    exit 1
}

mkdir -p "$ROOT/logs"
run_logged "$ROOT/logs/vivado_program.log" vivado -mode batch -nolog -nojournal -source "$ROOT/vivado/program.tcl"
