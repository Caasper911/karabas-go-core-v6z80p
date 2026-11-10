// generated from bglinebuffer504.sch
module bglinebuffer504 (
    input wire [3:0] xstartcoarse_in,
    input wire bm_bufwren_in,
    input wire tm_bufwren_in,
    input wire bm_latchdest_in,
    input wire tm_latchdest_in,
    input wire tm_lbaddr_inc_en_in,
    input wire bm_lbaddr_inc_en_in,
    output wire [8:0] linebuffaddr_out,
    input wire [7:0] slb_outword_addr,
    input wire sys_clock_16mhz,
    input wire slb_wrzero_en,
    input wire linecount_lsb,
    input wire slb_enable,
    input wire slb_byte_select,
    output wire [7:0] bgnd_pixel,
    input wire tile_mode_on,
    input wire chunky_mode_on,
    input wire [3:0] xstartfine_in,
    input wire [7:0] vram_databus,
    input wire [7:0] bitmap_pixel,
    input wire flood_mode
);

    wire [7:0] bglbstartaddr;
    wire [15:0] buffer_a_out;
    wire [15:0] buffer_b_out;
    wire latchdest_in;
    wire lbaddrclken_in;
    wire pixel_src_sel;
    wire [15:0] slb_word_out;
    wire [15:0] slb_word_out_tb0;
    wire [15:0] slb_word_out_tb1;
    wire [7:0] smear_latch;
    wire [7:0] source_pixel;
    wire wrenbuffa_in;
    wire wrenbuffb_in;
    wire XLXN_1382;
    wire XLXN_1389;
    wire XLXN_1485;
    wire [15:0] XLXN_1889;
    wire XLXN_1897;
    wire XLXN_1900;
    wire XLXN_1903;
    wire XLXN_1934;
    wire [7:0] XLXN_2043;
    wire XLXN_2048;
    wire XLXN_2264;
    wire XLXN_2342;
    wire XLXN_2344;
    wire XLXN_2349;
    wire XLXN_2350;
    wire XLXN_2351;
    wire XLXN_2352;
    wire XLXN_2353;
    wire XLXN_2354;
    wire XLXN_2355;
    wire [7:0] XLXN_2356;
    wire [7:0] XLXN_2357;
    wire XLXN_2358;
    wire XLXN_2363;
    wire XLXN_2364;
    wire XLXN_2365;
    wire XLXN_2366;

    cb8cle XLXI_121 (.C(sys_clock_16mhz), .CE(lbaddrclken_in), .CLR(XLXN_1389), .D(bglbstartaddr[7:0]), .L(latchdest_in), .CEO(XLXN_1382), .Q(linebuffaddr_out[7:0]), .TC());
    cb2re XLXI_138 (.C(sys_clock_16mhz), .CE(XLXN_1382), .R(latchdest_in), .CEO(), .Q0(linebuffaddr_out[8]), .Q1(), .TC());
    gnd XLXI_130 (.G(XLXN_1389));
    and2b1 XLXI_716 (.I0(linecount_lsb), .I1(XLXN_1485), .O(wrenbuffb_in));
    and2 XLXI_715 (.I0(linecount_lsb), .I1(XLXN_1485), .O(wrenbuffa_in));
    m2_1 XLXI_714 (.D0(bm_bufwren_in), .D1(tm_bufwren_in), .S0(tile_mode_on), .O(XLXN_1485));
    m2_1 XLXI_717 (.D0(bm_latchdest_in), .D1(tm_latchdest_in), .S0(tile_mode_on), .O(latchdest_in));
    m2_1 XLXI_718 (.D0(bm_lbaddr_inc_en_in), .D1(tm_lbaddr_inc_en_in), .S0(tile_mode_on), .O(lbaddrclken_in));
    buf_x XLXI_414 [3:0] (.I(xstartcoarse_in[3:0]), .O(bglbstartaddr[7:4]));
    ramb4_s8_s16 XLXI_869 (.ADDRA(linebuffaddr_out[8:0]), .ADDRB(slb_outword_addr[7:0]), .CLKA(sys_clock_16mhz), .CLKB(sys_clock_16mhz), .DIA(source_pixel[7:0]), .DIB(XLXN_1889[15:0]), .ENA(wrenbuffa_in), .ENB(XLXN_1900), .RSTA(XLXN_1897), .RSTB(XLXN_1897), .WEA(XLXN_1934), .WEB(slb_wrzero_en), .DOA(), .DOB(buffer_a_out[15:0]));
    ramb4_s8_s16 XLXI_870 (.ADDRA(linebuffaddr_out[8:0]), .ADDRB(slb_outword_addr[7:0]), .CLKA(sys_clock_16mhz), .CLKB(sys_clock_16mhz), .DIA(source_pixel[7:0]), .DIB(XLXN_1889[15:0]), .ENA(wrenbuffb_in), .ENB(XLXN_1903), .RSTA(XLXN_1897), .RSTB(XLXN_1897), .WEA(XLXN_1934), .WEB(slb_wrzero_en), .DOA(), .DOB(buffer_b_out[15:0]));
    and2b1 XLXI_872 (.I0(linecount_lsb), .I1(slb_enable), .O(XLXN_1900));
    and2 XLXI_873 (.I0(linecount_lsb), .I1(slb_enable), .O(XLXN_1903));
    gnd XLXI_874 [15:0] (.G(XLXN_1889[15:0]));
    gnd XLXI_875 (.G(XLXN_1897));
    vcc XLXI_877 (.P(XLXN_1934));
    buft16 XLXI_879 (.I(buffer_a_out[15:0]), .T(linecount_lsb), .O(slb_word_out_tb0[15:0]));
    bufe16 XLXI_880 (.E(linecount_lsb), .I(buffer_b_out[15:0]), .O(slb_word_out_tb1[15:0]));
    fd8re XLXI_911 (.C(sys_clock_16mhz), .CE(slb_byte_select), .D(slb_word_out[15:8]), .R(XLXN_2048), .Q(XLXN_2043[7:0]));
    gnd XLXI_912 (.G(XLXN_2048));
    selector_2x8 XLXI_913 (.input_a(XLXN_2043[7:0]), .input_b(slb_word_out[7:0]), .select_ab(slb_byte_select), .output_c(bgnd_pixel[7:0]));
    and2b1 XLXI_919 (.I0(chunky_mode_on), .I1(xstartfine_in[3]), .O(bglbstartaddr[3]));
    and2b1 XLXI_920 (.I0(chunky_mode_on), .I1(xstartfine_in[2]), .O(bglbstartaddr[2]));
    and2b1 XLXI_921 (.I0(chunky_mode_on), .I1(xstartfine_in[1]), .O(bglbstartaddr[1]));
    and2b1 XLXI_922 (.I0(chunky_mode_on), .I1(xstartfine_in[0]), .O(bglbstartaddr[0]));
    selector_2x8 XLXI_935 (.input_a(vram_databus[7:0]), .input_b(smear_latch[7:0]), .select_ab(XLXN_2355), .output_c(XLXN_2356[7:0]));
    xor8reg XLXI_1012 (.clock_in(sys_clock_16mhz), .in_a(vram_databus[7:0]), .out_b(smear_latch[7:0]), .reset_in(XLXN_2264));
    inv XLXI_986 (.I(bm_bufwren_in), .O(XLXN_2264));
    and2b1 XLXI_1014 (.I0(tile_mode_on), .I1(flood_mode), .O(XLXN_2355));
    selector_2x8 XLXI_1015 (.input_a(bitmap_pixel[7:0]), .input_b(XLXN_2356[7:0]), .select_ab(pixel_src_sel), .output_c(source_pixel[7:0]));
    or2 XLXI_914 (.I0(chunky_mode_on), .I1(tile_mode_on), .O(pixel_src_sel));
    assign slb_word_out[0] = slb_word_out_tb0[0] | slb_word_out_tb1[0];
    assign slb_word_out[1] = slb_word_out_tb0[1] | slb_word_out_tb1[1];
    assign slb_word_out[2] = slb_word_out_tb0[2] | slb_word_out_tb1[2];
    assign slb_word_out[3] = slb_word_out_tb0[3] | slb_word_out_tb1[3];
    assign slb_word_out[4] = slb_word_out_tb0[4] | slb_word_out_tb1[4];
    assign slb_word_out[5] = slb_word_out_tb0[5] | slb_word_out_tb1[5];
    assign slb_word_out[6] = slb_word_out_tb0[6] | slb_word_out_tb1[6];
    assign slb_word_out[7] = slb_word_out_tb0[7] | slb_word_out_tb1[7];
    assign slb_word_out[8] = slb_word_out_tb0[8] | slb_word_out_tb1[8];
    assign slb_word_out[9] = slb_word_out_tb0[9] | slb_word_out_tb1[9];
    assign slb_word_out[10] = slb_word_out_tb0[10] | slb_word_out_tb1[10];
    assign slb_word_out[11] = slb_word_out_tb0[11] | slb_word_out_tb1[11];
    assign slb_word_out[12] = slb_word_out_tb0[12] | slb_word_out_tb1[12];
    assign slb_word_out[13] = slb_word_out_tb0[13] | slb_word_out_tb1[13];
    assign slb_word_out[14] = slb_word_out_tb0[14] | slb_word_out_tb1[14];
    assign slb_word_out[15] = slb_word_out_tb0[15] | slb_word_out_tb1[15];

endmodule
