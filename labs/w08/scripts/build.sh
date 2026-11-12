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

bash "$ROOT/scripts/simulate.sh"
command -v vivado >/dev/null 2>&1 || { echo '[FAIL] Vivado unavailable'; exit 1; }
mkdir -p "$ROOT/logs" "$ROOT/build" "$ROOT/artifacts" "$ROOT/checkpoints" "$ROOT/reports"
rm -f "$ROOT/artifacts/fir3_pynqz2.bit" "$ROOT/artifacts/fir3_pynqz2.ltx" "$ROOT/checkpoints/fir3_pynqz2_routed.dcp"

set +e
run_logged "$ROOT/logs/vivado_build.log" vivado -mode batch -nolog -nojournal -source "$ROOT/vivado/build.tcl"
rc=$?
set -e
if ((rc != 0)); then
    tail -n 65 "$ROOT/logs/vivado_build.log"
    echo '[FAIL] Vivado build; see logs/vivado_build.log'
    exit "$rc"
fi

grep -Fq '[RESULT] WEEK8_BOARD_HANDOFF_ACCEPTED' "$ROOT/logs/vivado_build.log" || { echo '[FAIL] Vivado handoff was not accepted'; exit 1; }
for file in "$ROOT/artifacts/fir3_pynqz2.bit" "$ROOT/artifacts/fir3_pynqz2.ltx" "$ROOT/checkpoints/fir3_pynqz2_routed.dcp"; do
    [[ -s "$file" ]] || { echo "[FAIL] Missing or empty artifact: $file"; exit 1; }
done
printf '%s\n' '[PASS] Standalone Week 8 build accepted'
