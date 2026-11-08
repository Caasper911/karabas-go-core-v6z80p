// generated from RAM_dual_8in16outx16.sch
module ram_dual_8in16outx16 (
    input wire write_clock,
    input wire [3:0] write_addr,
    input wire msb_wr_en,
    input wire lsb_wr_en,
    input wire [7:0] data_in,
    output wire [15:0] data_out,
    input wire [3:0] read_addr
);

    wire [7:0] hidata;
    wire [7:0] lodata;
    wire XLXN_10;
    wire XLXN_11;
    wire XLXN_12;
    wire XLXN_13;

    ram16x8d XLXI_5 (.A0(write_addr[0]), .A1(write_addr[1]), .A2(write_addr[2]), .A3(write_addr[3]), .D(data_in[7:0]), .DPRA0(read_addr[0]), .DPRA1(read_addr[1]), .DPRA2(read_addr[2]), .DPRA3(read_addr[3]), .WCLK(write_clock), .WE(msb_wr_en), .DPO(hidata[7:0]), .SPO());
    buf_x XLXI_3 [7:0] (.I(hidata[7:0]), .O(data_out[15:8]));
    buf_x XLXI_4 [7:0] (.I(lodata[7:0]), .O(data_out[7:0]));
    ram16x8d XLXI_8 (.A0(write_addr[0]), .A1(write_addr[1]), .A2(write_addr[2]), .A3(write_addr[3]), .D(data_in[7:0]), .DPRA0(read_addr[0]), .DPRA1(read_addr[1]), .DPRA2(read_addr[2]), .DPRA3(read_addr[3]), .WCLK(write_clock), .WE(lsb_wr_en), .DPO(lodata[7:0]), .SPO());

endmodule
