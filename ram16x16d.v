// generated from ram16x16d.sch
module ram16x16d (
    input wire write_en,
    input wire wr_clk,
    input wire wr_addr1,
    input wire wr_addr0,
    input wire wr_addr2,
    input wire wr_addr3,
    input wire rd_addr0,
    input wire rd_addr1,
    input wire rd_addr2,
    input wire rd_addr3,
    output wire [15:0] data_out,
    input wire [15:0] data_in
);

    wire XLXN_1;
    wire XLXN_10;
    wire XLXN_12;
    wire XLXN_15;
    wire XLXN_16;
    wire XLXN_17;
    wire XLXN_18;
    wire [7:0] XLXN_4;
    wire XLXN_43;
    wire XLXN_5;
    wire XLXN_7;
    wire XLXN_9;

    ram16x8d XLXI_1 (.A0(wr_addr0), .A1(wr_addr1), .A2(wr_addr2), .A3(wr_addr3), .D(data_in[7:0]), .DPRA0(rd_addr0), .DPRA1(rd_addr1), .DPRA2(rd_addr2), .DPRA3(rd_addr3), .WCLK(wr_clk), .WE(write_en), .DPO(data_out[7:0]), .SPO());
    ram16x8d XLXI_2 (.A0(wr_addr0), .A1(wr_addr1), .A2(wr_addr2), .A3(wr_addr3), .D(data_in[15:8]), .DPRA0(rd_addr0), .DPRA1(rd_addr1), .DPRA2(rd_addr2), .DPRA3(rd_addr3), .WCLK(wr_clk), .WE(write_en), .DPO(data_out[15:8]), .SPO());

endmodule
