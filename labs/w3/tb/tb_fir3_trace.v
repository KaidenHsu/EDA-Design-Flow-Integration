// tb_fir3_trace.v
// Week 3 - Testbench-only FIR state trace and checker
// Plain Verilog testbench
//
// This file deliberately keeps d0/d1/d2 as TESTBENCH state. It demonstrates
// the Week 3 hand-trace convention without providing the full sequential FIR
// DUT that students will write in Week 4.

`timescale 1ns/1ps

module tb_fir3_trace;

reg clk;
reg rst_n;
reg valid_in;
reg signed [7:0] x_in;
reg signed [7:0] d0;
reg signed [7:0] d1;
reg signed [7:0] d2;
reg signed [7:0] old_d0;
reg signed [7:0] old_d1;

reg signed [7:0] h0;
reg signed [7:0] h1;
reg signed [7:0] h2;
wire signed [15:0] p0;
wire signed [15:0] p1;
wire signed [15:0] p2;
wire signed [16:0] s0;
wire signed [17:0] y_out;

integer errors;
integer sample_index;

fir3_arith dut_arith (
    .d0(d0), .d1(d1), .d2(d2),
    .h0(h0), .h1(h1), .h2(h2),
    .p0(p0), .p1(p1), .p2(p2),
    .s0(s0), .y_out(y_out)
);

// 10 ns clock period: rising edges at 5, 15, 25, ... ns.
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

task accept_and_check;
    input signed [7:0] sample;
    input signed [17:0] expected_y;
    begin
        // Apply the sample away from the active edge.
        @(negedge clk);
        x_in    = sample;
        valid_in = 1'b1;

        // At the next rising edge, emulate the Week 3 state transition
        // using the OLD d0/d1 values explicitly.
        @(posedge clk);
        old_d0 = d0;
        old_d1 = d1;
        d0 = x_in;
        d1 = old_d0;
        d2 = old_d1;

        #1;
        $display("[TRACE] n=%0d x=%0d state[d0,d1,d2]=[%0d,%0d,%0d] p=[%0d,%0d,%0d] y=%0d",
                 sample_index, x_in, d0, d1, d2, p0, p1, p2, y_out);

        if (y_out !== expected_y) begin
            $display("[FAIL] n=%0d expected y=%0d got y=%0d", sample_index, expected_y, y_out);
            errors = errors + 1;
        end else begin
            $display("[PASS] n=%0d expected y=%0d", sample_index, expected_y);
        end

        sample_index = sample_index + 1;
        valid_in = 1'b0;
    end
endtask

initial begin
    $dumpfile("waves/fir3_trace.vcd");
    $dumpvars(0, tb_fir3_trace);

    errors = 0;
    sample_index = 0;
    h0 = 8'sd1;
    h1 = 8'sd2;
    h2 = 8'sd1;

    rst_n = 1'b0;
    valid_in = 1'b0;
    x_in = 0;
    d0 = 0;
    d1 = 0;
    d2 = 0;
    old_d0 = 0;
    old_d1 = 0;

    $display("============================================================");
    $display("Week 3 FIR hand-trace simulation started");
    $display("Reset history begins at state [0,0,0]");
    $display("============================================================");

    // Keep reset asserted through the first rising edge at 5 ns.
    @(posedge clk);
    #1;
    if ((d0 !== 0) || (d1 !== 0) || (d2 !== 0)) begin
        $display("[FAIL] reset state is not [0,0,0]");
        errors = errors + 1;
    end else begin
        $display("[PASS] reset state [d0,d1,d2]=[0,0,0]");
    end

    // Release reset at a falling edge, i.e. between rising edges.
    // Reset release itself does not shift the sample history.
    @(negedge clk);
    rst_n = 1'b1;
    #1;
    if ((d0 !== 0) || (d1 !== 0) || (d2 !== 0)) begin
        $display("[FAIL] state changed at reset release");
        errors = errors + 1;
    end else begin
        $display("[PASS] reset release does not capture a sample");
    end

    // Hand-trace sequence from the Week 3 slides/handout.
    accept_and_check(8'sd1, 18'sd1);
    accept_and_check(8'sd2, 18'sd4);
    accept_and_check(8'sd3, 18'sd8);
    accept_and_check(8'sd0, 18'sd8);
    accept_and_check(8'sd0, 18'sd3);

    $display("============================================================");
    $display("Expected output sequence: 1, 4, 8, 8, 3");
    if (errors == 0)
        $display("[RESULT] FIR3 TRACE TEST PASSED");
    else
        $display("[RESULT] FIR3 TRACE TEST FAILED with %0d error(s)", errors);
    $display("============================================================");

    #10;
    $finish;
end

endmodule
