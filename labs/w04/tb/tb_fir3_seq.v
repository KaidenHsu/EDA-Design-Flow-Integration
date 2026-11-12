`timescale 1ns/1ps

module tb_fir3_seq;

    reg clk;
    reg rst_n;
    reg valid_in;
    reg signed [7:0] x_in;

    wire valid_out;
    wire signed [9:0] y_out;

    integer errors;

    fir3_seq dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .x_in      (x_in),
        .valid_out (valid_out),
        .y_out     (y_out)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;  // 10 ns period; rising edges at 5,15,25,... ns

    task check_state;
        input signed [9:0] exp_d0;
        input signed [9:0] exp_d1;
        input signed [9:0] exp_d2;
        input signed [9:0] exp_y;
        input              exp_valid;
        input [8*48-1:0]   label;
        begin
            #1;
            if ((dut.d0 !== exp_d0) ||
                (dut.d1 !== exp_d1) ||
                (dut.d2 !== exp_d2) ||
                (y_out  !== exp_y)  ||
                (valid_out !== exp_valid)) begin
                $display("[FAIL] %0s t=%0t d0=%0d d1=%0d d2=%0d y=%0d valid=%0b | expected d0=%0d d1=%0d d2=%0d y=%0d valid=%0b",
                         label, $time, dut.d0, dut.d1, dut.d2, y_out, valid_out,
                         exp_d0, exp_d1, exp_d2, exp_y, exp_valid);
                errors = errors + 1;
            end else begin
                $display("[PASS] %0s t=%0t d0=%0d d1=%0d d2=%0d y=%0d valid=%0b",
                         label, $time, dut.d0, dut.d1, dut.d2, y_out, valid_out);
            end
        end
    endtask

    task drive_before_rise;
        input signed [7:0] sample;
        input              v;
        begin
            @(negedge clk);
            x_in     = sample;
            valid_in = v;
        end
    endtask

    initial begin
        errors   = 0;
        rst_n    = 1'b0;
        valid_in = 1'b0;
        x_in     = 8'sd0;

        $dumpfile("waves/fir3_seq.vcd");
        $dumpvars(0, tb_fir3_seq);

        // Reset is asserted from time 0. Check known state after a reset edge.
        #2;
        check_state(10'sd0, 10'sd0, 10'sd0, 10'sd0, 1'b0, "reset asserted");

        // Release reset at 22 ns, strictly between rising edges at 15 and 25 ns.
        #19;
        rst_n = 1'b1;
        #1;
        if ((dut.d0 !== 10'sd0) || (dut.d1 !== 10'sd0) ||
            (dut.d2 !== 10'sd0) || (y_out !== 10'sd0) ||
            (valid_out !== 1'b0)) begin
            $display("[FAIL] reset release changed state/captured input at t=%0t", $time);
            errors = errors + 1;
        end else begin
            $display("[PASS] reset release does not capture input at t=%0t", $time);
        end

        // Rising edge at 25 ns occurs with valid_in=0: state must still hold zero.
        @(posedge clk);
        check_state(10'sd0, 10'sd0, 10'sd0, 10'sd0, 1'b0, "post-reset hold");

        // Accepted sample sequence is 1,2,3,4,5.  The 99 at 55 ns is invalid
        // and must not advance the delay line.
        drive_before_rise(8'sd1, 1'b1);   // drive at 30 ns, accept at 35 ns
        @(posedge clk);
        check_state(10'sd1, 10'sd0, 10'sd0, 10'sd1, 1'b1, "accept x=1");

        drive_before_rise(8'sd2, 1'b1);   // accept at 45 ns
        @(posedge clk);
        check_state(10'sd2, 10'sd1, 10'sd0, 10'sd4, 1'b1, "accept x=2");

        drive_before_rise(8'sd99, 1'b0);  // edge at 55 ns: hold
        @(posedge clk);
        check_state(10'sd2, 10'sd1, 10'sd0, 10'sd4, 1'b0, "ignore invalid x=99");

        drive_before_rise(8'sd3, 1'b1);   // accept at 65 ns
        @(posedge clk);
        check_state(10'sd3, 10'sd2, 10'sd1, 10'sd8, 1'b1, "accept x=3");

        drive_before_rise(8'sd4, 1'b1);   // accept at 75 ns
        @(posedge clk);
        check_state(10'sd4, 10'sd3, 10'sd2, 10'sd12, 1'b1, "accept x=4");

        drive_before_rise(8'sd5, 1'b1);   // accept at 85 ns
        @(posedge clk);
        check_state(10'sd5, 10'sd4, 10'sd3, 10'sd16, 1'b1, "accept x=5");

        // One final invalid cycle proves state hold and valid_out deassertion.
        drive_before_rise(8'sd0, 1'b0);   // edge at 95 ns
        @(posedge clk);
        check_state(10'sd5, 10'sd4, 10'sd3, 10'sd16, 1'b0, "final hold");

        if (errors == 0) begin
            $display("[RESULT] FIR3_SEQ TEST PASSED");
        end else begin
            $display("[RESULT] FIR3_SEQ TEST FAILED errors=%0d", errors);
        end

        #4;
        $finish;
    end

endmodule
