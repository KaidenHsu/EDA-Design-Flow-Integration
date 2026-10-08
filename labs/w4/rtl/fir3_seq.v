`timescale 1ns/1ps

// Week 4 baseline: sequential sample history + combinational FIR arithmetic.
// Coefficients are fixed at h = [1, 2, 1].
// d0 = newest accepted sample, d1 = previous accepted sample,
// d2 = sample from two accepted inputs earlier.
module fir3_seq (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    valid_in,
    input  wire signed [7:0]       x_in,
    output reg                     valid_out,
    output wire signed [9:0]       y_out
);

    // 10-bit signed state is deliberately wider than x_in so the complete
    // h=[1,2,1] result range (-512..508) can be represented without overflow.
    reg signed [9:0] d0;
    reg signed [9:0] d1;
    reg signed [9:0] d2;

    // Explicit sign extension of the 8-bit input before storing it.
    wire signed [9:0] x_ext;
    assign x_ext = {{2{x_in[7]}}, x_in};

    // Exposed arithmetic nodes are useful for waveform-based debugging.
    wire signed [9:0] p0;
    wire signed [9:0] p1;
    wire signed [9:0] p2;
    wire signed [9:0] s0;

    assign p0 = d0;
    assign p1 = d1 <<< 1;   // coefficient h1 = 2
    assign p2 = d2;
    assign s0 = p0 + p1;
    assign y_out = s0 + p2;

    // Sample history and valid_out are sequential.
    // Reset is asynchronous and active low.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d0        <= 10'sd0;
            d1        <= 10'sd0;
            d2        <= 10'sd0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            d2        <= d1;
            d1        <= d0;
            d0        <= x_ext;
            valid_out <= 1'b1;
        end else begin
            // No assignments to d0/d1/d2: the sample history holds.
            valid_out <= 1'b0;
        end
    end

endmodule
