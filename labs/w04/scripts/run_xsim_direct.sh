#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p build logs waves

for tool in xvlog xelab xsim; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "[ERROR] $tool is not available. Source the Vivado settings64.sh first." >&2
        exit 2
    fi
done

rm -rf build/xsim.dir build/.Xil 2>/dev/null || true
rm -f waves/fir3_seq.vcd waves/fir3_seq_xsim.vcd 2>/dev/null || true

xvlog -nolog rtl/fir3_seq.v tb/tb_fir3_seq.v         > logs/fir3_seq_xvlog.log 2>&1

xelab -nolog tb_fir3_seq -debug typical -s tb_fir3_seq_sim         > logs/fir3_seq_xelab.log 2>&1

xsim -nolog tb_fir3_seq_sim -tclbatch scripts/vivado/run_fir3_seq_xsim.tcl         | tee logs/fir3_seq_xsim.log

grep -Fq "[RESULT] FIR3_SEQ TEST PASSED" logs/fir3_seq_xsim.log
! grep -Fq "[FAIL]" logs/fir3_seq_xsim.log

# Treat simulator ERROR lines as a failed run even if the self-checking TB passed.
if grep -Eq '(^|[[:space:]])ERROR:' logs/fir3_seq_xsim.log; then
    echo "[ERROR] XSim reported an ERROR line; inspect logs/fir3_seq_xsim.log." >&2
    exit 1
fi

# The single VCD should be produced by the testbench itself.
if [ ! -s waves/fir3_seq.vcd ]; then
    echo "[ERROR] Expected waveform waves/fir3_seq.vcd was not created." >&2
    exit 1
fi

echo "[PASS] Week 4 FIR XSim run passed with a single VCD waveform."
