#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p build logs waves

if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
    echo "[ERROR] Icarus Verilog (iverilog/vvp) is not available in PATH." >&2
    exit 2
fi

rm -f waves/fir3_seq.vcd 2>/dev/null || true

iverilog -g2005 -Wall -s tb_fir3_seq         -o build/fir3_seq.vvp rtl/fir3_seq.v tb/tb_fir3_seq.v         > logs/fir3_seq_iverilog_compile.log 2>&1

vvp build/fir3_seq.vvp | tee logs/fir3_seq_iverilog.log

grep -Fq "[RESULT] FIR3_SEQ TEST PASSED" logs/fir3_seq_iverilog.log
! grep -Fq "[FAIL]" logs/fir3_seq_iverilog.log

if [ ! -s waves/fir3_seq.vcd ]; then
    echo "[ERROR] Expected waveform waves/fir3_seq.vcd was not created." >&2
    exit 1
fi

echo "[PASS] Main Week 4 FIR simulation passed."
