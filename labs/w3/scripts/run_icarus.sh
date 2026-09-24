#!/usr/bin/env bash
# Optional local simulation script using Icarus Verilog.
# The course can also run these files with Vivado/XSim.

set -u

mkdir -p build/iverilog logs/iverilog waves/iverilog

printf "\n[INFO] Running FIR3 arithmetic simulation...\n"
iverilog -g2005 -o build/iveirlog/tb_fir3_arith.vvp rtl/fir3_arith.v tb/tb_fir3_arith.v
vvp build/iveirlog/tb_fir3_arith.vvp | tee logs/iveirlog/fir3_arith_sim.log

printf "\n[INFO] Running FIR3 hand-trace simulation...\n"
iverilog -g2005 -o build/iveirlog/tb_fir3_trace.vvp rtl/fir3_arith.v tb/tb_fir3_trace.v
vvp build/iveirlog/tb_fir3_trace.vvp | tee logs/iveirlog/fir3_trace_sim.log

printf "\n[INFO] Done. Logs are in logs/. VCD waveforms are in waves/.\n"
