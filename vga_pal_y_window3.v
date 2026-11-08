// generated from vga_pal_y_window3.sch
module vga_pal_y_window3 (
    output wire ywindow_out,
    input wire clock_in,
    input wire [8:3] line_count,
    input wire scanline_tc_in,
    input wire [3:0] start_coarse,
    input wire [3:0] stop_coarse,
    input wire vrtline
);

    wire set_match;
    wire XLXN_599;
    wire XLXN_620;
    wire XLXN_686;
    wire XLXN_687;
    wire XLXN_688;
    wire XLXN_689;
    wire XLXN_695;
    wire XLXN_696;
    wire XLXN_707;
    wire XLXN_711;
    wire XLXN_713;
    wire XLXN_715;
    wire XLXN_717;
    wire XLXN_718;
    wire XLXN_719;
    wire XLXN_720;
    wire XLXN_721;
    wire XLXN_723;

    comp4 XLXI_200 (.A0(XLXN_686), .A1(XLXN_687), .A2(XLXN_688), .A3(XLXN_689), .B0(line_count[3]), .B1(line_count[4]), .B2(line_count[5]), .B3(line_count[6]), .EQ(XLXN_599));
    fdrs XLXI_210 (.C(clock_in), .D(ywindow_out), .R(XLXN_715), .S(set_match), .Q(ywindow_out));
    and4b2 XLXI_213 (.I0(line_count[8]), .I1(line_count[7]), .I2(XLXN_620), .I3(scanline_tc_in), .O(set_match));
    comp4 XLXI_179 (.A0(start_coarse[0]), .A1(start_coarse[1]), .A2(start_coarse[2]), .A3(start_coarse[3]), .B0(line_count[3]), .B1(line_count[4]), .B2(line_count[5]), .B3(line_count[6]), .EQ(XLXN_620));
    add4 XLXI_216 (.A0(stop_coarse[0]), .A1(stop_coarse[1]), .A2(stop_coarse[2]), .A3(stop_coarse[3]), .B0(XLXN_695), .B1(XLXN_695), .B2(XLXN_696), .B3(XLXN_695), .CI(XLXN_695), .CO(XLXN_707), .OFL(), .S0(XLXN_686), .S1(XLXN_687), .S2(XLXN_688), .S3(XLXN_689));
    gnd XLXI_217 (.G(XLXN_695));
    vcc XLXI_218 (.P(XLXN_696));
    m2_1 XLXI_223 (.D0(line_count[7]), .D1(line_count[8]), .S0(XLXN_707), .O(XLXN_711));
    and3 XLXI_224 (.I0(XLXN_711), .I1(XLXN_599), .I2(scanline_tc_in), .O(XLXN_713));
    or2 XLXI_225 (.I0(vrtline), .I1(XLXN_713), .O(XLXN_715));

endmodule
