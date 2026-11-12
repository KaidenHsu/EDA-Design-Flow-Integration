# Week 10 Design Compiler synthesis run.
# Executed from the package root by run_lab.py, not from scripts/.
# All paths and timing assumptions are exported from config/lab_config.json.
# STOP on fatal problems; do not create fabricated timing/area data.

proc must_env {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        error "Missing required environment variable: $name"
    }
    return $::env($name)
}

set rtl_paths [split [must_env W10_RTL_FILES] {|}]
set top         [must_env W10_TOP]
set lib_db      [must_env W10_LIB_DB]
set clk_port    [must_env W10_CLK_PORT]
set inputs      [split [must_env W10_INPUT_PORTS] {|}]
set outputs     [split [must_env W10_OUTPUT_PORTS] {|}]
set period      [must_env W10_PERIOD_NS]
set indir_max   [must_env W10_INPUT_MAX_NS]
set indir_min   [must_env W10_INPUT_MIN_NS]
set outdir_max  [must_env W10_OUTPUT_MAX_NS]
set outdir_min  [must_env W10_OUTPUT_MIN_NS]
set outdir      [must_env W10_OUTDIR]
set compile_cmd [must_env W10_COMPILE_COMMAND]

if {![file readable $lib_db]} { error "Library not readable: $lib_db" }
foreach f $rtl_paths { if {![file readable $f]} { error "RTL not readable: $f" } }
file mkdir $outdir

# Correct Synopsys application-variable assignments.
set_app_var target_library [list $lib_db]
set_app_var link_library [concat [list "*"] $target_library]

read_verilog $rtl_paths
current_design $top
link
check_design

# Normally put in .sdc, but placed here for convenience in this lab.
set clk [get_ports $clk_port]
create_clock -name core_clk -period $period $clk
set inports [get_ports $inputs]
set outports [get_ports $outputs]
set_input_delay  -clock core_clk -max $indir_max $inports
set_input_delay  -clock core_clk -min $indir_min $inports
set_output_delay -clock core_clk -max $outdir_max $outports
set_output_delay -clock core_clk -min $outdir_min $outports

# Intentionally no blanket false_path/multicycle exceptions.
# Asynchronous reset is excluded from ordinary synchronous data I/O delays;
# inspect recovery/removal assumptions and relevant reports separately.
if {$compile_cmd eq "compile_ultra"} {
    compile_ultra
} elseif {$compile_cmd eq "compile"} {
    compile
} else {
    error "Unsupported W10_COMPILE_COMMAND: $compile_cmd"
}

report_area > [file join $outdir area.rpt]
report_reference > [file join $outdir refs.rpt]
report_timing -delay_type max -max_paths 10 > [file join $outdir setup.rpt]
# Hold/minimum-delay paths complement the setup-side maximum-delay paths.
report_timing -delay_type min -max_paths 10 > [file join $outdir hold.rpt]

# check_timing is a constraint sanity audit, NOT proof of full path/check coverage.
set coverage_file [file join $outdir timing_coverage.rpt]
set ch [open $coverage_file w]
puts $ch "CHECK_TIMING CONSTRAINT SANITY AUDIT (not signoff coverage or timing PASS)"
close $ch
check_timing >> $coverage_file
report_constraint -all_violators > [file join $outdir violations.rpt]
write_file -format verilog -hierarchy -output [file join $outdir mapped.v]
puts "W10_DC_RUN_COMPLETED period_ns=$period output=$outdir"
exit
