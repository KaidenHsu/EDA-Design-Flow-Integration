`timescale 1ns/1ps

// Week 5: registered parallel 3-tap FIR, beginner-level plain Verilog.
// Coefficients: h0 = 1, h1 = 2, h2 = 1.
// On an accepted rising edge, arithmetic uses x_in and the PRE-EDGE d0/d1 values.
// The delay-state width intentionally matches the Week 4 baseline.
module fir3_parallel (
    input  wire              clk,
    input  wire              rst_n,
    input  wire              valid_in,
    input  wire signed [7:0] x_in,
    output reg               valid_out,
    output reg  signed [9:0] y_out
);

    // Keep Week 4's 10-bit signed sample-history convention so Week 4/5
    // resource and timing comparisons do not silently change state width.
    reg signed [9:0] d0, d1, d2;

    // Explicit sign extension of the signed 8-bit input before use/storage.
    wire signed [9:0] x_ext;
    assign x_ext = {{2{x_in[7]}}, x_in};

    wire signed [9:0] p0, p1, p2;
    wire signed [9:0] s0;
    wire signed [9:0] y_next;

    // h = [1, 2, 1]
    assign p0 = x_ext;
    assign p1 = d0 <<< 1;   // +2*d0; d0 always stores sign-extended INT8 samples
    assign p2 = d1;

    // Two explicit two-input additions.
    assign s0     = p0 + p1;
    assign y_next = s0 + p2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d0        <= 10'sd0;
            d1        <= 10'sd0;
            d2        <= 10'sd0;
            y_out     <= 10'sd0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            // Simultaneous nonblocking delay-line update.
            d2 <= d1;
            d1 <= d0;
            d0 <= x_ext;

            // y_next uses x_in, d0_old, d1_old on this accepted edge.
            y_out     <= y_next;
            valid_out <= 1'b1;
        end else begin
            // Delay line and y_out hold when input is invalid.
            valid_out <= 1'b0;
        end
    end

endmodule
