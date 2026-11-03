# Week 8 ONLY: not the Week 6/7 analysis XDC.

# PYNQ-Z2 Ethernet PHY CLK125 -> PL H16. Real clock activity must be verified.
set_property PACKAGE_PIN H16 [get_ports clk]

set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -name clk -period 8.000 [get_ports clk]
