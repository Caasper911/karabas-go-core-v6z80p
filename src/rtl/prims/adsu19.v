// generated from adsu19.sch
module adsu19 (
    input wire [18:0] B,
    input wire [18:0] A,
    output wire [18:0] C,
    input wire CI,
    input wire ADD
);

    wire XLXN_23;
    wire XLXN_24;
    wire XLXN_29;

    gnd XLXI_4 (.G(XLXN_24));
    adsu16 XLXI_5 (.A(A[15:0]), .ADD(ADD), .B(B[15:0]), .CI(CI), .CO(XLXN_23), .OFL(), .S(C[15:0]));
    adsu4 XLXI_6 (.A0(A[16]), .A1(A[17]), .A2(A[18]), .A3(XLXN_24), .ADD(ADD), .B0(B[16]), .B1(B[17]), .B2(B[18]), .B3(XLXN_24), .CI(XLXN_23), .CO(), .OFL(), .S0(C[16]), .S1(C[17]), .S2(C[18]), .S3());

endmodule
