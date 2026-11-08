// generated from bufe19.sch
module bufe19 (
    input wire enable_hi,
    input wire [18:0] in_bus,
    output wire [18:0] out_bus
);

    wire [15:0] out_bus_tb0;
    wire out_bus_tb1;
    wire out_bus_tb2;
    wire out_bus_tb3;

    bufe16 XLXI_5 (.E(enable_hi), .I(in_bus[18:3]), .O(out_bus_tb0[15:0]));
    bufe XLXI_6 (.E(enable_hi), .I(in_bus[2]), .O(out_bus_tb1));
    bufe XLXI_7 (.E(enable_hi), .I(in_bus[1]), .O(out_bus_tb2));
    bufe XLXI_8 (.E(enable_hi), .I(in_bus[0]), .O(out_bus_tb3));
    assign out_bus[0] = out_bus_tb3;
    assign out_bus[1] = out_bus_tb2;
    assign out_bus[2] = out_bus_tb1;
    assign out_bus[3] = out_bus_tb0[0];
    assign out_bus[4] = out_bus_tb0[1];
    assign out_bus[5] = out_bus_tb0[2];
    assign out_bus[6] = out_bus_tb0[3];
    assign out_bus[7] = out_bus_tb0[4];
    assign out_bus[8] = out_bus_tb0[5];
    assign out_bus[9] = out_bus_tb0[6];
    assign out_bus[10] = out_bus_tb0[7];
    assign out_bus[11] = out_bus_tb0[8];
    assign out_bus[12] = out_bus_tb0[9];
    assign out_bus[13] = out_bus_tb0[10];
    assign out_bus[14] = out_bus_tb0[11];
    assign out_bus[15] = out_bus_tb0[12];
    assign out_bus[16] = out_bus_tb0[13];
    assign out_bus[17] = out_bus_tb0[14];
    assign out_bus[18] = out_bus_tb0[15];

endmodule
