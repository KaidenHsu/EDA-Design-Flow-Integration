#!/usr/bin/env bash
# Week 2 standalone Vivado/XSim simulation helper.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/logs" "$ROOT/waves"

run_one() {
  local design="$1"
  local top="$2"
  local rtl="$3"
  local tb="$4"

  local build="$ROOT/build/xsim_${design}"
  local tcl="$build/run_${design}.tcl"

  mkdir -p "$build/waves"
  cat > "$tcl" <<TCL
if {[catch {log_wave -recursive *} msg]} { puts "WARN: log_wave failed: \$msg" }
if {[catch {open_vcd ../../waves/${design}.vcd} msg]} {
    puts "WARN: open_vcd failed: \$msg"
} else {
    catch {log_vcd /}
}
run all
catch {close_vcd}
quit
TCL

  echo "[INFO] Running ${design} with standalone XSim tools"
  (
    cd "$build"
    xvlog -nolog "$ROOT/rtl/$rtl" "$ROOT/tb/$tb" > "$ROOT/logs/vivado/${design}_xvlog.log" 2>&1
    xelab -nolog "$top" -debug typical -s "${top}_sim" > "$ROOT/logs/vivado/${design}_xelab.log" 2>&1
    xsim "${top}_sim" -tclbatch "$tcl" > "$ROOT/logs/vivado/${design}_sim.log" 2>&1
  )
}

run_one mux2 tb_mux2 mux2.v tb_mux2.v
run_one reg8 tb_reg8 reg8.v tb_reg8.v

echo "[INFO] XSim run complete. Check logs/ and waves/."
