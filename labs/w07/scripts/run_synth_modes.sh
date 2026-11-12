#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
select_modes "$@"
command -v vivado >/dev/null || fail 'Vivado unavailable'
require_files "$ROOT/vivado/synth_modes.tcl" "$ROOT/rtl/fir3_pipe2.v" "$ROOT/constraints/fir3_pipe2.xdc"
mkdir -p "$ROOT/logs"
for mode in "${MODES[@]}"; do
  # A changed synthesis invalidates the previous routed implementation.
  clean_stage "$mode" impl
  clean_stage "$mode" synth
  mkdir -p "$ROOT/build/$mode/synth" "$ROOT/checkpoints/$mode" "$ROOT/reports/$mode/synth"
  log="$ROOT/logs/$mode/synth/vivado.log"
  if ! (cd "$ROOT/build/$mode/synth"; run_logged "$log" vivado -mode batch -nolog -nojournal -source "$ROOT/vivado/synth_modes.tcl" -tclargs "$mode"); then
    fail "Synthesis $mode failed: $log"
  fi
  grep -Fxq "SYNTH_COMPLETE=$mode" "$log" || fail "Missing synthesis completion marker: $mode"
  require_files "$ROOT/checkpoints/$mode/post_synth.dcp"
  for name in check_timing.rpt utilization.rpt timing_summary.rpt worst10_setup_paths.rpt; do require_files "$ROOT/reports/$mode/synth/$name"; done
done
