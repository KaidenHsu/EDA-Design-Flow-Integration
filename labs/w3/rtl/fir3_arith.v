// fir3_arith.v
// Week 3 - 3-tap FIR combinational arithmetic reference
// EDA Design Flow Integration
// Plain Verilog-2001, synthesizable combinational RTL
`timescale 1ns/1ps
//
// IMPORTANT:
//   This is NOT the full sequential FIR module for Week 4.
//   d0, d1, and d2 are supplied as already-stored sample values.
//   The purpose here is to make the multiply-and-add structure explicit.

module fir3_arith (
    input  wire signed [7:0]  d0,
    input  wire signed [7:0]  d1,
    input  wire signed [7:0]  d2,
    input  wire signed [7:0]  h0,
    input  wire signed [7:0]  h1,
    input  wire signed [7:0]  h2,
    output wire signed [15:0] p0,
    output wire signed [15:0] p1,
    output wire signed [15:0] p2,
    output wire signed [16:0] s0,
    output wire signed [17:0] y_out
);

// One explicit product per tap.
assign p0 = d0 * h0;
assign p1 = d1 * h1;
assign p2 = d2 * h2;

// Explicit two-adder chain for three products.
// Sign extension is written explicitly so the additions do not silently
// discard a carry/sign bit when the product range grows.
assign s0 = {p0[15], p0} + {p1[15], p1};
assign y_out = {s0[16], s0} + {{2{p2[15]}}, p2};

endmodule
