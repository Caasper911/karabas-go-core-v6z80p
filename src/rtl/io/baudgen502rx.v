// generated from baudgen502rx.sch
module baudgen502rx (
    input wire baud_a,
    input wire baud_b,
    input wire main_clock,
    input wire reset_bcount,
    output wire midpulse
);

    wire [7:0] baudcount;
    wire div2;
    wire div4;
    wire div8;
    wire XLXN_134;
    wire XLXN_136;
    wire XLXN_41;
    wire XLXN_42;
    wire XLXN_43;
    wire XLXN_44;
    wire XLXN_55;
    wire XLXN_56;
    wire XLXN_79;
    wire XLXN_80;
    wire XLXN_93;

    gnd XLXI_93 (.G(XLXN_43));
    gnd XLXI_94 (.G(XLXN_44));
    gnd XLXI_92 (.G(XLXN_42));
    vcc XLXI_96 (.P(XLXN_56));
    vcc XLXI_95 (.P(XLXN_55));
    m4_1e XLXI_60 (.D0(XLXN_41), .D1(div2), .D2(div4), .D3(div8), .E(XLXN_41), .S0(baud_a), .S1(baud_b), .O(XLXN_93));
    cb8re XLXI_16 (.C(main_clock), .CE(XLXN_93), .R(XLXN_80), .CEO(), .Q(baudcount[7:0]), .TC());
    or2 XLXI_103 (.I0(XLXN_79), .I1(reset_bcount), .O(XLXN_80));
    srl16 #(.INIT(16'h0001)) XLXI_104 (.A0(XLXN_41), .A1(XLXN_42), .A2(XLXN_42), .A3(XLXN_42), .CLK(main_clock), .D(div2), .Q(div2));
    srl16 #(.INIT(16'h0001)) XLXI_105 (.A0(XLXN_55), .A1(XLXN_55), .A2(XLXN_43), .A3(XLXN_43), .CLK(main_clock), .D(div4), .Q(div4));
    srl16 #(.INIT(16'h0001)) XLXI_106 (.A0(XLXN_56), .A1(XLXN_56), .A2(XLXN_56), .A3(XLXN_44), .CLK(main_clock), .D(div8), .Q(div8));
    vcc XLXI_97 (.P(XLXN_41));
    and3 XLXI_101 (.I0(baudcount[7]), .I1(baudcount[3]), .I2(baudcount[1]), .O(XLXN_79));
    and2 XLXI_108 (.I0(baudcount[6]), .I1(baudcount[2]), .O(XLXN_134));
    fdrs XLXI_129 (.C(main_clock), .D(XLXN_136), .R(XLXN_80), .S(XLXN_134), .Q(XLXN_136));
    and2b1 XLXI_130 (.I0(XLXN_136), .I1(XLXN_134), .O(midpulse));

endmodule
