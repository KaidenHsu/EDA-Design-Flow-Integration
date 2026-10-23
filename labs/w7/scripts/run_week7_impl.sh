#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
select_modes "$@"
command -v vivado >/dev/null || fail 'Vivado unavailable'
require_files "$ROOT/vivado/week7_impl.tcl" "$ROOT/constraints/fir3_pipe2.xdc"
# Validate every requested input before touching any existing output.
for mode in "${MODES[@]}"; do require_files "$ROOT/checkpoints/$mode/post_synth.dcp"; done
mkdir -p "$ROOT/logs"
for mode in "${MODES[@]}"; do
  clean_stage "$mode" impl
  mkdir -p "$ROOT/build/$mode/impl" "$ROOT/reports/$mode/impl"
  log="$ROOT/logs/$mode/impl/vivado.log"
  if ! (cd "$ROOT/build/$mode/impl"; run_logged "$log" vivado -mode batch -nolog -nojournal -source "$ROOT/vivado/week7_impl.tcl" -tclargs "$mode"); then
    fail "Implementation $mode failed: $log"
  fi
  grep -Fxq "IMPL_COMPLETE=$mode" "$log" || fail "Missing implementation completion marker: $mode"
  require_files "$ROOT/checkpoints/$mode/post_route.dcp"
  for name in timing_checks.rpt timing.rpt paths.rpt util.rpt power.rpt drc.rpt methodology.rpt route_status.rpt bitstream_readiness.txt; do require_files "$ROOT/reports/$mode/impl/$name"; done
done
