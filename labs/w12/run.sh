#!/usr/bin/env bash
set -euo pipefail

# Resolve lab paths from the script location so it can run from any directory.
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd -- "$ROOT"
source "$ROOT/config/default.env"

# Clear previous results and the generated NDM before starting a fresh run.
rm -rf -- "$OUT" "$NDM"

# Look for the installed tools and technology kit.
python3 "$ROOT/scripts/run_lab.py" --mode preflight

# Build the T18 NDM that ICC2 will use for floorplanning.
python3 "$ROOT/scripts/run_icc2.py" library --out "$OUT"

# Experiment A compares floorplans at 60% and 50% target utilization.
python3 "$ROOT/scripts/run_icc2.py" floor --out "$OUT" --netlist "$NETLIST" --ndm "$NDM"
python3 "$ROOT/scripts/run_lab.py" --lab A

# Experiment B builds the rails-only power grid for connectivity checks.
python3 "$ROOT/scripts/run_icc2.py" rails --out "$OUT"
python3 "$ROOT/scripts/run_lab.py" --lab B

# Experiment C compares ordinary and congestion-driven placement.
python3 "$ROOT/scripts/run_icc2.py" place --out "$OUT"
python3 "$ROOT/scripts/run_lab.py" --lab C

# Experiment D compares timing before and after the hold repair.
python3 "$ROOT/scripts/run_icc2.py" hold --out "$OUT"
python3 "$ROOT/scripts/run_lab.py" --lab D

# Verify the Week 13 checkpoint in a fresh ICC2 session.
python3 "$ROOT/scripts/run_icc2.py" reopen --out "$OUT"

# Package student work and the offline reports for submission.
python3 "$ROOT/scripts/collect_submission.py"
