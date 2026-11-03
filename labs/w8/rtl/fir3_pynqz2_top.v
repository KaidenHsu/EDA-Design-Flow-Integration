`timescale 1ns/1ps
// Week 8 PYNQ-Z2 board top; only clk maps to a physical package pin.
module fir3_pynqz2_top(input wire clk);
    wire rst_n, sample_req, valid_in, valid_out, valid_s1;
    wire signed [7:0] x_in;
    wire signed [9:0] y_out, d0, d1, d2;

    fir3_debug_wrapper u_wrapper(
        .clk(clk), .rst_n(rst_n), .sample_req(sample_req), .x_in(x_in),
        .valid_in(valid_in), .valid_out(valid_out), .y_out(y_out),
        .valid_s1(valid_s1), .d0(d0), .d1(d1), .d2(d2)
    );

    // Vivado-generated VIO IP (vio_fir3), configured by vivado/build.tcl.
    // Its .xci configuration and generated Verilog are stored under build/pynq_z2/.
    // VIO outputs: reset, sample request, signed sample; inputs: valid/result.
    vio_fir3 u_vio(
        .clk(clk), .probe_in0(valid_out), .probe_in1(y_out),
        .probe_out0(rst_n), .probe_out1(sample_req), .probe_out2(x_in)
    );

    // Genuine Week 6 internal sample history is 10-bit, not 8-bit.
    // Vivado-generated ILA IP (ila_fir3), also configured by vivado/build.tcl.
    // It captures the connected FIR control, input, output, and internal history signals.
    ila_fir3 u_ila(
        .clk(clk), .probe0(rst_n), .probe1(sample_req), .probe2(x_in),
        .probe3(valid_in), .probe4(valid_out), .probe5(y_out),
        .probe6(valid_s1), .probe7(d0), .probe8(d1), .probe9(d2)
    );
endmodule
