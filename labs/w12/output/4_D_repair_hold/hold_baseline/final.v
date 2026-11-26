// IC Compiler II Version X-2025.06 Verilog Writer
// Generated on 11/27/2026 at 2:1:49
// Library Name: fir3.dlib
// Block Name: fir3_reference
// User Label: 
// Write Command: write_verilog final.v
module fir3_reference_DW01_add_0 ( A , B , CI , SUM , CO ) ;
input  [9:0] A ;
input  [9:0] B ;
input  CI ;
output [9:0] SUM ;
output CO ;

wire [9:1] carry ;

assign SUM[0] = B[0] ;

XOR3X2 U1_9 ( .A ( A[9] ) , .B ( B[9] ) , .C ( carry[9] ) , .Y ( SUM[9] ) ) ;
ADDFX2 U1_8 ( .A ( A[8] ) , .B ( B[8] ) , .CI ( carry[8] ) , 
    .CO ( carry[9] ) , .S ( SUM[8] ) ) ;
ADDFX2 U1_7 ( .A ( A[7] ) , .B ( B[7] ) , .CI ( carry[7] ) , 
    .CO ( carry[8] ) , .S ( SUM[7] ) ) ;
ADDFX2 U1_6 ( .A ( A[6] ) , .B ( B[6] ) , .CI ( carry[6] ) , 
    .CO ( carry[7] ) , .S ( SUM[6] ) ) ;
ADDFX2 U1_5 ( .A ( A[5] ) , .B ( B[5] ) , .CI ( carry[5] ) , 
    .CO ( carry[6] ) , .S ( SUM[5] ) ) ;
ADDFX2 U1_4 ( .A ( A[4] ) , .B ( B[4] ) , .CI ( carry[4] ) , 
    .CO ( carry[5] ) , .S ( SUM[4] ) ) ;
ADDFX2 U1_3 ( .A ( A[3] ) , .B ( B[3] ) , .CI ( carry[3] ) , 
    .CO ( carry[4] ) , .S ( SUM[3] ) ) ;
ADDFX2 U1_2 ( .A ( A[2] ) , .B ( B[2] ) , .CI ( n1 ) , .CO ( carry[3] ) , 
    .S ( SUM[2] ) ) ;
AND2X2 U1 ( .A ( B[1] ) , .B ( A[1] ) , .Y ( n1 ) ) ;
XOR2X1 U2 ( .A ( B[1] ) , .B ( A[1] ) , .Y ( SUM[1] ) ) ;
endmodule


module fir3_reference ( clk , rst_n , valid_in , x_in , valid_out , y_out ) ;
input  clk ;
input  rst_n ;
input  valid_in ;
input  [7:0] x_in ;
output valid_out ;
output [9:0] y_out ;

wire [7:0] d0 ;
wire [7:0] d1 ;
wire [7:0] d2 ;
wire [9:1] \add_1_root_add_0_root_add_36_2/carry ;

fir3_reference_DW01_add_0 add_0_root_add_0_root_add_36_2 (
    .A ( { d1[7] , d1[7] , d1[6] , d1[5] , d1[4] , d1[3] , d1[2] , d1[1] , 
        d1[0] , 1'b0 } ) ,
    .B ( { N10 , N9 , N8 , N7 , N6 , N5 , N4 , N3 , N2 , N1 } ) ,
    .CI ( 1'b0 ) , .SUM ( y_out ) ) ;
DFFRHQX1 \d1_reg[7] ( .D ( n74 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d1[7] ) ) ;
DFFRHQX1 \d1_reg[6] ( .D ( n71 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d1[6] ) ) ;
DFFRHQX1 \d1_reg[5] ( .D ( n68 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d1[5] ) ) ;
DFFRHQX1 \d1_reg[4] ( .D ( n65 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d1[4] ) ) ;
DFFRHQX1 \d2_reg[7] ( .D ( n73 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d2[7] ) ) ;
DFFRHQX1 \d1_reg[3] ( .D ( n62 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d1[3] ) ) ;
DFFRHQX1 \d2_reg[6] ( .D ( n70 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d2[6] ) ) ;
DFFRHQX1 \d0_reg[7] ( .D ( n75 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d0[7] ) ) ;
DFFRHQX1 \d0_reg[6] ( .D ( n72 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d0[6] ) ) ;
DFFRHQX1 \d1_reg[2] ( .D ( n83 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d1[2] ) ) ;
DFFRHQX1 \d2_reg[5] ( .D ( n67 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d2[5] ) ) ;
DFFRHQX1 \d0_reg[5] ( .D ( n69 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d0[5] ) ) ;
DFFRHQX1 \d1_reg[1] ( .D ( n80 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d1[1] ) ) ;
DFFRHQX1 \d1_reg[0] ( .D ( n77 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d1[0] ) ) ;
DFFRHQX1 \d2_reg[4] ( .D ( n64 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d2[4] ) ) ;
DFFRHQX1 \d0_reg[4] ( .D ( n66 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d0[4] ) ) ;
DFFRHQX1 \d2_reg[3] ( .D ( n61 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d2[3] ) ) ;
DFFRHQX1 \d0_reg[3] ( .D ( n63 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d0[3] ) ) ;
DFFRHQX1 \d2_reg[2] ( .D ( n82 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d2[2] ) ) ;
DFFRHQX1 \d0_reg[2] ( .D ( n84 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d0[2] ) ) ;
DFFRHQX1 \d2_reg[0] ( .D ( n76 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d2[0] ) ) ;
DFFRHQX1 \d0_reg[1] ( .D ( n81 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d0[1] ) ) ;
DFFRHQX1 \d0_reg[0] ( .D ( n78 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d0[0] ) ) ;
DFFRHQX1 \d2_reg[1] ( .D ( n79 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( d2[1] ) ) ;
DFFRHQX1 valid_out_reg ( .D ( n52 ) , .CK ( clk ) , .RN ( rst_n ) , 
    .Q ( valid_out ) ) ;
AND2X2 U52 ( .A ( d0[0] ) , .B ( d2[0] ) , .Y ( n50 ) ) ;
INVX1 U53 ( .A ( n60 ) , .Y ( n51 ) ) ;
INVX1 U54 ( .A ( n60 ) , .Y ( n52 ) ) ;
ADDFX2 U55 ( .A ( d2[2] ) , .B ( d0[2] ) , 
    .CI ( \add_1_root_add_0_root_add_36_2/carry [2] ) , 
    .CO ( \add_1_root_add_0_root_add_36_2/carry [3] ) , .S ( N3 ) ) ;
ADDFX2 U56 ( .A ( d2[1] ) , .B ( d0[1] ) , .CI ( n50 ) , 
    .CO ( \add_1_root_add_0_root_add_36_2/carry [2] ) , .S ( N2 ) ) ;
XOR3X2 U57 ( .A ( d2[7] ) , .B ( d0[7] ) , 
    .C ( \add_1_root_add_0_root_add_36_2/carry [9] ) , .Y ( N10 ) ) ;
ADDFX2 U58 ( .A ( d2[3] ) , .B ( d0[3] ) , 
    .CI ( \add_1_root_add_0_root_add_36_2/carry [3] ) , 
    .CO ( \add_1_root_add_0_root_add_36_2/carry [4] ) , .S ( N4 ) ) ;
ADDFX2 U59 ( .A ( d2[4] ) , .B ( d0[4] ) , 
    .CI ( \add_1_root_add_0_root_add_36_2/carry [4] ) , 
    .CO ( \add_1_root_add_0_root_add_36_2/carry [5] ) , .S ( N5 ) ) ;
ADDFX2 U60 ( .A ( d2[7] ) , .B ( d0[7] ) , 
    .CI ( \add_1_root_add_0_root_add_36_2/carry [7] ) , 
    .CO ( \add_1_root_add_0_root_add_36_2/carry [8] ) , .S ( N8 ) ) ;
ADDFX2 U61 ( .A ( d2[7] ) , .B ( d0[7] ) , 
    .CI ( \add_1_root_add_0_root_add_36_2/carry [8] ) , 
    .CO ( \add_1_root_add_0_root_add_36_2/carry [9] ) , .S ( N9 ) ) ;
ADDFX2 U62 ( .A ( d2[5] ) , .B ( d0[5] ) , 
    .CI ( \add_1_root_add_0_root_add_36_2/carry [5] ) , 
    .CO ( \add_1_root_add_0_root_add_36_2/carry [6] ) , .S ( N6 ) ) ;
ADDFX2 U63 ( .A ( d2[6] ) , .B ( d0[6] ) , 
    .CI ( \add_1_root_add_0_root_add_36_2/carry [6] ) , 
    .CO ( \add_1_root_add_0_root_add_36_2/carry [7] ) , .S ( N7 ) ) ;
XOR2X1 U64 ( .A ( d0[0] ) , .B ( d2[0] ) , .Y ( N1 ) ) ;
INVX1 U65 ( .A ( n16 ) , .Y ( n75 ) ) ;
AOI22X1 U66 ( .A0 ( n55 ) , .A1 ( d0[7] ) , .B0 ( x_in[7] ) , .B1 ( n51 ) , 
    .Y ( n16 ) ) ;
INVX1 U67 ( .A ( n4 ) , .Y ( n63 ) ) ;
AOI22X1 U68 ( .A0 ( n55 ) , .A1 ( d0[3] ) , .B0 ( x_in[3] ) , .B1 ( n51 ) , 
    .Y ( n4 ) ) ;
INVX1 U69 ( .A ( n7 ) , .Y ( n66 ) ) ;
AOI22X1 U70 ( .A0 ( n53 ) , .A1 ( d0[4] ) , .B0 ( x_in[4] ) , .B1 ( n51 ) , 
    .Y ( n7 ) ) ;
INVX1 U71 ( .A ( n10 ) , .Y ( n69 ) ) ;
AOI22X1 U72 ( .A0 ( n53 ) , .A1 ( d0[5] ) , .B0 ( x_in[5] ) , .B1 ( n51 ) , 
    .Y ( n10 ) ) ;
INVX1 U73 ( .A ( n13 ) , .Y ( n72 ) ) ;
AOI22X1 U74 ( .A0 ( n54 ) , .A1 ( d0[6] ) , .B0 ( x_in[6] ) , .B1 ( n51 ) , 
    .Y ( n13 ) ) ;
INVX1 U75 ( .A ( valid_in ) , .Y ( n60 ) ) ;
INVX1 U76 ( .A ( n19 ) , .Y ( n78 ) ) ;
AOI22X1 U77 ( .A0 ( n53 ) , .A1 ( d0[0] ) , .B0 ( x_in[0] ) , .B1 ( n52 ) , 
    .Y ( n19 ) ) ;
INVX1 U78 ( .A ( n22 ) , .Y ( n81 ) ) ;
AOI22X1 U79 ( .A0 ( n53 ) , .A1 ( d0[1] ) , .B0 ( x_in[1] ) , .B1 ( n52 ) , 
    .Y ( n22 ) ) ;
INVX1 U80 ( .A ( n25 ) , .Y ( n84 ) ) ;
AOI22X1 U81 ( .A0 ( n55 ) , .A1 ( d0[2] ) , .B0 ( x_in[2] ) , .B1 ( n52 ) , 
    .Y ( n25 ) ) ;
INVX1 U82 ( .A ( n15 ) , .Y ( n74 ) ) ;
AOI22X1 U83 ( .A0 ( n54 ) , .A1 ( d1[7] ) , .B0 ( n52 ) , .B1 ( d0[7] ) , 
    .Y ( n15 ) ) ;
INVX1 U84 ( .A ( n18 ) , .Y ( n77 ) ) ;
AOI22X1 U85 ( .A0 ( n55 ) , .A1 ( d1[0] ) , .B0 ( n52 ) , .B1 ( d0[0] ) , 
    .Y ( n18 ) ) ;
INVX1 U86 ( .A ( n21 ) , .Y ( n80 ) ) ;
AOI22X1 U87 ( .A0 ( n53 ) , .A1 ( d1[1] ) , .B0 ( n52 ) , .B1 ( d0[1] ) , 
    .Y ( n21 ) ) ;
INVX1 U88 ( .A ( n24 ) , .Y ( n83 ) ) ;
AOI22X1 U89 ( .A0 ( n53 ) , .A1 ( d1[2] ) , .B0 ( n52 ) , .B1 ( d0[2] ) , 
    .Y ( n24 ) ) ;
INVX1 U90 ( .A ( n3 ) , .Y ( n62 ) ) ;
AOI22X1 U91 ( .A0 ( n55 ) , .A1 ( d1[3] ) , .B0 ( n52 ) , .B1 ( d0[3] ) , 
    .Y ( n3 ) ) ;
INVX1 U92 ( .A ( n6 ) , .Y ( n65 ) ) ;
AOI22X1 U93 ( .A0 ( n54 ) , .A1 ( d1[4] ) , .B0 ( n52 ) , .B1 ( d0[4] ) , 
    .Y ( n6 ) ) ;
INVX1 U94 ( .A ( n9 ) , .Y ( n68 ) ) ;
AOI22X1 U95 ( .A0 ( n54 ) , .A1 ( d1[5] ) , .B0 ( n52 ) , .B1 ( d0[5] ) , 
    .Y ( n9 ) ) ;
INVX1 U96 ( .A ( n12 ) , .Y ( n71 ) ) ;
AOI22X1 U97 ( .A0 ( n54 ) , .A1 ( d1[6] ) , .B0 ( n52 ) , .B1 ( d0[6] ) , 
    .Y ( n12 ) ) ;
INVX1 U98 ( .A ( n1 ) , .Y ( n61 ) ) ;
AOI22X1 U99 ( .A0 ( d1[3] ) , .A1 ( n51 ) , .B0 ( d2[3] ) , .B1 ( n59 ) , 
    .Y ( n1 ) ) ;
INVX1 U100 ( .A ( n17 ) , .Y ( n76 ) ) ;
AOI22X1 U101 ( .A0 ( n51 ) , .A1 ( d1[0] ) , .B0 ( d2[0] ) , .B1 ( n57 ) , 
    .Y ( n17 ) ) ;
INVX1 U102 ( .A ( n20 ) , .Y ( n79 ) ) ;
AOI22X1 U103 ( .A0 ( n51 ) , .A1 ( d1[1] ) , .B0 ( d2[1] ) , .B1 ( n58 ) , 
    .Y ( n20 ) ) ;
INVX1 U104 ( .A ( n23 ) , .Y ( n82 ) ) ;
AOI22X1 U105 ( .A0 ( n51 ) , .A1 ( d1[2] ) , .B0 ( d2[2] ) , .B1 ( n59 ) , 
    .Y ( n23 ) ) ;
INVX1 U106 ( .A ( n5 ) , .Y ( n64 ) ) ;
AOI22X1 U107 ( .A0 ( n51 ) , .A1 ( d1[4] ) , .B0 ( d2[4] ) , .B1 ( n57 ) , 
    .Y ( n5 ) ) ;
INVX1 U108 ( .A ( n8 ) , .Y ( n67 ) ) ;
AOI22X1 U109 ( .A0 ( n51 ) , .A1 ( d1[5] ) , .B0 ( d2[5] ) , .B1 ( n58 ) , 
    .Y ( n8 ) ) ;
INVX1 U110 ( .A ( n11 ) , .Y ( n70 ) ) ;
AOI22X1 U111 ( .A0 ( n51 ) , .A1 ( d1[6] ) , .B0 ( d2[6] ) , .B1 ( n56 ) , 
    .Y ( n11 ) ) ;
INVX1 U112 ( .A ( n14 ) , .Y ( n73 ) ) ;
AOI22X1 U113 ( .A0 ( n51 ) , .A1 ( d1[7] ) , .B0 ( d2[7] ) , .B1 ( n56 ) , 
    .Y ( n14 ) ) ;
INVX1 U114 ( .A ( valid_in ) , .Y ( n59 ) ) ;
INVX1 U115 ( .A ( valid_in ) , .Y ( n57 ) ) ;
INVX1 U116 ( .A ( valid_in ) , .Y ( n58 ) ) ;
INVX1 U117 ( .A ( valid_in ) , .Y ( n56 ) ) ;
INVX1 U118 ( .A ( valid_in ) , .Y ( n53 ) ) ;
INVX1 U119 ( .A ( valid_in ) , .Y ( n55 ) ) ;
INVX1 U120 ( .A ( valid_in ) , .Y ( n54 ) ) ;
endmodule


