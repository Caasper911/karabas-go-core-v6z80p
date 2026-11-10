// generated from spi_sch5.sch
module spi_sch5 (
    input wire [7:0] byte_to_write,
    input wire cpu_wr,
    output wire busy,
    output wire spi_out,
    output wire [7:0] byte_received,
    input wire spi_input,
    input wire port_selected,
    input wire speed_select,
    output wire spi_clock,
    input wire clock_16mhz
);

    wire [7:0] slow_clock;
    wire [7:0] spi_data;
    wire XLXN_167;
    wire XLXN_169;
    wire XLXN_274;
    wire XLXN_276;
    wire XLXN_277;
    wire XLXN_329;
    wire XLXN_339;
    wire XLXN_343;
    wire XLXN_398;
    wire XLXN_401;
    wire XLXN_403;
    wire XLXN_78;
    wire XLXN_79;
    wire XLXN_85;
    wire XLXN_86;
    wire XLXN_87;
    wire XLXN_96;
    wire XLXN_99;

    m8_1e XLXI_16 (.D0(spi_data[7]), .D1(spi_data[6]), .D2(spi_data[5]), .D3(spi_data[4]), .D4(spi_data[3]), .D5(spi_data[2]), .D6(spi_data[1]), .D7(spi_data[0]), .E(XLXN_79), .S0(XLXN_85), .S1(XLXN_86), .S2(XLXN_87), .O(XLXN_99));
    vcc XLXI_28 (.P(XLXN_79));
    or2b1 XLXI_31 (.I0(busy), .I1(XLXN_99), .O(spi_out));
    fdce XLXI_63 (.C(cpu_wr), .CE(port_selected), .CLR(XLXN_96), .D(XLXN_169), .Q(busy));
    cb8re XLXI_92 (.C(clock_16mhz), .CE(XLXN_169), .R(XLXN_398), .CEO(), .Q(slow_clock[7:0]), .TC());
    fd XLXI_30 (.C(clock_16mhz), .D(XLXN_329), .Q(XLXN_96));
    and5 XLXI_98 (.I0(slow_clock[4]), .I1(slow_clock[3]), .I2(slow_clock[2]), .I3(slow_clock[1]), .I4(slow_clock[0]), .O(XLXN_277));
    inv XLXI_100 (.I(busy), .O(XLXN_398));
    vcc XLXI_64 (.P(XLXN_169));
    fd XLXI_29 (.C(clock_16mhz), .D(busy), .Q(XLXN_274));
    fd8re XLXI_15 (.C(cpu_wr), .CE(port_selected), .D(byte_to_write[7:0]), .R(XLXN_78), .Q(spi_data[7:0]));
    gnd XLXI_27 (.G(XLXN_78));
    sr8re XLXI_60 (.C(clock_16mhz), .CE(XLXN_339), .R(XLXN_167), .SLI(spi_input), .Q(byte_received[7:0]));
    cb4re XLXI_11 (.C(clock_16mhz), .CE(XLXN_343), .R(XLXN_96), .CEO(XLXN_329), .Q0(spi_clock), .Q1(XLXN_85), .Q2(XLXN_86), .Q3(XLXN_87), .TC());
    or2 XLXI_99 (.I0(XLXN_277), .I1(speed_select), .O(XLXN_276));
    and2 XLXI_97 (.I0(XLXN_276), .I1(XLXN_274), .O(XLXN_343));
    gnd XLXI_62 (.G(XLXN_167));
    inv XLXI_105 (.I(spi_clock), .O(XLXN_401));
    and3 XLXI_106 (.I0(busy), .I1(XLXN_401), .I2(XLXN_343), .O(XLXN_339));

endmodule
