`timescale 1ns/1ps

module tb_fir3_pipe2;

    reg clk;
    reg rst_n;
    reg valid_in;
    reg signed [7:0] x_in;
    wire valid_out;
    wire signed [9:0] y_out;

    integer errors;

    fir3_pipe2 dut (
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

    task drive_at_negedge;
        input signed [7:0] sample;
        input              v;
        begin
            @(negedge clk);
            x_in = sample;
            valid_in = v;
        end
    endtask

    task check_output;
        input              e_valid;
        input signed [9:0] e_y;
        input integer      check_y;
        input [8*48-1:0]   label;
        begin
            #1;
            if (valid_out !== e_valid) begin
                $display("[FAIL] %0s valid_out=%0b expected %0b", label, valid_out, e_valid);
                errors = errors + 1;
            end
            if (check_y && y_out !== e_y) begin
                $display("[FAIL] %0s y_out=%0d expected %0d", label, y_out, e_y);
                errors = errors + 1;
            end
            if (valid_out === e_valid && (!check_y || y_out === e_y))
                $display("[PASS] %0s y=%0d valid=%0b", label, y_out, valid_out);
        end
    endtask

    task check_products;
        input signed [9:0] e_p0;
        input signed [9:0] e_p1;
        input signed [9:0] e_p2;
        input              e_v1;
        input [8*48-1:0]   label;
        begin
            #1;
            if (dut.p0_s1 !== e_p0 || dut.p1_s1 !== e_p1 ||
                dut.p2_s1 !== e_p2 || dut.valid_s1 !== e_v1) begin
                $display("[FAIL] %0s products=%0d/%0d/%0d valid_s1=%0b expected %0d/%0d/%0d %0b",
                         label, dut.p0_s1, dut.p1_s1, dut.p2_s1, dut.valid_s1,
                         e_p0, e_p1, e_p2, e_v1);
                errors = errors + 1;
            end else begin
                $display("[PASS] %0s products=%0d/%0d/%0d valid_s1=%0b",
                         label, dut.p0_s1, dut.p1_s1, dut.p2_s1, dut.valid_s1);
            end
        end
    endtask

    task check_delay;
        input signed [9:0] e_d0;
        input signed [9:0] e_d1;
        input signed [9:0] e_d2;
        input [8*48-1:0]   label;
        begin
            #1;
            if (dut.d0 !== e_d0 || dut.d1 !== e_d1 || dut.d2 !== e_d2) begin
                $display("[FAIL] %0s delay state=%0d/%0d/%0d expected %0d/%0d/%0d",
                         label, dut.d0, dut.d1, dut.d2, e_d0, e_d1, e_d2);
                errors = errors + 1;
            end else begin
                $display("[PASS] %0s delay state=%0d/%0d/%0d",
                         label, dut.d0, dut.d1, dut.d2);
            end
        end
    endtask

    initial begin
        errors = 0;
        rst_n = 1'b0;
        valid_in = 1'b0;
        x_in = 8'sd0;

        $dumpfile("waves/fir3_pipe2.vcd");
        $dumpvars(0, tb_fir3_pipe2);

        #2;
        if (dut.d0 !== 0 || dut.d1 !== 0 || dut.d2 !== 0 ||
            dut.p0_s1 !== 0 || dut.p1_s1 !== 0 || dut.p2_s1 !== 0 ||
            dut.valid_s1 !== 0 || valid_out !== 0 || y_out !== 0) begin
            $display("[FAIL] reset did not clear all pipeline state");
            errors = errors + 1;
        end else begin
            $display("[PASS] reset clears delay/product/valid/output state");
        end

        // Reset release alone must not capture input.
        @(negedge clk);
        rst_n = 1'b1;
        x_in = 8'sd77;
        valid_in = 1'b1;
        #1;
        if (dut.d0 !== 0 || dut.valid_s1 !== 0 || valid_out !== 0) begin
            $display("[FAIL] reset release changed registers without a rising edge");
            errors = errors + 1;
        end else begin
            $display("[PASS] reset release does not capture input");
        end
        valid_in = 1'b0;

        // E1: accept x=1. Stage 1 becomes 1/0/0; no output yet.
        drive_at_negedge(8'sd1, 1'b1);
        @(posedge clk);
        check_output(1'b0, 10'sd0, 1, "E1 first accepted sample");
        check_products(10'sd1, 10'sd0, 10'sd0, 1'b1, "E1 product stage");
        check_delay(10'sd1, 10'sd0, 10'sd0, "E1 delay state");

        // E2: accept x=2; output FIR(1)=1; new products 2/2/0.
        drive_at_negedge(8'sd2, 1'b1);
        @(posedge clk);
        check_output(1'b1, 10'sd1, 1, "E2 output sample 1");
        check_products(10'sd2, 10'sd2, 10'sd0, 1'b1, "E2 product stage");
        check_delay(10'sd2, 10'sd1, 10'sd0, "E2 delay state");

        // E3 BUBBLE: invalid x=99 must not advance state or products.
        // Stage 2 still emits FIR(2)=4 from E2's valid Stage-1 products.
        drive_at_negedge(8'sd99, 1'b0);
        @(posedge clk);
        check_output(1'b1, 10'sd4, 1, "E3 bubble emits prior sample 2");
        check_products(10'sd2, 10'sd2, 10'sd0, 1'b0, "E3 bubble product hold");
        check_delay(10'sd2, 10'sd1, 10'sd0, "E3 bubble delay hold");

        // E4: valid traffic resumes with x=3. Because E3 was invalid,
        // valid_out must show a one-cycle output bubble and y_out must hold 4.
        drive_at_negedge(8'sd3, 1'b1);
        @(posedge clk);
        check_output(1'b0, 10'sd4, 1, "E4 delayed output bubble");
        check_products(10'sd3, 10'sd4, 10'sd1, 1'b1, "E4 recovery product stage");
        check_delay(10'sd3, 10'sd2, 10'sd1, "E4 recovery delay state");

        // E5: accept x=4; output FIR(3)=8.
        drive_at_negedge(8'sd4, 1'b1);
        @(posedge clk);
        check_output(1'b1, 10'sd8, 1, "E5 output sample 3");
        check_products(10'sd4, 10'sd6, 10'sd2, 1'b1, "E5 product stage");

        // E6: accept x=5; output FIR(4)=12.
        drive_at_negedge(8'sd5, 1'b1);
        @(posedge clk);
        check_output(1'b1, 10'sd12, 1, "E6 output sample 4");
        check_products(10'sd5, 10'sd8, 10'sd3, 1'b1, "E6 product stage");

        // E7 drain: no new input. Held products produce final 16; valid_s1 becomes 0.
        drive_at_negedge(8'sd0, 1'b0);
        @(posedge clk);
        check_output(1'b1, 10'sd16, 1, "E7 drain final output");
        check_products(10'sd5, 10'sd8, 10'sd3, 1'b0, "E7 held products ignored next cycle");
        check_delay(10'sd5, 10'sd4, 10'sd3, "E7 drain delay hold");

        // Idle: final data may remain stored, but valid_out must be 0.
        drive_at_negedge(8'sd0, 1'b0);
        @(posedge clk);
        check_output(1'b0, 10'sd16, 1, "idle after drain");
        check_products(10'sd5, 10'sd8, 10'sd3, 1'b0, "idle product hold");

        if (errors == 0)
            $display("[RESULT] FIR3_PIPE2 TEST PASSED");
        else
            $display("[RESULT] FIR3_PIPE2 TEST FAILED with %0d error(s)", errors);

        #4;
        $finish;
    end

endmodule
