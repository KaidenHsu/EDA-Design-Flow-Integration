// reg8.v
// Week 2 - Small sequential register module
// EDA Design Flow Integration
// Plain Verilog, synthesizable RTL

`timescale 1ns/1ps

module reg8 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] d,
    output reg  [7:0] q
);

// Active-low asynchronous reset.
// After reset is released, q captures d only on a rising clock edge.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        q <= 8'h00;
    else
        q <= d;
end

endmodule
