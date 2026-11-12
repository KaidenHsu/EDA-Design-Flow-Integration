`timescale 1ns/1ps
// Simulation for the BUNDLED teaching reference only.
module tb_fir3_reference;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst_n = 1'b0;
    reg valid_in = 1'b0;
    reg signed [7:0] x_in = 0;
    wire valid_out;
    wire signed [9:0] y_out;
    integer old0 = 0, old1 = 0, old2 = 0;
    integer expected, errors = 0, samples = 0;
    fir3_reference #(.W(8)) dut (
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in),
        .x_in(x_in), .valid_out(valid_out), .y_out(y_out)
    );
    task apply;
        input integer signed_value;
        input integer is_valid;
        begin
            @(negedge clk);
            x_in = signed_value;
            valid_in = is_valid;
            @(posedge clk);
            if (is_valid) begin
                old2 = old1;
                old1 = old0;
                old0 = signed_value;
            end
            expected = old0 + 2*old1 + old2;
            #1;
            if (valid_out !== (is_valid != 0) || y_out !== expected) begin
                $display("FAIL n=%0d valid=%0d got=%0d expected=%0d", samples,
                         valid_out, y_out, expected);
                errors = errors + 1;
            end else begin
                $display("PASS n=%0d valid=%0d y=%0d", samples, valid_out, y_out);
            end
            samples = samples + 1;
        end
    endtask
    initial begin
        $dumpfile("results/offline/fir3_reference.vcd");
        $dumpvars(0, tb_fir3_reference);
        repeat (2) @(posedge clk);
        #1;
        if (valid_out !== 1'b0 || y_out !== 10'sd0) begin
            $display("FAIL reset behavior"); errors = errors + 1;
        end
        @(negedge clk); rst_n = 1'b1;
        apply(1,1);
        apply(2,1);
        apply(3,1);
        apply(4,1);
        apply(5,1);
        apply(77,0);  // valid bubble: all three delay registers must hold
        apply(-3,1);
        apply(-128,1);
        apply(127,1);
        apply(-11,0);
        apply(0,1);
        if (errors == 0) $display("W10_FIR_TB_PASS samples=%0d", samples);
        else $display("W10_FIR_TB_FAIL errors=%0d", errors);
        $finish;
    end
endmodule
