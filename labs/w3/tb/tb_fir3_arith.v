// tb_fir3_arith.v
// Week 3 - Unit test for fir3_arith.v
// Plain Verilog testbench

`timescale 1ns/1ps

module tb_fir3_arith;

reg  signed [7:0] d0;
reg  signed [7:0] d1;
reg  signed [7:0] d2;
reg  signed [7:0] h0;
reg  signed [7:0] h1;
reg  signed [7:0] h2;
wire signed [15:0] p0;
wire signed [15:0] p1;
wire signed [15:0] p2;
wire signed [16:0] s0;
wire signed [17:0] y_out;

integer errors;

fir3_arith dut (
    .d0(d0), .d1(d1), .d2(d2),
    .h0(h0), .h1(h1), .h2(h2),
    .p0(p0), .p1(p1), .p2(p2),
    .s0(s0), .y_out(y_out)
);

task check_state;
    input signed [7:0]  td0;
    input signed [7:0]  td1;
    input signed [7:0]  td2;
    input signed [17:0] expected_y;
    begin
        d0 = td0;
        d1 = td1;
        d2 = td2;
        #1;

        if (y_out !== expected_y) begin
            $display("[FAIL] d0=%0d d1=%0d d2=%0d p0=%0d p1=%0d p2=%0d s0=%0d expected y=%0d got y=%0d",
                     d0, d1, d2, p0, p1, p2, s0, expected_y, y_out);
            errors = errors + 1;
        end else begin
            $display("[PASS] d0=%0d d1=%0d d2=%0d -> p=[%0d,%0d,%0d] s0=%0d y=%0d",
                     d0, d1, d2, p0, p1, p2, s0, y_out);
        end
    end
endtask

initial begin
    $dumpfile("waves/fir3_arith.vcd");
    $dumpvars(0, tb_fir3_arith);

    errors = 0;

    // Week 3 coefficients h = [1, 2, 1].
    h0 = 8'sd1;
    h1 = 8'sd2;
    h2 = 8'sd1;

    d0 = 0;
    d1 = 0;
    d2 = 0;
    #5;

    $display("============================================================");
    $display("Week 3 FIR arithmetic simulation started");
    $display("Equation: y_out = h0*d0 + h1*d1 + h2*d2");
    $display("Coefficients: h0=1 h1=2 h2=1");
    $display("============================================================");

    // Register states corresponding to x = 1, 2, 3, 0, 0
    // after successive accepted rising edges with zero reset history.
    check_state( 8'sd1,  8'sd0,  8'sd0,  18'sd1);
    check_state( 8'sd2,  8'sd1,  8'sd0,  18'sd4);
    check_state( 8'sd3,  8'sd2,  8'sd1,  18'sd8);
    check_state( 8'sd0,  8'sd3,  8'sd2,  18'sd8);
    check_state( 8'sd0,  8'sd0,  8'sd3,  18'sd3);

    // Signed-width sanity check. This is not a new Week 3 hand-trace case;
    // it simply verifies that the reference arithmetic handles signed values.
    // 8'sh80 = -128, -128x3=-512
    check_state(8'sh80, 8'sh80, 8'sh80, -18'sd512);

    $display("============================================================");
    if (errors == 0)
        $display("[RESULT] FIR3 ARITH TEST PASSED");
    else
        $display("[RESULT] FIR3 ARITH TEST FAILED with %0d error(s)", errors);
    $display("============================================================");

    #5;
    $finish;
end

endmodule
