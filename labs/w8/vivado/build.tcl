# Week 8 fresh PYNQ-Z2 build, from Week 6 original FIR-derived debug-only RTL.
# Vivado project flow; do NOT reuse Week 7 10ns post-route DCP for board programming.

# ======================================================================================
#                  1. Initialize Paths and Validate Source Files
# ======================================================================================

# Resolve all paths relative to this script so the flow can be launched from any directory.
set root [file normalize [file join [file dirname [info script]] ..]]
cd $root

# Identify the project, RTL sources, and board timing constraints.
set proj [file join $root build pynq_z2]
set debug_rtl [file join $root rtl fir3_pipe2_debug.v]
set wrapper_rtl [file join $root rtl fir3_debug_wrapper.v]
set top_rtl [file join $root rtl fir3_pynqz2_top.v]
set board_xdc [file join $root constraints fir3_pynqz2.xdc]

# Create output directories and reject incomplete source snapshots before opening Vivado.
file mkdir [file join $root build] [file join $root artifacts] [file join $root checkpoints] [file join $root reports]
foreach f [list \
    $debug_rtl $wrapper_rtl $top_rtl $board_xdc] {
    if {![file isfile $f] || [file size $f] < 20} {error "Missing Week 8 source file: $f"}
}

# ======================================================================================
#                  2. Create Vivado Project and Register Design Sources
# ======================================================================================

# Create a fresh project for the PYNQ-Z2 device and register the design sources.
create_project -force fir3_pynqz2 $proj -part xc7z020clg400-1
set_property target_language Verilog [current_project]
add_files [list $debug_rtl $wrapper_rtl $top_rtl]
add_files -fileset constrs_1 $board_xdc
set_property top fir3_pynqz2_top [current_fileset]

# ======================================================================================
#                  3. Configure and Generate VIO Control IP
# ======================================================================================

# Configure and generate the VIO controls and observations used during bring-up.
create_ip -name vio -vendor xilinx.com -library ip -module_name vio_fir3
set_property -dict [list \
    CONFIG.C_NUM_PROBE_IN {2} CONFIG.C_NUM_PROBE_OUT {3} \
    CONFIG.C_PROBE_IN0_WIDTH {1} CONFIG.C_PROBE_IN1_WIDTH {10} \
    CONFIG.C_PROBE_OUT0_WIDTH {1} CONFIG.C_PROBE_OUT1_WIDTH {1} CONFIG.C_PROBE_OUT2_WIDTH {8} \
] [get_ips vio_fir3]
generate_target all [get_ips vio_fir3]
export_ip_user_files -of_objects [get_ips vio_fir3] -no_script -sync -force -quiet

# ======================================================================================
#                  4. Configure and Generate ILA Debug IP
# ======================================================================================

# Configure and generate the ILA probes, including the three 10-bit FIR history registers.
create_ip -name ila -vendor xilinx.com -library ip -module_name ila_fir3
set_property -dict [list \
    CONFIG.C_NUM_OF_PROBES {10} CONFIG.C_PROBE0_WIDTH {1} \
    CONFIG.C_PROBE1_WIDTH {1} CONFIG.C_PROBE2_WIDTH {8} \
    CONFIG.C_PROBE3_WIDTH {1} CONFIG.C_PROBE4_WIDTH {1} \
    CONFIG.C_PROBE5_WIDTH {10} CONFIG.C_PROBE6_WIDTH {1} \
    CONFIG.C_PROBE7_WIDTH {10} CONFIG.C_PROBE8_WIDTH {10} CONFIG.C_PROBE9_WIDTH {10} \
] [get_ips ila_fir3]
generate_target all [get_ips ila_fir3]
export_ip_user_files -of_objects [get_ips ila_fir3] -no_script -sync -force -quiet

# Refresh the design-source compilation order after adding RTL and generated IP files.
update_compile_order -fileset sources_1

# ======================================================================================
#                  5. Synthesize the Design and Generate Synthesis Reports
# ======================================================================================

# Synthesize the design and save initial utilization and timing reports.
launch_runs synth_1 -jobs 4
wait_on_run synth_1

set st [get_property STATUS [get_runs synth_1]]
if {![string match "*Complete*" $st]} {error "Week 8 synthesis failed: $st"}

open_run synth_1
report_utilization -file [file join $root reports synth_utilization.rpt]
report_timing_summary -file [file join $root reports synth_timing_summary.rpt]
close_design

# ======================================================================================
#                  6. Implement, Route, and Save the Design Checkpoint
# ======================================================================================

# Route the design first, then reject timing and DRC failures before creating a handoff.
launch_runs impl_1 -to_step route_design -jobs 4
wait_on_run impl_1
set st [get_property STATUS [get_runs impl_1]]
if {![string match "*Complete*" $st]} {error "Week 8 route failed: $st"}
open_run impl_1

# Save the routed design before any optional report or handoff validation can
# abort the script.  This is the primary implementation checkpoint.
set checkpoint [file join $root checkpoints fir3_pynqz2_routed.dcp]
write_checkpoint -force $checkpoint

# ======================================================================================
#                  7. Generate Implementation Reports and Validate Timing
# ======================================================================================

# Generate implementation reports used to review timing, utilization, routing, power, and DRCs.
set out [file join $root reports]
check_timing -verbose -file [file join $out timing_checks.rpt]
report_timing_summary -delay_type min_max -report_unconstrained -file [file join $out impl_timing_summary.rpt]
report_utilization -file [file join $out impl_utilization.rpt]
report_route_status -file [file join $out impl_route_status.rpt]
report_clock_utilization -file [file join $out impl_clock_utilization.rpt]
report_power -file [file join $out impl_power_estimate.rpt]
report_drc -file [file join $out impl_drc.rpt]
report_methodology -file [file join $out impl_methodology.rpt]

# Confirm the 125 MHz clock constraint and require valid setup/hold timing paths.
set c [get_clocks -quiet -of_objects [get_ports clk]]
if {[llength $c] != 1} {error "Week 8 125MHz clock missing from implementation"}

set period [get_property PERIOD [lindex $c 0]]
if {abs(double($period)-8.0) > 0.0001} {error "Wrong clock period $period; expected 8.000ns"}

set setup [get_timing_paths -delay_type max -max_paths 1 -quiet]
set hold  [get_timing_paths -delay_type min -max_paths 1 -quiet]
if {[llength $setup] == 0 || [llength $hold] == 0} {error "Missing constrained setup/hold paths; do not handoff"}

set wns [get_property SLACK [lindex $setup 0]]
set whs [get_property SLACK [lindex $hold 0]]
puts "WEEK8_ROUTED_WNS_NS=$wns"
puts "WEEK8_ROUTED_WHS_NS=$whs"

# Do not continue to bitstream generation if timing or blocking DRC checks fail.
if {double($wns) < 0 || double($whs) < 0} {error "Week 8 setup/hold violation: WNS=$wns WHS=$whs"}
set blocking [get_drc_violations -quiet -filter {SEVERITY == Error || SEVERITY == "Critical Warning"}]
if {[llength $blocking] > 0} {error "Blocking implementation DRC findings: [llength $blocking]"}
close_design

# ======================================================================================
#                  8. Generate Bitstream and Debug-Probes Handoff Files
# ======================================================================================

# Complete the implementation run to generate the bitstream and debug probes.
launch_runs impl_1 -next_step -jobs 4
wait_on_run impl_1

set st [get_property STATUS [get_runs impl_1]]
if {![string match "*Complete*" $st]} {error "Week 8 write_bitstream failed: $st"}

set bs [glob -nocomplain [file join $proj fir3_pynqz2.runs impl_1 *.bit]]
if {[llength $bs] != 1} {error "Expected one generated bitstream, found [llength $bs]"}

file copy -force [lindex $bs 0] [file join $root artifacts fir3_pynqz2.bit]
open_run impl_1

# Export the VIO/ILA probe metadata for Hardware Manager.
# The .ltx file must match the bitstream generated by this implementation.
write_debug_probes -force [file join $root artifacts fir3_pynqz2.ltx]

# ======================================================================================
#                  9. Validate and Accept the Board Handoff
# ======================================================================================

# Verify that all programming handoff files exist and are non-empty.
foreach f [list \
    [file join $root artifacts fir3_pynqz2.bit] \
    [file join $root artifacts fir3_pynqz2.ltx] \
    [file join $root checkpoints fir3_pynqz2_routed.dcp]] {
    if {![file isfile $f] || [file size $f] <= 0} {error "Handoff artifact absent or empty: $f"}
}

# Mark the handoff accepted only after all checks and artifact validation pass.
puts {[RESULT] WEEK8_BOARD_HANDOFF_ACCEPTED}
puts {Use artifacts/fir3_pynqz2.bit + artifacts/fir3_pynqz2.ltx together}
