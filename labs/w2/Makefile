# Week 2 source-code package Makefile
# Optional Icarus Verilog path. Vivado/XSim users can use scripts/run_xsim_direct.sh.

.PHONY: all mux2 reg8 clean

all: mux2 reg8

mux2:
	mkdir -p build logs waves
	iverilog -g2005 -Wall -o build/tb_mux2.vvp rtl/mux2.v tb/tb_mux2.v
	vvp build/tb_mux2.vvp | tee logs/mux2_sim.log

reg8:
	mkdir -p build logs waves
	iverilog -g2005 -Wall -o build/tb_reg8.vvp rtl/reg8.v tb/tb_reg8.v
	vvp build/tb_reg8.vvp | tee logs/reg8_sim.log

clean:
	rm -rf build logs/*.log waves/*.vcd waves/*.wdb
