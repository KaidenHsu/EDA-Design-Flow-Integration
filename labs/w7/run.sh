#!/usr/bin/env bash
# Reproduce shared simulation and all requested synthesis/implementation modes.
set -euo pipefail
source "$(dirname "$0")/scripts/common.sh"
select_modes "$@"

# Validate tools and sources before removing selected modes' previous outputs.
for tool in vivado xvlog xelab xsim; do
  command -v "$tool" >/dev/null || fail "$tool unavailable"
done

require_files "$ROOT/rtl/fir3_pipe2.v" "$ROOT/constraints/fir3_pipe2.xdc" \
  "$ROOT/tb/tb_fir3_pipe2.v" "$ROOT/tb/tb_fir3_pipe2_signed.v" \
  "$ROOT/vivado/synth_modes.tcl" "$ROOT/vivado/week7_impl.tcl" \
  "$ROOT/scripts/run_xsim_regression.sh" "$ROOT/scripts/run_synth_modes.sh" \
  "$ROOT/scripts/run_week7_impl.sh"

# Preserve unselected modes and leave checkpoints to each stage's cleanup.
for mode in "${MODES[@]}"; do
  rm -rf -- "$ROOT/build/$mode" "$ROOT/logs/$mode" \
    "$ROOT/reports/$mode" "$ROOT/waves/$mode"
done

bash "$ROOT/scripts/run_xsim_regression.sh" "${MODES[@]}"
bash "$ROOT/scripts/run_synth_modes.sh" "${MODES[@]}"
bash "$ROOT/scripts/run_week7_impl.sh" "${MODES[@]}"
