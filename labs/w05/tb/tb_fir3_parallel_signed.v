`timescale 1ns/1ps

// Signed-width boundary regression for the Week 5 registered-parallel FIR.
module tb_fir3_parallel_signed;
    reg clk;
    reg rst_n;
    reg valid_in;
    reg signed [7:0] x_in;
    wire valid_out;
    wire signed [9:0] y_out;
    integer errors;

    fir3_parallel dut (
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in), .x_in(x_in),
        .valid_out(valid_out), .y_out(y_out)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task accept_and_check;
        input signed [7:0] sample;
        input signed [9:0] expected;
        begin
            @(negedge clk);
            x_in = sample;
            valid_in = 1'b1;
            @(posedge clk);
            #1;
            if (y_out !== expected || valid_out !== 1'b1) begin
                $display("[FAIL] signed parallel sample=%0d y=%0d valid=%0b expected=%0d/1",
                         sample, y_out, valid_out, expected);
                errors = errors + 1;
            end else begin
                $display("[PASS] signed parallel sample=%0d y=%0d", sample, y_out);
            end
        end
    endtask

    initial begin
        errors = 0;
        rst_n = 1'b0;
        valid_in = 1'b0;
        x_in = 8'sd0;

        $dumpfile("waves/fir3_parallel_signed.vcd");
        $dumpvars(0, tb_fir3_parallel_signed);

        #12;
        rst_n = 1'b1;

        // Repeated minimum INT8 input reaches the exact -512 FIR output bound.
        accept_and_check(8'sh80, 10'sh380);  // -128
        accept_and_check(8'sh80, 10'sh280);  // -384
        accept_and_check(8'sh80, 10'sh200);  // -512

        @(negedge clk);
        valid_in = 1'b0;
        x_in = 8'sd0;
        @(posedge clk);
        #1;
        if (valid_out !== 1'b0 || y_out !== 10'sh200) begin
            $display("[FAIL] signed parallel invalid hold y=%0d valid=%0b", y_out, valid_out);
            errors = errors + 1;
        end else begin
            $display("[PASS] signed parallel invalid hold preserves -512 and deasserts valid");
        end

        if (errors == 0)
            $display("[RESULT] FIR3_PARALLEL SIGNED TEST PASSED");
        else
            $display("[RESULT] FIR3_PARALLEL SIGNED TEST FAILED with %0d error(s)", errors);

        #4;
        $finish;
    end
endmodule
