// generated from baudgen501tx.sch
module baudgen501tx (
    input wire mainclock,
    output wire baudrate_pulse,
    input wire reset_bc,
    input wire baud_a,
    input wire baud_b
);

    wire [7:0] bgen;
    wire div2;
    wire div4;
    wire div8;
    wire XLXN_108;
    wire XLXN_109;
    wire XLXN_121;
    wire XLXN_122;
    wire XLXN_123;
    wire XLXN_125;
    wire XLXN_14;
    wire XLXN_151;
    wire XLXN_160;

    or2 XLXI_50 (.I0(baudrate_pulse), .I1(reset_bc), .O(XLXN_14));
    gnd XLXI_92 (.G(XLXN_109));
    gnd XLXI_93 (.G(XLXN_121));
    gnd XLXI_94 (.G(XLXN_122));
    vcc XLXI_95 (.P(XLXN_123));
    vcc XLXI_96 (.P(XLXN_125));
    vcc XLXI_97 (.P(XLXN_108));
    m4_1e XLXI_60 (.D0(XLXN_151), .D1(div2), .D2(div4), .D3(div8), .E(XLXN_151), .S0(baud_a), .S1(baud_b), .O(XLXN_160));
    vcc XLXI_106 (.P(XLXN_151));
    cb8re XLXI_16 (.C(mainclock), .CE(XLXN_160), .R(XLXN_14), .CEO(), .Q(bgen[7:0]), .TC());
    and3 XLXI_59 (.I0(bgen[7]), .I1(bgen[3]), .I2(bgen[1]), .O(baudrate_pulse));
    srl16 #(.INIT(16'h0001)) XLXI_107 (.A0(XLXN_108), .A1(XLXN_109), .A2(XLXN_109), .A3(XLXN_109), .CLK(mainclock), .D(div2), .Q(div2));
    srl16 #(.INIT(16'h0001)) XLXI_108 (.A0(XLXN_123), .A1(XLXN_123), .A2(XLXN_121), .A3(XLXN_121), .CLK(mainclock), .D(div4), .Q(div4));
    srl16 #(.INIT(16'h0001)) XLXI_109 (.A0(XLXN_125), .A1(XLXN_125), .A2(XLXN_125), .A3(XLXN_122), .CLK(mainclock), .D(div8), .Q(div8));

endmodule
