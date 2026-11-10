// generated from add19.sch
module add19 (
    input wire [18:0] B,
    input wire [18:0] A,
    output wire [18:0] C,
    input wire CI
);

    wire XLXN_23;
    wire XLXN_24;
    wire [15:0] XLXN_26;
    wire [15:0] XLXN_27;

    add16 XLXI_1 (.A(A[15:0]), .B(B[15:0]), .CI(CI), .CO(XLXN_23), .OFL(), .S(C[15:0]));
    add4 XLXI_2 (.A0(A[16]), .A1(A[17]), .A2(A[18]), .A3(XLXN_24), .B0(B[16]), .B1(B[17]), .B2(B[18]), .B3(XLXN_24), .CI(XLXN_23), .CO(), .OFL(), .S0(C[16]), .S1(C[17]), .S2(C[18]), .S3());
    gnd XLXI_4 (.G(XLXN_24));

endmodule
