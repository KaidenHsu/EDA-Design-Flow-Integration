# Files and Usage

## Project Layout

| Path | Purpose |
|---|---|
| [`run_lab.py`](../run_lab.py) | Loads the configuration, runs synthesis, and saves logs and run metadata. |
| [`config/lab_config.json`](../config/lab_config.json) | Defines the RTL files, top module, ports, target library, clock periods, I/O delays, and compile command. |
| [`scripts/run_dc.tcl`](../scripts/run_dc.tcl) | Reads and links the RTL, applies timing constraints, compiles the design, and writes the netlist and reports. |
| `results/10ns_period/` and `results/8ns_period/` | Store the outputs for each clock period. |
| `results/manifest.json` | Records configuration and RTL hashes, tool options, run status, and log paths. |

Each run overwrites the manifest and replaces the generated reports and logs for the configured periods.

## Synthesis Settings

The 10 ns and 8 ns runs use the same RTL, T18 library corner, I/O delays, and compile command so the comparison isolates the requested clock period.

The configured delays are 2.0 ns maximum and 0.5 ns minimum for inputs, and 2.5 ns maximum and −0.2 ns minimum for outputs. These values assume the library time unit is nanoseconds. Input transition and output load are not independently characterized, so the reports reflect these synthesis assumptions rather than a complete interface model.

The asynchronous reset, `rst_n`, has no blanket false-path exception. Its recovery/removal checks and timing assumptions need separate review.

The default synthesis command is `compile`; `compile_ultra` can be selected in the configuration when the installation and license support it. Synopsys software and proprietary T18 libraries are installed separately. The configured `.db` path refers to the server installation.

## Run and Review

From the project root:

```bash
python3 run_lab.py --tool dc
```

1. Check the configuration and RTL revision before running. The manifest records the source hashes used for the comparison.
2. Check `tool.log` and the manifest for completion or errors. A launcher or license error, including `DCSH-1`, needs to be resolved before evaluating synthesis results.
3. Inspect `mapped.v` for the mapped cell instances, register implementation, reset and enable logic, and arithmetic structure.
4. Review `area.rpt` and `refs.rpt` for cell area and cell usage. Cell area can be expressed as `A_cells = Σ N_i A_i`, where `N_i` is the instance count and `A_i` is the library area of each cell type.
5. Read `setup.rpt` for maximum-delay paths and `hold.rpt` for minimum-delay paths. Check startpoints, endpoints, required times, and slack.
6. Review `timing_coverage.rpt`, `violations.rpt`, and tool warnings for constraint issues. `check_timing` checks constraint sanity; it does not establish timing signoff.
7. Compare the 10 ns and 8 ns results after both runs complete, using the same configuration apart from the clock period.

The runner requires a completion marker, a successful tool exit, and nonempty output files before reporting success. Completed synthesis still requires review of timing constraints, warnings, and violations.

## Generated Reports

| File | Contents |
|---|---|
| `mapped.v` | Mapped Verilog netlist. |
| `area.rpt` | Cell counts and area summary. |
| `refs.rpt` | Cell and subdesign reference usage. |
| `setup.rpt` | Reported maximum-delay paths. |
| `hold.rpt` | Reported minimum-delay paths. |
| `timing_coverage.rpt` | Output from `check_timing`. |
| `violations.rpt` | Reported constraint violations. |
| `tool.log` | Captured tool output and errors. |
