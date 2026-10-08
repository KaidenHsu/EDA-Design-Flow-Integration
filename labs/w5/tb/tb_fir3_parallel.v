`timescale 1ns/1ps

module tb_fir3_parallel;

    reg clk;
    reg rst_n;
    reg valid_in;
    reg signed [7:0] x_in;
    wire valid_out;
    wire signed [9:0] y_out;

    integer errors;

    fir3_parallel dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .x_in(x_in),
        .valid_out(valid_out),
        .y_out(y_out)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task expect_state;
        input signed [9:0] e_d0;
        input signed [9:0] e_d1;
        input signed [9:0] e_d2;
        input              e_valid;
        input signed [9:0] e_y;
        input integer      check_y;
        input [8*48-1:0]   label;
        begin
            #1;
            if (dut.d0 !== e_d0 || dut.d1 !== e_d1 || dut.d2 !== e_d2) begin
                $display("[FAIL] %0s delay state: d0=%0d d1=%0d d2=%0d expected %0d %0d %0d",
                         label, dut.d0, dut.d1, dut.d2, e_d0, e_d1, e_d2);
                errors = errors + 1;
            end
            if (valid_out !== e_valid) begin
                $display("[FAIL] %0s valid_out=%0b expected %0b", label, valid_out, e_valid);
                errors = errors + 1;
            end
            if (check_y && y_out !== e_y) begin
                $display("[FAIL] %0s y_out=%0d expected %0d", label, y_out, e_y);
                errors = errors + 1;
            end
            if (dut.d0 === e_d0 && dut.d1 === e_d1 && dut.d2 === e_d2 &&
                valid_out === e_valid && (!check_y || y_out === e_y))
                $display("[PASS] %0s d0=%0d d1=%0d d2=%0d y=%0d valid=%0b",
                         label, dut.d0, dut.d1, dut.d2, y_out, valid_out);
        end
    endtask

    task drive_at_negedge;
        input signed [7:0] sample;
        input              v;
        begin
            @(negedge clk);
            x_in = sample;
            valid_in = v;
        end
    endtask

    initial begin
        errors = 0;
        rst_n = 1'b0;
        valid_in = 1'b0;
        x_in = 8'sd0;

        $dumpfile("waves/fir3_parallel.vcd");
        $dumpvars(0, tb_fir3_parallel);

        // Asynchronous active-low reset establishes a known state.
        #2;
        expect_state(10'sd0, 10'sd0, 10'sd0, 1'b0, 10'sd0, 1, "reset asserted");

        // Release reset away from a rising edge; release itself must not capture input.
        @(negedge clk);
        rst_n = 1'b1;
        x_in = 8'sd77;
        valid_in = 1'b1;
        #1;
        expect_state(10'sd0, 10'sd0, 10'sd0, 1'b0, 10'sd0, 1, "reset release no capture");
        valid_in = 1'b0;

        // Accept 1 -> y=1.
        drive_at_negedge(8'sd1, 1'b1);
        @(posedge clk);
        expect_state(10'sd1, 10'sd0, 10'sd0, 1'b1, 10'sd1, 1, "accept x=1");

        // Accept 2 -> y=4.
        drive_at_negedge(8'sd2, 1'b1);
        @(posedge clk);
        expect_state(10'sd2, 10'sd1, 10'sd0, 1'b1, 10'sd4, 1, "accept x=2");

        // Invalid x=99 must be ignored; delay state and y_out hold, valid_out=0.
        drive_at_negedge(8'sd99, 1'b0);
        @(posedge clk);
        expect_state(10'sd2, 10'sd1, 10'sd0, 1'b0, 10'sd4, 1, "hold invalid x=99");

        // Continue accepted sequence.
        drive_at_negedge(8'sd3, 1'b1);
        @(posedge clk);
        expect_state(10'sd3, 10'sd2, 10'sd1, 1'b1, 10'sd8, 1, "accept x=3");

        drive_at_negedge(8'sd4, 1'b1);
        @(posedge clk);
        expect_state(10'sd4, 10'sd3, 10'sd2, 1'b1, 10'sd12, 1, "accept x=4");

        drive_at_negedge(8'sd5, 1'b1);
        @(posedge clk);
        expect_state(10'sd5, 10'sd4, 10'sd3, 1'b1, 10'sd16, 1, "accept x=5");

        drive_at_negedge(8'sd0, 1'b0);
        @(posedge clk);
        expect_state(10'sd5, 10'sd4, 10'sd3, 1'b0, 10'sd16, 1, "post-sequence hold");

        if (errors == 0)
            $display("[RESULT] FIR3_PARALLEL TEST PASSED");
        else
            $display("[RESULT] FIR3_PARALLEL TEST FAILED with %0d error(s)", errors);

        #4;
        $finish;
    end

endmodule
