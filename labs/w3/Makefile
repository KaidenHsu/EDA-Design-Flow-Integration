# Week 3 source-code package Makefile
# Optional path for students with Icarus Verilog installed.
# Vivado/XSim users can run the Tcl scripts in scripts/vivado/.

.PHONY: all arith trace clean

all: arith trace

arith:
	mkdir -p build/iverilog logs/iverilog waves/iverilog
	iverilog -g2005 -o build/iverilog/tb_fir3_arith.vvp rtl/fir3_arith.v tb/tb_fir3_arith.v
	vvp build/iverilog/tb_fir3_arith.vvp | tee logs/iverilog/fir3_arith_sim.log

trace:
	mkdir -p build/iverilog logs/iverilog waves/iverilog
	iverilog -g2005 -o build/iverilog/tb_fir3_trace.vvp rtl/fir3_arith.v tb/tb_fir3_trace.v
	vvp build/iverilog/tb_fir3_trace.vvp | tee logs/iverilog/fir3_trace_sim.log

clean:
	rm -rf build/iverilog logs/iverilog/*.log waves/iverilog/*.vcd
