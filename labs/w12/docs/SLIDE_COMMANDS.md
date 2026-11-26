# Week 12 — Commands for the 24-Slide Deck

For a manual run, start with an empty `output/` directory. Set variables once from the extracted package root.

```bash
source config/default.env
```

| Slide | Real ICC2 command or action | Supplementary model |
|---|---|---|
| 5 | Build the reference library using the commands below. | `python3 scripts/run_lab.py --mode preflight` (discovery only) |
| 8 | `python3 scripts/run_icc2.py floor --out "$OUT" --netlist "$NETLIST" --ndm "$NDM"` | `python3 scripts/run_lab.py --lab A` |
| 11 | `python3 scripts/run_icc2.py rails --out "$OUT"` — inspect incomplete rails and floating pins | `python3 scripts/run_lab.py --lab B`; edit `student_work/power_grid_edges.json`; rerun |
| 12 | Inspect rail geometry; compute the illustrative alternative stripe width/spacing, not an unvalidated physical variant | Read `output/6_gen_offline_reports/lab_B.json` |
| 15 | `python3 scripts/run_icc2.py place --out "$OUT"` — builds mesh, places pins, runs both placement strategies and legalization | `python3 scripts/run_lab.py --lab C`; edit `student_work/placement.json`; rerun |
| 17 | Read final congestion reports from `output/3_C_place_cells/ordinary_report/icc2.log` and `output/3_C_place_cells/congestion_report/icc2.log`; use final table, not phase lines | Read `output/6_gen_offline_reports/lab_C.json` |
| 21 | `python3 scripts/run_icc2.py hold --out "$OUT"` — controlled buffer insertion under zero-interconnect-delay model | `python3 scripts/run_lab.py --lab D` |
| 23 | `python3 scripts/run_icc2.py reopen --out "$OUT"`; inspect checkpoint, netlist diff and placement statuses; complete answers | `python3 scripts/collect_submission.py` |

## Build the Reference Library

Build a new NDM using the server’s Library Manager and T18 kit. A successful build publishes the NDM to `$NDM` at the lab root. Build diagnostics stay under `output/0_build_reference_library/`.

```bash
python3 scripts/run_icc2.py library --out "$OUT"
```

## Inspect the Logs

```bash
grep -E 'Core Area is|Utilization Ratio:|Total Area of cells:' "$OUT"/1_A_create_floorplans/floor{60,50}/icc2.log
grep -E 'Number of floating|No errors found|TOTAL.*Violations' "$OUT"/3_C_place_cells/ordinary/icc2.log
for v in ordinary congestion; do grep -A 12 'Report : congestion' "$OUT/3_C_place_cells/${v}_report/icc2.log"; done
for v in hold_baseline hold_optimized; do grep -E 'slack \(|No. of Hold Violations:|Leaf Cell Count:|Cell Area \(netlist\):|TIM-102' "$OUT/4_D_repair_hold/$v/icc2.log"; done
diff -u "$OUT/4_D_repair_hold/hold_baseline/final.v" "$OUT/4_D_repair_hold/hold_optimized/final.v" || true
for v in hold_baseline hold_optimized; do sed -n '/^COMPONENTS /,/^END COMPONENTS/p' "$OUT/4_D_repair_hold/$v/final.def" | grep -oE '\+ (PLACED|UNPLACED|FIXED|COVER)' | sort | uniq -c; done
```

Reference comparisons differ from slide illustrative numbers; do not relabel illustrative data as measured. Full reports remain local. The new wrapper is locally checked but not itself exercised on the licensed server.
