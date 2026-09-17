# Week 2 Vivado batch wrapper for reg8.
# Usage from package root:
#   vivado -mode batch -source scripts/vivado/run_reg8_xsim.tcl
set origin_dir [file normalize [pwd]]
file mkdir $origin_dir/build/xsim_reg8/waves
file mkdir $origin_dir/logs
file mkdir $origin_dir/waves
cd $origin_dir/build/xsim_reg8
exec xvlog -nolog $origin_dir/rtl/reg8.v $origin_dir/tb/tb_reg8.v
exec xelab -nolog tb_reg8 -debug typical -s tb_reg8_sim
set f [open run_reg8.tcl w]
puts $f {catch {log_wave -recursive *}}
puts $f {catch {open_vcd ../../waves/reg8.vcd}}
puts $f {catch {log_vcd /}}
puts $f {run all}
puts $f {catch {close_vcd}}
puts $f {quit}
close $f
exec xsim tb_reg8_sim -tclbatch run_reg8.tcl >@ stdout
cd $origin_dir
