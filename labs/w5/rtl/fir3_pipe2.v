`timescale 1ns/1ps

// Week 5: one-cycle pipelined 3-tap FIR, beginner-level plain Verilog.
// Stage 1 stores products. Stage 2 adds the stored products and registers y_out.
// Coefficients: h0 = 1, h1 = 2, h2 = 1.
// The delay-state width intentionally matches the Week 4 baseline.
module fir3_pipe2 (
    input  wire              clk,
    input  wire              rst_n,
    input  wire              valid_in,
    input  wire signed [7:0] x_in,
    output reg               valid_out,
    output reg  signed [9:0] y_out
);

    // Same 10-bit signed sample-history convention as Week 4.
    reg signed [9:0] d0, d1, d2;

    wire signed [9:0] x_ext;
    assign x_ext = {{2{x_in[7]}}, x_in};

    reg signed [9:0] p0_s1, p1_s1, p2_s1;
    reg              valid_s1;

    wire signed [9:0] s0_s1;
    wire signed [9:0] y_s1;

    // Stage-2 combinational adder structure from registered products.
    assign s0_s1 = p0_s1 + p1_s1;
    assign y_s1  = s0_s1 + p2_s1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d0        <= 10'sd0;
            d1        <= 10'sd0;
            d2        <= 10'sd0;
            p0_s1     <= 10'sd0;
            p1_s1     <= 10'sd0;
            p2_s1     <= 10'sd0;
            y_out     <= 10'sd0;
            valid_s1  <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            // Stage 2 consumes the previous cycle's Stage-1 values.
            if (valid_s1)
                y_out <= y_s1;
            valid_out <= valid_s1;

            // Stage-1 valid follows this cycle's accepted input.
            valid_s1 <= valid_in;

            if (valid_in) begin
                // Products use x_in and PRE-EDGE d0/d1 values.
                p0_s1 <= x_ext;
                p1_s1 <= d0 <<< 1;
                p2_s1 <= d1;

                // Delay line advances only on accepted rising edges.
                d2 <= d1;
                d1 <= d0;
                d0 <= x_ext;
            end
            // When valid_in=0, product registers and d0/d1/d2 hold.
        end
    end

endmodule
