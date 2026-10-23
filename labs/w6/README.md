# Week 6. FIR Filter: FPGA Synthesis Options, Phases, and Reports

## 1. Introduction

This project uses a small, signed, two-stage, three-tap FIR filter to
illustrate how Vivado synthesis reports describe an FPGA design. It focuses
on understanding resource and timing synthesis reports and comparing them
across five synthesis configurations. It also documents the design and
simulation flow and explains the main utilization and timing reports using
excerpts from the baseline run.

The RTL includes `d2`, which is optimized out during synthesis. Also,
post-synthesis timing uses estimated nets; Week 7 checks routed timing.

## 2. Reproduction Flow

1. Run the regression before synthesis:

```bash
$ ./scripts/run_xsim_regression.sh
```

Expected final marker: `[RESULT] WEEK6 INCLASS FIR REGRESSIONS PASSED`.
Check `waves/fir3_pipe2.vcd` and `waves/fir3_pipe2_signed.vcd`.
**Do not run synthesis if the simulation regression fails.**

The simulation regression script uses three core XSim commands:

- `xvlog` compiles the RTL and the selected Verilog testbench.
- `xelab` elaborates the compiled design and creates a simulation snapshot.
- `xsim` runs the snapshot and produces the test results and waveform.

2. Run the controlled synthesis configuration experiments

```bash
$ ./scripts/run_synth_modes.sh A B C D E
```

The synthesis script runs Vivado in batch mode for each selected mode. Its
core Vivado commands are:

- `read_verilog` loads `rtl/fir3_pipe2.v` into the synthesis flow.
- `read_xdc` loads the 10 ns clock constraint from
  `constraints/fir3_pipe2.xdc`.
- `synth_design` elaborates and optimizes the RTL using the selected mode
  options.

The synthesis log reports that the unused `d2_reg` sequential element was
removed:

```text
WARNING: [Synth 8-6014] Unused sequential element d2_reg was removed. [/home/kaiden/EDA/w6/rtl/fir3_pipe2.v:36]
```

This corresponds to the RTL signal `d2`: it exists in the source but is not
consumed by the FIR datapath, so synthesis removes the associated hardware.
The warning is useful evidence that synthesis has optimized away logic that
does not affect any output.

The synthesis flow then checks timing coverage, writes utilization and timing
reports, saves the ten worst setup paths, and writes a post-synthesis
checkpoint.

## 3. Design and Verification

<p align="center"><img src="images/design.png" alt="design" /></p>

`rtl/fir3_pipe2.v` is the same pipelined FIR design used in Week 5. It is a
three-tap signed FIR filter with coefficients `[1, 2, 1]`. The design
sign-extends each 8-bit input sample to 10 bits and maintains a short history
of accepted samples so it can calculate the weighted sum:

```text
y[n] = x[n] + 2x[n-1] + x[n-2]
```

The datapath is divided into two clocked stages. Stage 1 captures the current
sample history and the three coefficient products. Stage 2 adds the registered
products and registers the output. The `valid_in` signal controls when a
sample is accepted, and `valid_out` indicates when the corresponding
pipeline result is available. Invalid input cycles hold the datapath state and
do not advance the sample history.

The project uses two self-checking testbenches:

- `tb/tb_fir3_pipe2.v` checks normal FIR operation, pipeline latency, and
  invalid bubbles between accepted samples.
- `tb/tb_fir3_pipe2_signed.v` checks signed boundary behavior using `-128` and
  verifies the corresponding negative FIR results.

- PYNQ-Z2 FPGA target `xc7z020clg400-1`; source XDC is the uploaded Week 6 `constraints/fir3_pipe2.xdc` (10 ns clock).
- RTL top `fir3_pipe2`, simulation tops `tb_fir3_pipe2`, `tb_fir3_pipe2_signed`.

## 4. Understanding Synthesis Options

<p align="center"><img src="images/modes.png" alt="mode options" /></p>

| Mode | Synthesis option | Expected impact |
|---|---|---|
| A | Default settings | Reference implementation for all comparisons |
| B | `-directive AreaOptimized_high` | Tests area-oriented optimization against timing |
| C | `-flatten_hierarchy full` | Tests whether complete hierarchy visibility changes optimization |
| D | `-resource_sharing off` | Tests the cost of disabling arithmetic sharing |
| E | `-global_retiming on` | Tests whether register movement improves timing |

Each mode changes exactly one synthesis setting.

## 5. Understanding Synthesis Phases

The `logs/synth_*.log` files show the following Vivado synthesis phases. The
same major phases appear in modes A through E; mode E also reports a retiming
step during technology mapping.

| Phase | Interpretation |
|---|---|
| RTL Elaboration | Reads the RTL, builds the design hierarchy, and identifies the modules, registers, and arithmetic components. The logs also report that the unused `d2_reg` sequential element was removed. |
| Handling Custom Attributes | Processes synthesis attributes before optimization. |
| RTL Optimization Phase 1 | Performs initial RTL-level simplification and optimization before constraints are applied. |
| Constraint Validation | Parses the XDC file and validates the clock and other design constraints. |
| Loading Part and Timing Information | Loads the target device resources and timing data for `xc7z020clg400-1`. |
| Applying `set_property` XDC Constraints | Applies non-timing properties from the XDC constraints. |
| RTL Optimization Phase 2 | Continues RTL optimization after the device and constraints are available; the logs report the inferred adders and registers. |
| Cross Boundary and Area Optimization | Optimizes logic across hierarchy boundaries and considers area-oriented transformations. |
| Applying XDC Timing Constraints | Applies clock timing constraints to the synthesized design. |
| Timing Optimization | Optimizes the design with timing requirements in view. |
| Technology Mapping | Maps optimized logic to FPGA primitives such as LUTs, `CARRY4`, and flip-flops. In mode E, global retiming is attempted here, but the logs report zero forward and backward moves. |
| IO Insertion | Inserts input and output buffer primitives and performs final flattening and netlist cleanup before reporting. |
| Renaming and Hierarchy Cleanup | Renames generated instances, ports, and nets, rebuilds the user hierarchy, and preserves final netlist organization. |
| Writing Synthesis Report | Reports black boxes and cell usage, then completes synthesis. All five logs report zero errors, zero critical warnings, and zero warnings. |

## 6. Understanding Synthesis Reports

The following reports are generated for the baseline synthesis, mode A, in
`reports/A/`. They provide evidence about resource usage, timing coverage, and
critical paths without requiring the full raw report output to be reproduced
here.

### 6.1 `utilization.rpt`

**Utilization Design Information** describes how much of the target FPGA is
used by the synthesized design. It separates LUTs, registers, memory, DSP,
I/O, and clocking resources and compares each used count with the device
capacity. From this report, we can determine whether the design is area
limited, identify which resource types dominate implementation, and see
whether arithmetic mapped to LUT/carry logic or to dedicated DSP blocks.

**Summary of Registers by Type** shows the control characteristics of the
inferred registers, including clock enables and synchronous or asynchronous
controls. It helps verify that the synthesized register structure matches the
RTL and reveals whether reset or enable logic introduces unexpected hardware.

**Memory**, **DSP**, **IO and GT Specific**, and **Clocking** summarize the
specialized device resources. These tables reveal whether the design infers
block RAM, uses DSP slices, consumes ordinary or specialized I/O resources,
or requires additional clock-management primitives.

**Primitives** gives the post-synthesis cell-level implementation. It lets us
connect the aggregate utilization counts to concrete FPGA primitives such as
`FDCE`, `IBUF`, `OBUF`, LUTs, `CARRY4`, and `BUFG`, and helps explain how the
RTL was mapped into hardware.

For this FIR, the report shows a small implementation using 36 flip-flops, 11
LUTs, three `CARRY4` primitives, 22 I/O buffers, and one global clock buffer.
No block RAM or DSP resources are used.

### 6.2 `check_timing.rpt`

**Timing Checks** lists checks for missing clocks, constant or multiple clocks,
generated clocks, timing loops, and incomplete input or output delay
constraints. We can use it to distinguish a clean timing setup from a design
whose timing results are incomplete because constraints are missing.

For this design, the clock and loop checks pass, but the report identifies
nine input ports without input delays and eleven output ports without output
delays. Therefore, internal register-to-register timing is analyzed, while
external interface timing is not fully modeled.

### 6.3 `timing_summary.rpt`

**Design Timing Summary** consolidates setup, hold, and pulse-width results.
The key metrics are worst negative slack (`WNS` and `WHS`), total negative
slack (`TNS` and `THS`), and worst and total pulse-width slack (`WPWS` and
`TPWS`). Positive worst slack and zero total negative slack indicate that the
checked paths meet their requirements.

**Intra Clock Table** groups timing results by clock domain. It helps identify
which clock is responsible for a violation and whether timing problems are
localized to one clock domain. Here, the 100 MHz `clk` domain has positive
setup, hold, and pulse-width margins with no failing endpoints.

**Clock Summary** identifies each clock's waveform, period, and frequency. It
confirms that the design is analyzed against the intended 10 ns clock period.

**Max Delay Paths** describes setup paths at the slow corner, including source
and destination registers, logic depth, routing delay, clock skew, and slack.
It shows where the critical path is and whether delay is dominated by logic or
routing. In this design, the worst setup path passes through LUT and `CARRY4`
logic and has substantial positive slack.

**Min Delay Paths** describes hold paths at the fast corner. It shows whether
new data reaches a destination too early and explains the effect of clock skew
and minimum data delay on hold margin. The reported path has positive hold
slack, so it does not violate the hold requirement.

**Pulse Width Checks** verifies the minimum clock period and high- and
low-pulse-width requirements. It confirms that the 10 ns period and 5 ns
half-cycles exceed the required minimums.

**Unconstrained Paths** identifies paths for which no finite timing requirement
was available. Such paths are not proof of safe timing; they indicate where
additional interface constraints may be needed.

### 6.4 `worst10_setup_paths.rpt`

**Max Delay Paths** is repeated for the ten worst setup paths in this report.
The ordered slack values show the critical path and the margin on the next
nine paths. Reviewing these paths helps determine whether timing risk is
concentrated in one path or spread across many similar datapaths, and exposes
the registers, logic levels, and routing segments most worth optimizing.

## 7. Result

This three-tap sequential FIR is a fairly small design. Its datapath contains
only a few registers, LUTs, and carry-chain additions, so changing synthesis
options may have no observable impact on the synthesized result. The
comparison must therefore use the generated logs and reports rather than
assuming that an option produces a difference.

### 7.1 Resource Comparison

| Mode | FDCE | OBUF | IBUF | LUT1 | LUT2 | LUT3 | LUT4 | LUT5 | CARRY4 | BRAM | DSP |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| A | 36 | 11 | 11 | 1 | 1 | 8 | 6 | 1 | 3 | 0 | 0 |
| B | 36 | 11 | 11 | 1 | 1 | 8 | 6 | 1 | 3 | 0 | 0 |
| C | 36 | 11 | 11 | 1 | 1 | 8 | 6 | 1 | 3 | 0 | 0 |
| D | 36 | 11 | 11 | 1 | 1 | 8 | 6 | 1 | 3 | 0 | 0 |
| E | 36 | 11 | 11 | 1 | 1 | 8 | 6 | 1 | 3 | 0 | 0 |

Observations: 

- All modes use 36 `FDCE` flip-flops, 11 `OBUF` instances, and 11 `IBUF`
  instances.
- The LUT primitive breakdown is identical: one `LUT1`, one `LUT2`, eight
  `LUT3`, six `LUT4`, and one `LUT5`.
- All modes use three `CARRY4` arithmetic primitives.
- No mode uses block RAM or DSP resources; the I/O primitives account for the
  design's external ports.
- The identical resource counts show no observable resource impact from the
  tested options.

### 7.2 Timing Comparison

| Mode | WNS (ns) | TNS (ns) | WHS (ns) | THS (ns) | WPWS (ns) | TPWS (ns) |
|---|---:|---:|---:|---:|---:|---:|
| A | 6.642 | 0.000 | 0.156 | 0.000 | 4.500 | 0.000 |
| B | 6.642 | 0.000 | 0.156 | 0.000 | 4.500 | 0.000 |
| C | 6.642 | 0.000 | 0.156 | 0.000 | 4.500 | 0.000 |
| D | 6.642 | 0.000 | 0.156 | 0.000 | 4.500 | 0.000 |
| E | 6.642 | 0.000 | 0.156 | 0.000 | 4.500 | 0.000 |

Observations:

- All modes pass setup, hold, and pulse-width timing with zero total
  violation.
- WNS, TNS, WHS, THS, WPWS, and TPWS are identical across all modes.
- The timing reports therefore show no measurable timing benefit from the
  area-optimization directive, flattening, disabling resource sharing, or
  enabling global retiming.
- Every mode reports 9 inputs without input delays and 11 outputs without
  output delays, so external I/O timing remains unconstrained.

## 8. Conclusion

The five synthesis modes apply different optimization strategies: mode A uses
the default settings, mode B applies `AreaOptimized_high`, mode C enables full
hierarchy flattening, mode D disables resource sharing, and mode E enables
global retiming. For this small FIR, none of these options changes the
measured implementation. Every mode uses 36 `FDCE` registers, 11 LUTs, three
`CARRY4` primitives, 22 I/O buffers, no block RAM, and no DSP resources.
Likewise, every mode has the same timing results: WNS `6.642 ns`, TNS
`0.000 ns`, WHS `0.156 ns`, THS `0.000 ns`, WPWS `4.500 ns`, and TPWS
`0.000 ns`.

Going forward, synthesis reports should serve as evidence for design decisions
rather than assuming that an optimization option will improve the result.
Timing coverage and constraints should be checked first, followed by resource
counts, critical-path details, slack, and unconstrained paths across
controlled runs. In a serious project, input and output delays should also be
specified so that external interface paths are constrained and the static
timing analysis (STA) results are correct. This makes it possible to
distinguish a real improvement from a setting that has no observable effect,
identify missing constraints before trusting timing conclusions, and determine
when a larger or more complex design is needed to reveal an optimization
trade-off.
