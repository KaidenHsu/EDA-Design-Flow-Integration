/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : Y-2026.03
// Date      : Thu Nov 12 20:55:52 2026
/////////////////////////////////////////////////////////////


module fir3_seq_DW01_add_1 ( A, B, CI, SUM, CO );
  input [9:0] A;
  input [9:0] B;
  output [9:0] SUM;
  input CI;
  output CO;
  wire   n1;
  wire   [9:1] carry;

  ADDFX2 U1_8 ( .A(A[8]), .B(B[8]), .CI(carry[8]), .CO(carry[9]), .S(SUM[8])
         );
  ADDFX2 U1_7 ( .A(A[7]), .B(B[7]), .CI(carry[7]), .CO(carry[8]), .S(SUM[7])
         );
  ADDFX2 U1_6 ( .A(A[6]), .B(B[6]), .CI(carry[6]), .CO(carry[7]), .S(SUM[6])
         );
  ADDFX2 U1_5 ( .A(A[5]), .B(B[5]), .CI(carry[5]), .CO(carry[6]), .S(SUM[5])
         );
  ADDFX2 U1_4 ( .A(A[4]), .B(B[4]), .CI(carry[4]), .CO(carry[5]), .S(SUM[4])
         );
  ADDFX2 U1_3 ( .A(A[3]), .B(B[3]), .CI(carry[3]), .CO(carry[4]), .S(SUM[3])
         );
  XOR3X2 U1_9 ( .A(A[9]), .B(B[9]), .C(carry[9]), .Y(SUM[9]) );
  ADDFX2 U1_1 ( .A(A[1]), .B(B[1]), .CI(n1), .CO(carry[2]), .S(SUM[1]) );
  ADDFX2 U1_2 ( .A(A[2]), .B(B[2]), .CI(carry[2]), .CO(carry[3]), .S(SUM[2])
         );
  AND2X2 U1 ( .A(B[0]), .B(A[0]), .Y(n1) );
  XOR2X1 U2 ( .A(B[0]), .B(A[0]), .Y(SUM[0]) );
endmodule


module fir3_seq_DW01_add_0 ( A, B, CI, SUM, CO );
  input [9:0] A;
  input [9:0] B;
  output [9:0] SUM;
  input CI;
  output CO;
  wire   \B[0] , n1;
  wire   [9:1] carry;
  assign SUM[0] = \B[0] ;
  assign \B[0]  = B[0];

  XOR3X2 U1_9 ( .A(A[9]), .B(B[9]), .C(carry[9]), .Y(SUM[9]) );
  ADDFX2 U1_8 ( .A(A[8]), .B(B[8]), .CI(carry[8]), .CO(carry[9]), .S(SUM[8])
         );
  ADDFX2 U1_7 ( .A(A[7]), .B(B[7]), .CI(carry[7]), .CO(carry[8]), .S(SUM[7])
         );
  ADDFX2 U1_6 ( .A(A[6]), .B(B[6]), .CI(carry[6]), .CO(carry[7]), .S(SUM[6])
         );
  ADDFX2 U1_5 ( .A(A[5]), .B(B[5]), .CI(carry[5]), .CO(carry[6]), .S(SUM[5])
         );
  ADDFX2 U1_4 ( .A(A[4]), .B(B[4]), .CI(carry[4]), .CO(carry[5]), .S(SUM[4])
         );
  ADDFX2 U1_3 ( .A(A[3]), .B(B[3]), .CI(carry[3]), .CO(carry[4]), .S(SUM[3])
         );
  ADDFX2 U1_2 ( .A(A[2]), .B(B[2]), .CI(n1), .CO(carry[3]), .S(SUM[2]) );
  AND2X2 U1 ( .A(B[1]), .B(A[1]), .Y(n1) );
  XOR2X1 U2 ( .A(B[1]), .B(A[1]), .Y(SUM[1]) );
endmodule


module fir3_seq ( clk, rst_n, valid_in, x_in, valid_out, y_out );
  input [7:0] x_in;
  output [9:0] y_out;
  input clk, rst_n, valid_in;
  output valid_out;
  wire   \d1[9] , n1, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15,
         n16, n17, n18, n19, n20, n21, n22, n23, n24, n25, n26, n27, n28, n29,
         n53, n56, n59, \s0[9] , \s0[8] , \s0[7] , \s0[6] , \s0[5] , \s0[4] ,
         \s0[3] , \s0[2] , \s0[1] , \s0[0] , n60, n61, n62, n63, n64, n65, n66,
         n67, n68, n69, n70, n71, n72, n73, n74, n75, n76, n77, n78, n79, n80,
         n81, n82, n83, n84, n85, n86, n87, n88, n89, n90, n91, n92, n93, n94,
         n95, n96, n97, n98, n99;
  wire   [9:0] p0;
  wire   [9:1] p1;
  wire   [9:0] p2;

  fir3_seq_DW01_add_1 add_1_root_add_0_root_add_36 ( .A(p2), .B(p0), .CI(1'b0), 
        .SUM({\s0[9] , \s0[8] , \s0[7] , \s0[6] , \s0[5] , \s0[4] , \s0[3] , 
        \s0[2] , \s0[1] , \s0[0] }) );
  fir3_seq_DW01_add_0 add_0_root_add_0_root_add_36 ( .A({p1, 1'b0}), .B({
        \s0[9] , \s0[8] , \s0[7] , \s0[6] , \s0[5] , \s0[4] , \s0[3] , \s0[2] , 
        \s0[1] , \s0[0] }), .CI(1'b0), .SUM(y_out) );
  DFFRHQX1 \d1_reg[9]  ( .D(n83), .CK(clk), .RN(rst_n), .Q(\d1[9] ) );
  DFFRHQX1 \d1_reg[8]  ( .D(n81), .CK(clk), .RN(rst_n), .Q(p1[9]) );
  DFFRHQX1 \d0_reg[9]  ( .D(n59), .CK(clk), .RN(rst_n), .Q(p0[9]) );
  DFFRHQX1 \d1_reg[7]  ( .D(n79), .CK(clk), .RN(rst_n), .Q(p1[8]) );
  DFFRHQX1 \d2_reg[9]  ( .D(n82), .CK(clk), .RN(rst_n), .Q(p2[9]) );
  DFFRHQX1 \d1_reg[6]  ( .D(n76), .CK(clk), .RN(rst_n), .Q(p1[7]) );
  DFFRHQX1 \d0_reg[8]  ( .D(n56), .CK(clk), .RN(rst_n), .Q(p0[8]) );
  DFFRHQX1 \d2_reg[8]  ( .D(n80), .CK(clk), .RN(rst_n), .Q(p2[8]) );
  DFFRHQX1 \d1_reg[5]  ( .D(n73), .CK(clk), .RN(rst_n), .Q(p1[6]) );
  DFFRHQX1 \d0_reg[7]  ( .D(n53), .CK(clk), .RN(rst_n), .Q(p0[7]) );
  DFFRHQX1 \d1_reg[4]  ( .D(n97), .CK(clk), .RN(rst_n), .Q(p1[5]) );
  DFFRHQX1 \d2_reg[7]  ( .D(n78), .CK(clk), .RN(rst_n), .Q(p2[7]) );
  DFFRHQX1 \d1_reg[3]  ( .D(n94), .CK(clk), .RN(rst_n), .Q(p1[4]) );
  DFFRHQX1 \d2_reg[6]  ( .D(n75), .CK(clk), .RN(rst_n), .Q(p2[6]) );
  DFFRHQX1 \d0_reg[6]  ( .D(n77), .CK(clk), .RN(rst_n), .Q(p0[6]) );
  DFFRHQX1 \d1_reg[2]  ( .D(n91), .CK(clk), .RN(rst_n), .Q(p1[3]) );
  DFFRHQX1 \d2_reg[5]  ( .D(n99), .CK(clk), .RN(rst_n), .Q(p2[5]) );
  DFFRHQX1 \d0_reg[5]  ( .D(n74), .CK(clk), .RN(rst_n), .Q(p0[5]) );
  DFFRHQX1 \d1_reg[1]  ( .D(n88), .CK(clk), .RN(rst_n), .Q(p1[2]) );
  DFFRHQX1 \d1_reg[0]  ( .D(n85), .CK(clk), .RN(rst_n), .Q(p1[1]) );
  DFFRHQX1 \d2_reg[4]  ( .D(n96), .CK(clk), .RN(rst_n), .Q(p2[4]) );
  DFFRHQX1 \d0_reg[4]  ( .D(n98), .CK(clk), .RN(rst_n), .Q(p0[4]) );
  DFFRHQX1 \d2_reg[3]  ( .D(n93), .CK(clk), .RN(rst_n), .Q(p2[3]) );
  DFFRHQX1 \d0_reg[3]  ( .D(n95), .CK(clk), .RN(rst_n), .Q(p0[3]) );
  DFFRHQX1 \d2_reg[2]  ( .D(n90), .CK(clk), .RN(rst_n), .Q(p2[2]) );
  DFFRHQX1 \d0_reg[2]  ( .D(n92), .CK(clk), .RN(rst_n), .Q(p0[2]) );
  DFFRHQX1 \d2_reg[0]  ( .D(n84), .CK(clk), .RN(rst_n), .Q(p2[0]) );
  DFFRHQX1 \d0_reg[1]  ( .D(n89), .CK(clk), .RN(rst_n), .Q(p0[1]) );
  DFFRHQX1 \d0_reg[0]  ( .D(n86), .CK(clk), .RN(rst_n), .Q(p0[0]) );
  DFFRHQX1 \d2_reg[1]  ( .D(n87), .CK(clk), .RN(rst_n), .Q(p2[1]) );
  DFFRHQX1 valid_out_reg ( .D(n62), .CK(clk), .RN(rst_n), .Q(valid_out) );
  INVX1 U62 ( .A(n71), .Y(n60) );
  INVX1 U63 ( .A(n71), .Y(n62) );
  INVX1 U64 ( .A(n1), .Y(n73) );
  AOI22X1 U65 ( .A0(n63), .A1(p1[6]), .B0(p0[5]), .B1(n60), .Y(n1) );
  INVX1 U66 ( .A(n3), .Y(n74) );
  AOI22X1 U67 ( .A0(n65), .A1(p0[5]), .B0(x_in[5]), .B1(n60), .Y(n3) );
  INVX1 U68 ( .A(valid_in), .Y(n71) );
  INVX1 U69 ( .A(n72), .Y(n61) );
  INVX1 U70 ( .A(valid_in), .Y(n72) );
  INVX1 U71 ( .A(n16), .Y(n86) );
  AOI22X1 U72 ( .A0(n65), .A1(p0[0]), .B0(x_in[0]), .B1(n61), .Y(n16) );
  INVX1 U73 ( .A(n19), .Y(n89) );
  AOI22X1 U74 ( .A0(n65), .A1(p0[1]), .B0(x_in[1]), .B1(n61), .Y(n19) );
  INVX1 U75 ( .A(n22), .Y(n92) );
  AOI22X1 U76 ( .A0(n65), .A1(p0[2]), .B0(x_in[2]), .B1(n61), .Y(n22) );
  INVX1 U77 ( .A(n25), .Y(n95) );
  AOI22X1 U78 ( .A0(n65), .A1(p0[3]), .B0(x_in[3]), .B1(n61), .Y(n25) );
  INVX1 U79 ( .A(n28), .Y(n98) );
  AOI22X1 U80 ( .A0(n63), .A1(p0[4]), .B0(x_in[4]), .B1(n61), .Y(n28) );
  INVX1 U81 ( .A(n6), .Y(n77) );
  AOI22X1 U82 ( .A0(n64), .A1(p0[6]), .B0(x_in[6]), .B1(n61), .Y(n6) );
  INVX1 U83 ( .A(n15), .Y(n85) );
  AOI22X1 U84 ( .A0(n65), .A1(p1[1]), .B0(n61), .B1(p0[0]), .Y(n15) );
  INVX1 U85 ( .A(n18), .Y(n88) );
  AOI22X1 U86 ( .A0(n63), .A1(p1[2]), .B0(n61), .B1(p0[1]), .Y(n18) );
  INVX1 U87 ( .A(n21), .Y(n91) );
  AOI22X1 U88 ( .A0(n64), .A1(p1[3]), .B0(n61), .B1(p0[2]), .Y(n21) );
  INVX1 U89 ( .A(n24), .Y(n94) );
  AOI22X1 U90 ( .A0(n64), .A1(p1[4]), .B0(n61), .B1(p0[3]), .Y(n24) );
  INVX1 U91 ( .A(n27), .Y(n97) );
  AOI22X1 U92 ( .A0(n63), .A1(p1[5]), .B0(n61), .B1(p0[4]), .Y(n27) );
  INVX1 U93 ( .A(n5), .Y(n76) );
  AOI22X1 U94 ( .A0(n64), .A1(p1[7]), .B0(n61), .B1(p0[6]), .Y(n5) );
  INVX1 U95 ( .A(n8), .Y(n79) );
  AOI22X1 U96 ( .A0(n64), .A1(p1[8]), .B0(n61), .B1(p0[7]), .Y(n8) );
  INVX1 U97 ( .A(n13), .Y(n83) );
  AOI22X1 U98 ( .A0(n60), .A1(p0[9]), .B0(n71), .B1(\d1[9] ), .Y(n13) );
  INVX1 U99 ( .A(n14), .Y(n84) );
  AOI22X1 U100 ( .A0(n60), .A1(p1[1]), .B0(p2[0]), .B1(n68), .Y(n14) );
  INVX1 U101 ( .A(n17), .Y(n87) );
  AOI22X1 U102 ( .A0(n60), .A1(p1[2]), .B0(p2[1]), .B1(n67), .Y(n17) );
  INVX1 U103 ( .A(n20), .Y(n90) );
  AOI22X1 U104 ( .A0(n60), .A1(p1[3]), .B0(p2[2]), .B1(n66), .Y(n20) );
  INVX1 U105 ( .A(n23), .Y(n93) );
  AOI22X1 U106 ( .A0(n60), .A1(p1[4]), .B0(p2[3]), .B1(n67), .Y(n23) );
  INVX1 U107 ( .A(n26), .Y(n96) );
  AOI22X1 U108 ( .A0(n60), .A1(p1[5]), .B0(p2[4]), .B1(n66), .Y(n26) );
  INVX1 U109 ( .A(n29), .Y(n99) );
  AOI22X1 U110 ( .A0(n60), .A1(p1[6]), .B0(p2[5]), .B1(n70), .Y(n29) );
  INVX1 U111 ( .A(n4), .Y(n75) );
  AOI22X1 U112 ( .A0(n60), .A1(p1[7]), .B0(p2[6]), .B1(n70), .Y(n4) );
  INVX1 U113 ( .A(n7), .Y(n78) );
  AOI22X1 U114 ( .A0(n60), .A1(p1[8]), .B0(p2[7]), .B1(n68), .Y(n7) );
  INVX1 U115 ( .A(n10), .Y(n80) );
  AOI22X1 U116 ( .A0(n60), .A1(p1[9]), .B0(p2[8]), .B1(n69), .Y(n10) );
  INVX1 U117 ( .A(n12), .Y(n82) );
  AOI22X1 U118 ( .A0(n60), .A1(\d1[9] ), .B0(p2[9]), .B1(n69), .Y(n12) );
  INVX1 U119 ( .A(n11), .Y(n81) );
  AOI22X1 U120 ( .A0(n64), .A1(p1[9]), .B0(n62), .B1(p0[8]), .Y(n11) );
  NAND2X1 U121 ( .A(x_in[7]), .B(n62), .Y(n9) );
  OAI2BB1X1 U122 ( .A0N(n63), .A1N(p0[7]), .B0(n9), .Y(n53) );
  OAI2BB1X1 U123 ( .A0N(n63), .A1N(p0[8]), .B0(n9), .Y(n56) );
  OAI2BB1X1 U124 ( .A0N(n63), .A1N(p0[9]), .B0(n9), .Y(n59) );
  INVX1 U125 ( .A(valid_in), .Y(n67) );
  INVX1 U126 ( .A(valid_in), .Y(n66) );
  INVX1 U127 ( .A(valid_in), .Y(n70) );
  INVX1 U128 ( .A(valid_in), .Y(n68) );
  INVX1 U129 ( .A(valid_in), .Y(n69) );
  INVX1 U130 ( .A(valid_in), .Y(n63) );
  INVX1 U131 ( .A(valid_in), .Y(n65) );
  INVX1 U132 ( .A(valid_in), .Y(n64) );
endmodule

