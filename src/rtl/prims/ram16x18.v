// generated from RAM16x18.sch
module ram16x18 (
    output wire [17:0] data_out,
    input wire write_enable,
    input wire write_clock,
    input wire [17:0] data_in,
    input wire [3:0] address
);

    wire [7:0] hidata;
    wire [7:0] lodata;
    wire XLXN_1;
    wire [3:0] XLXN_10;
    wire XLXN_2;
    wire XLXN_3;
    wire XLXN_4;
    wire XLXN_5;
    wire XLXN_8;

    ram16x8s XLXI_1 (.A0(address[3]), .A1(address[2]), .A2(address[1]), .A3(address[0]), .D(data_in[15:8]), .WCLK(write_clock), .WE(write_enable), .O(hidata[7:0]));
    ram16x8s XLXI_2 (.A0(address[3]), .A1(address[2]), .A2(address[1]), .A3(address[0]), .D(data_in[7:0]), .WCLK(write_clock), .WE(write_enable), .O(lodata[7:0]));
    buf_x XLXI_3 [7:0] (.I(hidata[7:0]), .O(data_out[15:8]));
    buf_x XLXI_4 [7:0] (.I(lodata[7:0]), .O(data_out[7:0]));
    ram16x2s XLXI_5 (.A0(address[3]), .A1(address[2]), .A2(address[1]), .A3(address[0]), .D0(data_in[16]), .D1(data_in[17]), .WCLK(write_clock), .WE(write_enable), .O0(data_out[16]), .O1(data_out[17]));

endmodule
