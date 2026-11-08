// generated from serial_508.sch
module serial_508 (
    input wire clock_16mhz,
    input wire serial_port_selected,
    output wire rec_byte_rdy,
    output wire [7:0] byte_out,
    input wire rx_input,
    input wire baudrate_a,
    input wire baudrate_b,
    input wire cpu_read,
    input wire delayed_wr,
    output wire sending_frame,
    output wire tx_output,
    input wire [7:0] cpu_databus_in
);

    wire beyond_start_bit;
    wire clr_serial_rdy;
    wire count_eq_9;
    wire [7:0] data_out;
    wire frame_in;
    wire midpoint;
    wire [7:0] parallel_data;
    wire XLXN_112;
    wire XLXN_284;
    wire XLXN_285;
    wire XLXN_286;
    wire XLXN_290;
    wire XLXN_365;
    wire XLXN_384;
    wire XLXN_386;
    wire XLXN_387;
    wire XLXN_393;
    wire XLXN_398;
    wire XLXN_407;
    wire XLXN_426;
    wire XLXN_480;
    wire XLXN_483;
    wire XLXN_484;
    wire XLXN_496;
    wire XLXN_499;
    wire XLXN_505;
    wire XLXN_540;
    wire XLXN_546;
    wire XLXN_61;
    wire XLXN_642;
    wire [7:0] XLXN_71;
    wire XLXN_72;

    buf_x XLXI_18 [7:0] (.I({data_out[0], data_out[1], data_out[2], data_out[3], data_out[4], data_out[5], data_out[6], data_out[7]}), .O(XLXN_71[7:0]));
    sr8re XLXI_14 (.C(clock_16mhz), .CE(XLXN_496), .R(XLXN_61), .SLI(rx_input), .Q(data_out[7:0]));
    fdce XLXI_33 (.C(clock_16mhz), .CE(XLXN_499), .CLR(clr_serial_rdy), .D(XLXN_112), .Q(rec_byte_rdy));
    fd8re XLXI_26 (.C(clock_16mhz), .CE(XLXN_499), .D(XLXN_71[7:0]), .R(XLXN_72), .Q(byte_out[7:0]));
    vcc XLXI_34 (.P(XLXN_112));
    fd XLXI_187 (.C(clock_16mhz), .D(midpoint), .Q(XLXN_480));
    cb4re XLXI_188 (.C(clock_16mhz), .CE(XLXN_480), .R(XLXN_540), .CEO(), .Q0(XLXN_484), .Q1(), .Q2(), .Q3(XLXN_483), .TC());
    and2 XLXI_189 (.I0(XLXN_484), .I1(XLXN_483), .O(count_eq_9));
    and2b1 XLXI_190 (.I0(count_eq_9), .I1(midpoint), .O(XLXN_496));
    gnd XLXI_19 (.G(XLXN_61));
    gnd XLXI_28 (.G(XLXN_72));
    and2 XLXI_191 (.I0(count_eq_9), .I1(midpoint), .O(XLXN_499));
    fdrs XLXI_192 (.C(clock_16mhz), .D(frame_in), .R(XLXN_499), .S(XLXN_505), .Q(frame_in));
    inv XLXI_195 (.I(rx_input), .O(XLXN_505));
    inv XLXI_196 (.I(frame_in), .O(XLXN_546));
    and2 XLXI_197 (.I0(count_eq_9), .I1(XLXN_480), .O(XLXN_540));
    and2b1 XLXI_167 (.I0(cpu_read), .I1(serial_port_selected), .O(clr_serial_rdy));
    fdc XLXI_161 (.C(delayed_wr), .CLR(sending_frame), .D(serial_port_selected), .Q(XLXN_398));
    baudgen501tx XLXI_200 (.baudrate_pulse(XLXN_387), .baud_a(baudrate_a), .baud_b(baudrate_b), .mainclock(clock_16mhz), .reset_bc(XLXN_642));
    inv XLXI_165 (.I(sending_frame), .O(XLXN_642));
    and2 XLXI_168 (.I0(XLXN_426), .I1(XLXN_387), .O(XLXN_386));
    fd XLXI_153 (.C(clock_16mhz), .D(XLXN_384), .Q(tx_output));
    or3b1 XLXI_158 (.I0(sending_frame), .I1(XLXN_365), .I2(XLXN_426), .O(XLXN_384));
    and2 XLXI_166 (.I0(XLXN_387), .I1(beyond_start_bit), .O(XLXN_407));
    and2 XLXI_163 (.I0(sending_frame), .I1(XLXN_387), .O(XLXN_393));
    fdrs XLXI_162 (.C(clock_16mhz), .D(beyond_start_bit), .R(XLXN_642), .S(XLXN_393), .Q(beyond_start_bit));
    fdrs XLXI_155 (.C(clock_16mhz), .D(sending_frame), .R(XLXN_386), .S(XLXN_398), .Q(sending_frame));
    gnd XLXI_114 (.G(XLXN_290));
    cb4re XLXI_113 (.C(clock_16mhz), .CE(XLXN_407), .R(XLXN_642), .CEO(), .Q0(XLXN_284), .Q1(XLXN_285), .Q2(XLXN_286), .Q3(XLXN_426), .TC());
    m8_1e XLXI_112 (.D0(parallel_data[0]), .D1(parallel_data[1]), .D2(parallel_data[2]), .D3(parallel_data[3]), .D4(parallel_data[4]), .D5(parallel_data[5]), .D6(parallel_data[6]), .D7(parallel_data[7]), .E(beyond_start_bit), .S0(XLXN_284), .S1(XLXN_285), .S2(XLXN_286), .O(XLXN_365));
    fd8re XLXI_111 (.C(delayed_wr), .CE(serial_port_selected), .D(cpu_databus_in[7:0]), .R(XLXN_290), .Q(parallel_data[7:0]));
    baudgen502rx XLXI_217 (.baud_a(baudrate_a), .baud_b(baudrate_b), .main_clock(clock_16mhz), .midpulse(midpoint), .reset_bcount(XLXN_546));

endmodule
