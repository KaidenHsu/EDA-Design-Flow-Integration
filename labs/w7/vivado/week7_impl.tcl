# Routed implementation of one synthesis mode; invoked by run_week7_impl.sh.
if {[llength $argv] != 1} {error "Expected one mode: A B C D E"}
set mode [string toupper [lindex $argv 0]]
if {$mode ni {A B C D E}} {error "Invalid mode $mode"}
set root [file normalize [file join [file dirname [file normalize [info script]]] ..]]
set checkpoints [file join $root checkpoints $mode]
set src [file join $checkpoints post_synth.dcp]
set out [file join $root reports $mode impl]
file mkdir $out
if {![file isfile $src] || [file size $src] == 0} {error "Missing synthesis checkpoint: $src"}
puts "WEEK7_FIR_INPUT=$src"
# Restore the synthesized design and its saved constraints, then verify that
# it targets the FPGA part used by the Week 6 baseline.
open_checkpoint $src
set part_in_dcp [get_property PART [current_project]]
if {![string equal -nocase $part_in_dcp "xc7z020clg400-1"]} {
    error "FPGA part mismatch in synthesis checkpoint: found $part_in_dcp, expected xc7z020clg400-1"
}
puts "WEEK7_CHECKPOINT_PART=$part_in_dcp"

# Require one top-level clk port with one associated 10 ns (100 MHz) clock.
# Reject a different timing baseline before starting implementation.
set clk_port [get_ports -quiet clk]
if {[llength $clk_port] != 1} {error "Exactly one top-level clk port is required"}
set clocks [get_clocks -quiet -of_objects $clk_port]
if {[llength $clocks] != 1} {error "Expected exactly one clock on port clk, found [llength $clocks]"}
set period [get_property PERIOD [lindex $clocks 0]]
if {![string is double -strict $period] || abs(double($period)-10.0) > 0.0001} {
    error "FIR clock mismatch: found PERIOD=$period ns; require Week 6 10.000 ns DCP"
}
puts "WEEK7_FIR_CLOCK_PERIOD=$period ns"
puts "WEEK7_FIR_TARGET=xc7z020clg400-1 (same part as Week 6)"

# The checkpoint contains the Week 6 timing constraints; do not read the XDC
# again, which could double-apply constraints or differ from Week 6 evidence.
# Optimize the synthesized netlist, place logic on device resources, and route
# the connections between those resources in that order.
opt_design
place_design
route_design

# Check constraint coverage and report both setup (max delay) and hold (min
# delay) timing. Also save the five worst max-delay paths for closer review.
# These commands write their detailed results directly to the named .rpt files;
# ordinary command progress and warnings also remain in the launcher's log.
check_timing -verbose -file [file join $out timing_checks.rpt]
report_timing_summary -delay_type min_max -report_unconstrained -max_paths 10 -file [file join $out timing.rpt]
report_timing -delay_type max -max_paths 5 -file [file join $out paths.rpt]

# Capture resource usage, estimated power, design-rule/methodology findings,
# and routing status so the routed implementation can be reviewed.
report_utilization -file [file join $out util.rpt]
report_power -file [file join $out power.rpt]
report_drc -file [file join $out drc.rpt]
report_methodology -file [file join $out methodology.rpt]
report_route_status -file [file join $out route_status.rpt]

# Save the routed design for later inspection or continuation in Vivado.
# Existing output files are overwritten when this script is rerun.
write_checkpoint -force [file join $checkpoints post_route.dcp]

# Record the handoff boundary: this run stops before bitstream generation and
# board execution; board-level constraints and deployment still need review.
set fp [open [file join $out bitstream_readiness.txt] w]
puts $fp "Week 7 FIR: routed implementation saved for xc7z020clg400-1"
puts $fp "Source: checkpoints/$mode/post_synth.dcp (10.000 ns Week 6 baseline)"
puts $fp "Routed checkpoint: checkpoints/$mode/post_route.dcp"
puts $fp "Status: PRE-BITSTREAM ONLY; review reports and constraints before future deployment."
puts $fp "Week 7 generates NO .bit and performs NO PYNQ-Z2 hardware execution."
puts $fp "Week 8 board-level LOC/IOSTANDARD, bitstream, and download remain outstanding."
close $fp

# Require every expected artifact to exist and contain data before announcing
# completion. This checks output presence, not whether report findings pass.
foreach name {timing_checks.rpt timing.rpt paths.rpt util.rpt power.rpt drc.rpt methodology.rpt route_status.rpt bitstream_readiness.txt} {
    set f [file join $out $name]
    if {![file isfile $f] || [file size $f] <= 0} {error "Missing or empty Week 7 artifact: $f"}
}

puts "IMPL_COMPLETE=$mode"
