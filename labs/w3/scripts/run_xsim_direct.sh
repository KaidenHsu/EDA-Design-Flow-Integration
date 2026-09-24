#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/build/vivado/xsim_fir3_arith/waves" "$ROOT/build/vivado/xsim_fir3_trace/waves" "$ROOT/logs/vivado" "$ROOT/waves/vivado"

run_one() {
  local design="$1"
  local top="$2"
  local tb="$3"
  local build="$ROOT/build/vivado/xsim_${design}"

  echo "[INFO] Running ${design} with standalone XSim tools"
  cd "$build"
  xvlog -nolog "$ROOT/rtl/fir3_arith.v" "$ROOT/tb/${tb}" > "$ROOT/logs/vivado/${design}_xvlog.log" 2>&1
  xelab -nolog "$top" -debug typical -s "${top}_sim" > "$ROOT/logs/vivado/${design}_xelab.log" 2>&1
  xsim "${top}_sim" -R > "$ROOT/logs/vivado/${design}_sim.log" 2>&1
  if [ -s "$build/waves/${design}.vcd" ]; then
    cp -f "$build/waves/${design}.vcd" "$ROOT/waves/vivado/${design}.vcd"
  fi
}

run_one fir3_arith tb_fir3_arith tb_fir3_arith.v
run_one fir3_trace tb_fir3_trace tb_fir3_trace.v

echo "[INFO] XSim direct run complete. Check logs/ and waves/."
