// Week 10 TEACHING REFERENCE — not a claim of byte-level identity with Week 4 RTL.
// Three clocked sample-delay registers; combinational FIR output.
// Coefficients: [1, 2, 1]. Accept samples only when valid_in=1.
// For W=8, y_out is 10-bit signed; no rounding or truncation in this model.
module fir3_reference #(
    parameter integer W = 8
) (
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire                      valid_in,
    input  wire signed [W-1:0]       x_in,
    output reg                       valid_out,
    output wire signed [W+1:0]       y_out
);
    reg signed [W-1:0] d0, d1, d2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d0 <= {W{1'b0}};
            d1 <= {W{1'b0}};
            d2 <= {W{1'b0}};
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            if (valid_in) begin
                d2 <= d1;
                d1 <= d0;
                d0 <= x_in;
            end
        end
    end

    // Explicitly sign-extend before shifting and adding.
    wire signed [W+1:0] t0 = {{2{d0[W-1]}}, d0};
    wire signed [W+1:0] t1 = {{2{d1[W-1]}}, d1};
    wire signed [W+1:0] t2 = {{2{d2[W-1]}}, d2};
    assign y_out = t0 + (t1 <<< 1) + t2;
endmodule
