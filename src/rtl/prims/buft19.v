// generated from buft19.sch
module buft19 (
    input wire enable_lo,
    input wire [18:0] in_bus,
    output wire [18:0] out_bus
);

    wire out_bus_tb0;
    wire [15:0] out_bus_tb1;
    wire out_bus_tb2;
    wire out_bus_tb3;
    wire XLXN_1;
    wire XLXN_2;
    wire XLXN_7;

    buft XLXI_1 (.I(in_bus[2]), .T(enable_lo), .O(out_bus_tb0));
    buft16 XLXI_2 (.I(in_bus[18:3]), .T(enable_lo), .O(out_bus_tb1[15:0]));
    buft XLXI_3 (.I(in_bus[1]), .T(enable_lo), .O(out_bus_tb2));
    buft XLXI_4 (.I(in_bus[0]), .T(enable_lo), .O(out_bus_tb3));
    assign out_bus[0] = out_bus_tb3;
    assign out_bus[1] = out_bus_tb2;
    assign out_bus[2] = out_bus_tb0;
    assign out_bus[3] = out_bus_tb1[0];
    assign out_bus[4] = out_bus_tb1[1];
    assign out_bus[5] = out_bus_tb1[2];
    assign out_bus[6] = out_bus_tb1[3];
    assign out_bus[7] = out_bus_tb1[4];
    assign out_bus[8] = out_bus_tb1[5];
    assign out_bus[9] = out_bus_tb1[6];
    assign out_bus[10] = out_bus_tb1[7];
    assign out_bus[11] = out_bus_tb1[8];
    assign out_bus[12] = out_bus_tb1[9];
    assign out_bus[13] = out_bus_tb1[10];
    assign out_bus[14] = out_bus_tb1[11];
    assign out_bus[15] = out_bus_tb1[12];
    assign out_bus[16] = out_bus_tb1[13];
    assign out_bus[17] = out_bus_tb1[14];
    assign out_bus[18] = out_bus_tb1[15];

endmodule
