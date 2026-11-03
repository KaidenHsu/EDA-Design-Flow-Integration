`timescale 1ns/1ps
// Week 8 wrapper; original Week 6 RTL remains unchanged.
module fir3_debug_wrapper (
    input wire clk, input wire rst_n, input wire sample_req,
    input wire signed [7:0] x_in,
    output wire valid_in, output wire valid_out, output wire signed [9:0] y_out,
    output wire valid_s1, output wire signed [9:0] d0, d1, d2
);
    reg sample_req_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) sample_req_d <= 1'b0;
        else        sample_req_d <= sample_req;
    end

    // Only LOW -> HIGH makes a request; holding HIGH never repeats.
    assign valid_in = sample_req & ~sample_req_d;

    fir3_pipe2_debug u_core (
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in), .x_in(x_in),
        .valid_out(valid_out), .y_out(y_out),
        .dbg_valid_s1(valid_s1), .dbg_d0(d0), .dbg_d1(d1), .dbg_d2(d2)
    );
endmodule
