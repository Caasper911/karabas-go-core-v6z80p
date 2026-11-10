// generated from ud_counter_883.sch
module ud_counter_883 (
    input wire [7:0] set_low,
    input wire [7:0] set_hi,
    input wire async_clr,
    output wire [18:0] addr_out,
    input wire clk_enable,
    input wire latch_low,
    input wire latch_hi,
    input wire up_or_down,
    input wire clock_source,
    input wire latch_msbs,
    input wire [2:0] set_msbs
);

    wire XLXN_4;
    wire XLXN_40;
    wire XLXN_61;

    cb8cled XLXI_5 (.C(clock_source), .CE(clk_enable), .CLR(async_clr), .D(set_low[7:0]), .L(latch_low), .UP(up_or_down), .CEO(XLXN_4), .Q(addr_out[7:0]), .TC());
    cb8cled XLXI_6 (.C(clock_source), .CE(XLXN_4), .CLR(async_clr), .D(set_hi[7:0]), .L(latch_hi), .UP(up_or_down), .CEO(XLXN_40), .Q(addr_out[15:8]), .TC());
    gnd XLXI_10 (.G(XLXN_61));
    cb4cled XLXI_11 (.C(clock_source), .CE(XLXN_40), .CLR(async_clr), .D0(set_msbs[0]), .D1(set_msbs[1]), .D2(set_msbs[2]), .D3(XLXN_61), .L(latch_msbs), .UP(up_or_down), .CEO(), .Q0(addr_out[16]), .Q1(addr_out[17]), .Q2(addr_out[18]), .Q3(), .TC());

endmodule
