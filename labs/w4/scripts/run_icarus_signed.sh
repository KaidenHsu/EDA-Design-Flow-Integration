#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p build logs waves

if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
    echo "[ERROR] Icarus Verilog (iverilog/vvp) is not available in PATH." >&2
    exit 2
fi

iverilog -g2005 -Wall -s tb_fir3_seq_signed \
    -o build/fir3_seq_signed.vvp rtl/fir3_seq.v tb/tb_fir3_seq_signed.v \
    > logs/fir3_seq_signed_iverilog_compile.log 2>&1
vvp build/fir3_seq_signed.vvp | tee logs/fir3_seq_signed_iverilog.log

grep -Fq "[RESULT] FIR3_SEQ SIGNED TEST PASSED" logs/fir3_seq_signed_iverilog.log
! grep -Fq "[FAIL]" logs/fir3_seq_signed_iverilog.log

echo "[PASS] Signed-width sanity simulation passed."
