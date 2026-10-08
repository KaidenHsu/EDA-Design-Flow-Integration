#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
mkdir -p logs build/iverilog waves

for tool in iverilog vvp; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "[FAIL] $tool not found. Use Vivado/XSim or install Icarus Verilog."
    exit 1
  fi
done

run_one() {
  local name="$1"
  local rtl="$2"
  local tb="$3"
  local top="$4"
  local marker="$5"
  local vcd="$6"
  local compile_log="logs/${name}_iverilog_compile.log"
  local run_log="logs/${name}_iverilog_run.log"

  rm -f "$vcd"
  iverilog -g2005 -Wall -s "$top" -o "build/iverilog/${name}.out" "$rtl" "$tb" > "$compile_log" 2>&1
  vvp "build/iverilog/${name}.out" | tee "$run_log"

  if grep -Fq "[FAIL]" "$run_log"; then
    echo "[FAIL] $name self-checking testbench reported a failure."
    exit 1
  fi
  if ! grep -Fq "$marker" "$run_log"; then
    echo "[FAIL] $name final PASS marker missing."
    exit 1
  fi
  if [ ! -s "$vcd" ]; then
    echo "[FAIL] $name waveform was not created: $vcd"
    exit 1
  fi

  echo "[PASS] $name Icarus self-check and waveform verification passed"
}

run_one fir3_parallel        rtl/fir3_parallel.v tb/tb_fir3_parallel.v        tb_fir3_parallel        "[RESULT] FIR3_PARALLEL TEST PASSED"        waves/fir3_parallel.vcd
run_one fir3_parallel_signed rtl/fir3_parallel.v tb/tb_fir3_parallel_signed.v tb_fir3_parallel_signed "[RESULT] FIR3_PARALLEL SIGNED TEST PASSED" waves/fir3_parallel_signed.vcd
run_one fir3_pipe2           rtl/fir3_pipe2.v    tb/tb_fir3_pipe2.v           tb_fir3_pipe2           "[RESULT] FIR3_PIPE2 TEST PASSED"           waves/fir3_pipe2.vcd
run_one fir3_pipe2_signed    rtl/fir3_pipe2.v    tb/tb_fir3_pipe2_signed.v    tb_fir3_pipe2_signed    "[RESULT] FIR3_PIPE2 SIGNED TEST PASSED"    waves/fir3_pipe2_signed.vcd

echo "[RESULT] ALL WEEK 5 ICARUS TESTS PASSED"
