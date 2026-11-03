`timescale 1ns/1ps
module tb_debug_wrapper;
    reg clk=0, rst_n=0, sample_req=0;
    reg signed [7:0] x_in=0;
    wire valid_in, valid_out, valid_s1;
    wire signed [9:0] y_out, d0, d1, d2;
    integer errors=0, checks=0;
    fir3_debug_wrapper dut(
        .clk(clk), .rst_n(rst_n), .sample_req(sample_req), .x_in(x_in),
        .valid_in(valid_in), .valid_out(valid_out), .y_out(y_out),
        .valid_s1(valid_s1), .d0(d0), .d1(d1), .d2(d2)
    );
    always #4 clk = ~clk;
    task reset_case;
      begin
        @(negedge clk); rst_n=0; sample_req=0; x_in=0;
        repeat(3) @(negedge clk);
        if (valid_out !== 0 || y_out !== 0 || valid_in !== 0) begin
            $display("[FAIL] reset contract"); errors=errors+1;
        end
        rst_n=1;
        repeat(2) @(negedge clk);
      end
    endtask
    task send;
      input signed [7:0] value;
      input signed [9:0] expected;
      begin
        @(negedge clk);
        x_in=value; sample_req=1;
        #1;
        if (valid_in !== 1'b1) begin $display("[FAIL] missing accepted request"); errors=errors+1; end
        @(posedge clk); #1;
        if (valid_s1 !== 1'b1 || valid_out !== 1'b0 || valid_in !== 1'b0) begin
            $display("[FAIL] stage-1 valid or single-shot pulse"); errors=errors+1;
        end
        @(negedge clk); sample_req=0;
        #1;
        if (valid_in !== 0) begin $display("[FAIL] LOW incorrectly created pulse"); errors=errors+1; end
        @(posedge clk); #1;
        if (valid_out !== 1'b1 || $signed(y_out) !== expected) begin
            $display("[FAIL] input=%0d expected=%0d got=%0d valid=%b",value,expected,y_out,valid_out);
            errors=errors+1;
        end
        checks=checks+1;
      end
    endtask
    task no_request;
      input signed [9:0] held;
      begin
        @(negedge clk); sample_req=0; x_in=-128;
        repeat(3) begin
            @(posedge clk); #1;
            if (valid_in !== 0 || valid_out !== 0 || $signed(y_out) !== held) begin
                $display("[FAIL] idle changes valid or output"); errors=errors+1;
            end
        end
      end
    endtask
    initial begin
      reset_case;
      send(1,1); send(2,4); send(3,8); send(0,8); send(0,3);
      reset_case;
      send(5,5); no_request(5);
      reset_case;
      send(-128,-128); send(-128,-384); send(-128,-512);
      reset_case;
      send(2,2);
      // Two accepted transactions separated by idle clock cycles.
      repeat(4) @(negedge clk);
      send(3,7);
      reset_case;
      @(negedge clk); x_in=5; sample_req=1;
      @(posedge clk); #1;
      if (valid_s1 !== 1 || valid_in !== 0) begin
        $display("[FAIL] held-high initial acceptance"); errors=errors+1;
      end
      @(posedge clk); #1; // The single expected output from the first request.
      if (valid_out !== 1 || $signed(y_out) !== 5) begin
        $display("[FAIL] held-high expected one output"); errors=errors+1;
      end
      repeat(5) begin
        @(posedge clk); #1;
        if (valid_out !== 0 || valid_in !== 0) begin
          $display("[FAIL] held-high repeated sample"); errors=errors+1;
        end
      end
      @(negedge clk); sample_req=0;
      repeat(2) @(posedge clk);
      if(errors == 0 && checks == 11)
        $display("[RESULT] DEBUG WRAPPER REGRESSION PASSED");
      else
        $display("[FAIL] DEBUG WRAPPER REGRESSION FAILED errors=%0d checks=%0d",errors,checks);
      $finish;
    end
endmodule
