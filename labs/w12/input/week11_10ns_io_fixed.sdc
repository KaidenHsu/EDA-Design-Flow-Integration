# Week 11 FIR teaching constraints
# Illustrative interface budgets, not physical signoff.

create_clock -name core_clk -period 10.0 [get_ports clk]

# Data inputs: valid_in and x_in[7:0]
set_input_delay -clock core_clk -max 2.0 \
    [get_ports {valid_in x_in*}]
set_input_delay -clock core_clk -min 0.5 \
    [get_ports {valid_in x_in*}]

# Outputs: valid_out and y_out[9:0]
set_output_delay -clock core_clk -max 2.5 \
    [get_ports {valid_out y_out*}]
set_output_delay -clock core_clk -min -0.2 \
    [get_ports {valid_out y_out*}]

# rst_n is an asynchronous reset, reviewed separately.
# No invented timing exceptions or uncertainty.
