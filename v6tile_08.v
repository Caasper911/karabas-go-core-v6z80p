// generated from v6tile_08.sch
module v6tile_08 (
    input wire clock_16mhz,
    input wire extended_mode,
    input wire start_line,
    input wire [7:0] vram_data_in,
    input wire layer_b_block_bank,
    input wire layer_a_block_bank,
    input wire dual_playfield,
    output wire slb_latch_dest,
    input wire scanline_start,
    input wire right_border,
    output wire pri_adjusted_layer,
    output wire stop_line,
    input wire eight_by_eight_mode,
    output wire [18:0] vram_addr_out,
    input wire layer_a_mapsel,
    input wire layer_b_mapsel,
    input wire priority_swap,
    input wire [3:0] yhwsavalue_in,
    input wire [3:0] yhwsbvalue_in,
    input wire vrtline_in,
    input wire latchbyhws_in,
    input wire latchayhws_in,
    output wire slb_addr_inc_en,
    output wire slb_wr_en
);

    wire [10:0] block_addr;
    wire block_addr_8x8_hi0;
    wire block_addr_8x8_hi1;
    wire [18:3] def_addr;
    wire [18:3] def_addr_16x16;
    wire [18:3] def_addr_8x8;
    wire [15:0] def_addr_tb0;
    wire [15:0] def_addr_tb1;
    wire end_tile_ops;
    wire ext_pri;
    wire fetch_pixels;
    wire flipx;
    wire flipy;
    wire latch_hi;
    wire latch_lo;
    wire [7:0] lcounta;
    wire [7:0] lcountb;
    wire line0_flipmod;
    wire line1_flipmod;
    wire line2_flipmod;
    wire line3_flipmod;
    wire [7:0] lineindex;
    wire map_access_a5;
    wire map_index_a10;
    wire map_index_a11;
    wire map_index_a12;
    wire map_index_a13;
    wire map_index_a6;
    wire map_index_a7;
    wire map_index_a8;
    wire map_index_a9;
    wire map_sel;
    wire mapx0;
    wire mapx1;
    wire mapx2;
    wire mapx3;
    wire mapx4;
    wire mapx5;
    wire pf_layer;
    wire pixel0;
    wire pixel0_flipmod;
    wire pixel1;
    wire pixel1_flipmod;
    wire pixel2;
    wire pixel2_flipmod;
    wire pixel3;
    wire pixel3_flipmod;
    wire rightmost_pixel;
    wire running;
    wire set_pf_layer_b;
    wire XLXN_12;
    wire XLXN_13;
    wire XLXN_136;
    wire XLXN_142;
    wire XLXN_145;
    wire XLXN_1466;
    wire XLXN_1467;
    wire XLXN_1528;
    wire XLXN_1544;
    wire XLXN_1560;
    wire XLXN_1566;
    wire XLXN_1570;
    wire XLXN_158;
    wire XLXN_160;
    wire XLXN_161;
    wire XLXN_162;
    wire XLXN_174;
    wire XLXN_35;
    wire XLXN_4;
    wire XLXN_477;
    wire XLXN_479;
    wire XLXN_569;
    wire XLXN_570;
    wire XLXN_601;
    wire XLXN_603;
    wire XLXN_606;
    wire XLXN_715;
    wire XLXN_728;
    wire XLXN_729;
    wire XLXN_741;
    wire XLXN_772;
    wire XLXN_778;
    wire XLXN_779;
    wire XLXN_783;
    wire XLXN_803;
    wire y_count_enable;

    fde XLXI_72 (.C(clock_16mhz), .CE(latch_hi), .D(vram_data_in[0]), .Q(XLXN_160));
    fde XLXI_73 (.C(clock_16mhz), .CE(latch_hi), .D(vram_data_in[1]), .Q(XLXN_161));
    fde XLXI_74 (.C(clock_16mhz), .CE(latch_hi), .D(vram_data_in[2]), .Q(XLXN_162));
    m2_1 XLXI_76 (.D0(XLXN_174), .D1(XLXN_160), .S0(extended_mode), .O(block_addr[8]));
    and2 XLXI_77 (.I0(extended_mode), .I1(XLXN_161), .O(block_addr[9]));
    and2 XLXI_78 (.I0(extended_mode), .I1(XLXN_162), .O(block_addr[10]));
    fd8re XLXI_71 (.C(clock_16mhz), .CE(latch_lo), .D(vram_data_in[7:0]), .R(XLXN_158), .Q(block_addr[7:0]));
    m2_1 XLXI_79 (.D0(layer_a_block_bank), .D1(layer_b_block_bank), .S0(pri_adjusted_layer), .O(XLXN_174));
    and2 XLXI_727 (.I0(pf_layer), .I1(y_count_enable), .O(XLXN_601));
    or2 XLXI_728 (.I0(XLXN_603), .I1(XLXN_601), .O(end_tile_ops));
    and2b1 XLXI_729 (.I0(dual_playfield), .I1(y_count_enable), .O(XLXN_603));
    and2 XLXI_730 (.I0(dual_playfield), .I1(y_count_enable), .O(set_pf_layer_b));
    inv XLXI_2 (.I(XLXN_35), .O(XLXN_4));
    fdrs XLXI_3 (.C(clock_16mhz), .D(fetch_pixels), .R(rightmost_pixel), .S(XLXN_35), .Q(fetch_pixels));
    cb4re XLXI_4 (.C(clock_16mhz), .CE(XLXN_13), .R(XLXN_12), .CEO(XLXN_1466), .Q0(pixel0), .Q1(pixel1), .Q2(pixel2), .Q3(pixel3), .TC());
    inv XLXI_5 (.I(fetch_pixels), .O(XLXN_12));
    vcc XLXI_6 (.P(XLXN_13));
    fdr XLXI_7 (.C(clock_16mhz), .D(XLXN_4), .R(XLXN_136), .Q(XLXN_35));
    and2b1 XLXI_15 (.I0(fetch_pixels), .I1(XLXN_35), .O(latch_hi));
    or2 XLXI_65 (.I0(rightmost_pixel), .I1(XLXN_142), .O(XLXN_136));
    fdrs XLXI_66 (.C(clock_16mhz), .D(XLXN_145), .R(end_tile_ops), .S(start_line), .Q(XLXN_145));
    fd XLXI_68 (.C(clock_16mhz), .D(XLXN_145), .Q(running));
    nor3 XLXI_70 (.I0(fetch_pixels), .I1(XLXN_35), .I2(XLXN_142), .O(latch_lo));
    inv XLXI_69 (.I(running), .O(XLXN_142));
    fdrs XLXI_725 (.C(clock_16mhz), .D(pf_layer), .R(start_line), .S(set_pf_layer_b), .Q(pf_layer));
    and2 XLXI_731 (.I0(XLXN_606), .I1(latch_lo), .O(slb_latch_dest));
    fdrs XLXI_733 (.C(clock_16mhz), .D(XLXN_741), .R(scanline_start), .S(end_tile_ops), .Q(XLXN_741));
    and2 XLXI_735 (.I0(rightmost_pixel), .I1(right_border), .O(y_count_enable));
    gnd XLXI_75 (.G(XLXN_158));
    fde XLXI_767 (.C(clock_16mhz), .CE(latch_hi), .D(vram_data_in[6]), .Q(XLXN_728));
    fde XLXI_768 (.C(clock_16mhz), .CE(latch_hi), .D(vram_data_in[7]), .Q(XLXN_729));
    and2 XLXI_770 (.I0(extended_mode), .I1(XLXN_728), .O(flipx));
    and2 XLXI_771 (.I0(extended_mode), .I1(XLXN_729), .O(flipy));
    and2b1 XLXI_772 (.I0(XLXN_741), .I1(end_tile_ops), .O(stop_line));
    m2_1 XLXI_792 (.D0(lineindex[4]), .D1(mapx5), .S0(eight_by_eight_mode), .O(map_access_a5));
    m2_1 XLXI_793 (.D0(lineindex[5]), .D1(lineindex[3]), .S0(eight_by_eight_mode), .O(map_index_a6));
    m2_1 XLXI_794 (.D0(lineindex[6]), .D1(lineindex[4]), .S0(eight_by_eight_mode), .O(map_index_a7));
    m2_1 XLXI_795 (.D0(lineindex[7]), .D1(lineindex[5]), .S0(eight_by_eight_mode), .O(map_index_a8));
    m2_1 XLXI_796 (.D0(map_sel), .D1(lineindex[6]), .S0(eight_by_eight_mode), .O(map_index_a9));
    m2_1 XLXI_797 (.D0(pri_adjusted_layer), .D1(lineindex[7]), .S0(eight_by_eight_mode), .O(map_index_a10));
    m2_1 XLXI_804 (.D0(ext_pri), .D1(latch_hi), .S0(eight_by_eight_mode), .O(map_index_a11));
    and2 XLXI_812 (.I0(eight_by_eight_mode), .I1(map_sel), .O(map_index_a12));
    and2 XLXI_813 (.I0(eight_by_eight_mode), .I1(pri_adjusted_layer), .O(map_index_a13));
    cb4re XLXI_203 (.C(clock_16mhz), .CE(latch_hi), .R(XLXN_715), .CEO(XLXN_803), .Q0(mapx0), .Q1(mapx1), .Q2(mapx2), .Q3(mapx3), .TC());
    cb2re XLXI_789 (.C(clock_16mhz), .CE(XLXN_803), .R(XLXN_715), .CEO(), .Q0(mapx4), .Q1(mapx5), .TC());
    or2 XLXI_732 (.I0(start_line), .I1(y_count_enable), .O(XLXN_715));
    m2_1 XLXI_103 (.D0(mapx4), .D1(def_addr[4]), .S0(fetch_pixels), .O(vram_addr_out[4]));
    m2_1 XLXI_104 (.D0(map_access_a5), .D1(def_addr[5]), .S0(fetch_pixels), .O(vram_addr_out[5]));
    m2_1 XLXI_105 (.D0(map_index_a6), .D1(def_addr[6]), .S0(fetch_pixels), .O(vram_addr_out[6]));
    m2_1 XLXI_106 (.D0(map_index_a7), .D1(def_addr[7]), .S0(fetch_pixels), .O(vram_addr_out[7]));
    m2_1 XLXI_107 (.D0(map_index_a8), .D1(def_addr[8]), .S0(fetch_pixels), .O(vram_addr_out[8]));
    m2_1 XLXI_99 (.D0(mapx0), .D1(pixel0_flipmod), .S0(fetch_pixels), .O(vram_addr_out[0]));
    m2_1 XLXI_100 (.D0(mapx1), .D1(pixel1_flipmod), .S0(fetch_pixels), .O(vram_addr_out[1]));
    m2_1 XLXI_101 (.D0(mapx2), .D1(pixel2_flipmod), .S0(fetch_pixels), .O(vram_addr_out[2]));
    m2_1 XLXI_102 (.D0(mapx3), .D1(def_addr[3]), .S0(fetch_pixels), .O(vram_addr_out[3]));
    and2 XLXI_122 (.I0(fetch_pixels), .I1(def_addr[14]), .O(vram_addr_out[14]));
    and2 XLXI_123 (.I0(fetch_pixels), .I1(def_addr[15]), .O(vram_addr_out[15]));
    m2_1 XLXI_165 (.D0(map_index_a9), .D1(def_addr[9]), .S0(fetch_pixels), .O(vram_addr_out[9]));
    m2_1 XLXI_167 (.D0(map_index_a10), .D1(def_addr[10]), .S0(fetch_pixels), .O(vram_addr_out[10]));
    m2_1 XLXI_168 (.D0(map_index_a11), .D1(def_addr[11]), .S0(fetch_pixels), .O(vram_addr_out[11]));
    m2_1 XLXI_810 (.D0(map_index_a12), .D1(def_addr[12]), .S0(fetch_pixels), .O(vram_addr_out[12]));
    m2_1 XLXI_811 (.D0(map_index_a13), .D1(def_addr[13]), .S0(fetch_pixels), .O(vram_addr_out[13]));
    fde XLXI_1031 (.C(clock_16mhz), .CE(latch_hi), .D(vram_data_in[3]), .Q(block_addr_8x8_hi0));
    fde XLXI_1032 (.C(clock_16mhz), .CE(latch_hi), .D(vram_data_in[4]), .Q(block_addr_8x8_hi1));
    buf_x XLXI_877 (.I(line0_flipmod), .O(def_addr_8x8[3]));
    buf_x XLXI_878 (.I(line1_flipmod), .O(def_addr_8x8[4]));
    buf_x XLXI_879 (.I(line2_flipmod), .O(def_addr_8x8[5]));
    buf_x XLXI_882 (.I(block_addr[2]), .O(def_addr_8x8[8]));
    buf_x XLXI_883 (.I(block_addr[3]), .O(def_addr_8x8[9]));
    buf_x XLXI_884 (.I(block_addr[4]), .O(def_addr_8x8[10]));
    buf_x XLXI_885 (.I(block_addr[5]), .O(def_addr_8x8[11]));
    buf_x XLXI_886 (.I(block_addr[6]), .O(def_addr_8x8[12]));
    buf_x XLXI_887 (.I(block_addr[7]), .O(def_addr_8x8[13]));
    buf_x XLXI_888 (.I(block_addr[8]), .O(def_addr_8x8[14]));
    buf_x XLXI_889 (.I(block_addr[9]), .O(def_addr_8x8[15]));
    buf_x XLXI_890 (.I(block_addr[10]), .O(def_addr_8x8[16]));
    buf_x XLXI_891 (.I(block_addr_8x8_hi0), .O(def_addr_8x8[17]));
    buf_x XLXI_892 (.I(block_addr_8x8_hi1), .O(def_addr_8x8[18]));
    buf_x XLXI_881 (.I(block_addr[1]), .O(def_addr_8x8[7]));
    buf_x XLXI_880 (.I(block_addr[0]), .O(def_addr_8x8[6]));
    bufe16 XLXI_974 (.E(eight_by_eight_mode), .I(def_addr_8x8[18:3]), .O(def_addr_tb0[15:0]));
    buft16 XLXI_975 (.I(def_addr_16x16[18:3]), .T(eight_by_eight_mode), .O(def_addr_tb1[15:0]));
    buf_x XLXI_934 (.I(pixel3_flipmod), .O(def_addr_16x16[3]));
    buf_x XLXI_935 (.I(line0_flipmod), .O(def_addr_16x16[4]));
    buf_x XLXI_936 (.I(line1_flipmod), .O(def_addr_16x16[5]));
    buf_x XLXI_937 (.I(line2_flipmod), .O(def_addr_16x16[6]));
    buf_x XLXI_938 (.I(line3_flipmod), .O(def_addr_16x16[7]));
    buf_x XLXI_939 (.I(block_addr[0]), .O(def_addr_16x16[8]));
    buf_x XLXI_940 (.I(block_addr[1]), .O(def_addr_16x16[9]));
    buf_x XLXI_941 (.I(block_addr[2]), .O(def_addr_16x16[10]));
    buf_x XLXI_942 (.I(block_addr[3]), .O(def_addr_16x16[11]));
    buf_x XLXI_943 (.I(block_addr[4]), .O(def_addr_16x16[12]));
    buf_x XLXI_944 (.I(block_addr[5]), .O(def_addr_16x16[13]));
    buf_x XLXI_945 (.I(block_addr[6]), .O(def_addr_16x16[14]));
    buf_x XLXI_946 (.I(block_addr[7]), .O(def_addr_16x16[15]));
    buf_x XLXI_947 (.I(block_addr[8]), .O(def_addr_16x16[16]));
    buf_x XLXI_948 (.I(block_addr[9]), .O(def_addr_16x16[17]));
    buf_x XLXI_949 (.I(block_addr[10]), .O(def_addr_16x16[18]));
    xor2 XLXI_754 (.I0(pixel0), .I1(flipx), .O(pixel0_flipmod));
    xor2 XLXI_755 (.I0(pixel1), .I1(flipx), .O(pixel1_flipmod));
    xor2 XLXI_756 (.I0(pixel2), .I1(flipx), .O(pixel2_flipmod));
    xor2 XLXI_757 (.I0(pixel3), .I1(flipx), .O(pixel3_flipmod));
    xor2 XLXI_758 (.I0(lineindex[0]), .I1(flipy), .O(line0_flipmod));
    xor2 XLXI_759 (.I0(lineindex[1]), .I1(flipy), .O(line1_flipmod));
    xor2 XLXI_760 (.I0(lineindex[2]), .I1(flipy), .O(line2_flipmod));
    xor2 XLXI_761 (.I0(lineindex[3]), .I1(flipy), .O(line3_flipmod));
    m2_1 XLXI_166 (.D0(layer_a_mapsel), .D1(layer_b_mapsel), .S0(pri_adjusted_layer), .O(map_sel));
    and2 XLXI_169 (.I0(latch_hi), .I1(extended_mode), .O(ext_pri));
    xor2 XLXI_769 (.I0(pf_layer), .I1(priority_swap), .O(pri_adjusted_layer));
    or2 XLXI_1097 (.I0(XLXN_1466), .I1(XLXN_1467), .O(rightmost_pixel));
    and4 XLXI_1099 (.I0(eight_by_eight_mode), .I1(pixel2), .I2(pixel1), .I3(pixel0), .O(XLXN_1467));
    cb8cle XLXI_1 (.C(clock_16mhz), .CE(XLXN_479), .CLR(vrtline_in), .D({lcounta[7:4], yhwsavalue_in[3:0]}), .L(XLXN_778), .CEO(), .Q(lcounta[7:0]), .TC());
    cb8cle XLXI_192 (.C(clock_16mhz), .CE(XLXN_477), .CLR(vrtline_in), .D({lcountb[7:4], yhwsbvalue_in[3:0]}), .L(XLXN_779), .CEO(), .Q(lcountb[7:0]), .TC());
    m2_1 XLXI_193 (.D0(lcounta[0]), .D1(lcountb[0]), .S0(pri_adjusted_layer), .O(lineindex[0]));
    m2_1 XLXI_194 (.D0(lcounta[1]), .D1(lcountb[1]), .S0(pri_adjusted_layer), .O(lineindex[1]));
    m2_1 XLXI_195 (.D0(lcounta[2]), .D1(lcountb[2]), .S0(pri_adjusted_layer), .O(lineindex[2]));
    m2_1 XLXI_196 (.D0(lcounta[3]), .D1(lcountb[3]), .S0(pri_adjusted_layer), .O(lineindex[3]));
    m2_1 XLXI_197 (.D0(lcounta[4]), .D1(lcountb[4]), .S0(pri_adjusted_layer), .O(lineindex[4]));
    m2_1 XLXI_8 (.D0(lcounta[5]), .D1(lcountb[5]), .S0(pri_adjusted_layer), .O(lineindex[5]));
    m2_1 XLXI_9 (.D0(lcounta[6]), .D1(lcountb[6]), .S0(pri_adjusted_layer), .O(lineindex[6]));
    m2_1 XLXI_10 (.D0(lcounta[7]), .D1(lcountb[7]), .S0(pri_adjusted_layer), .O(lineindex[7]));
    and2 XLXI_11 (.I0(pri_adjusted_layer), .I1(y_count_enable), .O(XLXN_477));
    and2b1 XLXI_12 (.I0(pri_adjusted_layer), .I1(y_count_enable), .O(XLXN_479));
    or2 XLXI_788 (.I0(XLXN_783), .I1(latchbyhws_in), .O(XLXN_779));
    or2 XLXI_787 (.I0(XLXN_783), .I1(latchayhws_in), .O(XLXN_778));
    fd XLXI_785 (.C(clock_16mhz), .D(vrtline_in), .Q(XLXN_772));
    and2b1 XLXI_786 (.I0(vrtline_in), .I1(XLXN_772), .O(XLXN_783));
    nor6 XLXI_1100 (.I0(mapx5), .I1(mapx4), .I2(mapx3), .I3(mapx2), .I4(mapx1), .I5(mapx0), .O(XLXN_606));
    m2_1 XLXI_1101 (.D0(extended_mode), .D1(def_addr[16]), .S0(fetch_pixels), .O(vram_addr_out[16]));
    m2_1 XLXI_1102 (.D0(extended_mode), .D1(def_addr[17]), .S0(fetch_pixels), .O(vram_addr_out[17]));
    m2_1 XLXI_1103 (.D0(extended_mode), .D1(XLXN_1566), .S0(fetch_pixels), .O(vram_addr_out[18]));
    or9 XLXI_717 (.I0(XLXN_570), .I1(vram_data_in[7]), .I2(vram_data_in[6]), .I3(vram_data_in[5]), .I4(vram_data_in[4]), .I5(vram_data_in[3]), .I6(vram_data_in[2]), .I7(vram_data_in[1]), .I8(vram_data_in[0]), .O(XLXN_569));
    inv XLXI_719 (.I(pf_layer), .O(XLXN_570));
    buf_x XLXI_720 (.I(fetch_pixels), .O(slb_addr_inc_en));
    and3 XLXI_1104 (.I0(fetch_pixels), .I1(XLXN_569), .I2(running), .O(slb_wr_en));
    xor2 XLXI_1118 (.I0(def_addr[18]), .I1(XLXN_1570), .O(XLXN_1566));
    and2 XLXI_1119 (.I0(layer_b_block_bank), .I1(extended_mode), .O(XLXN_1570));
    assign def_addr[3] = def_addr_tb0[0] | def_addr_tb1[0];
    assign def_addr[4] = def_addr_tb0[1] | def_addr_tb1[1];
    assign def_addr[5] = def_addr_tb0[2] | def_addr_tb1[2];
    assign def_addr[6] = def_addr_tb0[3] | def_addr_tb1[3];
    assign def_addr[7] = def_addr_tb0[4] | def_addr_tb1[4];
    assign def_addr[8] = def_addr_tb0[5] | def_addr_tb1[5];
    assign def_addr[9] = def_addr_tb0[6] | def_addr_tb1[6];
    assign def_addr[10] = def_addr_tb0[7] | def_addr_tb1[7];
    assign def_addr[11] = def_addr_tb0[8] | def_addr_tb1[8];
    assign def_addr[12] = def_addr_tb0[9] | def_addr_tb1[9];
    assign def_addr[13] = def_addr_tb0[10] | def_addr_tb1[10];
    assign def_addr[14] = def_addr_tb0[11] | def_addr_tb1[11];
    assign def_addr[15] = def_addr_tb0[12] | def_addr_tb1[12];
    assign def_addr[16] = def_addr_tb0[13] | def_addr_tb1[13];
    assign def_addr[17] = def_addr_tb0[14] | def_addr_tb1[14];
    assign def_addr[18] = def_addr_tb0[15] | def_addr_tb1[15];

endmodule
