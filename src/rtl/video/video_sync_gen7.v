// generated from video_sync_gen7.sch
module video_sync_gen7 (
    input wire clock_in,
    output wire full_scanline_tc,
    output wire vga_hsync,
    output wire last16cycles,
    output wire vga_scanline_a_tc,
    input wire mode_VGA,
    output wire [8:0] adjusted_linecount,
    output wire rgb_enable,
    output wire vga_vsync_pal_csync,
    output wire last_line,
    output wire long_frame,
    input wire interlace_in,
    input wire Force_VGA_to_50Hz
);

    wire and1fb;
    wire clocks_per_line_1016;
    wire [15:0] horizontal_count;
    wire interlace;
    wire last_line_internal;
    wire last_line_unsyncd;
    wire last_pal_line;
    wire lc_lsbs7;
    wire line_261;
    wire [8:0] line_count;
    wire line_zero;
    wire longframe_left_synctype;
    wire longframe_right_synctype;
    wire pal_longframe;
    wire pal_RGB_enable;
    wire pal_sync;
    wire pal_sync_long;
    wire pal_sync_normal;
    wire pal_sync_short;
    wire pal_vrt_zone;
    wire shortframe_left_synctype;
    wire shortframe_right_synctype;
    wire VGA_50Hz;
    wire VGA_60Hz;
    wire vga_vsync;
    wire vga_xwindow_max;
    wire vga_ywindow_max;
    wire XLXN_1039;
    wire XLXN_1051;
    wire XLXN_1066;
    wire XLXN_1067;
    wire XLXN_1068;
    wire XLXN_1073;
    wire XLXN_1377;
    wire XLXN_1380;
    wire XLXN_2463;
    wire XLXN_2466;
    wire XLXN_2488;
    wire XLXN_2493;
    wire XLXN_2647;
    wire XLXN_2648;
    wire XLXN_2698;
    wire XLXN_2706;
    wire XLXN_2718;
    wire XLXN_2719;
    wire XLXN_2727;
    wire XLXN_2728;
    wire XLXN_2731;
    wire XLXN_2764;
    wire XLXN_2801;
    wire XLXN_2805;
    wire XLXN_2812;
    wire XLXN_2815;
    wire XLXN_2816;
    wire XLXN_2838;
    wire XLXN_2839;
    wire XLXN_2840;
    wire XLXN_2843;
    wire XLXN_2844;
    wire XLXN_2845;
    wire XLXN_2846;
    wire XLXN_2848;
    wire XLXN_331;
    wire XLXN_334;
    wire XLXN_335;
    wire XLXN_336;
    wire XLXN_340;
    wire XLXN_341;
    wire XLXN_345;
    wire XLXN_347;
    wire XLXN_350;
    wire XLXN_4;
    wire XLXN_564;
    wire XLXN_571;
    wire XLXN_592;
    wire XLXN_702;
    wire XLXN_758;
    wire XLXN_791;
    wire XLXN_830;
    wire XLXN_837;
    wire XLXN_917;
    wire XLXN_919;
    wire XLXN_927;
    wire XLXN_936;
    wire XLXN_986;

    and8 XLXI_5 (.I0(horizontal_count[8]), .I1(horizontal_count[7]), .I2(horizontal_count[6]), .I3(horizontal_count[5]), .I4(horizontal_count[4]), .I5(horizontal_count[2]), .I6(horizontal_count[1]), .I7(horizontal_count[0]), .O(XLXN_331));
    vcc XLXI_6 (.P(XLXN_4));
    cc16re XLXI_4 (.C(clock_in), .CE(XLXN_4), .R(full_scanline_tc), .CEO(), .Q(horizontal_count[15:0]), .TC());
    and2 XLXI_161 (.I0(horizontal_count[9]), .I1(XLXN_331), .O(XLXN_345));
    rom32x1 #(.INIT(32'hfffe0003)) XLXI_163 (.A0(horizontal_count[2]), .A1(horizontal_count[3]), .A2(horizontal_count[4]), .A3(horizontal_count[5]), .A4(horizontal_count[6]), .O(XLXN_334));
    rom32x1 #(.INIT(32'hffff0001)) XLXI_164 (.A0(horizontal_count[2]), .A1(horizontal_count[3]), .A2(horizontal_count[4]), .A3(horizontal_count[5]), .A4(horizontal_count[6]), .O(XLXN_335));
    or2 XLXI_165 (.I0(horizontal_count[8]), .I1(horizontal_count[7]), .O(XLXN_336));
    or3 XLXI_166 (.I0(horizontal_count[9]), .I1(XLXN_336), .I2(XLXN_334), .O(XLXN_340));
    or3b1 XLXI_168 (.I0(horizontal_count[9]), .I1(XLXN_336), .I2(XLXN_335), .O(XLXN_341));
    and2 XLXI_169 (.I0(XLXN_341), .I1(XLXN_340), .O(XLXN_927));
    and2 XLXI_173 (.I0(XLXN_345), .I1(horizontal_count[3]), .O(XLXN_350));
    and2 XLXI_174 (.I0(clocks_per_line_1016), .I1(XLXN_345), .O(XLXN_347));
    or2 XLXI_172 (.I0(XLXN_347), .I1(XLXN_350), .O(full_scanline_tc));
    fdrs XLXI_258 (.C(clock_in), .D(vga_xwindow_max), .R(XLXN_791), .S(XLXN_592), .Q(vga_xwindow_max));
    or2 XLXI_311 (.I0(and1fb), .I1(full_scanline_tc), .O(XLXN_791));
    and8 XLXI_312 (.I0(horizontal_count[8]), .I1(horizontal_count[7]), .I2(horizontal_count[6]), .I3(horizontal_count[5]), .I4(horizontal_count[4]), .I5(horizontal_count[3]), .I6(horizontal_count[1]), .I7(horizontal_count[0]), .O(and1fb));
    and3b1 XLXI_254 (.I0(line_count[8]), .I1(full_scanline_tc), .I2(line_count[4]), .O(XLXN_571));
    or2 XLXI_319 (.I0(XLXN_830), .I1(XLXN_837), .O(XLXN_592));
    and6 XLXI_320 (.I0(horizontal_count[9]), .I1(horizontal_count[6]), .I2(horizontal_count[4]), .I3(horizontal_count[3]), .I4(horizontal_count[2]), .I5(horizontal_count[0]), .O(XLXN_830));
    and4b1 XLXI_324 (.I0(horizontal_count[8]), .I1(horizontal_count[6]), .I2(horizontal_count[5]), .I3(horizontal_count[0]), .O(XLXN_837));
    fdrs XLXI_265 (.C(clock_in), .D(pal_RGB_enable), .R(XLXN_702), .S(XLXN_919), .Q(pal_RGB_enable));
    or2 XLXI_276 (.I0(pal_vrt_zone), .I1(XLXN_1068), .O(XLXN_702));
    and4b1 XLXI_343 (.I0(horizontal_count[9]), .I1(horizontal_count[6]), .I2(horizontal_count[7]), .I3(XLXN_917), .O(XLXN_919));
    fdrs XLXI_344 (.C(clock_in), .D(XLXN_917), .R(last_pal_line), .S(line_count[4]), .Q(XLXN_917));
    inv XLXI_347 (.I(mode_VGA), .O(XLXN_2845));
    and9 XLXI_358 (.I0(horizontal_count[8]), .I1(horizontal_count[7]), .I2(horizontal_count[6]), .I3(horizontal_count[5]), .I4(horizontal_count[4]), .I5(horizontal_count[3]), .I6(XLXN_986), .I7(horizontal_count[1]), .I8(horizontal_count[0]), .O(XLXN_1073));
    inv XLXI_359 (.I(horizontal_count[2]), .O(XLXN_986));
    inv XLXI_250 (.I(last_line_unsyncd), .O(XLXN_564));
    fde XLXI_248 (.C(clock_in), .CE(full_scanline_tc), .D(XLXN_564), .Q(vga_vsync));
    and2 XLXI_301 (.I0(last_line_unsyncd), .I1(full_scanline_tc), .O(last_line_internal));
    cb8re XLXI_365 (.C(clock_in), .CE(full_scanline_tc), .R(last_line_internal), .CEO(XLXN_1039), .Q(line_count[7:0]), .TC());
    cb2re XLXI_380 (.C(clock_in), .CE(XLXN_1039), .R(last_line_internal), .CEO(), .Q0(line_count[8]), .Q1(), .TC());
    and5 XLXI_381 (.I0(horizontal_count[5]), .I1(horizontal_count[6]), .I2(horizontal_count[7]), .I3(horizontal_count[8]), .I4(horizontal_count[9]), .O(XLXN_1051));
    and2 XLXI_382 (.I0(horizontal_count[4]), .I1(XLXN_1051), .O(XLXN_1068));
    fdrs XLXI_385 (.C(clock_in), .D(last16cycles), .R(full_scanline_tc), .S(XLXN_1067), .Q(last16cycles));
    or2 XLXI_386 (.I0(XLXN_1066), .I1(XLXN_1068), .O(XLXN_1067));
    and3 XLXI_384 (.I0(clocks_per_line_1016), .I1(horizontal_count[3]), .I2(XLXN_1051), .O(XLXN_1066));
    and2 XLXI_388 (.I0(mode_VGA), .I1(XLXN_1073), .O(vga_scanline_a_tc));
    cb8re XLXI_483 (.C(clock_in), .CE(full_scanline_tc), .R(XLXN_1380), .CEO(XLXN_1377), .Q(adjusted_linecount[7:0]), .TC());
    cb2re XLXI_484 (.C(clock_in), .CE(XLXN_1377), .R(XLXN_1380), .CEO(), .Q0(adjusted_linecount[8]), .Q1(), .TC());
    m2_1 XLXI_292 (.D0(pal_sync), .D1(vga_vsync), .S0(mode_VGA), .O(XLXN_936));
    m2_1 XLXI_293 (.D0(pal_RGB_enable), .D1(XLXN_758), .S0(mode_VGA), .O(rgb_enable));
    and2 XLXI_294 (.I0(vga_xwindow_max), .I1(vga_ywindow_max), .O(XLXN_758));
    fd XLXI_348 (.C(clock_in), .D(XLXN_936), .Q(vga_vsync_pal_csync));
    and2 XLXI_837 (.I0(VGA_60Hz), .I1(line_261), .O(XLXN_2805));
    and3 XLXI_838 (.I0(line_count[0]), .I1(line_count[2]), .I2(line_count[8]), .O(line_261));
    m2_1 XLXI_927 (.D0(shortframe_left_synctype), .D1(shortframe_right_synctype), .S0(horizontal_count[9]), .O(XLXN_2647));
    m2_1 XLXI_928 (.D0(longframe_left_synctype), .D1(longframe_right_synctype), .S0(horizontal_count[9]), .O(XLXN_2648));
    m2_1 XLXI_929 (.D0(XLXN_2647), .D1(XLXN_2648), .S0(pal_longframe), .O(XLXN_2727));
    m2_1 XLXI_936 (.D0(pal_sync_normal), .D1(XLXN_2728), .S0(XLXN_2698), .O(XLXN_2718));
    rom16x1 #(.INIT(16'h0018)) XLXI_202 (.A0(line_count[0]), .A1(line_count[1]), .A2(line_count[2]), .A3(line_count[3]), .O(shortframe_left_synctype));
    rom16x1 #(.INIT(16'h1c)) XLXI_506 (.A0(line_count[0]), .A1(line_count[1]), .A2(line_count[2]), .A3(line_count[3]), .O(shortframe_right_synctype));
    rom16x1 #(.INIT(16'h0038)) XLXI_845 (.A0(line_count[0]), .A1(line_count[1]), .A2(line_count[2]), .A3(line_count[3]), .O(longframe_left_synctype));
    rom16x1 #(.INIT(16'h0018)) XLXI_938 (.A0(line_count[0]), .A1(line_count[1]), .A2(line_count[2]), .A3(line_count[3]), .O(longframe_right_synctype));
    nor4 XLXI_944 (.I0(line_count[3]), .I1(line_count[2]), .I2(line_count[1]), .I3(line_count[0]), .O(line_zero));
    and2b1 XLXI_948 (.I0(XLXN_2706), .I1(pal_vrt_zone), .O(XLXN_2698));
    and3b1 XLXI_951 (.I0(horizontal_count[9]), .I1(line_zero), .I2(pal_longframe), .O(XLXN_2706));
    or2 XLXI_955 (.I0(XLXN_2719), .I1(XLXN_2718), .O(pal_sync));
    m2_1 XLXI_957 (.D0(pal_sync_short), .D1(pal_sync_long), .S0(XLXN_2727), .O(XLXN_2728));
    rom16x1 #(.INIT(16'hfffe)) XLXI_195 (.A0(horizontal_count[5]), .A1(horizontal_count[6]), .A2(horizontal_count[7]), .A3(horizontal_count[8]), .O(pal_sync_short));
    rom16x1 #(.INIT(16'hfffe)) XLXI_198 (.A0(horizontal_count[6]), .A1(horizontal_count[7]), .A2(horizontal_count[8]), .A3(horizontal_count[9]), .O(pal_sync_normal));
    rom16x1 #(.INIT(16'h8000)) XLXI_196 (.A0(horizontal_count[5]), .A1(horizontal_count[6]), .A2(horizontal_count[7]), .A3(horizontal_count[8]), .O(pal_sync_long));
    and5b1 XLXI_969 (.I0(pal_longframe), .I1(line_count[2]), .I2(line_count[1]), .I3(line_count[0]), .I4(horizontal_count[9]), .O(XLXN_2719));
    and2 XLXI_850 (.I0(full_scanline_tc), .I1(last_pal_line), .O(XLXN_2488));
    fdrs XLXI_849 (.C(clock_in), .D(pal_vrt_zone), .R(XLXN_2493), .S(XLXN_2488), .Q(pal_vrt_zone));
    inv XLXI_859 (.I(interlace), .O(XLXN_2466));
    inv XLXI_858 (.I(pal_longframe), .O(XLXN_2463));
    fdre XLXI_866 (.C(clock_in), .CE(XLXN_2488), .D(XLXN_2463), .R(XLXN_2466), .Q(pal_longframe));
    and3 XLXI_974 (.I0(line_count[2]), .I1(line_count[1]), .I2(line_count[0]), .O(lc_lsbs7));
    and2b1 XLXI_977 (.I0(pal_longframe), .I1(lc_lsbs7), .O(XLXN_2764));
    or2 XLXI_982 (.I0(line_count[3]), .I1(XLXN_2764), .O(XLXN_2731));
    and4 XLXI_983 (.I0(line_count[8]), .I1(line_count[5]), .I2(line_count[4]), .I3(XLXN_2731), .O(last_pal_line));
    and3b1 XLXI_994 (.I0(line_count[8]), .I1(lc_lsbs7), .I2(full_scanline_tc), .O(XLXN_2493));
    rom32x1 #(.INIT(32'h001FFFFF)) XLXI_995 (.A0(line_count[0]), .A1(line_count[1]), .A2(line_count[2]), .A3(line_count[3]), .A4(line_count[4]), .O(XLXN_2838));
    nor4 XLXI_997 (.I0(line_count[8]), .I1(line_count[7]), .I2(line_count[6]), .I3(line_count[5]), .O(XLXN_2801));
    rom32x1 #(.INIT(32'h00003fff)) XLXI_998 (.A0(line_count[0]), .A1(line_count[1]), .A2(line_count[2]), .A3(line_count[3]), .A4(line_count[4]), .O(XLXN_2839));
    rom32x1 #(.INIT(32'h00000001)) XLXI_999 (.A0(line_count[0]), .A1(line_count[1]), .A2(line_count[2]), .A3(line_count[3]), .A4(line_count[4]), .O(XLXN_2840));
    m4_1e XLXI_1002 (.D0(XLXN_2838), .D1(XLXN_2838), .D2(XLXN_2840), .D3(XLXN_2839), .E(XLXN_2801), .S0(VGA_50Hz), .S1(mode_VGA), .O(XLXN_1380));
    fd XLXI_1003 (.C(clock_in), .D(last_line_unsyncd), .Q(last_line));
    or2 XLXI_1004 (.I0(last_pal_line), .I1(XLXN_2805), .O(last_line_unsyncd));
    buf_x XLXI_1005 (.I(pal_longframe), .O(long_frame));
    buf_x XLXI_1006 (.I(mode_VGA), .O(clocks_per_line_1016));
    or2 XLXI_1008 (.I0(XLXN_2816), .I1(XLXN_2815), .O(XLXN_2812));
    fdrs XLXI_251 (.C(clock_in), .D(vga_ywindow_max), .R(XLXN_2812), .S(XLXN_571), .Q(vga_ywindow_max));
    and3 XLXI_1007 (.I0(VGA_60Hz), .I1(full_scanline_tc), .I2(line_count[8]), .O(XLXN_2815));
    and2 XLXI_1011 (.I0(last_pal_line), .I1(full_scanline_tc), .O(XLXN_2816));
    and2b1 XLXI_836 (.I0(mode_VGA), .I1(interlace_in), .O(interlace));
    and2 XLXI_1015 (.I0(Force_VGA_to_50Hz), .I1(mode_VGA), .O(VGA_50Hz));
    and2b1 XLXI_1018 (.I0(Force_VGA_to_50Hz), .I1(mode_VGA), .O(VGA_60Hz));
    fds XLXI_1019 (.C(clock_in), .D(XLXN_927), .S(XLXN_2845), .Q(vga_hsync));

endmodule
