# Week 2 Vivado batch wrapper for mux2.
# Usage from package root:
#   vivado -mode batch -source scripts/vivado/run_mux2_xsim.tcl
set origin_dir [file normalize [pwd]]
file mkdir $origin_dir/build/xsim_mux2/waves
file mkdir $origin_dir/logs
file mkdir $origin_dir/waves
cd $origin_dir/build/xsim_mux2
exec xvlog -nolog $origin_dir/rtl/mux2.v $origin_dir/tb/tb_mux2.v
exec xelab -nolog tb_mux2 -debug typical -s tb_mux2_sim
set f [open run_mux2.tcl w]
puts $f {catch {log_wave -recursive *}}
puts $f {catch {open_vcd ../../waves/mux2.vcd}}
puts $f {catch {log_vcd /}}
puts $f {run all}
puts $f {catch {close_vcd}}
puts $f {quit}
close $f
exec xsim tb_mux2_sim -tclbatch run_mux2.tcl >@ stdout
cd $origin_dir
