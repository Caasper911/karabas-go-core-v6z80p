// generated from bitmapcore_603.sch
module bitmapcore_603 (
    input wire clk_fast,          // Karabas Go port: the registers written by the CPU / line copper run on the fast clock,
    input wire wr_pulse,          // enabled by one pulse at the start of each write (they were clocked by the write strobe)
    input wire [7:0] vram_databus,
    output wire [7:0] planar_pixel,
    input wire [7:0] cpu_databus,
    input wire [7:0] cpu_addr,
    input wire cpu_write,
    input wire regs_ab_select,
    input wire vreg_range,
    input wire stop_slb_writes,
    input wire start_linegen_in,
    input wire tilemap_mode_in,
    output wire bitmap_linedone_out,
    input wire clk16mhz_in,
    input wire new_scanline_in,
    input wire [2:0] no_of_planes,
    input wire chunky_mode,
    output wire bitmaplbwren_out,
    output wire bm_lbaddrinc_en,
    input wire vrt_in,
    output wire [18:0] vram_bmaddr_out,
    input wire enable_expand
);

    wire bitmapbusy;
    wire bitmapend;
    wire [17:0] bitmapoffset;
    wire [18:0] bitplane_base;
    wire [18:0] bm_addition;
    wire bm_srcaddr_inc_en;
    wire bmstartreq_in;
    wire bp_select_a;
    wire bp_select_b;
    wire bp_select_c;
    wire [7:0] bplanea;
    wire [7:0] bplaneb;
    wire [7:0] bplanec;
    wire [7:0] bplaned;
    wire [7:0] bplanee;
    wire [7:0] bplanef;
    wire [7:0] bplaneg;
    wire [7:0] bplaneh;
    wire expand_clocken;
    wire inv_cpu_wr;
    wire latch_bp0;
    wire latch_bp1;
    wire latch_bp2;
    wire latch_bp3;
    wire latch_bp4;
    wire latch_bp5;
    wire latch_bp6;
    wire latch_bp7;
    wire latching_phase;
    wire mod_ff;
    wire mod_inc_offset;
    wire [7:0] modulo_val;
    wire phase_zero;
    wire planar_lbaddrinc_en;
    wire reached_count;
    wire regwren;
    wire reset_count;
    wire reset_offset;
    wire sli_input;
    wire XLXN_1805;
    wire XLXN_1886;
    wire XLXN_2058;
    wire XLXN_2135;
    wire XLXN_2136;
    wire XLXN_2137;
    wire XLXN_2155;
    wire XLXN_2160;
    wire XLXN_2161;
    wire XLXN_2255;
    wire XLXN_2261;
    wire XLXN_2363;
    wire XLXN_2385;
    wire XLXN_2393;
    wire XLXN_2405;
    wire XLXN_2415;
    wire XLXN_2419;
    wire XLXN_2426;
    wire XLXN_2459;
    wire XLXN_2461;
    wire XLXN_2518;
    wire XLXN_2521;
    wire XLXN_2524;
    wire XLXN_2561;
    wire XLXN_2572;
    wire XLXN_2573;
    wire XLXN_2619;
    wire XLXN_2620;
    wire XLXN_2621;
    wire XLXN_2622;
    wire XLXN_2627;
    wire XLXN_2655;
    wire XLXN_2662;
    wire XLXN_2663;
    wire XLXN_2677;
    wire XLXN_2682;
    wire XLXN_2686;
    wire XLXN_2688;
    wire XLXN_2692;
    wire XLXN_2693;
    wire XLXN_2694;
    wire XLXN_41;
    wire XLXN_42;
    wire XLXN_45;
    wire XLXN_48;

    sr8cle XLXI_1 (.C(clk16mhz_in), .CE(planar_lbaddrinc_en), .CLR(new_scanline_in), .D(vram_databus[7:0]), .L(latch_bp0), .SLI(sli_input), .Q(bplanea[7:0]));
    sr8cle XLXI_2 (.C(clk16mhz_in), .CE(planar_lbaddrinc_en), .CLR(new_scanline_in), .D(vram_databus[7:0]), .L(latch_bp1), .SLI(sli_input), .Q(bplaneb[7:0]));
    sr8cle XLXI_3 (.C(clk16mhz_in), .CE(planar_lbaddrinc_en), .CLR(new_scanline_in), .D(vram_databus[7:0]), .L(latch_bp2), .SLI(sli_input), .Q(bplanec[7:0]));
    sr8cle XLXI_4 (.C(clk16mhz_in), .CE(planar_lbaddrinc_en), .CLR(new_scanline_in), .D(vram_databus[7:0]), .L(latch_bp3), .SLI(sli_input), .Q(bplaned[7:0]));
    sr8cle XLXI_5 (.C(clk16mhz_in), .CE(planar_lbaddrinc_en), .CLR(new_scanline_in), .D(vram_databus[7:0]), .L(latch_bp4), .SLI(sli_input), .Q(bplanee[7:0]));
    sr8cle XLXI_6 (.C(clk16mhz_in), .CE(planar_lbaddrinc_en), .CLR(new_scanline_in), .D(vram_databus[7:0]), .L(latch_bp5), .SLI(sli_input), .Q(bplanef[7:0]));
    sr8cle XLXI_7 (.C(clk16mhz_in), .CE(planar_lbaddrinc_en), .CLR(new_scanline_in), .D(vram_databus[7:0]), .L(latch_bp7), .SLI(sli_input), .Q(bplaneh[7:0]));
    sr8cle XLXI_8 (.C(clk16mhz_in), .CE(planar_lbaddrinc_en), .CLR(new_scanline_in), .D(vram_databus[7:0]), .L(latch_bp6), .SLI(sli_input), .Q(bplaneg[7:0]));
    buf_x XLXI_9 (.I(bplaneg[7]), .O(planar_pixel[6]));
    buf_x XLXI_10 (.I(bplanef[7]), .O(planar_pixel[5]));
    buf_x XLXI_11 (.I(bplanee[7]), .O(planar_pixel[4]));
    buf_x XLXI_12 (.I(bplaneh[7]), .O(planar_pixel[7]));
    buf_x XLXI_13 (.I(bplaneb[7]), .O(planar_pixel[1]));
    buf_x XLXI_14 (.I(bplanea[7]), .O(planar_pixel[0]));
    buf_x XLXI_15 (.I(bplanec[7]), .O(planar_pixel[2]));
    buf_x XLXI_16 (.I(bplaned[7]), .O(planar_pixel[3]));
    gnd XLXI_702 (.G(sli_input));
    and2 XLXI_711 (.I0(regwren), .I1(XLXN_48), .O(XLXN_45));
    nor2 XLXI_712 (.I0(cpu_addr[1]), .I1(cpu_addr[0]), .O(XLXN_48));
    inv XLXI_715 (.I(cpu_write), .O(inv_cpu_wr));
    ram16x8d XLXI_717 (.A0(cpu_addr[2]), .A1(cpu_addr[3]), .A2(cpu_addr[4]), .A3(cpu_addr[5]), .D(cpu_databus[7:0]), .DPRA0(bp_select_a), .DPRA1(bp_select_b), .DPRA2(bp_select_c), .DPRA3(regs_ab_select), .WCLK(clk_fast), .WE((XLXN_42) & wr_pulse), .DPO(bitplane_base[15:8]), .SPO());
    ram16x8d XLXI_718 (.A0(cpu_addr[2]), .A1(cpu_addr[3]), .A2(cpu_addr[4]), .A3(cpu_addr[5]), .D(cpu_databus[7:0]), .DPRA0(bp_select_a), .DPRA1(bp_select_b), .DPRA2(bp_select_c), .DPRA3(regs_ab_select), .WCLK(clk_fast), .WE((XLXN_45) & wr_pulse), .DPO(bitplane_base[7:0]), .SPO());
    and3b1 XLXI_734 (.I0(cpu_addr[1]), .I1(regwren), .I2(cpu_addr[0]), .O(XLXN_42));
    and3b1 XLXI_735 (.I0(cpu_addr[0]), .I1(regwren), .I2(cpu_addr[1]), .O(XLXN_41));
    and3b2 XLXI_749 (.I0(vreg_range), .I1(cpu_addr[7]), .I2(cpu_addr[6]), .O(regwren));
    fdrs XLXI_632 (.C(clk16mhz_in), .D(bitmapbusy), .R(bitmapend), .S(bmstartreq_in), .Q(bitmapbusy));
    and2b1 XLXI_703 (.I0(tilemap_mode_in), .I1(start_linegen_in), .O(bmstartreq_in));
    and3 XLXI_780 (.I0(bp_select_a), .I1(bp_select_b), .I2(bp_select_c), .O(XLXN_2155));
    fdre XLXI_781 (.C(clk16mhz_in), .CE(reached_count), .D(latching_phase), .R(new_scanline_in), .Q(planar_lbaddrinc_en));
    inv XLXI_782 (.I(planar_lbaddrinc_en), .O(latching_phase));
    and2 XLXI_21 (.I0(planar_lbaddrinc_en), .I1(XLXN_2155), .O(XLXN_2459));
    cb4re XLXI_786 (.C(clk16mhz_in), .CE(bitmapbusy), .R(XLXN_2255), .CEO(), .Q0(bp_select_a), .Q1(bp_select_b), .Q2(bp_select_c), .Q3(), .TC());
    xor2 XLXI_787 (.I0(no_of_planes[0]), .I1(bp_select_a), .O(XLXN_2135));
    xor2 XLXI_788 (.I0(no_of_planes[1]), .I1(bp_select_b), .O(XLXN_2136));
    xor2 XLXI_789 (.I0(no_of_planes[2]), .I1(bp_select_c), .O(XLXN_2137));
    nor3 XLXI_790 (.I0(XLXN_2137), .I1(XLXN_2136), .I2(XLXN_2135), .O(XLXN_2160));
    and2 XLXI_28 (.I0(XLXN_2160), .I1(bitmapbusy), .O(XLXN_2161));
    m2_1 XLXI_792 (.D0(XLXN_2161), .D1(XLXN_2155), .S0(planar_lbaddrinc_en), .O(reached_count));
    nor4 XLXI_830 (.I0(bp_select_a), .I1(bp_select_b), .I2(bp_select_c), .I3(planar_lbaddrinc_en), .O(phase_zero));
    or3 XLXI_836 (.I0(chunky_mode), .I1(new_scanline_in), .I2(reached_count), .O(XLXN_2255));
    or2 XLXI_838 (.I0(chunky_mode), .I1(phase_zero), .O(XLXN_2693));
    d3_8e XLXI_622 (.A0(bp_select_a), .A1(bp_select_b), .A2(bp_select_c), .E(latching_phase), .D0(latch_bp0), .D1(latch_bp1), .D2(latch_bp2), .D3(latch_bp3), .D4(latch_bp4), .D5(latch_bp5), .D6(latch_bp6), .D7(latch_bp7));
    or2 XLXI_682 (.I0(bitmapend), .I1(new_scanline_in), .O(XLXN_1886));
    ftrse XLXI_656 (.C(clk16mhz_in), .CE(XLXN_1805), .R(XLXN_1886), .S(XLXN_2363), .T(reached_count), .Q(bitmaplbwren_out));
    vcc XLXI_658 (.P(XLXN_1805));
    and2 XLXI_852 (.I0(bitmapbusy), .I1(chunky_mode), .O(XLXN_2363));
    fdce XLXI_747 (.C(clk_fast), .CE((reset_count) & wr_pulse), .CLR(XLXN_2524), .D(XLXN_2058), .Q(XLXN_2518));
    vcc XLXI_748 (.P(XLXN_2058));
    m2_1 XLXI_851 (.D0(planar_lbaddrinc_en), .D1(bitmaplbwren_out), .S0(chunky_mode), .O(bm_lbaddrinc_en));
    fd XLXI_856 (.C(clk16mhz_in), .D(bitmapbusy), .Q(XLXN_2385));
    and2b1 XLXI_857 (.I0(bitmapbusy), .I1(XLXN_2385), .O(bitmap_linedone_out));
    ram16x3d XLXI_858 (.A0(cpu_addr[2]), .A1(cpu_addr[3]), .A2(cpu_addr[4]), .A3(cpu_addr[5]), .D(cpu_databus[2:0]), .DPO(bitplane_base[18:16]), .DPRA0(bp_select_a), .DPRA1(bp_select_b), .DPRA2(bp_select_c), .DPRA3(regs_ab_select), .SPO(), .WCLK(clk_fast), .WE((XLXN_41) & wr_pulse));
    and2 XLXI_867 (.I0(new_scanline_in), .I1(XLXN_2524), .O(XLXN_2521));
    or3 XLXI_889 (.I0(mod_inc_offset), .I1(XLXN_2461), .I2(XLXN_2459), .O(bm_srcaddr_inc_en));
    fdrs XLXI_903 (.C(clk16mhz_in), .D(XLXN_2524), .R(new_scanline_in), .S(XLXN_2518), .Q(XLXN_2524));
    fd8re XLXI_868 (.C(clk_fast), .CE((XLXN_2405) & wr_pulse), .D(cpu_databus[7:0]), .R(XLXN_2573), .Q(modulo_val[7:0]));
    cb8cled XLXI_869 (.C(clk16mhz_in), .CE(XLXN_2419), .CLR(XLXN_2573), .D(modulo_val[7:0]), .L(XLXN_2572), .UP(XLXN_2573), .CEO(), .Q(), .TC(XLXN_2426));
    fdre XLXI_872 (.C(clk16mhz_in), .CE(mod_inc_offset), .D(XLXN_2415), .R(XLXN_2573), .Q(XLXN_2419));
    inv XLXI_877 (.I(XLXN_2419), .O(XLXN_2415));
    and4b1 XLXI_892 (.I0(cpu_addr[2]), .I1(regwren), .I2(cpu_addr[1]), .I3(cpu_addr[0]), .O(reset_count));
    and4 XLXI_893 (.I0(cpu_addr[2]), .I1(regwren), .I2(cpu_addr[1]), .I3(cpu_addr[0]), .O(XLXN_2405));
    gnd XLXI_870 (.G(XLXN_2573));
    and8 XLXI_912 (.I0(modulo_val[7]), .I1(modulo_val[6]), .I2(modulo_val[5]), .I3(modulo_val[4]), .I4(modulo_val[3]), .I5(modulo_val[2]), .I6(modulo_val[1]), .I7(modulo_val[0]), .O(mod_ff));
    and2 XLXI_914 (.I0(new_scanline_in), .I1(mod_ff), .O(XLXN_2561));
    or3 XLXI_915 (.I0(XLXN_2521), .I1(XLXN_2561), .I2(vrt_in), .O(reset_offset));
    and2b2 XLXI_918 (.I0(bitmapbusy), .I1(XLXN_2426), .O(mod_inc_offset));
    and2b1 XLXI_917 (.I0(mod_ff), .I1(start_linegen_in), .O(XLXN_2572));
    cb16re XLXI_730 (.C(clk16mhz_in), .CE(bm_srcaddr_inc_en), .R(reset_offset), .CEO(XLXN_2261), .Q(bitmapoffset[15:0]), .TC());
    cb2re XLXI_890 (.C(clk16mhz_in), .CE(XLXN_2261), .R(reset_offset), .CEO(), .Q0(bitmapoffset[16]), .Q1(bitmapoffset[17]), .TC());
    add19 XLXI_859 (.A(bitplane_base[18:0]), .B(bm_addition[18:0]), .CI(XLXN_2393), .C(vram_bmaddr_out[18:0]));
    gnd XLXI_721 (.G(XLXN_2393));
    gnd XLXI_861 (.G(bm_addition[18]));
    buf_x XLXI_894 [17:0] (.I(bitmapoffset[17:0]), .O(bm_addition[17:0]));
    xor2 XLXI_945 (.I0(XLXN_2620), .I1(no_of_planes[1]), .O(XLXN_2622));
    xor2 XLXI_944 (.I0(XLXN_2619), .I1(no_of_planes[0]), .O(XLXN_2621));
    cb4re XLXI_956 (.C(clk16mhz_in), .CE(XLXN_2627), .R(XLXN_2655), .CEO(), .Q0(XLXN_2619), .Q1(XLXN_2620), .Q2(XLXN_2662), .Q3(), .TC());
    vcc XLXI_948 (.P(XLXN_2627));
    xor2 XLXI_959 (.I0(XLXN_2662), .I1(no_of_planes[2]), .O(XLXN_2663));
    nor3 XLXI_961 (.I0(XLXN_2663), .I1(XLXN_2622), .I2(XLXN_2621), .O(XLXN_2677));
    or2b1 XLXI_965 (.I0(enable_expand), .I1(XLXN_2677), .O(expand_clocken));
    or2 XLXI_968 (.I0(XLXN_2688), .I1(expand_clocken), .O(XLXN_2655));
    inv XLXI_971 (.I(bitmaplbwren_out), .O(XLXN_2688));
    and2b1 XLXI_972 (.I0(bitmapoffset[0]), .I1(stop_slb_writes), .O(XLXN_2692));
    and2 XLXI_973 (.I0(XLXN_2692), .I1(XLXN_2693), .O(bitmapend));
    and4b1 XLXI_976 (.I0(bitmapend), .I1(expand_clocken), .I2(bitmaplbwren_out), .I3(chunky_mode), .O(XLXN_2461));

endmodule
