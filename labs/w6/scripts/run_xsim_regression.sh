#!/usr/bin/env bash

# Stop on errors, unset variables, and failures within pipelines.
set -euo pipefail

# Run from the repository root so all output paths are consistent.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Verify that all XSim command-line tools are available before starting.
for exe in xvlog xelab xsim; do
  if ! command -v "$exe" >/dev/null 2>&1; then
    echo "[FAIL] $exe unavailable: load Vivado environment" >&2
    exit 1
  fi
done

# Store logs, waveform files, and temporary simulation builds in fixed locations.
mkdir -p logs waves build/xsim

# Record the command before capturing its output.
run_logged() {
  local output="$1"
  shift
  {
    printf '$'
    printf ' %q' "$@"
    printf '\n\n'
    "$@"
  } >"$output" 2>&1
}

run_one() {
  local name="$1"
  local tb="$2"
  local top="$3"
  local expected="$4"
  local vcd="$5"
  local work="$ROOT/build/xsim/$name"
  local sim="${top}_sim"

  # Start each regression from a clean simulation directory.
  rm -rf "$work"
  mkdir -p "$work/waves"
  rm -f "$ROOT/waves/$vcd"

  pushd "$work" >/dev/null
  run_logged "$ROOT/logs/${name}_xvlog.log" \
    xvlog -nolog "$ROOT/rtl/fir3_pipe2.v" "$ROOT/tb/$tb"
  run_logged "$ROOT/logs/${name}_xelab.log" \
    xelab -nolog "$top" -debug typical -s "$sim"
  run_logged "$ROOT/logs/${name}_xsim.log" \
    xsim -nolog "$sim" -runall
  popd >/dev/null

  # Treat either a testbench failure or a missing success marker as a failure.
  if grep -Fq '[FAIL]' "$ROOT/logs/${name}_xsim.log"; then
    echo "[FAIL] $name: testbench reported failure"; exit 1
  fi

  if ! grep -Fq "$expected" "$ROOT/logs/${name}_xsim.log"; then
    echo "[FAIL] $name: required final PASS marker missing"; exit 1
  fi

  if [ ! -s "$work/waves/$vcd" ]; then
    echo "[FAIL] $name: VCD not created at $work/waves/$vcd"; exit 1
  fi

  cp "$work/waves/$vcd" "$ROOT/waves/$vcd"
  echo "[PASS] $name: functional regression and VCD"
}

# Run both the unsigned and signed-boundary testbenches.
run_one fir3_pipe2 tb_fir3_pipe2.v tb_fir3_pipe2 '[RESULT] FIR3_PIPE2 TEST PASSED' fir3_pipe2.vcd
run_one fir3_pipe2_signed tb_fir3_pipe2_signed.v tb_fir3_pipe2_signed '[RESULT] FIR3_PIPE2 SIGNED TEST PASSED' fir3_pipe2_signed.vcd

echo '[RESULT] WEEK6 INCLASS FIR REGRESSIONS PASSED'
