# Week 7. FIR Filter: FPGA Implementation Phases and Reports

## 1. Introduction

Week 7 takes the sequential FIR filter from Week 6's synthesized netlist to a fully routed FPGA implementation. The focus is on reading the `opt_design`, `place_design`, and `route_design` logs; interpreting methodology, design-rule, routing, and power reports; and comparing post-synthesis estimates with post-route results.

The experiment uses five synthesis configurations, A–E, with the same RTL, device, clock constraint, and implementation commands. The checked-in reports were generated with Vivado 2025.2 for `xc7z020clg400-1`, the Zynq-7000 device on PYNQ-Z2, with a 10 ns (100 MHz) clock.

All five configurations finish routing and meet the specified internal timing constraints. However, external I/O timing, physical pin assignments, and I/O standards remain incomplete. This project stops before bitstream generation and board execution.

## 2. Reproduction Flow

From the project root, with Vivado and XSim commands available on `PATH`, run:

```bash
$ bash run.sh
```

This is the main script for reproducing the entire project. For Week 7, it calls [scripts/run_week7_impl.sh](scripts/run_week7_impl.sh), which launches [vivado/week7_impl.tcl](vivado/week7_impl.tcl) for modes A–E. To reproduce only selected variants, use `bash run.sh B E`.

If the post-synthesis checkpoints already exist, rerun only the Week 7 implementation stage with:

```bash
$ bash scripts/run_week7_impl.sh
```

For each mode, the implementation Tcl runs this sequence:

```tcl
open_checkpoint checkpoints/<mode>/post_synth.dcp
opt_design
place_design
route_design
```

| Location | Week 7 output |
|---|---|
| `logs/<mode>/impl/vivado.log` | Implementation commands, phases, warnings, and completion messages |
| `reports/<mode>/impl/` | Timing, utilization, power, methodology, DRC, and routing reports |
| `checkpoints/<mode>/post_route.dcp` | Saved routed design |
| `build/<mode>/impl/` | Tool working files |

Each successful implementation prints `IMPL_COMPLETE=<mode>`. This confirms flow completion and expected artifacts, not that every report finding passes. The generated `reports/<mode>/impl/bitstream_readiness.txt` records the remaining deployment work. Week 7 stops before bitstream generation and board execution; no `.bit` file is generated.

## 3. Design and Verification

### 3.1 FIR Filter Behavior

<p align="center"><img src="images/design.png" alt="Two-stage sequential three-tap FIR datapath" /></p>

The unchanged [RTL](rtl/fir3_pipe2.v) implements a signed three-tap FIR with coefficients `[1, 2, 1]`:

```text
y[n] = x[n] + 2x[n-1] + x[n-2]
```

Here, `n` counts accepted samples. Each signed 8-bit input is extended to 10 bits. Stage 1 registers the three coefficient products; Stage 2 adds the previous cycle's products and registers the signed 10-bit result. A sample accepted on one rising edge produces its result on the next rising edge, with `valid_out` identifying that result.

When `valid_in` is low, sample history and Stage 1 products hold. An already accepted sample can still finish Stage 2 during that bubble. Active-low asynchronous reset clears the state. The unused RTL history register `d2` is removed during synthesis because it does not affect the output.

Verification uses [tb_fir3_pipe2.v](tb/tb_fir3_pipe2.v) for normal operation, latency, and valid bubbles, and [tb_fir3_pipe2_signed.v](tb/tb_fir3_pipe2_signed.v) for signed boundary cases including `-128`. These are RTL simulations; the flow does not run a separate post-route simulation.

### 3.2 Synthesis Options

<p align="center"><img src="images/modes.png" alt="Synthesis configuration variants A through E" /></p>

The variants change synthesis options rather than FIR behavior. Each nonbaseline mode changes one setting relative to A in [synth_modes.tcl](vivado/synth_modes.tcl).

| Mode | Change from baseline | Purpose |
|---|---|---|
| A | Default directive; rebuilt hierarchy; automatic sharing; global retiming off | Reference configuration |
| B | `-directive AreaOptimized_high` | Test area-oriented synthesis |
| C | `-flatten_hierarchy full` | Test full hierarchy flattening |
| D | `-resource_sharing off` | Test synthesis without resource sharing |
| E | `-global_retiming on` | Test whether register retiming changes the result |

Every resulting checkpoint goes through the same default implementation commands. Thus, the comparison measures how these synthesis choices carry through implementation; it does not compare different placement or routing directives.

## 4. Understanding Implementation Logs

The baseline evidence is [logs/A/impl/vivado.log](logs/A/impl/vivado.log). Phase names below follow that run; other Vivado versions or designs can produce different subphases. A phase appearing in the log means Vivado considered that operation, not necessarily that it changed the design.

### 4.1 `opt_design`

`opt_design` optimizes the synthesized logical netlist before placement. The baseline log contains these main phases:

| Phase | Interpretation |
|---|---|
| 1. Initialization | Generate or prepare cores, apply constraints, and sort the netlist. |
| 2. Timer Update And Timing Data Collection | Refresh timing information to guide optimization. |
| 3. Retarget | Adapt eligible primitives to supported device implementations. |
| 4. Constant propagation | Simplify logic driven by constant values. |
| 5. Sweep | Remove unused or redundant netlist objects. |
| 6. BUFG optimization | Review global clock-buffer usage. |
| 7. Shift Register Optimization | Review shift-register implementations for optimization opportunities. |
| 8. Post Processing Netlist | Perform netlist cleanup after optimization. |
| 9. Finalization | Finalize cores and shapes, then verify connectivity. |

Vivado also logs power-optimization and final-cleanup tasks afterward. In mode A, the listed logical optimization phases create and remove zero cells. This is consistent with a small netlist already simplified by synthesis. The earlier removal of `d2` happened during synthesis, not during these implementation phases.

### 4.2 `place_design`

Placement assigns logical cells to physical FPGA sites. The main phases are:

| Phase | Interpretation |
|---|---|
| 1. Placer Initialization | Sort the netlist, prepare I/O and clock placement, build the device/netlist models, and apply clock and macro restrictions. |
| 2. Global Placement | Choose broad locations using timing, connectivity, and congestion estimates. Includes floorplanning and physical synthesis within the placer. |
| 3. Detail Placement | Commit cells and macros to legal sites, refine packing, optimize register locations, and reassign LUT pins where useful. |
| 4. Post Placement Optimization and Clean-Up | Refine timing, review clock buffering, clean up placement, and report estimated congestion. |

The baseline's physical-synthesis summary reports zero added, removed, or optimized cells/nets in its listed operations. Several resource-specific optimizations are skipped because no setup violation is found. Placement still matters: it establishes physical distances and packing even when primitive counts remain unchanged.

The script does not issue a standalone `phys_opt_design` command. Physical-synthesis messages here belong to work performed inside `place_design`. Also, automatically assigned I/O sites allow this experiment to proceed but do not substitute for board-specific pin constraints.

### 4.3 `route_design`

Routing selects device wires and programmable connections between the placed cells.

| Phase | Interpretation |
|---|---|
| 1. Build RT Design | Construct the router's representation of the placed design. |
| 2. Router Initialization | Apply topology restrictions, clean up, update timing, and establish routing budgets. |
| 3. Global Routing | Plan routing at a broad level. |
| 4. Initial Routing | Make the first detailed connections. |
| 5. Rip-up And Reroute | Replace routes to resolve conflicts or improve results. |
| 6. Delay and Skew Optimization | Refine data-path delays and clock skew. |
| 7. Post Hold Fix | Address minimum-delay/hold requirements. |
| 8. Route finalize | Finalize routing and report its status. |
| 9. Verifying routed nets | Check routed connectivity. |
| 10. Depositing Routes | Store the selected routes in the design database. |
| 11. Post Process Routing | Perform routing postprocessing. |
| 12. Post Router Timing | Recalculate timing using the routed design. |
| 13. Post-Route Event Processing | Complete post-route updates. |

Read the final routing status and timing reports together. A fully connected route can still fail timing, and passing internal timing can coexist with incomplete external constraints.

## 5. Understanding Implementation Reports

These reports are generated after `route_design` by [week7_impl.tcl](vivado/week7_impl.tcl). The links use mode A as the baseline; equivalent files exist for B–E.

| Report | Generating command | Main question |
|---|---|---|
| [methodology.rpt](reports/A/impl/methodology.rpt) | `report_methodology` | Are constraints and design practices complete? |
| [drc.rpt](reports/A/impl/drc.rpt) | `report_drc` | Which device or implementation rules need attention? |
| [route_status.rpt](reports/A/impl/route_status.rpt) | `report_route_status` | Are all routable nets connected without routing errors? |
| [power.rpt](reports/A/impl/power.rpt) | `report_power` | What power, supply current, and temperature does the model estimate? |
| [util.rpt](reports/A/impl/util.rpt) | `report_utilization` | What physical resources does the routed design occupy? |
| [timing.rpt](reports/A/impl/timing.rpt) | `report_timing_summary` | Do the constrained setup, hold, and pulse-width checks pass? |
| [paths.rpt](reports/A/impl/paths.rpt) | `report_timing` | What determines the five worst reported setup paths? |
| [timing_checks.rpt](reports/A/impl/timing_checks.rpt) | `check_timing` | Which timing coverage or constraint issues remain? |

### 5.1 [methodology.rpt](reports/A/impl/methodology.rpt)

The baseline reports **20 `TIMING-18` warnings** for missing input or output delays: nine data/control inputs (`valid_in` and eight `x_in` bits) and eleven outputs (`valid_out` and ten `y_out` bits).

`create_clock` specifies the internal clock period, but it does not describe when another device delivers input data or requires output data. Those interface requirements need appropriate `set_input_delay` and `set_output_delay` constraints. The asynchronous reset is separately excluded from synchronous data-path analysis by the source XDC's false-path constraint.

The summary groups findings by rule; the detail section names each affected port. For example, `TIMING-18#1` means rule `TIMING-18`, reported instance `#1`. The suffixes are identifiers, not severity levels. Passing the constrained internal paths therefore does not prove that the external interface meets timing.

### 5.2 [drc.rpt](reports/A/impl/drc.rpt)

The baseline contains three reported violations:

| Rule | Severity | Finding and consequence |
|---|---|---|
| `NSTD-1` | Critical Warning | All 22 logical ports use the default I/O standard. Board-compatible electrical standards must be assigned before bitstream generation. |
| `UCIO-1` | Critical Warning | All 22 logical ports lack user-assigned physical pin locations. Board-specific package-pin constraints are required. |
| `ZPS7-1` | Warning | The Zynq design lacks the PS7 processing-system block needed for correct default configuration. The intended Zynq system configuration needs review before deployment. |

One violation instance can include many ports: `NSTD-1#1` covers all 22 ports rather than indicating only one affected port. Likewise, three findings in the summary do not mean only three ports are involved.

A warning asks for review; a critical warning identifies a more serious issue that can prevent a later stage. Here, missing I/O standards and locations block normal bitstream generation even though routing completed. Fix them using the actual board schematic and constraints. Lowering their severity would not supply the missing board information.

### 5.3 [route_status.rpt](reports/A/impl/route_status.rpt)

The baseline has **101 logical nets**. Of these, **42 are internally routed and need no general routing**, while **59 are routable and all 59 are fully routed**. There are **zero nets with routing errors**.

The counts reconcile as `101 = 42 + 59`. Internally routed nets use connections internal to device resources rather than requiring the general routing fabric. The decisive checks are that every routable net is fully routed and that routing-error counts are zero. This report describes connectivity, not timing closure or readiness to program a board.

### 5.4 [power.rpt](reports/A/impl/power.rpt)

The summary separates **dynamic power**, associated with the active design, from **device static power**, mainly baseline leakage. Their sum is total on-chip power. Mode A estimates **0.009 W dynamic + 0.104 W static = 0.113 W total**. Static power dominates this small design.

The **Power Supply Summary** breaks current down by voltage rail. `Vccint` supplies internal logic, `Vccaux` auxiliary circuits, `Vcco*` I/O supplies, and `Vccbram` block RAM. `MGT*` rows concern high-speed transceivers; `Vccp*`, `Vccpll`, and the DDR/MIO rows concern Zynq processing-system circuitry; `Vccadc` supplies ADC circuitry.

For each rail, `Total (A)` is the sum of dynamic and static current. Multiply voltage by current to estimate that rail's power: the reported `Vccint` values give `1.000 V × 0.008 A = 0.008 W`. `Powerup (A)` concerns startup current where reported, `Budget (A)` is a user-entered current allowance, and `Margin (A)` is the remaining allowance. `Unspecified` and `NA` indicate missing or inapplicable values, not zero demand; `0.000` can also reflect rounding. Supply power and on-chip thermal power can differ when external loads or startup requirements are included.

The **Environment** section records thermal assumptions:

- Ambient and board temperatures are both 25°C.
- Effective junction-to-ambient resistance, `ThetaJA`, is 11.5°C/W. A simple estimate is `junction temperature ≈ ambient + on-chip power × ThetaJA`, consistent with the reported 26.3°C.
- Airflow is 250 linear feet per minute (about 1.27 m/s), representing moving air rather than still air.
- No heat sink is modeled. `ThetaSA` is sink-to-ambient thermal resistance; its `0.0` entry here does not mean perfect cooling.
- The assumed PCB is medium-sized, 10 × 10 inches, with 8–11 conductive layers. Board size and copper layers affect modeled heat spreading.

These settings are model inputs, not measurements of the PYNQ-Z2. The report's overall confidence is **Low**: more than 75% of inputs lack user-specified activity, and no simulation activity file is loaded by the implementation script. Generating VCD files in the simulation stage does not automatically apply them to `report_power`. Power and temperature should therefore be read as estimates under the recorded assumptions, especially while I/O standards remain unspecified.

## 6. Comparison across Design Variants

The tables below summarize the checked-in A–E reports at their printed precision. Identical totals demonstrate no observed benefit from these options for this FIR; they do not establish that the options are equivalent for larger designs or that every physical route is identical.

### 6.1 Power

| Mode | Total on-chip (W) | Dynamic (W) | Static (W) | Junction temperature (°C) | Confidence |
|---|---:|---:|---:|---:|---|
| A | 0.113 | 0.009 | 0.104 | 26.3 | Low |
| B | 0.113 | 0.009 | 0.104 | 26.3 | Low |
| C | 0.113 | 0.009 | 0.104 | 26.3 | Low |
| D | 0.113 | 0.009 | 0.104 | 26.3 | Low |
| E | 0.113 | 0.009 | 0.104 | 26.3 | Low |

There is no reported power reduction across variants. Approximately 92% of the total is device static power, limiting the visible effect of changes to this very small datapath. No post-synthesis power report is generated by the current flow, so a synthesis-to-route power comparison is unavailable.

### 6.2 Route Status

| Mode | Logical nets | Internally routed | Routable | Fully routed | Routing errors |
|---|---:|---:|---:|---:|---:|
| A | 101 | 42 | 59 | 59 | 0 |
| B | 101 | 42 | 59 | 59 | 0 |
| C | 101 | 42 | 59 | 59 | 0 |
| D | 101 | 42 | 59 | 59 | 0 |
| E | 101 | 42 | 59 | 59 | 0 |

Every variant completes all required routing. Equal net counts describe equal routing completion and scale; they do not measure wire length, congestion, or timing quality.

### 6.3 Utilization

In this table, arrows show **post-synthesis → post-route** counts.

| Mode | Slice LUTs | Registers | CARRY4 | BRAM / DSP | Bonded IOBs | BUFGCTRL | Routed slices |
|---|---|---|---|---|---|---|---:|
| A | 11 → 11 | 36 → 36 | 3 → 3 | 0 / 0 → 0 / 0 | 22 → 22 | 1 → 1 | 9 |
| B | 11 → 11 | 36 → 36 | 3 → 3 | 0 / 0 → 0 / 0 | 22 → 22 | 1 → 1 | 9 |
| C | 11 → 11 | 36 → 36 | 3 → 3 | 0 / 0 → 0 / 0 | 22 → 22 | 1 → 1 | 9 |
| D | 11 → 11 | 36 → 36 | 3 → 3 | 0 / 0 → 0 / 0 | 22 → 22 | 1 → 1 | 9 |
| E | 11 → 11 | 36 → 36 | 3 → 3 | 0 / 0 → 0 / 0 | 22 → 22 | 1 → 1 | 9 |

Neither the synthesis options nor implementation change these resource counts. The arithmetic uses LUTs and carry chains without dedicated DSPs; the short history uses registers without BRAM. Post-route placement packs the logic into nine slices, adding physical occupancy information that an unplaced synthesis netlist does not provide.

Slice LUT occupancy is not the same as summing LUT primitive instances: compatible LUT functions can share a physical LUT site. The primitive breakdown remains one LUT1, one LUT2, eight LUT3s, six LUT4s, and one LUT5, while reported slice LUT usage is 11. Registers remain 36 `FDCE` instances. Read aggregate utilization and primitive counts as complementary views rather than adding them together.

### 6.4 Timing

Arrows again show **post-synthesis → post-route**, in nanoseconds.

| Mode | Setup WNS | Hold WHS | Pulse-width WPWS | TNS / THS / TPWS |
|---|---|---|---|---|
| A | 6.642 → 6.268 | 0.156 → 0.121 | 4.500 → 4.500 | 0 / 0 / 0 → 0 / 0 / 0 |
| B | 6.642 → 6.268 | 0.156 → 0.121 | 4.500 → 4.500 | 0 / 0 / 0 → 0 / 0 / 0 |
| C | 6.642 → 6.268 | 0.156 → 0.121 | 4.500 → 4.500 | 0 / 0 / 0 → 0 / 0 / 0 |
| D | 6.642 → 6.268 | 0.156 → 0.121 | 4.500 → 4.500 | 0 / 0 / 0 → 0 / 0 / 0 |
| E | 6.642 → 6.268 | 0.156 → 0.121 | 4.500 → 4.500 | 0 / 0 / 0 → 0 / 0 / 0 |

Routing reduces setup margin by **0.374 ns** and hold margin by **0.035 ns** in every mode. Post-synthesis analysis uses estimated net delays, whereas post-route analysis uses the implemented connections and clock distribution. Unchanged logic counts therefore do not imply unchanged timing. Pulse-width margin remains 4.500 ns.

The baseline routed critical setup path runs from `p1_s1_reg[4]` to `y_out_reg[9]`. Its data-path delay is **3.778 ns**, comprising **1.790 ns logic** and **1.988 ns routing**, through two CARRY4s, one LUT3, and one LUT4. Routing accounts for approximately 53% of that path delay. Setup slack also includes clock skew, uncertainty, and the destination register's timing requirement, so it is not simply `10 ns − data-path delay`.

All variants meet the specified 100 MHz internal checks. The 20 missing external I/O delay findings remain, however, so these results are not complete interface timing sign-off. Hold margin is also much smaller than setup margin and must be reviewed independently.

## 7. Conclusion

Week 7 turns the synthesized FIR into a fully routed implementation and shows how to read the evidence at each step. All five variants retain 11 slice LUTs, 36 registers, and three CARRY4s, occupy nine routed slices, and route all 59 routable nets without errors. None of the tested synthesis options yields a measurable advantage in the reported implementation metrics.

The main progression is in timing: setup slack changes from 6.642 ns to 6.268 ns and hold slack from 0.156 ns to 0.121 ns as estimated connections become actual routes. Estimated total on-chip power is 0.113 W, but its Low confidence and assumed thermal environment limit the conclusion.

Successful routing is one milestone in the implementation flow. Before board deployment, the project still needs board-specific pin and I/O-standard constraints, complete external timing requirements, and review of the Zynq PS7 configuration. These findings explain why a routed design with passing internal timing is not yet ready for bitstream generation and hardware execution.
