#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
select_modes "$@"
for tool in xvlog xelab xsim; do
  command -v "$tool" >/dev/null || fail "$tool unavailable"
done
require_files "$ROOT/rtl/fir3_pipe2.v" "$ROOT/tb/tb_fir3_pipe2.v" "$ROOT/tb/tb_fir3_pipe2_signed.v"
for mode in "${MODES[@]}"; do
  clean_stage "$mode" sim
  rm -rf -- "$ROOT/waves/$mode"
done

# Simulate identical RTL once under the first selected mode. Copy diagnostics
# even on failure so each selected mode has the same command evidence.
owner="${MODES[0]}"
publish_logs() {
  local mode
  for mode in "${MODES[@]}"; do
    if [[ "$mode" != "$owner" && -d "$ROOT/logs/$owner/sim" ]]; then
      mkdir -p "$ROOT/logs/$mode"
      cp -R "$ROOT/logs/$owner/sim" "$ROOT/logs/$mode/sim"
    fi
  done
}
trap publish_logs EXIT

run_one() {
  local name="$1" tb="$2" top="$3" expected="$4" vcd="$5"
  local work="$ROOT/build/$owner/sim/$name"
  local logs="$ROOT/logs/$owner/sim/$name"
  local snapshot="${top}_sim"
  mkdir -p "$work/waves"
  (
    cd "$work"
    # XSim lacks -nojournal; discard its incidental journal on success or failure.
    trap 'rm -f -- xsim.jou "xsim.dir/$snapshot/xsimkernel.log" "xsim.dir/$snapshot/xsimcrash.log"' EXIT
    run_logged "$logs/xvlog.log" xvlog -nolog "$ROOT/rtl/fir3_pipe2.v" "$ROOT/tb/$tb"
    run_logged "$logs/xelab.log" xelab -nolog "$top" -debug typical -s "$snapshot"
    run_logged "$logs/xsim.log" xsim -nolog "$snapshot" -runall
  )
  if grep -Fq '[FAIL]' "$logs/xsim.log"; then fail "$name: testbench failure; see $logs"; fi
  grep -Fq "$expected" "$logs/xsim.log" || fail "$name: missing PASS marker; see $logs"
  require_files "$work/waves/$vcd"
  local mode
  for mode in "${MODES[@]}"; do
    mkdir -p "$ROOT/waves/$mode"
    cp "$work/waves/$vcd" "$ROOT/waves/$mode/$vcd"
  done
}
run_one fir3_pipe2 tb_fir3_pipe2.v tb_fir3_pipe2 '[RESULT] FIR3_PIPE2 TEST PASSED' fir3_pipe2.vcd
run_one fir3_pipe2_signed tb_fir3_pipe2_signed.v tb_fir3_pipe2_signed '[RESULT] FIR3_PIPE2 SIGNED TEST PASSED' fir3_pipe2_signed.vcd
