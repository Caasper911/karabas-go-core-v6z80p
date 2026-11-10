// generated from serjoy2.sch
module serjoy2 (
    input wire PIC_joy_data_in,
    output wire bit_a_out,
    output wire bit_d_out,
    output wire bit_b_out,
    output wire bit_e_out,
    output wire bit_f_out,
    output wire bit_c_out,
    input wire joy_sel_rd,
    input wire slow_clock,
    output wire PIC_clk_out
);

    wire bita;
    wire bitb;
    wire bitc;
    wire bitd;
    wire bite;
    wire bitf;
    wire blahblah;
    wire joy_sel_wr;
    wire XLXN_102;
    wire XLXN_114;
    wire XLXN_116;
    wire XLXN_21;
    wire XLXN_22;
    wire XLXN_24;
    wire XLXN_34;
    wire XLXN_35;
    wire XLXN_36;
    wire XLXN_82;
    wire XLXN_83;
    wire XLXN_84;
    wire XLXN_87;
    wire XLXN_88;

    ram16x1d XLXI_1 (.A0(joy_sel_wr), .A1(XLXN_34), .A2(XLXN_34), .A3(XLXN_34), .D(PIC_joy_data_in), .DPRA0(joy_sel_rd), .DPRA1(XLXN_34), .DPRA2(XLXN_34), .DPRA3(XLXN_34), .WCLK(slow_clock), .WE(bitd), .DPO(bit_d_out), .SPO());
    ram16x1d XLXI_2 (.A0(joy_sel_wr), .A1(XLXN_21), .A2(XLXN_21), .A3(XLXN_21), .D(PIC_joy_data_in), .DPRA0(joy_sel_rd), .DPRA1(XLXN_21), .DPRA2(XLXN_21), .DPRA3(XLXN_21), .WCLK(slow_clock), .WE(bita), .DPO(bit_a_out), .SPO());
    ram16x1d XLXI_3 (.A0(joy_sel_wr), .A1(XLXN_22), .A2(XLXN_22), .A3(XLXN_22), .D(PIC_joy_data_in), .DPRA0(joy_sel_rd), .DPRA1(XLXN_22), .DPRA2(XLXN_22), .DPRA3(XLXN_22), .WCLK(slow_clock), .WE(bitb), .DPO(bit_b_out), .SPO());
    ram16x1d XLXI_4 (.A0(joy_sel_wr), .A1(XLXN_35), .A2(XLXN_35), .A3(XLXN_35), .D(PIC_joy_data_in), .DPRA0(joy_sel_rd), .DPRA1(XLXN_35), .DPRA2(XLXN_35), .DPRA3(XLXN_35), .WCLK(slow_clock), .WE(bite), .DPO(bit_e_out), .SPO());
    ram16x1d XLXI_5 (.A0(joy_sel_wr), .A1(XLXN_24), .A2(XLXN_24), .A3(XLXN_24), .D(PIC_joy_data_in), .DPRA0(joy_sel_rd), .DPRA1(XLXN_24), .DPRA2(XLXN_24), .DPRA3(XLXN_24), .WCLK(slow_clock), .WE(bitc), .DPO(bit_c_out), .SPO());
    ram16x1d XLXI_6 (.A0(joy_sel_wr), .A1(XLXN_36), .A2(XLXN_36), .A3(XLXN_36), .D(PIC_joy_data_in), .DPRA0(joy_sel_rd), .DPRA1(XLXN_36), .DPRA2(XLXN_36), .DPRA3(XLXN_36), .WCLK(slow_clock), .WE(bitf), .DPO(bit_f_out), .SPO());
    gnd XLXI_7 (.G(XLXN_21));
    gnd XLXI_8 (.G(XLXN_34));
    gnd XLXI_9 (.G(XLXN_35));
    gnd XLXI_10 (.G(XLXN_36));
    gnd XLXI_11 (.G(XLXN_24));
    gnd XLXI_12 (.G(XLXN_22));
    d3_8e XLXI_13 (.A0(XLXN_82), .A1(XLXN_83), .A2(XLXN_84), .E(XLXN_114), .D0(), .D1(), .D2(bita), .D3(bitb), .D4(bitc), .D5(bitd), .D6(bite), .D7(bitf));
    cb4ce XLXI_14 (.C(XLXN_116), .CE(XLXN_87), .CLR(XLXN_88), .CEO(XLXN_102), .Q0(XLXN_82), .Q1(XLXN_83), .Q2(XLXN_84), .Q3(joy_sel_wr), .TC());
    gnd XLXI_15 (.G(XLXN_88));
    vcc XLXI_16 (.P(XLXN_87));
    cb4ce XLXI_20 (.C(XLXN_116), .CE(XLXN_102), .CLR(XLXN_88), .CEO(), .Q0(XLXN_114), .Q1(), .Q2(), .Q3(), .TC());
    fd XLXI_23 (.C(XLXN_116), .D(XLXN_114), .Q(blahblah));
    and2 XLXI_24 (.I0(slow_clock), .I1(blahblah), .O(PIC_clk_out));
    inv XLXI_25 (.I(slow_clock), .O(XLXN_116));

endmodule
