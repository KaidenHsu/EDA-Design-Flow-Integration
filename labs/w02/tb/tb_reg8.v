// tb_reg8.v
// Week 2 - Self-checking testbench for reg8.v
// Demonstrates active-low asynchronous reset and rising-edge capture.

`timescale 1ns/1ps

module tb_reg8;

reg        clk;
reg        rst_n;
reg  [7:0] d;
wire [7:0] q;

integer errors;

reg8 dut (
    .clk(clk),
    .rst_n(rst_n),
    .d(d),
    .q(q)
);

// 10 ns clock period. Rising edges occur at 5, 15, 25, 35, ... ns.
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

task check_q;
    input [7:0] expected_q;
    input [8*64-1:0] tag;
    begin
        if (q !== expected_q) begin
            $display("[FAIL] %0s time=%0t expected_q=%02h got_q=%02h",
                     tag, $time, expected_q, q);
            errors = errors + 1;
        end else begin
            $display("[PASS] %0s time=%0t q=%02h", tag, $time, q);
        end
    end
endtask

initial begin
    $dumpfile("waves/reg8.vcd");
    $dumpvars(0, tb_reg8);

    errors = 0;
    rst_n  = 1'b1;
    d      = 8'h00;

    $display("============================================================");
    $display("Week 2 reg8 functional simulation started");
    $display("Expected behavior: rst_n=0 clears q asynchronously;");
    $display("after release, q captures d only on rising clock edges");
    $display("============================================================");

    // Assert reset between clock edges and verify asynchronous clearing.
    #1;
    rst_n = 1'b0;
    #1;
    check_q(8'h00, "ASYNC_RESET");

    // Keep reset asserted through the first rising edge at 5 ns.
    @(posedge clk);
    #1;
    check_q(8'h00, "RESET_HELD_AT_EDGE");

    // Release reset between rising edges. Release itself must not capture d.
    #6;                 // time = 12 ns
    rst_n = 1'b1;
    d     = 8'hA5;
    #1;
    check_q(8'h00, "RESET_RELEASE_NO_CAPTURE");

    // First normal rising edge at 15 ns captures A5.
    @(posedge clk);
    #1;
    check_q(8'hA5, "CAPTURE_A5");

    // Change d between edges. q must hold until the next rising edge.
    #4;                 // time = 20 ns
    d = 8'h3C;
    #1;
    check_q(8'hA5, "HOLD_BETWEEN_EDGES");

    @(posedge clk);     // 25 ns
    #1;
    check_q(8'h3C, "CAPTURE_3C");

    // Change d again between edges; q still holds.
    #2;
    d = 8'hF0;
    #1;
    check_q(8'h3C, "HOLD_AFTER_D_CHANGE");

    // Assert reset again between clock edges; q must clear immediately.
    #1;
    rst_n = 1'b0;
    #1;
    check_q(8'h00, "ASYNC_RESET_AGAIN");

    // Release reset between edges; release still does not capture.
    #1;
    rst_n = 1'b1;
    d     = 8'h0F;
    #1;
    check_q(8'h00, "SECOND_RELEASE_NO_CAPTURE");

    @(posedge clk);     // 35 ns
    #1;
    check_q(8'h0F, "CAPTURE_0F");

    $display("============================================================");
    if (errors == 0)
        $display("[RESULT] REG8 TEST PASSED");
    else
        $display("[RESULT] REG8 TEST FAILED with %0d error(s)", errors);
    $display("============================================================");

    #4;
    $finish;
end

endmodule
