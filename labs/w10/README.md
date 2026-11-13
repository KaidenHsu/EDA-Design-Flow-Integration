# Week 10: FIR Filter: Cell-based Synthesis Phases and Reports

## 1. Introduction

This project takes the Week 4 three-tap FIR filter through logic synthesis using Synopsys Design Compiler and the ARM/TSMC T18 standard-cell library. The filter computes `y_out = d0 + 2*d1 + d2` from registered sample history. The synthesis flow translates this RTL into a mapped netlist containing flip-flops, arithmetic cells, and register-enable logic.

The experiment compares clock periods of 10 ns and 8 ns while keeping the RTL, library corner, I/O delays, and compile command fixed. Tool logs show the mapping and optimization phases, while the generated netlists and reports show the resulting circuit structure, cell area, and setup and hold timing. The comparison examines whether the tighter clock target changes the implementation and how it affects the reported timing margins.

## 2. Reproduction Flow

Run from the project root on a machine with Design Compiler and the configured T18 library installed:

```bash
$ python3 run_lab.py --tool dc
```

The runner loads `config/lab_config.json` and invokes Design Compiler through the `dc` site wrapper. It saves reports and logs in `results/10ns_period/` and `results/8ns_period/`, along with configuration and RTL hashes in `results/manifest.json`. New runs replace the generated reports and logs for both periods and overwrite the manifest.

The runner performs synthesis only. Run the RTL testbench separately before synthesis. See [files_and_usage.md](docs/files_and_usage.md) for the file layout and report review workflow.

## 3. RTL Design

The synthesis input is [rtl/fir3_seq.v](rtl/fir3_seq.v), the Week 4 FIR filter baseline. It accepts signed 8-bit samples and computes a signed 10-bit output with coefficients `[1, 2, 1]`:

```text
y_out = d0 + 2*d1 + d2
```

Three 10-bit registers store the sample history and update when `valid_in` is asserted. The design uses an active-low asynchronous reset. `valid_out` is registered, while `y_out` is combinational. This lab does not repeat functional verification.

## 4. Synthesis Constraints

This project does not use a separate `.sdc` file. The synthesis constraints are included directly in [run_dc.tcl](scripts/run_dc.tcl), which applies `create_clock`, `set_input_delay`, and `set_output_delay` using the settings in [lab_config.json](config/lab_config.json).

[run_lab.py](run_lab.py) loads [config/lab_config.json](config/lab_config.json) and uses `export_env()` with `subprocess.run(..., env=...)` to pass `W10_*` variables to DC without changing the calling shell. Numbers and paths become strings; file and port lists are joined with `|`. In Tcl, `must_env` reads and validates each value from `::env`, and lists are split on `|`. For example, `set period [must_env W10_PERIOD_NS]` supplies the period used by `create_clock -name core_clk -period $period $clk`.

| Setting | Value |
|---|---|
| Top Module | `fir3_seq` |
| Target Library | ARM/TSMC T18 `typical.db` |
| Clock | Timing clock named `core_clk`, attached to RTL input port `clk`; periods of 10 ns and 8 ns |
| Input Delays | Maximum 2.0 ns; minimum 0.5 ns, relative to `core_clk` |
| Output Delays | Maximum 2.5 ns; minimum −0.2 ns, relative to `core_clk` |
| Compile Command | `compile` |

The input delays apply to `x_in` and `valid_in`, excluding `rst_n`. No `set_false_path` exception is applied to reset; its deassertion requires separate recovery/removal review. In addition to the configured timing budgets above, the following delay-modeling settings remain unspecified:

| Unspecified Setting | What It Describes | Why It Matters |
|---|---|---|
| Input Transition | How quickly an input voltage rises or falls | Input slew affects the delay through receiving cells. |
| Output Load | The capacitance driven by an output | A larger load generally increases output delay and may require stronger cells. |
| Wire-Load Model | A statistical estimate of internal wiring before layout | Estimated wiring resistance and capacitance affect net delay and loading. |

Input/output delays specify external timing budgets, not input slew or output capacitance. Results depend on DC's applicable defaults and library settings for unspecified quantities; the area reports confirm that no wire-load model was active.

## 5. Synthesis Phases

10ns: [tool.log](results/10ns_period/tool.log), 8ns: [tool.log](results/8ns_period/tool.log).

| Phase | Interpretation | Observations |
|---|---|---|
| Pass 1 Mapping | Begins technology mapping and updates timing information. | Both runs process `fir3_seq` and update timing information. |
| Implementation Selection | Evaluates implementation alternatives for inferred arithmetic and DesignWare components. | Builds `DW01_add_width10` candidates labeled `rpl` and `cla`, then processes the two generated adder modules. Candidate models are not additional retained instances. |
| Mapping Optimizations (Medium Effort) | Refines mapped logic and cell choices against timing, area, and design-rule objectives. | Displayed area decreases from 9134.3 to 4227.9 in both runs. |
| Delay Optimization | Refines the implementation to improve timing. | Displayed area remains 4227.9; worst negative slack, setup cost, and design-rule cost remain zero. |
| Area-Recovery Phase (Cleanup) | Reduces area while accounting for timing and design-rule constraints. | Displayed area decreases from 4227.9 to 4187.9 in both runs. |
| Optimization Complete | Ends compilation; the script subsequently generates reports and the mapped netlist. | Both runs finish compilation and generate the required outputs. |

Both clock targets follow the same logged phase sequence and area progression. Most of the displayed area reduction occurs during mapping optimization, followed by a smaller reduction during area recovery. The log area values are rounded library area units. Zero worst negative slack does not establish hold closure: the final reports still show a −0.04 ns hold violation.

## 6. Synthesized Netlist

10ns: [mapped.v](results/10ns_period/mapped.v), 8ns: [mapped.v](results/8ns_period/mapped.v).

### 6.1 Generated Adder Modules

DC implements the RTL additions as two generated DesignWare-derived modules. Their definitions are identical in the 10 ns and 8 ns netlists, including cell types, drive-strength variants, and internal connections.

| Module | Connected Operation | Cells in 10 ns Netlist | Cells in 8 ns Netlist |
|---|---|---|---|
| `fir3_seq_DW01_add_1` | `d2 + d0` | 8 `ADDFX2`, 1 `XOR3X2`, 1 `AND2X2`, 1 `XOR2X1` | Same |
| `fir3_seq_DW01_add_0` | `(d1 << 1) + (d2 + d0)` | 7 `ADDFX2`, 1 `XOR3X2`, 1 `AND2X2`, 1 `XOR2X1` | Same |

**Observations:**

- **Arithmetic reassociation:** The RTL forms `s0 = d0 + (d1 <<< 1)` followed by `y_out = s0 + d2`. In the netlist, `_add_1` receives `p2` and `p0`, which are the `d2` and `d0` register outputs. Its sum feeds `_add_0`, whose other input is `{p1, 1'b0}`. DC has therefore rearranged the expression into `(d0 + d2) + (d1 << 1)`. The generated wires named `s0` carry this new intermediate sum; the retained name does not imply the original RTL grouping.

- **Ripple-carry implementation:** In `_add_1`, each `ADDFX2` full-adder cell passes its `CO` output to the next bit's `CI` input. Bits 1–8 form a serial carry chain. Bit 0 uses `XOR2X1` for the sum and `AND2X2` for the carry because the instance's carry-in is fixed at zero. Bit 9 uses `XOR3X2` to combine the two operand bits and incoming carry; no final carry-generation cell is needed because only the 10-bit sum is consumed.

- **Constant-bit optimization:** `_add_0` has one fewer full adder. Its shifted operand has `A[0] = 0`, and carry-in is also zero, so `SUM[0]` is wired directly to `B[0]`. There is no carry from bit 0. Bit 1 consequently uses an XOR/AND pair, bits 2–8 use seven full adders, and bit 9 uses a three-input XOR. The different cell counts reflect the known zero bit in this specific instance.

- **Wiring replaces multiplication:** The coefficient of two is implemented by connecting the `d1` bits one position higher and appending a zero. There is no multiplier or barrel shifter. Neither generated module contains flip-flops, so the two adders form a combinational output path with no extra pipeline stage.

- **The timing path crosses both modules:** The reported worst setup path passes through `_add_1` and then `_add_0`, including their carry logic. The 8 ns run retains the same ripple-carry structure and exact arithmetic cell variants as the 10 ns run; it does not introduce a different adder architecture or larger arithmetic cells.

### 6.2 Register and Enable Logic

The following counts are direct instances inside the top module, excluding cells inside the two adder modules.

| Cell | Role in This Netlist | 10 ns | 8 ns |
|---|---|---:|---:|
| `DFFRHQX1` | Sample-history and `valid_out` flip-flops, with `CK` and active-low `RN` pins | 31 | 31 |
| `AOI22X1` | Two-product inverted logic used with inverters for register input selection | 27 | 27 |
| `INVX1` | Selection-logic inversion and replicated enable polarity signals | 40 | 40 |
| `NAND2X1` | Shared input-sign/enable term | 1 | 1 |
| `OAI2BB1X1` | Selection logic for `d0` bits 7–9 using the shared sign-input term | 3 | 3 |

**Observations:**

- **Enable is implemented before the D pin:** The sample-history flip-flops have `D`, `CK`, `RN`, and `Q` connections, with no dedicated enable pin. For example, the 10 ns instance `U70` combines the old `p0[0]` value with `x_in[0]` through `AOI22X1`, and `U69` inverts its output before `d0_reg[0].D`. Together they implement `D = (!valid_in & old_value) | (valid_in & new_value)`. This is the RTL's hold-or-update behavior mapped into gates.

- **Sign extension shares logic:** `U121` forms a NAND of `x_in[7]` and an enabled-polarity signal. Its output feeds three `OAI2BB1X1` cells driving `d0_reg[7]`, `d0_reg[8]`, and `d0_reg[9]`. The repeated sign-bit input is shared while each register bit retains its own hold path.

- **Control replication changes slightly between runs:** Multiple `INVX1` instances generate copies of `!valid_in`. Some selection gates use different copies in the 8 ns netlist, and some instances are reordered or renumbered. For example, `U120.A0` changes from `n65` to `n64`; both are outputs of inverters driven by `valid_in`. The difference is in control-net connectivity, while the register count, arithmetic modules, and cell-type inventory remain unchanged.

- **Reset and output structure are preserved:** All 31 flip-flops connect `CK` to `clk` and `RN` to `rst_n`: 30 store sample history and one stores `valid_out`. `y_out` is driven directly by `_add_0`. These observations describe the mapped structure; they are not a formal equivalence result.

## 7. Results

### 7.1 Area and Mapping

10ns: [area.rpt](results/10ns_period/area.rpt), [refs.rpt](results/10ns_period/refs.rpt), 8ns: [area.rpt](results/8ns_period/area.rpt), [refs.rpt](results/8ns_period/refs.rpt).

| Property | 10 ns | 8 ns |
|---|---:|---:|
| Total Cells (`area.rpt`) | 128 | 128 |
| Combinational Cells (Reported) | 92 | 92 |
| Sequential Cells (Reported) | 31 | 31 |
| Buffer/Inverter Cells (Reported) | 40 | 40 |
| `DFFRHQX1` Instances (`refs.rpt`) | 31 | 31 |
| Hierarchical DesignWare Adder Instances (`refs.rpt`) | 2 | 2 |
| Combinational Area (Library Area Units) | 2022.451210 | 2022.451210 |
| Noncombinational Area (Library Area Units) | 2165.486420 | 2165.486420 |
| Total Cell Area (Library Area Units) | 4187.937630 | 4187.937630 |
| Net Interconnect Area | Undefined | Undefined |
| Total Area Including Interconnect | Undefined | Undefined |
| Macros / Black Boxes | 0 | 0 |

**Observations:**

- Both runs have identical reference inventories and reported cell areas. The two hierarchical adder references are `fir3_seq_DW01_add_0` and `fir3_seq_DW01_add_1`. The reported combinational and sequential counts do not sum to the reported total, so the table preserves DC's categories separately. Buffer/inverter area is included in combinational area.

- Both area reports state `Net Interconnect area: undefined (No wire load specified)`. The cell area is available, but the reports provide no interconnect-area estimate or total area including interconnect. Area values are left in library units because these reports do not establish the physical area unit.

### 7.2 Setup and Hold Timing

10ns: [setup.rpt](results/10ns_period/setup.rpt), [hold.rpt](results/10ns_period/hold.rpt), [violations.rpt](results/10ns_period/violations.rpt), 8ns: [setup.rpt](results/8ns_period/setup.rpt), [hold.rpt](results/8ns_period/hold.rpt), [violations.rpt](results/8ns_period/violations.rpt).

| Property | 10 ns | 8 ns |
|---|---:|---:|
| Worst of 10 Reported Setup Paths | +4.99 ns | +2.99 ns |
| Setup Path Arrival Time | 2.51 ns | 2.51 ns |
| Setup Path Required Time | 7.50 ns | 5.50 ns |
| Worst of 10 Reported Hold Paths | −0.04 ns | −0.04 ns |
| Violating Hold Path Actual Delay | 0.16 ns | 0.16 ns |
| Violating Hold Path Required Delay | 0.20 ns | 0.20 ns |

**Observations:**

- The worst reported setup path runs from `d0_reg[1]` to `y_out[9]`, with an arrival time of 2.51 ns in both runs. Reducing the clock period from 10 ns to 8 ns reduces the required time from 7.50 ns to 5.50 ns, lowering the reported slack by exactly 2.00 ns without changing the reported cell inventory or area.

- Both runs report a hold violation from `valid_out_reg` to `valid_out`: the actual path delay is 0.16 ns against a required 0.20 ns, giving −0.04 ns slack. The violation is recorded in both `hold.rpt` and `violations.rpt`.

### 7.3 Constraint Checks and Warnings

10ns: [timing_coverage.rpt](results/10ns_period/timing_coverage.rpt), [tool.log](results/10ns_period/tool.log), 8ns: [timing_coverage.rpt](results/8ns_period/timing_coverage.rpt), [tool.log](results/8ns_period/tool.log).

| Property | 10 ns | 8 ns |
|---|---|---|
| Tool Exit Code | 0 | 0 |
| Completion Marker | Present | Present |
| Diagnostic Warnings From `check_timing` | None reported | None reported |
| `VER-318` Unsigned-to-Signed Assignment Warnings | 1 | 1 |
| `VER-1065` RTL Ingestion Notice | Present | Present |
| `VO-4` Netlist Output Notice | Present | Present |

**Observations:**

- Neither `timing_coverage.rpt` contains diagnostic warnings from `check_timing`. This does not establish complete timing coverage or override the reported hold violation. The timing reports use ideal clock networks, and interconnect area remains undefined.

- Each tool log records one `VER-318` unsigned-to-signed assignment warning at RTL line 24, a `VER-1065` notice recommending `analyze`/`elaborate` for RTL ingestion, and a `VO-4` notice that the netlist contains `assign` or `tran` statements. The synthesis flow does not perform functional equivalence checking.

## 8. Conclusion

Both clock targets produce the same cell inventory and total cell area of 4187.937630 library area units. DC implements the FIR arithmetic with two generated adder modules containing ripple-carry logic and uses 31 resettable flip-flops for sample history and `valid_out`. The adder definitions are identical between runs, although some control-net connections and instance names differ. Tightening the period from 10 ns to 8 ns reduces the worst reported setup slack from +4.99 ns to +2.99 ns without changing the reported setup-path arrival time of 2.51 ns.

Both runs retain a −0.04 ns hold violation at `valid_out`, so positive reported setup slack does not establish timing closure. The results also use ideal clock networks, omit explicit input-transition and output-load settings, and provide no wire-load-based interconnect-area estimate. The completed runs demonstrate synthesis and mapping under the stated constraints; resolving the hold violation and reviewing the timing assumptions remain necessary before drawing conclusions about implementation timing closure.
