#!/usr/bin/env bash
# Shared launcher helpers. Call only with validated mode and stage names.
# Resolve the project root from this helper, independent of the caller's directory.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Report an error to stderr and stop the calling launcher.
fail() { echo "[FAIL] $*" >&2; exit 1; }

# Store requested modes in MODES, defaulting to all five configurations.
# Validate the entire selection before any launcher starts cleanup or work.
select_modes() {
  MODES=("$@")
  if ((${#MODES[@]} == 0)); then MODES=(A B C D E); fi
  local mode
  for mode in "${MODES[@]}"; do
    case "$mode" in A|B|C|D|E) ;; *) fail "Unknown mode: $mode" ;; esac
  done
}

# Require every supplied path to exist and contain data before proceeding.
require_files() {
  local f
  for f in "$@"; do
    [[ -s "$f" ]] || fail "Missing or empty input: $f"
  done
}

# Remove generated outputs for one validated mode and stage (synth or impl).
# Launchers must check prerequisites first and invalidate downstream stages
# explicitly; this helper preserves other modes and stages.
clean_stage() {
  local mode="$1" stage="$2"
  # Clear stage builds, reports, and diagnostic logs.
  rm -rf -- "$ROOT/build/$mode/$stage" "$ROOT/reports/$mode/$stage"
  rm -rf -- "$ROOT/logs/$mode/$stage"
  # Delete only this stage's checkpoint, preserving its input checkpoint.
  case "$stage" in
    synth) rm -f -- "$ROOT/checkpoints/$mode/post_synth.dcp" ;;
    impl) rm -f -- "$ROOT/checkpoints/$mode/post_route.dcp" ;;
  esac
}

# Record one external tool invocation, then its combined stdout and stderr.
# Keep the command status intact so launchers can stop on tool failures.
run_logged() {
  local output="$1"
  shift
  mkdir -p "$(dirname "$output")"
  # Show only the command on the terminal; keep tool output in its log.
  printf '$'
  printf ' %q' "$@"
  printf '\n'
  {
    printf '$'
    printf ' %q' "$@"
    printf '\n\n'
    "$@"
  } >"$output" 2>&1
}
