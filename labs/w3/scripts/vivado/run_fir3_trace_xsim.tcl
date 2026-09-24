# Vivado/XSim script for Week 3 FIR hand-trace simulation
# Usage from package root:
#   vivado -mode batch -source scripts/vivado/run_fir3_trace_xsim.tcl

set origin_dir [file normalize [pwd]]
file mkdir $origin_dir/build/xsim_fir3_trace
file mkdir $origin_dir/build/xsim_fir3_trace/waves
file mkdir $origin_dir/logs
file mkdir $origin_dir/waves

proc run_cmd {args} {
    puts "Running: $args"
    if {[catch {exec {*}$args} result]} {
        puts $result
        error "Command failed: $args"
    } else {
        puts $result
    }
}

cd $origin_dir/build/xsim_fir3_trace
run_cmd xvlog $origin_dir/rtl/fir3_arith.v $origin_dir/tb/tb_fir3_trace.v
run_cmd xelab tb_fir3_trace -debug typical -s tb_fir3_trace_sim
run_cmd xsim tb_fir3_trace_sim -R -log $origin_dir/logs/fir3_trace_xsim.log

if {[file exists $origin_dir/build/xsim_fir3_trace/waves/fir3_trace.vcd]} {
    file copy -force $origin_dir/build/xsim_fir3_trace/waves/fir3_trace.vcd $origin_dir/waves/fir3_trace.vcd
}
cd $origin_dir
