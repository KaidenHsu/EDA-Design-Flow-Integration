`timescale 1ns/1ps

// Signed-width boundary regression for the Week 5 one-cycle pipeline.
module tb_fir3_pipe2_signed;
    reg clk;
    reg rst_n;
    reg valid_in;
    reg signed [7:0] x_in;
    wire valid_out;
    wire signed [9:0] y_out;
    integer errors;

    fir3_pipe2 dut (
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in), .x_in(x_in),
        .valid_out(valid_out), .y_out(y_out)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task drive;
        input signed [7:0] sample;
        input v;
        begin
            @(negedge clk);
            x_in = sample;
            valid_in = v;
        end
    endtask

    task expect_output;
        input e_valid;
        input signed [9:0] e_y;
        input [8*48-1:0] label;
        begin
            #1;
            if (valid_out !== e_valid || y_out !== e_y) begin
                $display("[FAIL] %0s y=%0d valid=%0b expected=%0d/%0b",
                         label, y_out, valid_out, e_y, e_valid);
                errors = errors + 1;
            end else begin
                $display("[PASS] %0s y=%0d valid=%0b", label, y_out, valid_out);
            end
        end
    endtask

    initial begin
        errors = 0;
        rst_n = 1'b0;
        valid_in = 1'b0;
        x_in = 8'sd0;

        $dumpfile("waves/fir3_pipe2_signed.vcd");
        $dumpvars(0, tb_fir3_pipe2_signed);

        #12;
        rst_n = 1'b1;

        // First -128 is accepted into Stage 1; no output yet.
        drive(8'sh80, 1'b1);
        @(posedge clk);
        expect_output(1'b0, 10'sd0, "signed E1 no output yet");

        // Second accepted -128 emits FIR result for the first accepted sample.
        drive(8'sh80, 1'b1);
        @(posedge clk);
        expect_output(1'b1, 10'sh380, "signed E2 output -128");

        // Third accepted -128 emits -384.
        drive(8'sh80, 1'b1);
        @(posedge clk);
        expect_output(1'b1, 10'sh280, "signed E3 output -384");

        // Drain emits the exact lower bound -512.
        drive(8'sd0, 1'b0);
        @(posedge clk);
        expect_output(1'b1, 10'sh200, "signed E4 drain output -512");

        // One more invalid edge proves valid_out deasserts and y_out holds.
        drive(8'sd0, 1'b0);
        @(posedge clk);
        expect_output(1'b0, 10'sh200, "signed E5 idle after drain");

        if (errors == 0)
            $display("[RESULT] FIR3_PIPE2 SIGNED TEST PASSED");
        else
            $display("[RESULT] FIR3_PIPE2 SIGNED TEST FAILED with %0d error(s)", errors);

        #4;
        $finish;
    end
endmodule
