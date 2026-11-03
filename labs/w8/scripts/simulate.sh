#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

for tool in xvlog xelab xsim; do
    command -v "$tool" >/dev/null 2>&1 || { echo "[FAIL] $tool unavailable"; exit 1; }
done

for file in \
    rtl/fir3_pipe2.v \
    rtl/fir3_pipe2_debug.v \
    rtl/fir3_debug_wrapper.v \
    tb/tb_fir3_pipe2.v \
    tb/tb_fir3_pipe2_signed.v \
    tb/tb_debug_wrapper.v; do
    [[ -s "$file" ]] || { echo "[FAIL] Missing or empty input: $file"; exit 1; }
done

WORK="$ROOT/build/xsim"
LOGS="$ROOT/logs"
UNSIGNED_WORK="$WORK/unsigend"
SIGNED_WORK="$WORK/signed"
DEBUG_WRAPPER_WORK="$WORK/debug_wrapper"
mkdir -p "$UNSIGNED_WORK" "$UNSIGNED_WORK/waves" "$LOGS"

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

(
    cd "$UNSIGNED_WORK"
    run_logged "$LOGS/unsigned_xvlog.log" xvlog -nolog "$ROOT/rtl/fir3_pipe2.v" "$ROOT/tb/tb_fir3_pipe2.v"
    run_logged "$LOGS/unsigned_xelab.log" xelab -nolog tb_fir3_pipe2 -debug typical -s tb_fir3_pipe2_sim
    run_logged "$LOGS/unsigned_xsim.log" xsim -nolog tb_fir3_pipe2_sim -runall
)
grep -Fq '[RESULT] FIR3_PIPE2 TEST PASSED' "$LOGS/unsigned_xsim.log" || { tail -n 60 "$LOGS/unsigned_xsim.log"; exit 1; }

rm -rf "$SIGNED_WORK"
mkdir -p "$SIGNED_WORK/waves"
(
    cd "$SIGNED_WORK"
    run_logged "$LOGS/signed_xvlog.log" xvlog -nolog "$ROOT/rtl/fir3_pipe2.v" "$ROOT/tb/tb_fir3_pipe2_signed.v"
    run_logged "$LOGS/signed_xelab.log" xelab -nolog tb_fir3_pipe2_signed -debug typical -s tb_fir3_pipe2_signed_sim
    run_logged "$LOGS/signed_xsim.log" xsim -nolog tb_fir3_pipe2_signed_sim -runall
)
grep -Fq '[RESULT] FIR3_PIPE2 SIGNED TEST PASSED' "$LOGS/signed_xsim.log" || { tail -n 60 "$LOGS/signed_xsim.log"; exit 1; }

rm -rf "$DEBUG_WRAPPER_WORK"
mkdir -p "$DEBUG_WRAPPER_WORK/waves"
(
    cd "$DEBUG_WRAPPER_WORK"
    run_logged "$LOGS/debug_wrapper_xvlog.log" xvlog -nolog \
        "$ROOT/rtl/fir3_pipe2_debug.v" \
        "$ROOT/rtl/fir3_debug_wrapper.v" \
        "$ROOT/tb/tb_debug_wrapper.v"
    run_logged "$LOGS/debug_wrapper_xelab.log" xelab -nolog tb_debug_wrapper -debug typical -s debug_wrapper_sim
    run_logged "$LOGS/debug_wrapper_xsim.log" xsim -nolog debug_wrapper_sim -runall
)
if grep -Fq '[FAIL]' "$LOGS/debug_wrapper_xsim.log" || ! grep -Fq '[RESULT] DEBUG WRAPPER REGRESSION PASSED' "$LOGS/debug_wrapper_xsim.log"; then
    tail -n 60 "$LOGS/debug_wrapper_xsim.log"
    echo '[FAIL] Week 8 wrapper regression'
    exit 1
fi

printf '%s\n' '[RESULT] STANDALONE WEEK 8 SIMULATION PASSED'
