# Week 6 lab - synthesizes unchanged, canonical Week 5 FIR in modes A-E.
# Run via scripts/run_synth_modes.sh; all locations are script-relative.

# Require exactly one synthesis mode argument.
if {[llength $argv] != 1} {
  error "Expected one mode argument: A B C D or E"
}

# Normalize the mode name so lowercase input is also accepted.
set mode [string toupper [lindex $argv 0]]

# Reject unsupported synthesis modes before creating any output.
if {$mode ni {A B C D E}} {
  error "Invalid mode $mode"
}


# Resolve the project root from the location of this script.
set root [file normalize [file join [file dirname [file normalize [info script]]] ..]]

# Locate the RTL source and timing constraints.
set rtl [file join $root rtl fir3_pipe2.v]
set xdc [file join $root constraints fir3_pipe2.xdc]

# Keep reports for each synthesis mode in a separate directory.
set out [file join $root reports $mode]
file mkdir $out

# Fail early when an input file is missing.
foreach f [list $rtl $xdc] {
  if {![file isfile $f]} {
    error "Missing: $f"
  }
}


# Target Zynq-7000 device.
set part xc7z020clg400-1

# Print the selected inputs and Vivado version for reproducibility.
puts "MODE=$mode PART=$part RTL=$rtl XDC=$xdc"
puts "VIVADO_VERSION=[version -short]"


# Start with the baseline synthesis settings.
set directive default
set flatten_hierarchy rebuilt
set resource_sharing auto
set global_retiming off

# Change one setting for each comparison mode.
switch -- $mode {
  A {}
  B {set directive AreaOptimized_high}
  C {set flatten_hierarchy full}
  D {set resource_sharing off}
  E {set global_retiming on}
}

# Build the final argument list after applying the mode-specific setting.
set args [list \
  -top fir3_pipe2 \
  -part $part \
  -directive $directive \
  -flatten_hierarchy $flatten_hierarchy \
  -resource_sharing $resource_sharing \
  -global_retiming $global_retiming]

# Record the final arguments used for this synthesis run.
puts "SYNTH_ARGUMENTS=$args"


# Read the design and its timing constraints.
read_verilog $rtl
read_xdc $xdc

# Run synthesis with the selected configuration.
synth_design {*}$args


# A numerical WNS is not enough: include explicit timing-coverage report.
if {[llength [get_clocks -quiet]] < 1} {
  error "No synthesis clock found after applying $xdc"
}

# Check for timing issues and missing or incomplete constraints.
check_timing -file [file join $out check_timing.rpt]

# Record the synthesized resource usage.
report_utilization -file [file join $out utilization.rpt]

# Report both setup and hold timing, including unconstrained paths.
report_timing_summary -delay_type min_max -report_unconstrained \
  -file [file join $out timing_summary.rpt]

# Save the ten worst setup paths for detailed inspection.
report_timing -delay_type max -max_paths 10 -nworst 1 \
  -file [file join $out worst10_setup_paths.rpt]

# Save the post-synthesis design checkpoint.
write_checkpoint -force [file join $out post_synth.dcp]

# Mark the run as complete.
puts "[format {%s} SYNTH_COMPLETE]=$mode"
