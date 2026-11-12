#!/usr/bin/env bash
# Week 2 Icarus Verilog simulation helper.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p build logs waves

printf '\n[INFO] Running mux2 simulation...\n'
iverilog -g2005 -Wall -o build/tb_mux2.vvp rtl/mux2.v tb/tb_mux2.v
vvp build/tb_mux2.vvp | tee logs/iverilog/mux2_sim.log

printf '\n[INFO] Running reg8 simulation...\n'
iverilog -g2005 -Wall -o build/tb_reg8.vvp rtl/reg8.v tb/tb_reg8.v
vvp build/tb_reg8.vvp | tee logs/iverilog/reg8_sim.log

printf '\n[INFO] Done. Logs are in logs/. VCD waveforms are in waves/.\n'
