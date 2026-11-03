#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

MODE="${1:-all}"
if [[ "$MODE" != "program" ]]; then
    rm -rf -- \
        "$ROOT/artifacts" \
        "$ROOT/build" \
        "$ROOT/checkpoints" \
        "$ROOT/logs" \
        "$ROOT/reports"
fi

mkdir -p "$ROOT/logs"
RUN_LOG="$ROOT/logs/run.log"

run_logged() {
    local logfile=$1
    shift

    set +e
    {
        printf '$'
        printf ' %q' "$@"
        printf '\n\n'
        "$@"
    } 2>&1 | tee -a "$logfile"
    local rc=${PIPESTATUS[0]}
    set -e
    return "$rc"
}

usage() {
    cat <<'EOF'
Standalone Week 8 PYNQ-Z2 FIR flow
    ./run.sh                 Run the complete simulation, build, and programming flow
    ./run.sh sim             Run Week 6 continuity and Week 8 wrapper simulations
    ./run.sh build           Simulate, synthesize, implement, and create .bit/.ltx
    ./run.sh program         Program the powered PYNQ-Z2 and capture ILA evidence
EOF
}

case "$MODE" in
    help|-h|--help)
        usage
        ;;
    sim)
        run_logged "$RUN_LOG" bash "$ROOT/scripts/simulate.sh"
        ;;
    build)
        run_logged "$RUN_LOG" bash "$ROOT/scripts/build.sh"
        ;;
    all)
        run_logged "$RUN_LOG" bash "$ROOT/scripts/build.sh"
        run_logged "$RUN_LOG" bash "$ROOT/scripts/program.sh"
        ;;
    program)
        run_logged "$RUN_LOG" bash "$ROOT/scripts/program.sh"
        ;;
    *)
        usage
        exit 2
        ;;
esac
