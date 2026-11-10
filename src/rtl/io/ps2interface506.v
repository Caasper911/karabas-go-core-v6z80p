// generated from ps2interface506.sch
module ps2interface506 (
    input wire sys_clk,
    input wire main_divider_tc,
    input wire ps2_clk,
    output wire irq_out,
    input wire irq_clr,
    input wire manual_clock,
    input wire ps2_data,
    output wire [7:0] data_out
);

    wire bitpos_reset;
    wire [7:0] databyte;
    wire exit_frame;
    wire in_frame;
    wire one_cycle_pre_cfd;
    wire ps2_clk_fall_detect;
    wire XLXN_1;
    wire XLXN_166;
    wire XLXN_180;
    wire XLXN_217;
    wire XLXN_238;
    wire XLXN_241;
    wire XLXN_244;
    wire XLXN_260;
    wire XLXN_268;
    wire XLXN_273;
    wire XLXN_280;
    wire XLXN_30;
    wire XLXN_311;
    wire XLXN_313;
    wire XLXN_319;
    wire XLXN_4;

    cb4re XLXI_26 (.C(sys_clk), .CE(XLXN_268), .R(XLXN_180), .CEO(), .Q0(XLXN_280), .Q1(), .Q2(), .Q3(XLXN_273), .TC());
    and3 XLXI_55 (.I0(XLXN_273), .I1(XLXN_280), .I2(ps2_clk_fall_detect), .O(exit_frame));
    srl16 #(.INIT(16'h8000)) XLXI_2 (.A0(XLXN_4), .A1(XLXN_4), .A2(XLXN_4), .A3(XLXN_4), .CLK(sys_clk), .D(XLXN_1), .Q(XLXN_1));
    cb4re XLXI_3 (.C(sys_clk), .CE(ps2_clk), .R(XLXN_1), .CEO(), .Q0(), .Q1(), .Q2(), .Q3(XLXN_238), .TC());
    cb4re XLXI_60 (.C(sys_clk), .CE(XLXN_166), .R(one_cycle_pre_cfd), .CEO(), .Q0(), .Q1(), .Q2(), .Q3(), .TC(bitpos_reset));
    and2b1 XLXI_62 (.I0(bitpos_reset), .I1(main_divider_tc), .O(XLXN_166));
    srl16 #(.INIT(16'h0001)) XLXI_108 (.A0(XLXN_4), .A1(XLXN_4), .A2(XLXN_4), .A3(XLXN_4), .CLK(sys_clk), .D(XLXN_217), .Q(XLXN_217));
    vcc XLXI_59 (.P(XLXN_4));
    fde XLXI_111 (.C(sys_clk), .CE(XLXN_217), .D(XLXN_238), .Q(XLXN_241));
    and2b1 XLXI_116 (.I0(XLXN_241), .I1(XLXN_244), .O(one_cycle_pre_cfd));
    fd XLXI_118 (.C(sys_clk), .D(XLXN_241), .Q(XLXN_244));
    fd XLXI_119 (.C(sys_clk), .D(one_cycle_pre_cfd), .Q(ps2_clk_fall_detect));
    and2 XLXI_122 (.I0(ps2_clk_fall_detect), .I1(in_frame), .O(XLXN_268));
    fdrs XLXI_120 (.C(sys_clk), .D(in_frame), .R(exit_frame), .S(XLXN_313), .Q(in_frame));
    fdrs #(.INIT(1'b1)) XLXI_135 (.C(sys_clk), .D(XLXN_311), .R(manual_clock), .S(exit_frame), .Q(XLXN_311));
    fdce XLXI_56 (.C(sys_clk), .CE(exit_frame), .CLR(irq_clr), .D(XLXN_311), .Q(irq_out));
    or3b1 XLXI_137 (.I0(in_frame), .I1(bitpos_reset), .I2(manual_clock), .O(XLXN_180));
    and2b1 XLXI_138 (.I0(manual_clock), .I1(ps2_clk_fall_detect), .O(XLXN_313));
    sr8ce XLXI_1 (.C(sys_clk), .CE(XLXN_260), .CLR(XLXN_30), .SLI(ps2_data), .Q(databyte[7:0]));
    gnd XLXI_11 (.G(XLXN_30));
    buf_x XLXI_15 [7:0] (.I({databyte[0], databyte[1], databyte[2], databyte[3], databyte[4], databyte[5], databyte[6], databyte[7]}), .O(data_out[7:0]));
    and3b1 XLXI_124 (.I0(XLXN_273), .I1(in_frame), .I2(ps2_clk_fall_detect), .O(XLXN_260));

endmodule
