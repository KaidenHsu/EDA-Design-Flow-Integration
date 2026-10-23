# Week 6 synthesis constraint file for fir3_pipe2
# PYNQ-Z2 is the software synthesis target. No board programming is performed.

# 10 ns period = 100 MHz target clock.
create_clock -name clk -period 10.000 [get_ports clk]

# Asynchronous active-low reset is not analyzed as a synchronous data path.
set_false_path -from [get_ports rst_n]
