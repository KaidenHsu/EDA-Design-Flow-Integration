#!/usr/bin/env bash

# Stop on errors, unset variables, and failures within pipelines.
set -euo pipefail

# Run from the repository root so all output paths are consistent.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Validate the required tool and at least one requested synthesis mode.
if ! command -v vivado >/dev/null 2>&1; then
  echo '[FAIL] Vivado unavailable: load the Vivado environment' >&2
  exit 1
fi

if [ "$#" -lt 1 ]; then
  echo 'Usage: ./scripts/run_synth_modes.sh A [B C D E]' >&2
  exit 2
fi

# Keep generated reports, logs, and build products in predictable directories.
mkdir -p logs reports build

# Record the command before capturing its output.
run_logged() {
  local output="$1"
  shift
  {
    printf '$'
    printf ' %q' "$@"
    printf '\n\n'
    "$@"
  } >"$output" 2>&1
}

for mode in "$@"; do
  case "$mode" in
    A|B|C|D|E)
      ;;
    *)
      echo "[FAIL] Unknown mode $mode" >&2
      exit 2
      ;;
  esac

  echo "[INFO] Running mode $mode"
  mkdir -p "reports/$mode" "build/mode_$mode"

  log="$ROOT/logs/synth_$mode.log"

  if ! (
    cd "build/mode_$mode"
    run_logged "$log" vivado -mode batch -nojournal -nolog \
      -source "$ROOT/scripts/synth_modes.tcl" \
      -tclargs "$mode"
  ); then
    echo "[FAIL] Synthesis $mode: see $log" >&2; tail -40 "$log"; exit 1;
  fi

  if ! grep -Fxq "SYNTH_COMPLETE=$mode" "$log"; then
    echo "[FAIL] Missing completion marker for $mode" >&2
    exit 1
  fi

  # Every synthesis mode must produce the complete expected artifact set.
  for name in \
    check_timing.rpt \
    utilization.rpt \
    timing_summary.rpt \
    worst10_setup_paths.rpt \
    post_synth.dcp
  do
    if [ ! -s "reports/$mode/$name" ]; then
      echo "[FAIL] Missing reports/$mode/$name" >&2
      exit 1
    fi
  done

  echo "[PASS] $mode reports and checkpoint created"
done

echo '[RESULT] REQUESTED SYNTHESIS MODES COMPLETED'
