// tb_mux2.v
// Week 2 - Self-checking testbench for mux2.v
// Matches the four cases in the Week 2 Lab / Activity Handout.

`timescale 1ns/1ps

module tb_mux2;

reg  sel;
reg  a;
reg  b;
wire y;

integer errors;

mux2 dut (
    .sel(sel),
    .a(a),
    .b(b),
    .y(y)
);

task check_case;
    input integer case_id;
    input exp_sel;
    input exp_a;
    input exp_b;
    input exp_y;
    begin
        sel = exp_sel;
        a   = exp_a;
        b   = exp_b;
        #1;

        if (y !== exp_y) begin
            $display("[FAIL] case=%0d sel=%0b a=%0b b=%0b expected_y=%0b got_y=%0b",
                     case_id, sel, a, b, exp_y, y);
            errors = errors + 1;
        end else begin
            $display("[PASS] case=%0d sel=%0b a=%0b b=%0b y=%0b",
                     case_id, sel, a, b, y);
        end
    end
endtask

initial begin
    $dumpfile("waves/mux2.vcd");
    $dumpvars(0, tb_mux2);

    errors = 0;
    sel = 1'b0;
    a   = 1'b0;
    b   = 1'b0;
    #1;

    $display("============================================================");
    $display("Week 2 mux2 functional simulation started");
    $display("Expected behavior: sel=0 selects a; sel=1 selects b");
    $display("============================================================");

    // Exact cases from the Week 2 handout.
    check_case(1, 1'b0, 1'b0, 1'b1, 1'b0);
    check_case(2, 1'b1, 1'b0, 1'b1, 1'b1);
    check_case(3, 1'b0, 1'b1, 1'b0, 1'b1);
    check_case(4, 1'b1, 1'b1, 1'b0, 1'b0);

    $display("============================================================");
    if (errors == 0)
        $display("[RESULT] MUX2 TEST PASSED");
    else
        $display("[RESULT] MUX2 TEST FAILED with %0d error(s)", errors);
    $display("============================================================");

    #2;
    $finish;
end

endmodule
