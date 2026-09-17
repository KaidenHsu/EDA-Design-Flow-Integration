// mux2.v
// Week 2 - Small combinational RTL module
// EDA Design Flow Integration
// Plain Verilog, synthesizable RTL

`timescale 1ns/1ps

module mux2 (
    input  wire sel,
    input  wire a,
    input  wire b,
    output wire y
);

// 2:1 multiplexer:
//   sel = 0 -> y follows a
//   sel = 1 -> y follows b
assign y = sel ? b : a;

endmodule
