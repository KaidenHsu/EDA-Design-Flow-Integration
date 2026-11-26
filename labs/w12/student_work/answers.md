# Week 12 Student Submission

Kaiden Hsu, M143010027

The saved run used Synopsys ICC2 X-2025.06 and the university T18 kit. The design is the Week 10 mapped three-tap FIR, `fir3_reference`, with the Week 11 10 ns timing constraints. The reference NDM was built locally from the kit. The input paths and hashes are recorded in `output/1_A_create_floorplans/inputs.json`.

## Lab A — Floorplan Utilization

- **Pre-Class Model.** The core is 20,000 µm². The macro and halo exclude 2,000 µm², leaving 18,000 µm² eligible. A cell area of 10,800 µm² yields 60% utilization. A 65% target provides nominal area headroom. Pin access and routing capacity still need to be checked.
- **Growth Comparison.** Model A (160 × 100 µm) goes from 60% to 66% after 10% cell-area growth. Model B (160 × 120 µm) goes from 50% to 55%. At 60% utilization, 10,560 µm² of cells needs at least 17,600 µm² of eligible core area before rounding placement rows and sites to legal dimensions. B is the better starting point if 60% is the limit after growth.
- **ICC2 Input Audit.** The mapped netlist, SDC, technology file, and standard-cell NDM are available. This FIR uses no hard macros. In a macro design, halos, placement blockages, and pin access would reduce usable space. Placement is restricted to legal rows and sites. Signal pins are placed during Experiment C.
- **ICC2 Results.** The 60% target produced a core of 5,837.832 µm² with 61.99% actual utilization, 15 rows, and 1,755 sites. The 50% target produced 6,812.467 µm² with 53.12% utilization, 16 rows, and 2,048 sites. Both used 104 cells with a total area of 3,619.1232 µm². Reported utilization is cell area divided by the actual core area. The two logs are under `output/1_A_create_floorplans/`.

## Lab B — Power Grid Connectivity

- **Offline Connectivity.** The initial graph leaves `VDD.P2` disconnected. I added `["VDD.rail", "VDD.P2"]` to `power_grid_edges.json`. The candidate audit in `lab_B.json` reports no disconnected pins or cross-supply edges. An edge between VDD and VSS would short the two supplies.
- **Stripe Model.** At 10 µm pitch, a 2 µm stripe leaves 8 µm spacing and covers 20% of the pitch. A 3 µm stripe leaves 7 µm spacing and covers 30%, below the model’s 8 µm minimum spacing. A pitch of 11 µm restores 8 µm spacing for the 3 µm stripe. At equal length, thickness, and resistivity, the wider stripe has two-thirds of the narrower stripe’s resistance. The illustrative 20 mA path gives 10 mV at 0.5 Ω and 5 mV at 0.25 Ω.
- **ICC2 Checks.** The rails-only design reported 7 floating wires and 104 floating standard cells per supply. The full mesh had no floating wires before placement, with 104 floating standard cells per supply. After placement and legalization, both counts were zero and no PG DRC errors were reported. The rails-only and mesh designs start from different floorplans. These checks establish geometry and connectivity for this run. The kit-based physical experiment supplies no current distribution, IR-drop analysis, or electromigration results. See the logs in `output/2_B_build_cell_rails/` and `output/3_C_place_cells/ordinary/`.

## Lab C — Placement and Routing Congestion

- **Offline Legality.** The initial audit reports U1 off-grid, U2 overlapping blocked site R0:4, and overlaps between U1/U2 and U3/U4. The corrected positions are U1 at R0:0, U2 at R1:0, U3 at R1:3, and U4 at R1:5. The saved `lab_C.json` reports no candidate issues.
- **Offline Metrics.** The four cells occupy 9 of 14 eligible sites, giving 64.29% footprint utilization. The illustrative half-perimeter wirelength is 7 coordinate units. Both routing examples have total demand 29, but distributing the demand as 12/8/9 yields regional overflow 2/0/0, while 10/10/9 yields 0/0/0 at capacity 10 per region.
- **ICC2 Comparison.** Both strategies start from the same 50% floorplan and finish with zero legality violations. Average legalization displacement was 1.392 µm for ordinary placement and 1.434 µm for congestion-driven placement. The final congestion reports show total overflow of 1 versus 2, maximum local overflow of 1 for both, and 1 versus 2 affected routing cells. Ordinary placement was carried forward because its final total overflow was lower in this run. See the two final congestion report logs under `output/3_C_place_cells/`.
- **Remaining Physical Checks.** Pin access and local routing capacity can still limit routability. A production flow would also apply the kit’s tap, endcap, and filler policies and verify the design after detailed routing.

## Lab D — Pre-CTS Hold Repair

- **Illustrative Timing.** The setup budget is 10 − 1 − 0.3 − 0.7 = 8 ns. With data delays of 6.5 ns and 8.2 ns, the Week 11 and illustrative placed setup slacks are +1.50 ns and −0.20 ns. An earlier minimum-delay arrival reduces hold margin.
- **Illustrative Candidates.** A adds 2.08% area and gives +0.15 ns setup slack, −0.05 ns hold slack, and 2 tracks of overflow. B adds 3.13% area and gives +0.05 ns setup slack, +0.02 ns hold slack, and zero overflow. B meets both illustrative timing checks at the higher area cost. Power and IR/EM data were unavailable for these candidates.
- **ICC2 Timing and Cell Changes.** The target path runs from `valid_out_reg/Q` to `valid_out`. Inserting one BUFX1 improves reported hold slack from −0.04 ns to +0.05 ns and reduces target setup slack from +7.31 ns to +7.22 ns. Worst reported setup remains +4.99 ns. The exported netlist shows the new buffer and its intermediate net. Cell count rises from 104 to 105, and cell area rises from 3,619.12 to 3,632.43 µm². All components in both DEF exports are placed. The repaired checkpoint reports zero placement and PG DRC violations, and final overflow remains 1. See both timing logs and netlist exports under `output/4_D_repair_hold/`.
- **Coverage and Assumptions.** Timing used an ideal clock and zero interconnect delay (`TIM-102`). The checks reported 25 unconstrained reset endpoints and a missing clock-relative input delay on `rst_n`. Reset recovery and removal, formal equivalence, and power integrity remain unverified.

## Week 13 Handoff

- **Reproduction.** From the lab root, `bash run.sh` builds the reference library, runs ICC2, generates the offline reports, and collects the submission. The offline reports can be reproduced with `python3 scripts/run_lab.py`. Numeric observations above are identified as ICC2 or illustrative model results.
- **Checkpoint.** Preserve `output/4_D_repair_hold/hold_optimized/fir3.dlib`, block `fir3_reference.design`, and the associated reference library locally. The fresh-session check in `output/5_reopen_checkpoint/icc2.log` completed and reported zero placement violations, zero PG DRC errors, and zero floating wires or standard cells.
- **Remaining Work.** Resolve reset timing coverage, implement the clock tree and detailed signal routing, extract wire parasitics, and recheck timing and physical verification. The saved result is a pre-CTS teaching checkpoint.
