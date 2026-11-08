// generated from sprite_system513.sch
module sprite_system513 (
    input wire [7:0] cpu_databus,
    input wire [7:0] spr_pixel_data_in,
    output wire [16:0] spr_sram_addr,
    input wire cpu_sprite_reg_sel,
    input wire cpu_wr,
    input wire [8:0] spr_reg_addr_in,
    input wire clk_in_16mhz,
    input wire reset_sprite_gen,
    output wire last_sprite,
    input wire last_16_cycles,
    input wire [7:0] slb_read_addr,
    input wire slb_wr_zero_in,
    input wire slb_access_enable,
    input wire [8:0] modified_linecount,
    output wire [7:0] sprite_pixel,
    input wire slb_byte_select,
    output wire spr_priority,
    output wire global_sprite_enable,
    input wire cpu_sel_spr_ctrl,
    output wire spr_pri_option
);
    wire [8:0] buf_write_addr;
    wire height_c, height_d, linebuf_wren;
    wire [8:0] buf_write_addr_d;
    wire linebuf_wren_d, modlc0_d, height_c_d, height_d_d;
    fd XLXI_9100 [8:0] (.C(clk_in_16mhz), .D(buf_write_addr[8:0]), .Q(buf_write_addr_d[8:0]));
    fd XLXI_9101 (.C(clk_in_16mhz), .D(linebuf_wren), .Q(linebuf_wren_d));
    fd XLXI_9102 (.C(clk_in_16mhz), .D(modified_linecount[0]), .Q(modlc0_d));
    fd XLXI_9103 (.C(clk_in_16mhz), .D(height_c), .Q(height_c_d));
    fd XLXI_9104 (.C(clk_in_16mhz), .D(height_d), .Q(height_d_d));

    wire [4:0] block_diff;
    wire [15:0] bus_gnd;
    wire [7:0] control_reg_addr;
    wire [15:0] control_reg_output;
    wire [8:0] difference;
    wire [7:0] diffin;
    wire height_a;
    wire height_b;
    wire height_is_zero;
    wire inv_cpu_wr_line;
    wire inv_main_clock_16mhz;
    wire justsomegrounds;
    wire no_sprite_data;
    wire [7:0] pixel_to_write;
    wire [15:0] selected_word;
    wire [15:0] selected_word_tb0;
    wire [15:0] selected_word_tb1;
    wire source_pixel_or;
    wire [16:0] spr_ext_sram_addr;
    wire [4:0] spr_height;
    wire spr_opt1;
    wire spr_opt2;
    wire spr_reg_bank;
    wire spr_reg_mode;
    wire [8:0] spr_ypos;
    wire [7:0] sprite_register_sel;
    wire sprite_sixtythree;
    wire sprix_idx_a;
    wire sprix_idx_b;
    wire sprix_idx_c;
    wire sprix_idx_d;
    wire [15:0] sprlinebufa_out;
    wire [15:0] sprlinebufb_out;
    wire stage_two;
    wire [7:0] vreg7bits;
    wire XLXN_1053;
    wire XLXN_1071;
    wire XLXN_1076;
    wire XLXN_1158;
    wire XLXN_121;
    wire XLXN_1256;
    wire XLXN_1259;
    wire XLXN_1271;
    wire XLXN_1274;
    wire XLXN_1276;
    wire XLXN_1277;
    wire XLXN_1337;
    wire XLXN_1339;
    wire XLXN_1342;
    wire XLXN_1370;
    wire XLXN_1397;
    wire [15:0] XLXN_1452;
    wire XLXN_1495;
    wire XLXN_1504;
    wire [7:0] XLXN_1543;
    wire XLXN_1547;
    wire XLXN_1548;
    wire XLXN_1564;
    wire XLXN_1626;
    wire XLXN_1716;
    wire XLXN_1776;
    wire XLXN_1797;
    wire XLXN_1846;
    wire XLXN_1962;
    wire XLXN_1966;
    wire XLXN_1973;
    wire XLXN_49;
    wire XLXN_5;
    wire XLXN_666;
    wire XLXN_869;
    wire XLXN_870;
    wire XLXN_9;
    wire xpos_latch_enable;

    cb8cle XLXI_92 (.C(inv_main_clock_16mhz), .CE(XLXN_870), .CLR(XLXN_869), .D(control_reg_output[7:0]), .L(xpos_latch_enable), .CEO(XLXN_121), .Q(buf_write_addr[7:0]), .TC());
    cb2cle XLXI_93 (.C(inv_main_clock_16mhz), .CE(XLXN_121), .CLR(XLXN_869), .D0(control_reg_output[8]), .D1(XLXN_1256), .L(xpos_latch_enable), .CEO(), .Q0(buf_write_addr[8]), .Q1(), .TC());
    gnd XLXI_64 (.G(XLXN_869));
    gnd XLXI_79 (.G(justsomegrounds));
    gnd XLXI_63 (.G(XLXN_1256));
    ramb4_s8_s16 sprite_control_reg_ram (.ADDRA(spr_reg_addr_in[8:0]), .ADDRB(sprite_register_sel[7:0]), .CLKA(cpu_wr), .CLKB(clk_in_16mhz), .DIA(cpu_databus[7:0]), .DIB(bus_gnd[15:0]), .ENA(cpu_sprite_reg_sel), .ENB(XLXN_1966), .RSTA(justsomegrounds), .RSTB(justsomegrounds), .WEA(XLXN_666), .WEB(justsomegrounds), .DOA(), .DOB(control_reg_output[15:0]));
    gnd databus_b_gnd [15:0] (.G(bus_gnd[15:0]));
    vcc XLXI_31 (.P(XLXN_666));
    gnd XLXI_196 (.G(XLXN_1259));
    buf_x defadd [3:0] (.I(difference[7:4]), .O(diffin[3:0]));
    vcc XLXI_303 (.P(XLXN_870));
    add8 XLXI_189 (.A(control_reg_output[15:8]), .B(diffin[7:0]), .CI(XLXN_1259), .CO(XLXN_1274), .OFL(), .S(spr_ext_sram_addr[15:8]));
    gnd mygrounds [3:0] (.G(diffin[7:4]));
    fd4ce XLXI_322 (.C(inv_main_clock_16mhz), .CE(xpos_latch_enable), .CLR(XLXN_1259), .D0(control_reg_output[12]), .D1(control_reg_output[13]), .D2(control_reg_output[14]), .D3(control_reg_output[15]), .Q0(height_a), .Q1(height_b), .Q2(height_c), .Q3(height_d));
    gnd XLXI_363 (.G(XLXN_1053));
    and2 XLXI_367 (.I0(source_pixel_or), .I1(modlc0_d), .O(XLXN_1071));
    and2b1 XLXI_368 (.I0(modlc0_d), .I1(source_pixel_or), .O(XLXN_1076));
    nine_bit_subtract XLXI_387 (.input_a(modified_linecount[8:0]), .input_b(spr_ypos[8:0]), .output_c(difference[8:0]), .active_lo_carry());
    five_bit_subtract XLXI_391 (.input_a(block_diff[4:0]), .input_b(spr_height[4:0]), .output_c(), .active_lo_carry(no_sprite_data));
    buf_x XLXI_393 [4:0] (.I(difference[8:4]), .O(block_diff[4:0]));
    buf_x XLXI_394 [16:0] (.I(spr_ext_sram_addr[16:0]), .O(spr_sram_addr[16:0]));
    buf_x XLXI_290 [3:0] (.I(difference[3:0]), .O(spr_ext_sram_addr[7:4]));
    buf_x XLXI_396 [7:0] (.I(control_reg_output[7:0]), .O(spr_ypos[7:0]));
    xor2 XLXI_397 (.I0(XLXN_1271), .I1(XLXN_1274), .O(spr_ext_sram_addr[16]));
    fdrs XLXI_2 (.C(clk_in_16mhz), .D(stage_two), .R(XLXN_1158), .S(XLXN_49), .Q(stage_two));
    or2 XLXI_377 (.I0(stage_two), .I1(XLXN_1158), .O(XLXN_5));
    vcc XLXI_6 (.P(XLXN_9));
    cb4re XLXI_380 (.C(inv_main_clock_16mhz), .CE(XLXN_9), .R(XLXN_49), .CEO(), .Q0(sprix_idx_a), .Q1(sprix_idx_b), .Q2(sprix_idx_c), .Q3(sprix_idx_d), .TC(XLXN_1277));
    and2b1 XLXI_381 (.I0(stage_two), .I1(XLXN_49), .O(xpos_latch_enable));
    fd XLXI_382 (.C(inv_main_clock_16mhz), .D(XLXN_1342), .Q(linebuf_wren));
    cb8re XLXI_19 (.C(inv_main_clock_16mhz), .CE(XLXN_1339), .R(reset_sprite_gen), .CEO(), .Q(control_reg_addr[7:0]), .TC());
    fdr XLXI_1 (.C(clk_in_16mhz), .D(XLXN_1337), .R(XLXN_5), .Q(XLXN_49));
    inv XLXI_379 (.I(clk_in_16mhz), .O(inv_main_clock_16mhz));
    or3 XLXI_399 (.I0(reset_sprite_gen), .I1(XLXN_1276), .I2(XLXN_1277), .O(XLXN_1158));
    and2 XLXI_403 (.I0(no_sprite_data), .I1(stage_two), .O(XLXN_1276));
    vcc XLXI_406 (.P(XLXN_1337));
    and2b1 XLXI_408 (.I0(XLXN_1397), .I1(XLXN_49), .O(XLXN_1339));
    and2b1 XLXI_409 (.I0(XLXN_1548), .I1(stage_two), .O(XLXN_1342));
    buf_x XLXI_410 [6:0] (.I(control_reg_addr[6:0]), .O(sprite_register_sel[6:0]));
    m2_1 XLXI_411 (.D0(control_reg_addr[7]), .D1(spr_reg_bank), .S0(spr_reg_mode), .O(sprite_register_sel[7]));
    and7 XLXI_412 (.I0(control_reg_addr[0]), .I1(control_reg_addr[1]), .I2(control_reg_addr[2]), .I3(control_reg_addr[3]), .I4(control_reg_addr[4]), .I5(control_reg_addr[5]), .I6(control_reg_addr[6]), .O(sprite_sixtythree));
    and2 XLXI_413 (.I0(XLXN_1370), .I1(sprite_sixtythree), .O(XLXN_1397));
    or2 XLXI_414 (.I0(control_reg_addr[7]), .I1(spr_reg_mode), .O(XLXN_1370));
    or2 XLXI_418 (.I0(XLXN_1397), .I1(last_16_cycles), .O(last_sprite));
    ramb4_s8_s16 XLXI_421 (.ADDRA(buf_write_addr_d[8:0]), .ADDRB(slb_read_addr[7:0]), .CLKA(clk_in_16mhz), .CLKB(clk_in_16mhz), .DIA(pixel_to_write[7:0]), .DIB(XLXN_1452[15:0]), .ENA(XLXN_1071), .ENB(XLXN_1495), .RSTA(XLXN_1053), .RSTB(XLXN_1053), .WEA(linebuf_wren_d), .WEB(slb_wr_zero_in), .DOA(), .DOB(sprlinebufa_out[15:0]));
    ramb4_s8_s16 XLXI_422 (.ADDRA(buf_write_addr_d[8:0]), .ADDRB(slb_read_addr[7:0]), .CLKA(clk_in_16mhz), .CLKB(clk_in_16mhz), .DIA(pixel_to_write[7:0]), .DIB(XLXN_1452[15:0]), .ENA(XLXN_1076), .ENB(XLXN_1504), .RSTA(XLXN_1053), .RSTB(XLXN_1053), .WEA(linebuf_wren_d), .WEB(slb_wr_zero_in), .DOA(), .DOB(sprlinebufb_out[15:0]));
    gnd XLXI_427 [15:0] (.G(XLXN_1452[15:0]));
    and2b1 XLXI_430 (.I0(modified_linecount[0]), .I1(slb_access_enable), .O(XLXN_1495));
    and2 XLXI_432 (.I0(modified_linecount[0]), .I1(slb_access_enable), .O(XLXN_1504));
    or8 XLXI_423 (.I0(spr_pixel_data_in[7]), .I1(spr_pixel_data_in[6]), .I2(spr_pixel_data_in[5]), .I3(spr_pixel_data_in[4]), .I4(spr_pixel_data_in[3]), .I5(spr_pixel_data_in[2]), .I6(spr_pixel_data_in[1]), .I7(spr_pixel_data_in[0]), .O(source_pixel_or));
    or2 XLXI_440 (.I0(no_sprite_data), .I1(last_16_cycles), .O(XLXN_1548));
    or2 XLXI_466 (.I0(spr_pixel_data_in[6]), .I1(XLXN_1626), .O(pixel_to_write[6]));
    or2 XLXI_467 (.I0(spr_pixel_data_in[5]), .I1(XLXN_1626), .O(pixel_to_write[5]));
    or2 XLXI_468 (.I0(spr_pixel_data_in[4]), .I1(XLXN_1626), .O(pixel_to_write[4]));
    or2 XLXI_469 (.I0(spr_pixel_data_in[3]), .I1(XLXN_1626), .O(pixel_to_write[3]));
    or2 XLXI_470 (.I0(spr_pixel_data_in[2]), .I1(XLXN_1626), .O(pixel_to_write[2]));
    or2 XLXI_471 (.I0(spr_pixel_data_in[1]), .I1(XLXN_1626), .O(pixel_to_write[1]));
    or2 XLXI_472 (.I0(spr_pixel_data_in[0]), .I1(XLXN_1626), .O(pixel_to_write[0]));
    and3 XLXI_473 (.I0(source_pixel_or), .I1(height_c_d), .I2(spr_opt2), .O(XLXN_1626));
    xor2 XLXI_441 (.I0(XLXN_1564), .I1(sprix_idx_a), .O(spr_ext_sram_addr[0]));
    xor2 XLXI_442 (.I0(XLXN_1564), .I1(sprix_idx_b), .O(spr_ext_sram_addr[1]));
    xor2 XLXI_443 (.I0(XLXN_1564), .I1(sprix_idx_c), .O(spr_ext_sram_addr[2]));
    xor2 XLXI_444 (.I0(XLXN_1564), .I1(sprix_idx_d), .O(spr_ext_sram_addr[3]));
    fde XLXI_449 (.C(inv_main_clock_16mhz), .CE(xpos_latch_enable), .D(control_reg_output[11]), .Q(XLXN_1564));
    fde XLXI_516 (.C(inv_main_clock_16mhz), .CE(xpos_latch_enable), .D(control_reg_output[9]), .Q(spr_ypos[8]));
    fde XLXI_517 (.C(inv_main_clock_16mhz), .CE(xpos_latch_enable), .D(control_reg_output[10]), .Q(XLXN_1271));
    gnd XLXI_498 (.G(spr_height[4]));
    or2 XLXI_522 (.I0(height_a), .I1(height_is_zero), .O(spr_height[0]));
    or2 XLXI_523 (.I0(height_b), .I1(height_is_zero), .O(spr_height[1]));
    bufe16 XLXI_435 (.E(modified_linecount[0]), .I(sprlinebufb_out[15:0]), .O(selected_word_tb0[15:0]));
    buft16 XLXI_436 (.I(sprlinebufa_out[15:0]), .T(modified_linecount[0]), .O(selected_word_tb1[15:0]));
    fd8re XLXI_437 (.C(clk_in_16mhz), .CE(slb_byte_select), .D(selected_word[15:8]), .R(XLXN_1547), .Q(XLXN_1543[7:0]));
    selector_2x8 XLXI_438 (.input_a(XLXN_1543[7:0]), .input_b(selected_word[7:0]), .select_ab(slb_byte_select), .output_c(sprite_pixel[7:0]));
    gnd XLXI_439 (.G(XLXN_1547));
    nor2 XLXI_494 (.I0(height_b), .I1(height_a), .O(XLXN_1716));
    m2_1 XLXI_495 (.D0(XLXN_1776), .D1(XLXN_1716), .S0(spr_opt2), .O(spr_height[2]));
    or2 XLXI_521 (.I0(height_c), .I1(height_is_zero), .O(XLXN_1776));
    buf_x XLXI_812 (.I(vreg7bits[2]), .O(spr_reg_bank));
    buf_x XLXI_813 (.I(vreg7bits[3]), .O(spr_reg_mode));
    buf_x XLXI_772 (.I(vreg7bits[0]), .O(global_sprite_enable));
    buf_x XLXI_759 (.I(vreg7bits[1]), .O(spr_priority));
    buf_x XLXI_904 (.I(vreg7bits[4]), .O(spr_opt1));
    buf_x XLXI_905 (.I(vreg7bits[5]), .O(spr_opt2));
    gnd XLXI_894 (.G(XLXN_1962));
    fd8re XLXI_895 (.C(inv_cpu_wr_line), .CE(cpu_sel_spr_ctrl), .D(cpu_databus[7:0]), .R(XLXN_1962), .Q(vreg7bits[7:0]));
    buf_x XLXI_930 (.I(vreg7bits[6]), .O(spr_pri_option));
    inv XLXI_931 (.I(cpu_wr), .O(inv_cpu_wr_line));
    nor4 XLXI_519 (.I0(XLXN_1797), .I1(height_c), .I2(height_b), .I3(height_a), .O(XLXN_1846));
    and2b1 XLXI_582 (.I0(spr_opt2), .I1(XLXN_1846), .O(height_is_zero));
    or2 XLXI_520 (.I0(height_is_zero), .I1(XLXN_1797), .O(spr_height[3]));
    and2b1 XLXI_531 (.I0(spr_opt1), .I1(height_d), .O(XLXN_1797));
    inv XLXI_932 (.I(stage_two), .O(XLXN_1966));
    m2_1 XLXI_933 (.D0(spr_pixel_data_in[7]), .D1(height_d_d), .S0(XLXN_1973), .O(pixel_to_write[7]));
    and2 XLXI_934 (.I0(source_pixel_or), .I1(spr_opt1), .O(XLXN_1973));
    assign selected_word[0] = selected_word_tb0[0] | selected_word_tb1[0];
    assign selected_word[1] = selected_word_tb0[1] | selected_word_tb1[1];
    assign selected_word[2] = selected_word_tb0[2] | selected_word_tb1[2];
    assign selected_word[3] = selected_word_tb0[3] | selected_word_tb1[3];
    assign selected_word[4] = selected_word_tb0[4] | selected_word_tb1[4];
    assign selected_word[5] = selected_word_tb0[5] | selected_word_tb1[5];
    assign selected_word[6] = selected_word_tb0[6] | selected_word_tb1[6];
    assign selected_word[7] = selected_word_tb0[7] | selected_word_tb1[7];
    assign selected_word[8] = selected_word_tb0[8] | selected_word_tb1[8];
    assign selected_word[9] = selected_word_tb0[9] | selected_word_tb1[9];
    assign selected_word[10] = selected_word_tb0[10] | selected_word_tb1[10];
    assign selected_word[11] = selected_word_tb0[11] | selected_word_tb1[11];
    assign selected_word[12] = selected_word_tb0[12] | selected_word_tb1[12];
    assign selected_word[13] = selected_word_tb0[13] | selected_word_tb1[13];
    assign selected_word[14] = selected_word_tb0[14] | selected_word_tb1[14];
    assign selected_word[15] = selected_word_tb0[15] | selected_word_tb1[15];

endmodule
