# Lab Files and Usage

Use this guide to locate inputs and outputs and run individual lab commands. For execution order, checkpoint dependencies, and failure handling, see [Lab Automation](automation.md).

## Lab Inputs and Scripts

| File or directory | Role |
| --- | --- |
| [config/default.env](../config/default.env) | Sets the netlist, NDM, and output paths. |
| [input/mapped.v](../input/mapped.v) | Supplies the mapped Verilog for the 3-tap FIR filter. ICC2 imports it with `fir3_reference` as the top module. |
| `input/t18_typical.dnm/` | Supplies the T18 reference library for floorplanning. The wrapper builds it from the installed T18 kit. Build logs and status remain under `output/0_build_reference_library/`. |
| [input/week11_10ns_io_fixed.sdc](../input/week11_10ns_io_fixed.sdc) | Supplies the clock and I/O timing constraints for the ICC2 flow. |
| [scripts/run_icc2.py](../scripts/run_icc2.py) and [tcl/](../tcl/) | The Python runner validates inputs, copies prerequisite checkpoints, and launches the Tcl scripts that perform each ICC2 stage. |

See the [README results section](../README.md#6-results) for experiment output directories.

The Tcl filenames identify the action and, for the experiment scripts, the experiment letter.

- [0_build_reference_library.tcl](../tcl/0_build_reference_library.tcl)
- [1_A_create_floorplan.tcl](../tcl/1_A_create_floorplan.tcl)
- [2_B_build_cell_rails.tcl](../tcl/2_B_build_cell_rails.tcl)
- [3_C_place_cells_with_mesh.tcl](../tcl/3_C_place_cells_with_mesh.tcl)
- [3_C_report_routing_congestion.tcl](../tcl/3_C_report_routing_congestion.tcl)
- [4_D_repair_hold_timing.tcl](../tcl/4_D_repair_hold_timing.tcl)
- [5_reopen_checkpoint.tcl](../tcl/5_reopen_checkpoint.tcl)

For individual stage commands, see the [slide commands](SLIDE_COMMANDS.md).

## Offline Exercises

`python3 scripts/run_lab.py` runs simplified Python exercises for Labs A–D without launching ICC2 and writes illustrative JSON reports to `output/6_gen_offline_reports/`. Use `--lab A` (or B, C, or D) to run a single exercise.

The offline runner calls [scripts/gen_offline_reports.py](../scripts/gen_offline_reports.py), which reads [power_grid_edges.json](../student_work/power_grid_edges.json) for Lab B and [placement.json](../student_work/placement.json) for Lab C. Edit the fixtures and rerun the corresponding exercise to see how the candidate audits change. Follow the [student worksheet](STUDENT_WORKSHEET.md) for the exercise prompts.

## Submission

Record your findings in [student_work/answers.md](../student_work/answers.md). The wrapper finishes by running [scripts/collect_submission.py](../scripts/collect_submission.py), which packages your answers, fixtures, and available model reports into `Week12_submission.zip`. Run the collector again after editing your answers to refresh the ZIP.
