// generated from RAM16X3D.sch
module ram16x3d (
    input wire WCLK,
    input wire A0,
    input wire A1,
    input wire A2,
    input wire A3,
    input wire DPRA0,
    input wire DPRA1,
    input wire DPRA3,
    input wire DPRA2,
    input wire [2:0] D,
    input wire WE,
    output wire [2:0] SPO,
    output wire [2:0] DPO
);


    ram16x1d XLXI_1 (.A0(A0), .A1(A1), .A2(A2), .A3(A3), .D(D[0]), .DPRA0(DPRA0), .DPRA1(DPRA1), .DPRA2(DPRA2), .DPRA3(DPRA3), .WCLK(WCLK), .WE(WE), .DPO(DPO[0]), .SPO(SPO[0]));
    ram16x1d XLXI_2 (.A0(A0), .A1(A1), .A2(A2), .A3(A3), .D(D[1]), .DPRA0(DPRA0), .DPRA1(DPRA1), .DPRA2(DPRA2), .DPRA3(DPRA3), .WCLK(WCLK), .WE(WE), .DPO(DPO[1]), .SPO(SPO[1]));
    ram16x1d XLXI_3 (.A0(A0), .A1(A1), .A2(A2), .A3(A3), .D(D[2]), .DPRA0(DPRA0), .DPRA1(DPRA1), .DPRA2(DPRA2), .DPRA3(DPRA3), .WCLK(WCLK), .WE(WE), .DPO(DPO[2]), .SPO(SPO[2]));

endmodule
