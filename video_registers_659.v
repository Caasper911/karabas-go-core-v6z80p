// generated from video_registers_659.sch
module video_registers_659 (
    input wire clk_fast,          // Karabas Go port: the registers written by the CPU / line copper run on the fast clock,
    input wire wr_pulse,          // enabled by one pulse at the start of each write (they were clocked by the write strobe)
    output wire [3:0] dbg_ce,        // bring-up: write enables {y_window, xhws, vidctrl, rasthigh/window switch}
    input wire [7:0] cpu_databus,
    output wire tilemodeen_out,
    output wire cpu_sel_spr_ctrl,
    input wire new_scanline_in,
    output wire allow_virq,
    output wire [7:0] y_window_position,
    output wire [3:0] xstartcoarse_out,
    input wire main_clock_in,
    output wire rasterirq_status_out,
    input wire [7:0] cpu_addr_in,
    input wire vidreg_range_in,
    output wire dualpfen_out,
    output wire [3:0] xstopcoarse_out,
    output wire pfabufbmbufsel_out,
    output wire live_palette,
    input wire cpu_wr_line,
    output wire [3:0] xhws_out,
    input wire playfield1req_in,
    output wire pfablockbanksel_out,
    output wire pfbblockbanksel_out,
    output wire pfbbufsel_out,
    output wire wideborder_out,
    output wire global_video_enable,
    output wire [5:0] cpuaccvideopage_out,
    output wire [4:0] cpu_sprite_base_addr,
    output wire [3:0] yhwsavalue,
    output wire [3:0] yhwsbvalue,
    input wire [8:0] linecount_in,
    output wire latchayhws_out,
    output wire latchbyhws_out,
    output wire tile_extend,
    output wire [18:0] linecop_addr,
    output wire tile_pri_swap,
    output wire interlace,
    output wire hi_res,
    output wire palette_wr_sel
);

    wire [7:0] bothpfxhws;
    wire cpu_sel_linecopreg_hi;
    wire cpu_sel_linecopreg_lo;
    wire cpu_sel_more_pfsettings;
    wire cpu_sel_palette_ctrl;
    wire cpu_sel_rasthigh;
    wire cpu_sel_rastlow;
    wire cpu_sel_vidctrl;
    wire cpu_sel_vidpage;
    wire cpu_sel_windowreg;
    wire cpu_sel_xhws;
    wire cpu_sel_yhws;
    wire inv_cpu_wr_line;
    wire live_palette_unsyncd;
    wire playfield1req;
    wire setyhwsa;
    wire setyhwsb;
    wire [7:0] split_line_low;
    wire [7:0] spritepage;
    wire [7:0] vidpage;
    wire [7:0] vidreg_b;
    wire virq_raster_msb;
    wire [7:0] vreg_vidctrl;
    wire window_xyreg_switch;
    wire XLXN_1216;
    wire XLXN_1965;
    wire XLXN_2182;
    wire XLXN_2202;
    wire XLXN_2268;
    wire XLXN_2317;
    wire XLXN_2468;
    wire XLXN_2469;
    wire XLXN_2570;
    wire XLXN_2590;
    wire XLXN_2643;
    wire XLXN_2644;
    wire XLXN_2650;
    wire XLXN_2714;
    wire XLXN_2715;
    wire XLXN_2728;
    wire XLXN_3004;
    wire XLXN_3005;
    wire XLXN_3007;
    wire XLXN_3010;
    wire XLXN_3015;
    wire XLXN_3023;
    wire XLXN_3024;
    wire XLXN_3058;
    wire XLXN_3093;
    wire XLXN_3116;
    wire XLXN_3146;

    fd8re XLXI_762 (.C(clk_fast), .CE((XLXN_2182) & wr_pulse), .D(cpu_databus[7:0]), .R(XLXN_2268), .Q(y_window_position[7:0]));
    buf_x XLXI_680 [3:0] (.I(vidreg_b[7:4]), .O(xstartcoarse_out[3:0]));
    fd8re XLXI_154 (.C(clk_fast), .CE((XLXN_2202) & wr_pulse), .D(cpu_databus[7:0]), .R(XLXN_2268), .Q(vidreg_b[7:0]));
    and2b1 XLXI_774 (.I0(window_xyreg_switch), .I1(cpu_sel_windowreg), .O(XLXN_2182));
    and2 XLXI_775 (.I0(cpu_sel_windowreg), .I1(window_xyreg_switch), .O(XLXN_2202));
    gnd XLXI_766 (.G(XLXN_2268));
    and2b1 XLXI_803 (.I0(cpu_databus[7]), .I1(cpu_sel_rasthigh), .O(XLXN_2317));
    d4_16e XLXI_851 (.A0(cpu_addr_in[0]), .A1(cpu_addr_in[1]), .A2(cpu_addr_in[2]), .A3(cpu_addr_in[3]), .E(XLXN_2468), .D0(cpu_sel_xhws), .D1(cpu_sel_vidctrl), .D10(), .D11(), .D12(cpu_sel_more_pfsettings), .D13(cpu_sel_linecopreg_lo), .D14(cpu_sel_linecopreg_hi), .D15(cpu_sel_palette_ctrl), .D2(cpu_sel_windowreg), .D3(cpu_sel_yhws), .D4(cpu_sel_rasthigh), .D5(cpu_sel_rastlow), .D6(cpu_sel_vidpage), .D7(cpu_sel_spr_ctrl), .D8(), .D9());
    and2b2 XLXI_854 (.I0(vidreg_range_in), .I1(XLXN_2469), .O(XLXN_2468));
    or4 XLXI_853 (.I0(cpu_addr_in[7]), .I1(cpu_addr_in[6]), .I2(cpu_addr_in[5]), .I3(cpu_addr_in[4]), .O(XLXN_2469));
    fde XLXI_868 (.C(clk_fast), .CE((XLXN_2317) & wr_pulse), .D(cpu_databus[0]), .Q(virq_raster_msb));
    fde XLXI_869 (.C(clk_fast), .CE((XLXN_2317) & wr_pulse), .D(cpu_databus[1]), .Q(allow_virq));
    fde XLXI_870 (.C(clk_fast), .CE((XLXN_2317) & wr_pulse), .D(cpu_databus[2]), .Q(window_xyreg_switch));
    fde XLXI_871 (.C(main_clock_in), .CE(new_scanline_in), .D(vreg_vidctrl[0]), .Q(tilemodeen_out));
    fde XLXI_872 (.C(main_clock_in), .CE(new_scanline_in), .D(vreg_vidctrl[7]), .Q(dualpfen_out));
    fd4re XLXI_873 (.C(main_clock_in), .CE(new_scanline_in), .D0(vidreg_b[0]), .D1(vidreg_b[1]), .D2(vidreg_b[2]), .D3(vidreg_b[3]), .R(XLXN_2570), .Q0(xstopcoarse_out[0]), .Q1(xstopcoarse_out[1]), .Q2(xstopcoarse_out[2]), .Q3(xstopcoarse_out[3]));
    gnd XLXI_877 (.G(XLXN_2570));
    fde XLXI_921 (.C(main_clock_in), .CE(new_scanline_in), .D(vreg_vidctrl[5]), .Q(pfabufbmbufsel_out));
    fde XLXI_927 (.C(main_clock_in), .CE(new_scanline_in), .D(live_palette_unsyncd), .Q(live_palette));
    fd8re XLXI_146 (.C(clk_fast), .CE((cpu_sel_xhws) & wr_pulse), .D(cpu_databus[7:0]), .R(XLXN_2650), .Q(bothpfxhws[7:0]));
    inv XLXI_750 (.I(cpu_wr_line), .O(inv_cpu_wr_line));
    m2_1 XLXI_147 (.D0(bothpfxhws[0]), .D1(bothpfxhws[4]), .S0(playfield1req), .O(xhws_out[0]));
    m2_1 XLXI_148 (.D0(bothpfxhws[1]), .D1(bothpfxhws[5]), .S0(playfield1req), .O(xhws_out[1]));
    m2_1 XLXI_149 (.D0(bothpfxhws[2]), .D1(bothpfxhws[6]), .S0(playfield1req), .O(xhws_out[2]));
    m2_1 XLXI_150 (.D0(bothpfxhws[3]), .D1(bothpfxhws[7]), .S0(playfield1req), .O(xhws_out[3]));
    and2 XLXI_736 (.I0(tilemodeen_out), .I1(playfield1req_in), .O(playfield1req));
    fd8re XLXI_205 (.C(clk_fast), .CE((cpu_sel_vidctrl) & wr_pulse), .D(cpu_databus[7:0]), .R(XLXN_2650), .Q(vreg_vidctrl[7:0]));
    buf_x XLXI_672 (.I(vreg_vidctrl[3]), .O(pfablockbanksel_out));
    buf_x XLXI_673 (.I(vreg_vidctrl[4]), .O(pfbblockbanksel_out));
    buf_x XLXI_675 (.I(vreg_vidctrl[6]), .O(pfbbufsel_out));
    buf_x XLXI_733 (.I(vreg_vidctrl[1]), .O(wideborder_out));
    inv XLXI_802 (.I(vreg_vidctrl[2]), .O(global_video_enable));
    fd8re XLXI_682 (.C(clk_fast), .CE((cpu_sel_rastlow) & wr_pulse), .D(cpu_databus[7:0]), .R(XLXN_2650), .Q(split_line_low[7:0]));
    gnd XLXI_931 (.G(XLXN_2650));
    fd8re XLXI_960 (.C(clk_fast), .CE((XLXN_2728) & wr_pulse), .D(cpu_databus[7:0]), .R(XLXN_2714), .Q(vidpage[7:0]));
    fd8re XLXI_961 (.C(clk_fast), .CE((XLXN_2715) & wr_pulse), .D(cpu_databus[7:0]), .R(XLXN_2714), .Q(spritepage[7:0]));
    and2b1 XLXI_964 (.I0(cpu_databus[7]), .I1(cpu_sel_vidpage), .O(XLXN_2728));
    and2 XLXI_965 (.I0(cpu_sel_vidpage), .I1(cpu_databus[7]), .O(XLXN_2715));
    buf_x XLXI_968 [4:0] (.I(spritepage[4:0]), .O(cpu_sprite_base_addr[4:0]));
    buf_x XLXI_967 [5:0] (.I(vidpage[5:0]), .O(cpuaccvideopage_out[5:0]));
    fd4ce XLXI_344 (.C(clk_fast), .CE((setyhwsa) & wr_pulse), .CLR(XLXN_2714), .D0(cpu_databus[0]), .D1(cpu_databus[1]), .D2(cpu_databus[2]), .D3(cpu_databus[3]), .Q0(yhwsavalue[0]), .Q1(yhwsavalue[1]), .Q2(yhwsavalue[2]), .Q3(yhwsavalue[3]));
    fd4ce XLXI_995 (.C(clk_fast), .CE((setyhwsb) & wr_pulse), .CLR(XLXN_2714), .D0(cpu_databus[0]), .D1(cpu_databus[1]), .D2(cpu_databus[2]), .D3(cpu_databus[3]), .Q0(yhwsbvalue[0]), .Q1(yhwsbvalue[1]), .Q2(yhwsbvalue[2]), .Q3(yhwsbvalue[3]));
    gnd XLXI_996 (.G(XLXN_2714));
    and2 XLXI_997 (.I0(cpu_sel_yhws), .I1(cpu_databus[7]), .O(setyhwsb));
    and2b1 XLXI_998 (.I0(cpu_databus[7]), .I1(cpu_sel_yhws), .O(setyhwsa));
    comp8 XLXI_684 (.A(split_line_low[7:0]), .B(linecount_in[7:0]), .EQ(XLXN_3005));
    xor2 XLXI_1058 (.I0(virq_raster_msb), .I1(linecount_in[8]), .O(XLXN_3004));
    and3b1 XLXI_835 (.I0(XLXN_3004), .I1(XLXN_3005), .I2(new_scanline_in), .O(XLXN_3007));
    fdce XLXI_1060 (.C(main_clock_in), .CE(XLXN_3010), .CLR(XLXN_3015), .D(XLXN_3007), .Q(rasterirq_status_out));
    inv XLXI_843 (.I(rasterirq_status_out), .O(XLXN_3010));
    // raster IRQ flag clear (write $80 to vreg_rasthi): was and3 XLXI_760 (write & select & data[7]) straight into the flag's asynchronous CLR,
    // a decode glitch during any write could clear the flag (a lost interrupt).  Now a one-tick pulse from a register at the start of the write.
    reg rclr = 1'b0;
    always @(posedge clk_fast) rclr <= wr_pulse & cpu_sel_rasthigh & cpu_databus[7];
    assign XLXN_3015 = rclr;
    and2 XLXI_412 (.I0(new_scanline_in), .I1(XLXN_1965), .O(XLXN_1216));
    and2 XLXI_1070 (.I0(new_scanline_in), .I1(XLXN_3023), .O(XLXN_3024));
    fd XLXI_1072 (.C(main_clock_in), .D(XLXN_1216), .Q(latchayhws_out));
    fd XLXI_1073 (.C(main_clock_in), .D(XLXN_3024), .Q(latchbyhws_out));
    fdce XLXI_1075 (.C(clk_fast), .CE((setyhwsa) & wr_pulse), .CLR(latchayhws_out), .D(XLXN_3058), .Q(XLXN_1965));
    fdce XLXI_1076 (.C(clk_fast), .CE((setyhwsb) & wr_pulse), .CLR(latchbyhws_out), .D(XLXN_3058), .Q(XLXN_3023));
    vcc XLXI_1077 (.P(XLXN_3058));
    fd8re XLXI_881 (.C(clk_fast), .CE((cpu_sel_linecopreg_lo) & wr_pulse), .D(cpu_databus[7:0]), .R(XLXN_2590), .Q(linecop_addr[7:0]));
    fd8re XLXI_882 (.C(clk_fast), .CE((cpu_sel_linecopreg_hi) & wr_pulse), .D(cpu_databus[7:0]), .R(XLXN_2590), .Q(linecop_addr[15:8]));
    gnd XLXI_883 (.G(XLXN_2590));
    fde XLXI_861 (.C(clk_fast), .CE((cpu_sel_more_pfsettings) & wr_pulse), .D(cpu_databus[0]), .Q(tile_extend));
    fde XLXI_878 (.C(clk_fast), .CE((cpu_sel_more_pfsettings) & wr_pulse), .D(cpu_databus[1]), .Q(tile_pri_swap));
    fde XLXI_920 (.C(clk_fast), .CE((cpu_sel_more_pfsettings) & wr_pulse), .D(cpu_databus[2]), .Q(interlace));
    fde XLXI_1078 (.C(clk_fast), .CE((cpu_sel_more_pfsettings) & wr_pulse), .D(cpu_databus[3]), .Q(hi_res));
    fde XLXI_911 (.C(clk_fast), .CE((XLXN_2643) & wr_pulse), .D(cpu_databus[0]), .Q(live_palette_unsyncd));
    fde XLXI_912 (.C(clk_fast), .CE((XLXN_2644) & wr_pulse), .D(cpu_databus[0]), .Q(palette_wr_sel));
    and2b1 XLXI_914 (.I0(cpu_databus[1]), .I1(XLXN_3116), .O(XLXN_2643));
    and2 XLXI_913 (.I0(cpu_databus[1]), .I1(XLXN_3116), .O(XLXN_2644));
    fde #(.INIT(1'b1)) XLXI_1089 (.C(clk_fast), .CE((XLXN_3093) & wr_pulse), .D(cpu_databus[0]), .Q(linecop_addr[16]));
    fde #(.INIT(1'b1)) XLXI_1090 (.C(clk_fast), .CE((XLXN_3093) & wr_pulse), .D(cpu_databus[1]), .Q(linecop_addr[17]));
    fde #(.INIT(1'b1)) XLXI_1091 (.C(clk_fast), .CE((XLXN_3093) & wr_pulse), .D(cpu_databus[2]), .Q(linecop_addr[18]));
    and2 XLXI_1092 (.I0(cpu_databus[7]), .I1(cpu_sel_palette_ctrl), .O(XLXN_3093));
    and2b1 XLXI_1101 (.I0(cpu_databus[7]), .I1(cpu_sel_palette_ctrl), .O(XLXN_3116));

    assign dbg_ce = {XLXN_2182, cpu_sel_xhws, cpu_sel_vidctrl, XLXN_2317};
endmodule
