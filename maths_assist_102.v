// generated from maths_assist_102.sch
module maths_assist_102 (
    input wire reg_wr_clock,
    output wire [15:0] scaled,
    input wire latch_blockram,
    input wire [8:0] address,
    input wire [7:0] data_in,
    input wire sys_clock,
    input wire math_reg_range,
    input wire port_2a_sel,
    input wire port_29_sel,
    input wire port_28_sel
);

    wire [15:0] blkramout;
    wire latch_hi;
    wire latch_lo;
    wire [15:0] mulb;
    wire set_index;
    wire XLXN_21;
    wire XLXN_23;
    wire XLXN_25;
    wire XLXN_70;
    wire [7:0] XLXN_71;
    wire [15:0] XLXN_72;
    wire XLXN_89;
    wire XLXN_91;
    wire XLXN_92;

    fd8re XLXI_3 (.C(reg_wr_clock), .CE(XLXN_91), .D(data_in[7:0]), .R(XLXN_70), .Q(mulb[15:8]));
    gnd XLXI_9 (.G(XLXN_70));
    fd8re XLXI_4 (.C(reg_wr_clock), .CE(XLXN_92), .D(data_in[7:0]), .R(XLXN_70), .Q(mulb[7:0]));
    signed_scale XLXI_1 (.multiplier(blkramout[15:0]), .multiplicand(mulb[15:0]), .product(scaled[15:0]));
    vcc XLXI_11 (.P(XLXN_23));
    ramb4_s8_s16 XLXI_12 (.ADDRA(address[8:0]), .ADDRB(XLXN_71[7:0]), .CLKA(reg_wr_clock), .CLKB(sys_clock), .DIA(data_in[7:0]), .DIB(XLXN_72[15:0]), .ENA(latch_blockram), .ENB(XLXN_23), .RSTA(XLXN_25), .RSTB(XLXN_25), .WEA(XLXN_23), .WEB(XLXN_25), .DOA(), .DOB(blkramout[15:0]));
    fd8re XLXI_26 (.C(reg_wr_clock), .CE(XLXN_89), .D(data_in[7:0]), .R(XLXN_70), .Q(XLXN_71[7:0]));
    gnd XLXI_31 [15:0] (.G(XLXN_72[15:0]));
    gnd XLXI_13 (.G(XLXN_25));
    d2_4e XLXI_43 (.A0(address[0]), .A1(address[1]), .E(math_reg_range), .D0(latch_lo), .D1(latch_hi), .D2(set_index), .D3());
    or2 XLXI_44 (.I0(port_2a_sel), .I1(set_index), .O(XLXN_89));
    or2 XLXI_45 (.I0(port_29_sel), .I1(latch_hi), .O(XLXN_91));
    or2 XLXI_46 (.I0(port_28_sel), .I1(latch_lo), .O(XLXN_92));

endmodule
