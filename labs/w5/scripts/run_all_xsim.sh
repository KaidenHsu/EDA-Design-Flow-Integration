#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
mkdir -p logs build/xsim waves

for tool in xvlog xelab xsim; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "[FAIL] $tool not found. Load a Vivado/XSim environment first."
    exit 1
  fi
done

run_one() {
  local name="$1"
  local rtl="$2"
  local tb="$3"
  local top="$4"
  local marker="$5"
  local vcd_name="$6"
  local sim="${top}_sim"
  local work="$ROOT_DIR/build/xsim/$name"
  local run_log="$ROOT_DIR/logs/${name}_xsim.log"

  rm -rf "$work"
  mkdir -p "$work/waves"
  rm -f "$ROOT_DIR/waves/$vcd_name"

  pushd "$work" >/dev/null
  xvlog -nolog "$ROOT_DIR/$rtl" "$ROOT_DIR/$tb" > "$ROOT_DIR/logs/${name}_xvlog.log" 2>&1
  xelab -nolog "$top" -debug typical -s "$sim" > "$ROOT_DIR/logs/${name}_xelab.log" 2>&1
  xsim -nolog "$sim" -runall | tee "$run_log"
  popd >/dev/null

  if grep -Fq "[FAIL]" "$run_log"; then
    echo "[FAIL] $name self-checking testbench reported a failure."
    exit 1
  fi
  if ! grep -Fq "$marker" "$run_log"; then
    echo "[FAIL] $name final PASS marker missing."
    exit 1
  fi
  if grep -Eq '(^|[[:space:]])ERROR:' "$run_log"; then
    echo "[FAIL] $name XSim log contains ERROR:."
    exit 1
  fi
  if [ ! -s "$work/waves/$vcd_name" ]; then
    echo "[FAIL] $name waveform was not created by XSim: $work/waves/$vcd_name"
    exit 1
  fi

  cp "$work/waves/$vcd_name" "$ROOT_DIR/waves/$vcd_name"
  echo "[PASS] $name XSim self-check and waveform verification passed"
}

run_one fir3_parallel        rtl/fir3_parallel.v tb/tb_fir3_parallel.v        tb_fir3_parallel        "[RESULT] FIR3_PARALLEL TEST PASSED"        fir3_parallel.vcd
run_one fir3_parallel_signed rtl/fir3_parallel.v tb/tb_fir3_parallel_signed.v tb_fir3_parallel_signed "[RESULT] FIR3_PARALLEL SIGNED TEST PASSED" fir3_parallel_signed.vcd
run_one fir3_pipe2           rtl/fir3_pipe2.v    tb/tb_fir3_pipe2.v           tb_fir3_pipe2           "[RESULT] FIR3_PIPE2 TEST PASSED"           fir3_pipe2.vcd
run_one fir3_pipe2_signed    rtl/fir3_pipe2.v    tb/tb_fir3_pipe2_signed.v    tb_fir3_pipe2_signed    "[RESULT] FIR3_PIPE2 SIGNED TEST PASSED"    fir3_pipe2_signed.vcd

echo "[RESULT] ALL WEEK 5 XSIM TESTS PASSED"
