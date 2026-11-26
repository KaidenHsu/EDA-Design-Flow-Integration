# Student worksheet — 24-slide in-class deck

Use the original Week 12 slides as the question source. Run the primary ICC2 track following SLIDE_COMMANDS.md; the offline arithmetic/graph models below are supplementary. No proprietary inputs included.

| Slides | Activity | Minutes |
|---|---|---:|
| 1–4 | Review and pre-class exercise | 16 |
| 5–8 | Lab A: audit inputs and compare floorplans | 35 |
| 9–12 | Lab B: PG and stripe trade-offs | 32 |
| | Break | 10 |
| 13–17 | Lab C: special cells, legalization, HPWL and overflow | 40 |
| 18–21 | Lab D: pre-CTS optimization | 36 |
| 22–24 | Evidence review and Week 13 handoff | 11 |

## Lab A (4–8)
1. Calculate eligible area and utilization for the pre-class macro example before reading generated arithmetic. Explain whether the 65% target is sufficient for routability.
2. Run `python3 scripts/run_lab.py --lab A`. Compare the 160×100 and 160×120 µm candidates with 9,600 µm² cell area, then 10% growth. Explain the 60% growth budget and legal site rounding. Choose a baseline.
3. Audit the real input requirements (netlist, SDC, timing, physical/technology, RC, power/pin/site policy). Start with `input/mapped.v` and the generated `input/t18_typical.dnm/`. Record what is actually available. In REAL, compare the two floorplan runs, confirm actual dimensions and legal rows/pins. Model geometry is not measured FIR size.

## Lab B (9–12)
1. Run `python3 scripts/run_lab.py --lab B`. Inspect `student_work/power_grid_edges.json`; each pair describes an undirected edge. Find the disconnected supply pin and add a correct edge. Do not connect different supply nets. Rerun and record the candidate audit.
2. Calculate W/P metal fraction and spacing for the given 2/3 µm widths at 10 µm pitch. Explain the model 8 µm minimum, a legal alternative, simple resistance ratio, and the limits of the IR calculation. The graph cannot prove EM compliance.
3. REAL: inspect the rails-only log in `output/2_B_build_cell_rails/icc2.log` and the ordinary placement run before and after legalization. Explain physical vs logical connectivity, supply terminals, and vias. Compare the illustrative stripe alternatives only in the model; no second physical stripe-width variant is validated.

## Lab C (13–17)
1. Run `python3 scripts/run_lab.py --lab C`. Inspect the intentionally illegal `student_work/placement.json`. Each value is `[row, start_site]`. Preserve U1–U4 widths, integer starts, row bounds, R0 blocked sites 4–5 and non-overlap. Modify and rerun. More than one legal solution exists; do not add or remove cells.
2. Compute occupied/eligible sites, utilization, HPWL and each region's overflow. Explain why equal total demand does not imply equal routability. Identify required special-cell policy, macro/pin access limitations.
3. REAL: compare ordinary and congestion-driven placement on the same floor50 checkpoint. Use the final congestion table; record legalization displacements, legality and PG checks. No separate detailed-placement command is validated. Preserve original reports.

## Lab D (18–21)
1. Calculate the original and placed setup slacks using Week 11 illustrative path values. Explain how decreasing the earliest arrival can worsen hold.
2. Run `python3 scripts/run_lab.py --lab D`. Compare candidates A and B against baseline, compute area overhead, evaluate setup/hold and overflow. Power and IR/EM evidence is not supplied; do not invent it.
3. REAL: compare hold_baseline and hold_optimized under identical SDC, typical corner, ideal clock and zero interconnect delay. Note actual path endpoints, coverage and all violations. Read area, cell inventory, legalization, PG and congestion reports. Review equivalence status; do not claim signoff.

## Submit (22–24)
Fill `student_work/answers.md`; collect submission. Regenerate model reports if you used the supplementary track. For REAL, list the native checkpoint and block name, approved local references and unresolved issues, plus permitted text evidence. Do not share proprietary files. A real design must be reopenable for Week 13; model work is not a physical checkpoint.
