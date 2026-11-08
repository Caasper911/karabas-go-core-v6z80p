// generated from osca_pal.sch
module osca_core (
    input  wire        clk_fast,    // 96 MHz: the palette write strobe can be as short as 3 of its ticks (31 ns), shorter than a 16 MHz cycle
    input  wire        dbg_fixpal,  // bring-up: 1 = the colour outputs come from a fixed palette (colour = ~index) instead of the palette RAM
    input  wire [8:0]  dbg_paddr,  // bring-up: palette probe address, and the two palette bytes there {zero_red BRAM, green_blue BRAM}
    output wire [15:0] dbg_pdata,
    output wire [1:0] dbg_pal,     // bring-up taps: {colour_select[8] (displayed palette page), palette_write_select (written palette page)}
    output wire [29:0] dbg_core,   // bring-up taps: {cpu_databus_in[7:0], palette clk (XLXN_2825), palette enables XLXN_7421 / XLXN_2828, background_pixel[7:0], ywindow, xwindow, rgb_oe, palette_index[7:0]}
    output wire [7:0] vram_wdata,
    output wire vram_wdata_oe,
    input wire [7:0] vram_rdata,
    input wire [7:0] vram_rdata2,
    output wire [18:0] linecop_pc_o,
    output wire [18:0] vram_addr_out,
    output wire [7:0] spr_wdata,
    output wire spr_wdata_oe,
    input wire [7:0] spr_rdata,
    output wire spr_ram_wr,
    output wire spr_ram_rd,
    output wire tv_sync,
    output wire horizontal_sync,
    output wire [16:0] spr_addrbus,
    output wire vram_rd,
    output wire z80_wait,
    output wire vram_wr,
    output wire sdc_cs,
    output wire sdc_pow,
    input wire joystick_data_in,
    output wire joystick_clock_out,
    output wire col_red_b,
    output wire col_red_a,
    output wire col_red_d,
    output wire col_red_c,
    output wire col_green_d,
    output wire col_green_c,
    output wire col_green_b,
    output wire col_green_a,
    output wire col_blue_d,
    output wire col_blue_c,
    output wire col_blue_b,
    output wire col_blue_a,
    input wire z80_busack,
    input wire clock_16mhz,
    output wire z80_busreq,
    input wire eeprom_data_in,
    input wire pic_link_rb7,
    output wire pic_link_rb1,
    output wire pic_link_ra5,
    output wire ps2_kb_data_out,
    output wire ps2_ms_data_out,
    output wire [7:0] z80_data_o,
    output wire z80_data_oe,
    input wire [7:0] z80_data_i,
    inout wire expansion_pin_b,
    inout wire expansion_pin_a,
    output wire z80_nmi,
    input wire jumper_nmi,
    input wire jumper_reset,
    input wire jumper_vga,
    output wire [15:0] z80_addr_o,
    input wire [15:0] z80_addr_i,
    output wire system_ram_a16,
    output wire system_ram_a15,
    output wire system_ram_a17,
    output wire system_ram_a18,
    output wire system_ram_a14,
    output wire z80_write_o,
    input wire z80_write_i,
    output wire z80_mreq_o,
    input wire z80_mreq_i,
    output wire z80_ioreq_o,
    input wire z80_ioreq_i,
    output wire z80_read_o,
    input wire z80_read_i,
    output wire system_ram_cs,
    output wire z80_clock,
    input wire z80_m1,
    output wire audio_left,
    output wire audio_right,
    output wire serial_tx_pin,
    input wire serial_rx_pin,
    output wire ps2_kb_clock_out,
    output wire ps2_ms_clock_out,
    input wire ps2_ms_data_in,
    input wire ps2_kb_data_in,
    input wire ps2_kb_clock_in,
    input wire ps2_ms_clock_in,
    output wire system_reset_out,
    output wire z80_int,
    input wire sdc_dout,
    output wire sdc_clk,
    output wire sdc_din
);

    wire all_dma_done;
    wire all_writes_to_vram;
    wire alt_write_bank;
    wire any_page_mode;
    wire [18:0] audio_addr;
    wire [15:0] audio_dma_addr;
    wire audio_dma_done;
    wire audio_irq_enable;
    wire audio_irq_flag;
    wire [7:0] background_pixel;
    wire baud_sel_a;
    wire baud_sel_b;
    wire blit_op_pending;
    wire blitter_busmaster;
    wire [7:0] blitter_data_out;
    wire blitter_reading;
    wire blitter_to_bus;
    wire [18:0] blitter_vram_addr;
    wire blitter_vram_read;
    wire blitter_vram_wr;
    wire blitter_zero_byte;
    wire bm_lbaddrincen;
    wire bm_lbwren;
    wire bm_linedone;
    wire [7:0] bm_pixel;
    wire [18:0] bm_vram_addr;
    wire buffered_rb7;
    wire cabhnzero;
    wire clk_31250hz;
    wire clock_16mhz_dist;
    wire clocked_reset;
    wire [8:0] colour_select;
    wire commence_dma_ops;
    wire copro_vram_access;
    wire [15:0] cpu_acc_spr_addr;
    wire [15:0] cpu_address_bus;
    wire [15:0] cpu_address_bus_tb0;
    wire [15:0] cpu_address_bus_tb1;
    wire cpu_busack;
    wire [7:0] cpu_databus_in;
    wire cpu_ioreq;
    wire cpu_mreq;
    wire cpu_read;
    wire cpu_sel_vreg_sprctrl;
    wire [4:0] cpu_sprite_bank;
    wire cpu_write;
    wire [18:0] cpus_vram_acc_addr;
    wire [5:0] cpus_vram_page;
    wire cpuvram_buscontrol;
    wire [7:0] data_for_cpu_multiplex;
    wire [7:0] data_for_cpu_multiplex_tb0;
    wire [7:0] data_for_cpu_multiplex_tb1;
    wire [7:0] data_for_cpu_multiplex_tb10;
    wire [7:0] data_for_cpu_multiplex_tb11;
    wire [7:0] data_for_cpu_multiplex_tb12;
    wire [7:0] data_for_cpu_multiplex_tb13;
    wire [7:0] data_for_cpu_multiplex_tb14;
    wire [7:0] data_for_cpu_multiplex_tb15;
    wire [7:0] data_for_cpu_multiplex_tb16;
    wire [7:0] data_for_cpu_multiplex_tb2;
    wire [7:0] data_for_cpu_multiplex_tb3;
    wire [7:0] data_for_cpu_multiplex_tb4;
    wire [7:0] data_for_cpu_multiplex_tb5;
    wire [7:0] data_for_cpu_multiplex_tb6;
    wire [7:0] data_for_cpu_multiplex_tb7;
    wire [7:0] data_for_cpu_multiplex_tb8;
    wire [7:0] data_for_cpu_multiplex_tb9;
    wire delayed_cpu_wr;
    wire disable_nmi;
    wire disable_reset;
    wire dualpf_en;
    wire eeprom_byte_rdy;
    wire [7:0] eeprom_data;
    wire exp_pin_a_dir;
    wire exp_pin_b_dir;
    wire [7:0] expansion_pins_in;
    wire extended_tile_mode;
    wire force_50hz_VGA;
    wire force_blit_wait;
    wire [7:0] green_blue;
    wire hi_res_mode;
    wire [3:0] high_bank;
    wire [15:0] incoming_cpu_address;
    wire init_gfx_line_build;
    wire interlace_mode;
    wire [5:0] joystick_bits;
    wire joystick_select;
    wire keyboard_clock_in;
    wire [7:0] keyboard_data;
    wire keyboard_data_in;
    wire keyboard_irq_enable;
    wire keyboard_irq_flag;
    wire last_sixteen_clocks;
    wire last_sprite;
    wire latchyhws_a;
    wire latchyhws_b;
    wire [8:0] lb_build_addr;
    wire legacy_master_irq_en;
    wire legacy_video_irq_en;
    wire [8:0] line_count;
    wire linebuild_done;
    wire [18:0] linecop_addr;
    wire linecop_busy;
    wire [18:0] linecop_pc;
    wire [15:0] linecop_reg_addr;
    wire linecop_wr;
    wire [18:0] linedraw_addr;
    wire linedraw_busmaster;
    wire [7:0] linedraw_colour;
    wire linedraw_op_pending;
    wire linedraw_to_bus;
    wire linedraw_wr;
    wire linegen_go;
    wire live_palette;
    wire longframe;
    wire loram_selected_000_7ff;
    wire [3:0] low_bank;
    wire main_counter_tc;
    wire maths_table_selected_600_7ff;
    wire maths_wr;
    wire [7:0] modified_palette_index;
    wire mouse_clock_in;
    wire [7:0] mouse_data;
    wire mouse_data_in;
    wire mouse_irq_enable;
    wire mouse_irq_flag;
    wire [15:0] mulres;
    wire non_dma_sysram_a15;
    wire non_dma_sysram_a16;
    wire non_dma_sysram_a17;
    wire non_dma_sysram_a18;
    wire non_dma_sysram_cs;
    wire one_shot;
    wire [7:0] outgoing_data_for_vram;
    wire [7:0] outgoing_data_for_vram_tb0;
    wire [7:0] outgoing_data_for_vram_tb1;
    wire [7:0] outgoing_data_for_vram_tb2;
    wire page_in_sprite_bank;
    wire page_in_video_bank;
    wire [7:0] palette_index;
    wire palette_selected_000_1ff;
    wire [8:0] palette_wr_addr;
    wire palette_write_select;
    wire pfabanksel;
    wire pfabmbufsel;
    wire pfbbanksel;
    wire pfbbufsel;
    wire playfield;
    wire port_0_selected;
    wire [7:0] port_0_values;
    wire [7:0] port_1_outputs;
    wire port_1_selected;
    wire [7:0] port_1_values;
    wire port_20_selected;
    wire port_21_selected;
    wire port_22_selected;
    wire port_24_27_selected;
    wire port_28_selected;
    wire port_29_selected;
    wire port_2_selected;
    wire port_2a_selected;
    wire [7:0] port_3_outputs;
    wire port_3_selected;
    wire port_4_selected;
    wire port_5_selected;
    wire [7:0] port_5_values;
    wire port_6_selected;
    wire port_7_selected;
    wire port_8_selected;
    wire [7:0] port_8_values;
    wire port_9_selected;
    wire [7:0] port_9_values;
    wire port_a_selected;
    wire [7:0] port_b_bits;
    wire port_b_selected;
    wire port_c_selected;
    wire port_d_selected;
    wire port_e_selected;
    wire port_f_selected;
    wire raster_line_match;
    wire [7:0] received_serial_byte;
    wire [7:0] received_spi_byte;
    wire reset_req;
    wire rgb_oe;
    wire [7:0] dbg_pd0, dbg_pd1;
    wire right_border_stop;
    wire rom_selected;
    wire scale_range_sel;
    wire scanline_first_cycle;
    wire scanline_tc;
    wire serial_byte_rec_flag;
    wire serial_irq_enable;
    wire serial_out_busy;
    wire [7:0] slb_addr;
    wire slb_blkram_en;
    wire slb_latch_byte_select;
    wire slb_zero_wr_en;
    wire spi_busy;
    wire spi_clock_out;
    wire spi_data_enable;
    wire spi_speed;
    wire [16:0] spr_hw_addrbus;
    wire spr_ram_write_enable;
    wire spr_regs_selected_400_5ff;
    wire [16:0] spraddr;
    wire [15:0] spraddr_tb0;
    wire spraddr_tb1;
    wire [15:0] spraddr_tb2;
    wire spraddr_tb3;
    wire sprite_cpu_wait;
    wire sprite_enable;
    wire [7:0] sprite_pixel;
    wire sprite_priority_mode;
    wire sprite_priority_option;
    wire sprite_system_busy;
    wire [7:0] sprpixel_data_in;
    wire start_linecop;
    wire switch_tile_priority;
    wire sys_ports_selected;
    wire sys_reset;
    wire sysram_at_000_1ff;
    wire sysram_at_200_7ff;
    wire tilemap_mode;
    wire timer_irq_enable;
    wire timer_irq_flag;
    wire [7:0] timer_reload_value;
    wire tm_latchdest;
    wire tm_lbaddrincen;
    wire tm_lbwren;
    wire tm_linedone;
    wire [18:0] tm_vram_addr;
    wire vga_first_scanline_tc;
    wire vga_mode;
    wire video_enable;
    wire video_irq_enable;
    wire video_line;
    wire video_ram_selected;
    wire [7:0] video_status_flags;
    wire videosys_to_cpu_databus_en;
    wire vidsys_cpu_wait;
    wire vidsys_or_cpu_reading;
    wire [7:0] vram_databus_input;
    wire [2:0] vram_location;
    wire vreg_reading;
    wire vregs_selected_200_3ff;
    wire vrt_line;
    wire wide_border;
    wire wr_palette_rd_sysram;
    wire [3:0] write_bank;
    wire [3:0] xhws;
    wire XLXN_10097;
    wire XLXN_10150;
    wire XLXN_10151;
    wire XLXN_10191;
    wire XLXN_10198;
    wire XLXN_10293;
    wire XLXN_10312;
    wire XLXN_10314;
    wire XLXN_10315;
    wire XLXN_10316;
    wire XLXN_10526;
    wire XLXN_10553;
    wire XLXN_10568;
    wire XLXN_10569;
    wire XLXN_10577;
    wire XLXN_10660;
    wire XLXN_10664;
    wire XLXN_10851;
    wire XLXN_10852;
    wire XLXN_10855;
    wire XLXN_10856;
    wire XLXN_10900;
    wire XLXN_10905;
    wire XLXN_10906;
    wire XLXN_10907;
    wire XLXN_10908;
    wire XLXN_10921;
    wire XLXN_10922;
    wire [7:0] XLXN_1708;
    wire XLXN_1711;
    wire [7:0] XLXN_1719;
    wire XLXN_1723;
    wire XLXN_2337;
    wire XLXN_2458;
    wire XLXN_2500;
    wire XLXN_2501;
    wire XLXN_2527;
    wire XLXN_2593;
    wire XLXN_2602;
    wire XLXN_2603;
    wire XLXN_2606;
    wire XLXN_2616;
    wire XLXN_2617;
    wire XLXN_2788;
    wire XLXN_2792;
    wire XLXN_2809;
    wire XLXN_2825;
    wire XLXN_2828;
    wire XLXN_2888;
    wire XLXN_2890;
    wire XLXN_2982;
    wire XLXN_2998;
    wire XLXN_3165;
    wire XLXN_3221;
    wire XLXN_3233;
    wire XLXN_3572;
    wire XLXN_3686;
    wire XLXN_3765;
    wire XLXN_3767;
    wire XLXN_3813;
    wire XLXN_3814;
    wire XLXN_4167;
    wire XLXN_4171;
    wire XLXN_4435;
    wire XLXN_4808;
    wire XLXN_4828;
    wire XLXN_4866;
    wire XLXN_4869;
    wire XLXN_4871;
    wire XLXN_4880;
    wire XLXN_4881;
    wire XLXN_4887;
    wire XLXN_4888;
    wire XLXN_4959;
    wire XLXN_5002;
    wire XLXN_5003;
    wire XLXN_5004;
    wire XLXN_5105;
    wire XLXN_5108;
    wire XLXN_5309;
    wire XLXN_5327;
    wire XLXN_5429;
    wire XLXN_5434;
    wire XLXN_5507;
    wire XLXN_5599;
    wire XLXN_5609;
    wire XLXN_5639;
    wire XLXN_5663;
    wire XLXN_5673;
    wire XLXN_5795;
    wire XLXN_5838;
    wire XLXN_5839;
    wire XLXN_5865;
    wire XLXN_5868;
    wire XLXN_5921;
    wire XLXN_5978;
    wire XLXN_5980;
    wire XLXN_5981;
    wire XLXN_5983;
    wire XLXN_5985;
    wire XLXN_5986;
    wire XLXN_6166;
    wire XLXN_6167;
    wire XLXN_6186;
    wire XLXN_6193;
    wire XLXN_6295;
    wire XLXN_6296;
    wire XLXN_6299;
    wire XLXN_6309;
    wire XLXN_6347;
    wire XLXN_6421;
    wire XLXN_6506;
    wire XLXN_6507;
    wire XLXN_6538;
    wire XLXN_6541;
    wire [18:0] XLXN_6544;
    wire [18:0] XLXN_6544_tb0;
    wire [18:0] XLXN_6544_tb1;
    wire [18:0] XLXN_6544_tb2;
    wire [18:0] XLXN_6544_tb3;
    wire [18:0] XLXN_6544_tb4;
    wire XLXN_6706;
    wire XLXN_6711;
    wire XLXN_6790;
    wire XLXN_6849;
    wire XLXN_6916;
    wire XLXN_6993;
    wire [15:0] XLXN_7011;
    wire [15:0] XLXN_7011_tb0;
    wire [15:0] XLXN_7011_tb1;
    wire XLXN_7051;
    wire XLXN_7132;
    wire XLXN_7332;
    wire XLXN_7395;
    wire XLXN_7396;
    wire XLXN_7421;
    wire XLXN_7427;
    wire [7:0] XLXN_7651;
    wire XLXN_7676;
    wire XLXN_7677;
    wire XLXN_7712;
    wire XLXN_7726;
    wire XLXN_7727;
    wire XLXN_7846;
    wire XLXN_7851;
    wire XLXN_7852;
    wire XLXN_7941;
    wire XLXN_7973;
    wire XLXN_8010;
    wire XLXN_8067;
    wire XLXN_8086;
    wire XLXN_8087;
    wire XLXN_8106;
    wire XLXN_8153;
    wire XLXN_8179;
    wire XLXN_8185;
    wire XLXN_8271;
    wire XLXN_8273;
    wire XLXN_8308;
    wire XLXN_8522;
    wire XLXN_8547;
    wire XLXN_8550;
    wire XLXN_8594;
    wire XLXN_8599;
    wire XLXN_8779;
    wire XLXN_8990;
    wire XLXN_8992;
    wire XLXN_9400;
    wire XLXN_9401;
    wire XLXN_9402;
    wire XLXN_9540;
    wire XLXN_9598;
    wire XLXN_9656;
    wire XLXN_9663;
    wire XLXN_9666;
    wire XLXN_9668;
    wire XLXN_9681;
    wire XLXN_9732;
    wire XLXN_9819;
    wire XLXN_9885;
    wire [3:0] xstart_coarse;
    wire [3:0] xstop_coarse;
    wire xwindow;
    wire [7:0] y_window_pos;
    wire [3:0] yhws_a;
    wire [3:0] yhws_b;
    wire ywindow;
    wire [7:0] zero_red;

    buft8 XLXI_873 (.I(cpu_databus_in[7:0]), .T(copro_vram_access), .O(outgoing_data_for_vram_tb0[7:0]));
    assign vram_wdata = outgoing_data_for_vram[7:0];
    assign vram_wdata_oe = ~XLXN_2593;
    assign vram_databus_input[7:0] = vram_rdata;
    or2 XLXI_904 (.I0(vidsys_or_cpu_reading), .I1(blitter_reading), .O(XLXN_2593));
    or2b1 XLXI_746 (.I0(tilemap_mode), .I1(XLXN_2606), .O(XLXN_2602));
    or2 XLXI_745 (.I0(XLXN_2606), .I1(tilemap_mode), .O(XLXN_2603));
    inv XLXI_747 (.I(cpuvram_buscontrol), .O(XLXN_2606));
    buf_x XLXI_760 [12:0] (.I(cpu_address_bus[12:0]), .O(cpus_vram_acc_addr[12:0]));
    obuf XLXI_761 [18:0] (.I(XLXN_6544[18:0]), .O(vram_addr_out[18:0]));
    bufe16 XLXI_821 (.E(sprite_system_busy), .I(spr_hw_addrbus[15:0]), .O(spraddr_tb0[15:0]));
    bufe XLXI_822 (.E(sprite_system_busy), .I(spr_hw_addrbus[16]), .O(spraddr_tb1));
    buft16 XLXI_823 (.I(cpu_acc_spr_addr[15:0]), .T(sprite_system_busy), .O(spraddr_tb2[15:0]));
    buft XLXI_824 (.I(cpu_sprite_bank[4]), .T(sprite_system_busy), .O(spraddr_tb3));
    fdrs XLXI_955 (.C(clock_16mhz_dist), .D(XLXN_2792), .R(sprite_system_busy), .S(XLXN_3233), .Q(XLXN_2792));
    fdrs XLXI_1105 (.C(clock_16mhz_dist), .D(sprite_system_busy), .R(XLXN_2809), .S(XLXN_2788), .Q(sprite_system_busy));
    and2 XLXI_957 (.I0(spr_ram_write_enable), .I1(XLXN_2792), .O(XLXN_2788));
    fd XLXI_958 (.C(clock_16mhz_dist), .D(sprite_system_busy), .Q(XLXN_2890));
    or2 XLXI_967 (.I0(last_sprite), .I1(init_gfx_line_build), .O(XLXN_2809));
    inv XLXI_850 (.I(sprite_system_busy), .O(XLXN_4887));
    assign spr_wdata = cpu_databus_in[7:0];
    assign spr_wdata_oe = ~sprite_system_busy;
    buf_x XLXI_825 [11:0] (.I(cpu_address_bus[11:0]), .O(cpu_acc_spr_addr[11:0]));
    buf_x XLXI_826 [3:0] (.I(cpu_sprite_bank[3:0]), .O(cpu_acc_spr_addr[15:12]));
    or2b1 XLXI_1151 (.I0(XLXN_2888), .I1(spr_ram_write_enable), .O(sprite_cpu_wait));
    or3 XLXI_1152 (.I0(XLXN_2888), .I1(cpu_write), .I2(spr_ram_write_enable), .O(XLXN_4888));
    or2 XLXI_1150 (.I0(sprite_system_busy), .I1(XLXN_2890), .O(XLXN_2888));
    and3 XLXI_1274 (.I0(sprite_enable), .I1(init_gfx_line_build), .I2(ywindow), .O(XLXN_3233));
    assign sprpixel_data_in[7:0] = spr_rdata;
    pal_vga_slb_timing XLXI_1663 (.blkram_en(slb_blkram_en), .clock_16mhz(clock_16mhz_dist), .latch_en_byte_select(slb_latch_byte_select), .scanline_tc(scanline_tc), .slb_word_address(slb_addr[7:0]), .vga_mode(vga_mode), .vga_scanline_tc(vga_first_scanline_tc), .zero_wr_en(slb_zero_wr_en));
    obuf XLXI_1754 (.I(XLXN_4887), .O(spr_ram_rd));
    obuf XLXI_1755 (.I(XLXN_4888), .O(spr_ram_wr));
    obuf XLXI_1756 (.I(XLXN_5429), .O(tv_sync));
    obuf XLXI_1757 (.I(XLXN_7941), .O(horizontal_sync));
    obuf XLXI_1772 [16:0] (.I(spraddr[16:0]), .O(spr_addrbus[16:0]));
    or2 XLXI_946 (.I0(copro_vram_access), .I1(cpuvram_buscontrol), .O(XLXN_2616));
    and2 XLXI_954 (.I0(video_enable), .I1(ywindow), .O(video_line));
    and2 XLXI_865 (.I0(XLXN_3686), .I1(blitter_vram_read), .O(XLXN_4881));
    and2 XLXI_1068 (.I0(sprite_cpu_wait), .I1(vidsys_cpu_wait), .O(XLXN_4880));
    obuf XLXI_1752 (.I(XLXN_4881), .O(vram_rd));
    obuf XLXI_1753 (.I(XLXN_4880), .O(z80_wait));
    vga_pal_y_window3 XLXI_1961 (.clock_in(clock_16mhz_dist), .line_count(line_count[8:3]), .scanline_tc_in(scanline_tc), .start_coarse(y_window_pos[7:4]), .stop_coarse(y_window_pos[3:0]), .vrtline(vrt_line), .ywindow_out(ywindow));
    or2 XLXI_1974 (.I0(XLXN_5639), .I1(cpu_write), .O(XLXN_5507));
    inv XLXI_792 (.I(spr_regs_selected_400_5ff), .O(XLXN_8010));
    obuf XLXI_1751 (.I(XLXN_5868), .O(vram_wr));
    and3 XLXI_2051 (.I0(XLXN_5507), .I1(blitter_vram_wr), .I2(linedraw_wr), .O(XLXN_5868));
    or2 XLXI_2052 (.I0(blitter_busmaster), .I1(linedraw_busmaster), .O(copro_vram_access));
    buft8 XLXI_2065 (.I(blitter_data_out[7:0]), .T(blitter_to_bus), .O(outgoing_data_for_vram_tb1[7:0]));
    buft8 XLXI_2066 (.I(linedraw_colour[7:0]), .T(linedraw_to_bus), .O(outgoing_data_for_vram_tb2[7:0]));
    or2 XLXI_2067 (.I0(blitter_to_bus), .I1(cpuvram_buscontrol), .O(XLXN_2617));
    or2 XLXI_2068 (.I0(linedraw_to_bus), .I1(cpuvram_buscontrol), .O(XLXN_5921));
    or2b1 XLXI_2073 (.I0(linedraw_busmaster), .I1(blitter_busmaster), .O(linedraw_to_bus));
    or2 XLXI_2075 (.I0(linedraw_busmaster), .I1(blitter_busmaster), .O(XLXN_8308));
    wire clk16_n_w;
    wire ce_blt_q;
    inv XLXI_9001 (.I(clock_16mhz_dist), .O(clk16_n_w));
    fd XLXI_9002 (.C(clock_16mhz_dist), .D(XLXN_3767), .Q(ce_blt_q));
    fd8re XLXI_1428 (.C(clk16_n_w), .CE(ce_blt_q), .D(vram_rdata2[7:0]), .R(XLXN_3765), .Q(blitter_data_out[7:0]));
    inv XLXI_1987 (.I(XLXN_5599), .O(XLXN_4959));
    or3b1 XLXI_2038 (.I0(cpu_address_bus[4]), .I1(cpu_address_bus[5]), .I2(XLXN_5795), .O(XLXN_5599));
    gnd XLXI_1429 (.G(XLXN_3765));
    inv XLXI_2041 (.I(XLXN_5838), .O(XLXN_5839));
    or2b1 XLXI_2078 (.I0(cpu_address_bus[5]), .I1(XLXN_5795), .O(XLXN_5838));
    fd8re XLXI_2089 (.C(XLXN_5978), .CE(XLXN_5980), .D(cpu_databus_in[7:0]), .R(XLXN_5981), .Q(linedraw_colour[7:0]));
    inv XLXI_2090 (.I(cpu_write), .O(XLXN_5978));
    gnd XLXI_2091 (.G(XLXN_5981));
    inv XLXI_2093 (.I(cpu_address_bus[0]), .O(XLXN_5986));
    inv XLXI_2094 (.I(cpu_address_bus[1]), .O(XLXN_5985));
    inv XLXI_2095 (.I(cpu_address_bus[3]), .O(XLXN_5983));
    nor7 XLXI_2104 (.I0(XLXN_5986), .I1(XLXN_5985), .I2(cpu_address_bus[2]), .I3(XLXN_5983), .I4(cpu_address_bus[4]), .I5(cpu_address_bus[5]), .I6(XLXN_5795), .O(XLXN_5980));
    nor8 XLXI_2105 (.I0(blitter_data_out[0]), .I1(blitter_data_out[1]), .I2(blitter_data_out[2]), .I3(blitter_data_out[3]), .I4(blitter_data_out[4]), .I5(blitter_data_out[5]), .I6(blitter_data_out[6]), .I7(blitter_data_out[7]), .O(blitter_zero_byte));
    and2 XLXI_1430 (.I0(blitter_busmaster), .I1(blitter_reading), .O(XLXN_3767));
    buf_x XLXI_2109 [2:0] (.I(cpus_vram_page[5:3]), .O(cpus_vram_acc_addr[18:16]));
    selector_2x3 XLXI_2111 (.input_a(cpus_vram_page[2:0]), .input_b(cpu_address_bus[15:13]), .output_c(cpus_vram_acc_addr[15:13]), .select_ab(all_writes_to_vram));
    fdce XLXI_969 (.C(clock_16mhz_dist), .CE(XLXN_2501), .CLR(XLXN_2337), .D(XLXN_2500), .Q(timer_irq_flag));
    vcc XLXI_1042 (.P(XLXN_2500));
    and3b1 XLXI_1511 (.I0(cpu_write), .I1(cpu_databus_in[2]), .I2(port_2_selected), .O(XLXN_2337));
    vcc XLXI_1632 (.P(XLXN_4171));
    cb8re XLXI_2174 (.C(clock_16mhz_dist), .CE(XLXN_4171), .R(XLXN_6193), .CEO(XLXN_4167), .Q(), .TC());
    cb8cle XLXI_966 (.C(clock_16mhz_dist), .CE(XLXN_4167), .CLR(XLXN_6167), .D(timer_reload_value[7:0]), .L(XLXN_6166), .CEO(XLXN_2501), .Q(), .TC());
    or2 XLXI_2175 (.I0(XLXN_2501), .I1(XLXN_6193), .O(XLXN_6166));
    gnd XLXI_2176 (.G(XLXN_6167));
    fd XLXI_2187 (.C(clock_16mhz_dist), .D(XLXN_6186), .Q(XLXN_6193));
    fdc XLXI_2186 (.C(delayed_cpu_wr), .CLR(XLXN_6193), .D(port_7_selected), .Q(XLXN_6186));
    buft19 XLXI_2373 (.enable_lo(XLXN_2603), .in_bus(bm_vram_addr[18:0]), .out_bus(XLXN_6544_tb0[18:0]));
    buft19 XLXI_2374 (.enable_lo(XLXN_2602), .in_bus(tm_vram_addr[18:0]), .out_bus(XLXN_6544_tb1[18:0]));
    buft19 XLXI_2375 (.enable_lo(XLXN_2616), .in_bus(cpus_vram_acc_addr[18:0]), .out_bus(XLXN_6544_tb2[18:0]));
    buft19 XLXI_2376 (.enable_lo(XLXN_2617), .in_bus(blitter_vram_addr[18:0]), .out_bus(XLXN_6544_tb3[18:0]));
    buft19 XLXI_2377 (.enable_lo(XLXN_5921), .in_bus(linedraw_addr[18:0]), .out_bus(XLXN_6544_tb4[18:0]));
    blitter_601 XLXI_2378 (.blit_bus_master(blitter_busmaster), .blit_pending(blit_op_pending), .blit_reg_range_selected(XLXN_4959), .clock_in(clock_16mhz_dist), .cpu_addr(cpu_address_bus[3:0]), .cpu_databus_in(cpu_databus_in[7:0]), .cpu_wr(cpu_write), .databyte_zero(blitter_zero_byte), .pause_blit(force_blit_wait), .read_phase(blitter_reading), .vram_addr(blitter_vram_addr[18:0]), .vram_read(blitter_vram_read), .vram_write(blitter_vram_wr));
    line_draw_600 XLXI_2379 (.dev_selected(XLXN_5839), .addr_bus(cpu_address_bus[4:0]), .cpu_databus(cpu_databus_in[7:0]), .vram_datafetch(force_blit_wait), .main_clock(clock_16mhz_dist), .cpu_write(cpu_write), .ld_has_bus(linedraw_busmaster), .ld_pending(linedraw_op_pending), .vram_addr(linedraw_addr[18:0]), .vram_wr(linedraw_wr));
    fde #(.INIT(1'b0)) XLXI_2266 (.C(delayed_cpu_wr), .CE(port_9_selected), .D(cpu_databus_in[3]), .Q(force_50hz_VGA));
    fde #(.INIT(1'b0)) XLXI_2395 (.C(delayed_cpu_wr), .CE(port_5_selected), .D(cpu_databus_in[6]), .Q(spi_data_enable));
    fde #(.INIT(1'b0)) XLXI_2396 (.C(delayed_cpu_wr), .CE(port_5_selected), .D(cpu_databus_in[7]), .Q(spi_speed));
    gnd XLXI_2412 [1:0] (.G(expansion_pins_in[5:4]));
    fdce XLXI_1177 (.C(clock_16mhz_dist), .CE(main_counter_tc), .CLR(XLXN_2998), .D(XLXN_2982), .Q(clk_31250hz));
    inv XLXI_1179 (.I(clk_31250hz), .O(XLXN_2982));
    gnd XLXI_1180 (.G(XLXN_2998));
    serjoy2 XLXI_1187 (.bit_a_out(joystick_bits[0]), .bit_b_out(joystick_bits[1]), .bit_c_out(joystick_bits[2]), .bit_d_out(joystick_bits[3]), .bit_e_out(joystick_bits[4]), .bit_f_out(joystick_bits[5]), .joy_sel_rd(joystick_select), .PIC_clk_out(XLXN_4869), .PIC_joy_data_in(XLXN_4866), .slow_clock(clk_31250hz));
    ibuf XLXI_1725 (.I(joystick_data_in), .O(XLXN_4866));
    obuf XLXI_1748 (.I(XLXN_4869), .O(joystick_clock_out));
    fde #(.INIT(1'b1)) XLXI_2421 (.C(delayed_cpu_wr), .CE(port_6_selected), .D(cpu_databus_in[2]), .Q(sdc_cs));
    fde #(.INIT(1'b1)) XLXI_2422 (.C(delayed_cpu_wr), .CE(port_6_selected), .D(cpu_databus_in[3]), .Q(sdc_pow));
    comp4 XLXI_2455 (.A0(xstop_coarse[0]), .A1(xstop_coarse[1]), .A2(xstop_coarse[2]), .A3(xstop_coarse[3]), .B0(lb_build_addr[4]), .B1(lb_build_addr[5]), .B2(lb_build_addr[6]), .B3(lb_build_addr[7]), .EQ(XLXN_6790));
    and2 XLXI_2459 (.I0(lb_build_addr[8]), .I1(XLXN_6790), .O(right_border_stop));
    buf_x XLXI_2624 (.I(live_palette), .O(colour_select[8]));
    buf_x XLXI_2623 [7:0] (.I(modified_palette_index[7:0]), .O(colour_select[7:0]));
    // fixed palette for the bring-up test: same pipeline position as the palette RAM output (registered, cleared outside rgb_oe like its RSTB)
    reg [7:0] fx_gb = 8'd0, fx_red = 8'd0;
    always @(posedge clock_16mhz_dist) begin
        // index mod 8: grey, red, green, blue, yellow, magenta, cyan, white (as {red, green, blue} nibbles)
        case (colour_select[2:0])
            3'd0: begin fx_red <= 8'h04; fx_gb <= 8'h44; end
            3'd1: begin fx_red <= 8'h0f; fx_gb <= 8'h00; end
            3'd2: begin fx_red <= 8'h00; fx_gb <= 8'hf0; end
            3'd3: begin fx_red <= 8'h00; fx_gb <= 8'h0f; end
            3'd4: begin fx_red <= 8'h0f; fx_gb <= 8'hf0; end
            3'd5: begin fx_red <= 8'h0f; fx_gb <= 8'h0f; end
            3'd6: begin fx_red <= 8'h00; fx_gb <= 8'hff; end
            default: begin fx_red <= 8'h0f; fx_gb <= 8'hff; end
        endcase
        if (!rgb_oe) begin fx_red <= 8'h00; fx_gb <= 8'h00; end
    end
    wire [7:0] gb_ram, zr_ram;
    assign green_blue = dbg_fixpal ? fx_gb  : gb_ram;
    assign zero_red   = dbg_fixpal ? fx_red : zr_ram;
    // Palette write, synchronous on the 96 MHz clock (bring-up fix for the board).  The original clocks the palette RAM with the INVERTED cpu_write (the write is done at
    // the end of the strobe); on the FPGA that clock arrives later than the address / data, which change at the same clk16 edge, so the entry was not stored.  The strobe is
    // 3..9 ticks of 96 MHz wide.  Address, data and byte enables are pipelined every tick; when the strobe has ended the values from two ticks before its end are written.
    reg [8:0] pal_a1 = 9'd0, pal_a2 = 9'd0, pal_a_q = 9'd0;  reg [7:0] pal_d1 = 8'd0, pal_d2 = 8'd0, pal_d_q = 8'd0;
    reg pal_x1 = 1'b0, pal_x2 = 1'b0, pal_x_q = 1'b0, pal_y1 = 1'b0, pal_y2 = 1'b0, pal_y_q = 1'b0, pal_w1 = 1'b0, pal_w2 = 1'b0;
    always @(posedge clk_fast) begin
        pal_w1 <= cpu_write;  pal_w2 <= pal_w1;
        pal_a1 <= palette_wr_addr[8:0];  pal_a2 <= pal_a1;  pal_a_q <= pal_a2;
        pal_d1 <= cpu_databus_in[7:0];   pal_d2 <= pal_d1;  pal_d_q <= pal_d2;
        pal_x1 <= XLXN_2828;  pal_x2 <= pal_x1;  pal_x_q <= pal_x2;
        pal_y1 <= XLXN_7421;  pal_y2 <= pal_y1;  pal_y_q <= pal_y2;
    end
    wire pal_fall = pal_w2 & ~pal_w1;                      // the strobe was seen high two ticks ago and low one tick ago
    wire pal_en0 = pal_fall & pal_x_q;
    wire pal_en1 = pal_fall & pal_y_q;
    ramb4_s8_s8 XLXI_2620 (.ADDRC(dbg_paddr), .DOC(dbg_pd0), .ADDRA(pal_a_q[8:0]), .ADDRB(colour_select[8:0]), .CLKA(clk_fast), .CLKB(clock_16mhz_dist), .DIA(pal_d_q[7:0]), .DIB(XLXN_7651[7:0]), .ENA(pal_en0), .ENB(XLXN_7396), .RSTA(XLXN_7427), .RSTB(XLXN_7395), .WEA(XLXN_7396), .WEB(XLXN_7427), .DOA(), .DOB(gb_ram[7:0]));
    ramb4_s8_s8 XLXI_2621 (.ADDRC(dbg_paddr), .DOC(dbg_pd1), .ADDRA(pal_a_q[8:0]), .ADDRB(colour_select[8:0]), .CLKA(clk_fast), .CLKB(clock_16mhz_dist), .DIA(pal_d_q[7:0]), .DIB(XLXN_7651[7:0]), .ENA(pal_en1), .ENB(XLXN_7396), .RSTA(XLXN_7427), .RSTB(XLXN_7395), .WEA(XLXN_7396), .WEB(XLXN_7427), .DOA(), .DOB(zr_ram[7:0]));
    gnd XLXI_374 [7:0] (.G(XLXN_7651[7:0]));
    buf_x XLXI_2629 [7:0] (.I(cpu_address_bus[8:1]), .O(palette_wr_addr[7:0]));
    inv XLXI_413 (.I(cpu_write), .O(XLXN_2825));
    inv XLXI_2436 (.I(rgb_oe), .O(XLXN_7395));
    vcc XLXI_377 (.P(XLXN_7396));
    gnd XLXI_376 (.G(XLXN_7427));
    buf_x XLXI_2648 (.I(palette_write_select), .O(palette_wr_addr[8]));
    obuf XLXI_1768 (.I(zero_red[2]), .O(col_red_b));
    obuf XLXI_1769 (.I(zero_red[3]), .O(col_red_a));
    obuf XLXI_1766 (.I(zero_red[0]), .O(col_red_d));
    obuf XLXI_1767 (.I(zero_red[1]), .O(col_red_c));
    obuf XLXI_1762 (.I(green_blue[4]), .O(col_green_d));
    obuf XLXI_1763 (.I(green_blue[5]), .O(col_green_c));
    obuf XLXI_1764 (.I(green_blue[6]), .O(col_green_b));
    obuf XLXI_1765 (.I(green_blue[7]), .O(col_green_a));
    obuf XLXI_1758 (.I(green_blue[0]), .O(col_blue_d));
    obuf XLXI_1759 (.I(green_blue[1]), .O(col_blue_c));
    obuf XLXI_1760 (.I(green_blue[2]), .O(col_blue_b));
    obuf XLXI_1761 (.I(green_blue[3]), .O(col_blue_a));
    or2b1 XLXI_2693 (.I0(blitter_busmaster), .I1(linedraw_busmaster), .O(blitter_to_bus));
    buf_x XLXI_1888 (.I(xwindow), .O(video_status_flags[1]));
    buf_x XLXI_1889 (.I(ywindow), .O(video_status_flags[2]));
    buf_x XLXI_1890 (.I(raster_line_match), .O(video_status_flags[3]));
    buf_x XLXI_1891 (.I(XLXN_5865), .O(video_status_flags[4]));
    buf_x XLXI_1892 (.I(XLXN_9681), .O(video_status_flags[5]));
    buf_x XLXI_1894 (.I(vrt_line), .O(video_status_flags[0]));
    buf_x XLXI_2156 (.I(line_count[0]), .O(video_status_flags[6]));
    or2 XLXI_2704 (.I0(tm_linedone), .I1(bm_linedone), .O(linebuild_done));
    fd XLXI_2705 (.C(clock_16mhz_dist), .D(scanline_tc), .Q(scanline_first_cycle));
    fdrs XLXI_2706 (.C(clock_16mhz_dist), .D(force_blit_wait), .R(XLXN_7712), .S(scanline_tc), .Q(force_blit_wait));
    fdrs XLXI_2707 (.C(clock_16mhz_dist), .D(one_shot), .R(XLXN_7852), .S(scanline_tc), .Q(one_shot));
    inv XLXI_1372 (.I(XLXN_7852), .O(XLXN_7846));
    obuf XLXI_1710 (.I(XLXN_7846), .O(z80_busreq));
    m2_1 XLXI_2723 (.D0(commence_dma_ops), .D1(linebuild_done), .S0(video_line), .O(XLXN_7712));
    ibuf XLXI_1778 (.I(z80_busack), .O(cpu_busack));
    ibufg XLXI_1403 (.I(clock_16mhz), .O(clock_16mhz_dist));
    inv XLXI_1373 (.I(cpu_busack), .O(XLXN_3572));
    buf_x XLXI_1407 (.I(commence_dma_ops), .O(init_gfx_line_build));
    and2b1 XLXI_2716 (.I0(XLXN_7727), .I1(XLXN_7726), .O(commence_dma_ops));
    fd XLXI_2714 (.C(clock_16mhz_dist), .D(XLXN_3572), .Q(XLXN_7726));
    fd XLXI_2715 (.C(clock_16mhz_dist), .D(XLXN_7726), .Q(XLXN_7727));
    fdrs XLXI_2752 (.C(clock_16mhz_dist), .D(XLXN_7852), .R(all_dma_done), .S(XLXN_7851), .Q(XLXN_7852));
    and3 XLXI_2755 (.I0(vidsys_cpu_wait), .I1(sys_reset), .I2(one_shot), .O(XLXN_7851));
    buf_x XLXI_2757 (.I(longframe), .O(video_status_flags[7]));
    fdrs XLXI_2487 (.C(clock_16mhz_dist), .D(XLXN_6849), .R(scanline_tc), .S(audio_dma_done), .Q(XLXN_6849));
    and2b1 XLXI_2486 (.I0(XLXN_6849), .I1(audio_dma_done), .O(start_linecop));
    and2b1 XLXI_2498 (.I0(linecop_busy), .I1(XLXN_6849), .O(XLXN_6916));
    fdrs XLXI_2497 (.C(clock_16mhz_dist), .D(all_dma_done), .R(scanline_tc), .S(XLXN_6916), .Q(all_dma_done));
    inv XLXI_1669 (.I(sprite_system_busy), .O(XLXN_4435));
    sprite_system513 XLXI_2849 (.clk_in_16mhz(clock_16mhz_dist), .cpu_databus(cpu_databus_in[7:0]), .cpu_sel_spr_ctrl(cpu_sel_vreg_sprctrl), .cpu_sprite_reg_sel(XLXN_8010), .cpu_wr(cpu_write), .global_sprite_enable(sprite_enable), .last_16_cycles(last_sixteen_clocks), .last_sprite(last_sprite), .modified_linecount(line_count[8:0]), .reset_sprite_gen(XLXN_4435), .slb_access_enable(slb_blkram_en), .slb_byte_select(slb_latch_byte_select), .slb_read_addr(slb_addr[7:0]), .slb_wr_zero_in(slb_zero_wr_en), .sprite_pixel(sprite_pixel[7:0]), .spr_pixel_data_in(sprpixel_data_in[7:0]), .spr_priority(sprite_priority_mode), .spr_pri_option(sprite_priority_option), .spr_reg_addr_in(cpu_address_bus[8:0]), .spr_sram_addr(spr_hw_addrbus[16:0]));
    or4 XLXI_2855 (.I0(cpu_address_bus[6]), .I1(cpu_address_bus[7]), .I2(cpu_address_bus[8]), .I3(vregs_selected_200_3ff), .O(XLXN_5795));
    and2b2 XLXI_2897 (.I0(cpu_address_bus[0]), .I1(palette_selected_000_1ff), .O(XLXN_2828));
    and2b1 XLXI_2898 (.I0(palette_selected_000_1ff), .I1(cpu_address_bus[0]), .O(XLXN_7421));
    ramb4_s8 #(.INIT_00(256'h3C02073200002207D321D303D308D301D320D30BD300D36F67AF0FFF3156EDF3), .INIT_01(256'h80060000220A00C300C902D3C804E601DB0518043E07D32818020132043E09D3), .INIT_02(256'h00000000000000000069C322D35A3EC90000226860F510FB28002FCD0029CDAF), .INIT_03(256'h365006023021F820B1780B2300360400010200210BD3AF0A03C3000000000000), .INIT_04(256'h3E0618210000010BD300D3AF02D3013E8C36020432043E5936020221FB102300), .INIT_05(256'h000000000000000000000000000000000000000000000000000000001010C301), .INIT_06(256'h0000000000000000000000000000000000000000000000000000000000000000), .INIT_07(256'h0000000000000000000000000000000000000000000000000000000000000000), .INIT_08(256'h0000000000000000000000000000000000000000000000000000000000000000), .INIT_09(256'h0000000000000000000000000000000000000000000000000000000000000000), .INIT_0A(256'h0000000000000000000000000000000000000000000000000000000000000000), .INIT_0B(256'h0000000000000000000000000000000000000000000000000000000000000000), .INIT_0C(256'h0000000000000000000000000000000000000000000000000000000000000000), .INIT_0D(256'h0000000000000000000000000000000000000000000000000000000000000000), .INIT_0E(256'h0000000000000000000000000000000000000000000000000000000000000000), .INIT_0F(256'h0000000000000000000000000000000000000000000000000000000000000000)) ROM_data_a (.ADDR(cpu_address_bus[8:0]), .CLK(XLXN_5434), .DI(XLXN_1708[7:0]), .EN(XLXN_1723), .RST(XLXN_1711), .WE(XLXN_1711), .DO(XLXN_1719[7:0]));
    vcc XLXI_737 (.P(XLXN_1723));
    inv XLXI_1962 (.I(cpu_read), .O(XLXN_5434));
    gnd XLXI_736 (.G(XLXN_1711));
    gnd XLXI_735 [7:0] (.G(XLXN_1708[7:0]));
    buft8 XLXI_2265 (.I(XLXN_1719[7:0]), .T(rom_selected), .O(data_for_cpu_multiplex_tb0[7:0]));
    or3b1 XLXI_1986 (.I0(cpu_address_bus[10]), .I1(cpu_address_bus[9]), .I2(XLXN_8185), .O(spr_regs_selected_400_5ff));
    or3b2 XLXI_2916 (.I0(cpu_address_bus[9]), .I1(cpu_address_bus[10]), .I2(XLXN_8185), .O(maths_table_selected_600_7ff));
    or3b1 XLXI_2883 (.I0(cpu_address_bus[9]), .I1(cpu_address_bus[10]), .I2(XLXN_8185), .O(vregs_selected_200_3ff));
    and2b1 XLXI_2910 (.I0(linecop_busy), .I1(XLXN_8179), .O(XLXN_8185));
    or2 XLXI_2911 (.I0(sysram_at_200_7ff), .I1(loram_selected_000_7ff), .O(XLXN_8179));
    fde XLXI_2260 (.C(delayed_cpu_wr), .CE(port_d_selected), .D(cpu_databus_in[0]), .Q(XLXN_6541));
    sr8ce XLXI_2227 (.C(buffered_rb7), .CE(XLXN_6299), .CLR(XLXN_6296), .SLI(XLXN_6295), .Q(eeprom_data[7:0]));
    ibuf XLXI_2229 (.I(eeprom_data_in), .O(XLXN_6295));
    cb4ce XLXI_2243 (.C(buffered_rb7), .CE(XLXN_6299), .CLR(XLXN_6309), .CEO(), .Q0(), .Q1(), .Q2(), .Q3(eeprom_byte_rdy), .TC());
    vcc XLXI_2230 (.P(XLXN_6299));
    and2b1 XLXI_2246 (.I0(cpu_read), .I1(port_d_selected), .O(XLXN_6309));
    fde XLXI_2364 (.C(delayed_cpu_wr), .CE(port_d_selected), .D(cpu_databus_in[1]), .Q(XLXN_6538));
    obuf XLXI_2365 (.I(XLXN_6541), .O(pic_link_rb1));
    obuf XLXI_2366 (.I(XLXN_6538), .O(pic_link_ra5));
    ibuf XLXI_2228 (.I(pic_link_rb7), .O(buffered_rb7));
    gnd XLXI_2231 (.G(XLXN_6296));
    z80_video_interface XLXI_2960 (.blitter_active(XLXN_8308), .clock_cpu(clock_16mhz_dist), .cpu_a8(cpu_address_bus[8]), .cpu_wait_out(vidsys_cpu_wait), .fpga_to_cpudatabus_oe(videosys_to_cpu_databus_en), .fpga_to_vramdatabus_oe(vidsys_or_cpu_reading), .ok_to_start_gfx_line(init_gfx_line_build), .rd_cpu(cpu_read), .reg_rd(vreg_reading), .selected_600_7ff(maths_table_selected_600_7ff), .start_linegen_out(linegen_go), .vbusy_stop_in(linebuild_done), .vram_access_in(video_ram_selected), .vram_bus_switch_out(cpuvram_buscontrol), .vram_rd_out(XLXN_3686), .vram_wren_out(XLXN_5639), .ywindow_in(video_line));
    bufe8 XLXI_1800 (.E(XLXN_5002), .I(mulres[15:8]), .O(data_for_cpu_multiplex_tb1[7:0]));
    bufe8 XLXI_1803 (.E(XLXN_5003), .I(mulres[7:0]), .O(data_for_cpu_multiplex_tb2[7:0]));
    and2 XLXI_1801 (.I0(XLXN_10907), .I1(cpu_address_bus[0]), .O(XLXN_5002));
    and2b1 XLXI_1802 (.I0(cpu_address_bus[0]), .I1(XLXN_10907), .O(XLXN_5003));
    bufe8 XLXI_1834 (.E(XLXN_5108), .I(vram_rdata2[7:0]), .O(data_for_cpu_multiplex_tb3[7:0]));
    and2b1 XLXI_1848 (.I0(XLXN_5105), .I1(XLXN_5309), .O(XLXN_10908));
    and2b1 XLXI_1850 (.I0(videosys_to_cpu_databus_en), .I1(vreg_reading), .O(XLXN_5108));
    and2b1 XLXI_1914 (.I0(XLXN_5105), .I1(XLXN_5327), .O(XLXN_8086));
    and5b4 XLXI_1912 (.I0(cpu_address_bus[0]), .I1(cpu_address_bus[1]), .I2(cpu_address_bus[2]), .I3(cpu_address_bus[3]), .I4(cabhnzero), .O(XLXN_5327));
    or2 XLXI_2870 (.I0(XLXN_8086), .I1(port_7_selected), .O(XLXN_8087));
    bufe8 XLXI_1835 (.E(XLXN_8087), .I(video_status_flags[7:0]), .O(data_for_cpu_multiplex_tb4[7:0]));
    m2_1 XLXI_2961 (.D0(palette_index[0]), .D1(palette_index[4]), .S0(XLXN_8522), .O(modified_palette_index[0]));
    m2_1 XLXI_2962 (.D0(palette_index[1]), .D1(palette_index[5]), .S0(XLXN_8522), .O(modified_palette_index[1]));
    m2_1 XLXI_2963 (.D0(palette_index[2]), .D1(palette_index[6]), .S0(XLXN_8522), .O(modified_palette_index[2]));
    m2_1 XLXI_2964 (.D0(palette_index[3]), .D1(palette_index[7]), .S0(XLXN_8522), .O(modified_palette_index[3]));
    and2b1 XLXI_2969 (.I0(hi_res_mode), .I1(palette_index[4]), .O(modified_palette_index[4]));
    and2b1 XLXI_2970 (.I0(hi_res_mode), .I1(palette_index[5]), .O(modified_palette_index[5]));
    and2b1 XLXI_2972 (.I0(hi_res_mode), .I1(palette_index[7]), .O(modified_palette_index[7]));
    and2b1 XLXI_2971 (.I0(hi_res_mode), .I1(palette_index[6]), .O(modified_palette_index[6]));
    and2 XLXI_2990 (.I0(XLXN_8547), .I1(hi_res_mode), .O(XLXN_8522));
    inv XLXI_3010 (.I(XLXN_8547), .O(XLXN_8550));
    fdr XLXI_3011 (.C(clock_16mhz_dist), .D(XLXN_8550), .R(scanline_tc), .Q(XLXN_8547));
    buf_x XLXI_1475 (.I(port_0_values[6]), .O(page_in_video_bank));
    buf_x XLXI_1476 (.I(port_0_values[7]), .O(page_in_sprite_bank));
    buf_x XLXI_2112 (.I(port_0_values[5]), .O(all_writes_to_vram));
    buf_x XLXI_2151 (.I(port_0_values[4]), .O(alt_write_bank));
    buf_x XLXI_2304 (.I(port_0_values[3]), .O(high_bank[3]));
    buf_x XLXI_1472 (.I(port_0_values[0]), .O(high_bank[0]));
    buf_x XLXI_1473 (.I(port_0_values[1]), .O(high_bank[1]));
    buf_x XLXI_1474 (.I(port_0_values[2]), .O(high_bank[2]));
    fd8ce XLXI_461 (.C(delayed_cpu_wr), .CE(port_0_selected), .CLR(XLXN_8779), .D(cpu_databus_in[7:0]), .Q(port_0_values[7:0]));
    fd8ce XLXI_536 (.C(delayed_cpu_wr), .CE(port_1_selected), .CLR(XLXN_8779), .D(cpu_databus_in[7:0]), .Q(port_1_outputs[7:0]));
    fd8ce XLXI_537 (.C(delayed_cpu_wr), .CE(port_3_selected), .CLR(XLXN_8779), .D(cpu_databus_in[7:0]), .Q(port_3_outputs[7:0]));
    obuf XLXI_1355 (.I(port_3_outputs[7]), .O(ps2_ms_data_out));
    buf_x XLXI_1516 (.I(port_3_outputs[0]), .O(joystick_select));
    obuf XLXI_1357 (.I(port_3_outputs[5]), .O(ps2_kb_data_out));
    fd8ce XLXI_539 (.C(delayed_cpu_wr), .CE(port_7_selected), .CLR(XLXN_8779), .D(cpu_databus_in[7:0]), .Q(timer_reload_value[7:0]));
    gnd XLXI_3039 (.G(XLXN_8779));
    buf_x XLXI_3120 (.I(keyboard_irq_flag), .O(port_1_values[0]));
    buf_x XLXI_3121 (.I(mouse_irq_flag), .O(port_1_values[1]));
    buf_x XLXI_3122 (.I(timer_irq_flag), .O(port_1_values[2]));
    buf_x XLXI_3124 (.I(keyboard_clock_in), .O(port_1_values[4]));
    buf_x XLXI_3125 (.I(keyboard_data_in), .O(port_1_values[5]));
    buf_x XLXI_3126 (.I(mouse_clock_in), .O(port_1_values[6]));
    buf_x XLXI_3127 (.I(mouse_data_in), .O(port_1_values[7]));
    buf_x XLXI_3179 [5:0] (.I(joystick_bits[5:0]), .O(port_5_values[5:0]));
    buf_x XLXI_3180 (.I(serial_byte_rec_flag), .O(port_5_values[6]));
    buf_x XLXI_3181 (.I(serial_out_busy), .O(port_5_values[7]));
    buf_x XLXI_3257 (.I(raster_line_match), .O(port_1_values[3]));
    buf_x XLXI_3144 (.I(vga_mode), .O(port_9_values[5]));
    buf_x XLXI_3145 (.I(spi_busy), .O(port_9_values[6]));
    buf_x XLXI_3143 (.I(eeprom_byte_rdy), .O(port_9_values[4]));
    rom16x1 #(.INIT(16'h3676)) XLXI_1642 (.A0(cpu_address_bus[8]), .A1(cpu_address_bus[9]), .A2(cpu_address_bus[10]), .A3(cpu_address_bus[11]), .O(port_9_values[7]));
    buf_x XLXI_3150 (.I(low_bank[2]), .O(port_9_values[2]));
    buf_x XLXI_3151 (.I(low_bank[1]), .O(port_9_values[1]));
    buf_x XLXI_3152 (.I(low_bank[0]), .O(port_9_values[0]));
    m2_1 XLXI_3277 (.D0(buffered_rb7), .D1(low_bank[3]), .S0(port_20_selected), .O(port_9_values[3]));
    bufe8 XLXI_563 (.E(port_2_selected), .I(keyboard_data[7:0]), .O(data_for_cpu_multiplex_tb5[7:0]));
    bufe8 XLXI_564 (.E(port_1_selected), .I(port_1_values[7:0]), .O(data_for_cpu_multiplex_tb6[7:0]));
    bufe8 XLXI_605 (.E(port_5_selected), .I(port_5_values[7:0]), .O(data_for_cpu_multiplex_tb7[7:0]));
    bufe8 XLXI_540 (.E(port_4_selected), .I(received_serial_byte[7:0]), .O(data_for_cpu_multiplex_tb8[7:0]));
    bufe8 XLXI_488 (.E(port_0_selected), .I(port_0_values[7:0]), .O(data_for_cpu_multiplex_tb9[7:0]));
    bufe8 XLXI_3114 (.E(port_d_selected), .I(eeprom_data[7:0]), .O(data_for_cpu_multiplex_tb10[7:0]));
    bufe8 XLXI_3115 (.E(port_a_selected), .I(received_spi_byte[7:0]), .O(data_for_cpu_multiplex_tb11[7:0]));
    bufe8 XLXI_3116 (.E(port_8_selected), .I(port_8_values[7:0]), .O(data_for_cpu_multiplex_tb12[7:0]));
    bufe8 XLXI_3119 (.E(XLXN_9598), .I(port_9_values[7:0]), .O(data_for_cpu_multiplex_tb13[7:0]));
    bufe8 XLXI_1459 (.E(port_3_selected), .I(mouse_data[7:0]), .O(data_for_cpu_multiplex_tb14[7:0]));
    assign z80_data_o = data_for_cpu_multiplex[7:0];
    assign z80_data_oe = ~XLXN_9400;
    assign cpu_databus_in[7:0] = z80_data_i;
    and2 XLXI_3201 (.I0(videosys_to_cpu_databus_en), .I1(XLXN_9401), .O(XLXN_9400));
    or2 XLXI_3202 (.I0(cpu_read), .I1(XLXN_9402), .O(XLXN_9401));
    and2 XLXI_3200 (.I0(sys_ports_selected), .I1(rom_selected), .O(XLXN_9402));
    or2 XLXI_3286 (.I0(port_9_selected), .I1(port_20_selected), .O(XLXN_9598));
    video_sync_gen7 XLXI_3320 (.clock_in(clock_16mhz_dist), .interlace_in(interlace_mode), .mode_VGA(vga_mode), .Force_VGA_to_50Hz(force_50hz_VGA), .vga_vsync_pal_csync(XLXN_5429), .rgb_enable(rgb_oe), .full_scanline_tc(scanline_tc), .vga_hsync(XLXN_7941), .adjusted_linecount(line_count[8:0]), .last_line(vrt_line), .last16cycles(last_sixteen_clocks), .vga_scanline_a_tc(vga_first_scanline_tc), .long_frame(longframe));
    or2 XLXI_2050 (.I0(linedraw_op_pending), .I1(blit_op_pending), .O(XLXN_5865));
    and2b1 XLXI_3323 (.I0(force_50hz_VGA), .I1(vga_mode), .O(XLXN_9681));
    v6tile_08 XLXI_3324 (.clock_16mhz(clock_16mhz_dist), .dual_playfield(dualpf_en), .eight_by_eight_mode(XLXN_9732), .extended_mode(extended_tile_mode), .latchayhws_in(latchyhws_a), .latchbyhws_in(latchyhws_b), .layer_a_block_bank(pfabanksel), .layer_a_mapsel(pfabmbufsel), .layer_b_block_bank(pfbbanksel), .layer_b_mapsel(pfbbufsel), .priority_swap(switch_tile_priority), .pri_adjusted_layer(playfield), .right_border(right_border_stop), .scanline_start(scanline_first_cycle), .slb_addr_inc_en(tm_lbaddrincen), .slb_latch_dest(tm_latchdest), .slb_wr_en(tm_lbwren), .start_line(XLXN_6711), .stop_line(tm_linedone), .vram_addr_out(tm_vram_addr[18:0]), .vram_data_in(vram_databus_input[7:0]), .vrtline_in(vrt_line), .yhwsavalue_in(yhws_a[3:0]), .yhwsbvalue_in(yhws_b[3:0]));
    and2 XLXI_2444 (.I0(linegen_go), .I1(tilemap_mode), .O(XLXN_6711));
    and2 XLXI_3327 (.I0(pfabanksel), .I1(extended_tile_mode), .O(XLXN_9732));
    bufe8 XLXI_1353 (.E(XLXN_9540), .I(expansion_pins_in[7:0]), .O(data_for_cpu_multiplex_tb15[7:0]));
    or2 XLXI_3258 (.I0(port_6_selected), .I1(port_e_selected), .O(XLXN_9540));
    bufe8 XLXI_3335 (.E(port_b_selected), .I(port_b_bits[7:0]), .O(data_for_cpu_multiplex_tb16[7:0]));
    bitmapcore_603 XLXI_3336 (.bitmaplbwren_out(bm_lbwren), .bitmap_linedone_out(bm_linedone), .bm_lbaddrinc_en(bm_lbaddrincen), .chunky_mode(dualpf_en), .clk16mhz_in(clock_16mhz_dist), .cpu_addr(cpu_address_bus[7:0]), .cpu_databus(cpu_databus_in[7:0]), .cpu_write(cpu_write), .enable_expand(pfabanksel), .new_scanline_in(scanline_first_cycle), .no_of_planes(yhws_a[2:0]), .planar_pixel(bm_pixel[7:0]), .regs_ab_select(pfabmbufsel), .start_linegen_in(linegen_go), .stop_slb_writes(right_border_stop), .tilemap_mode_in(tilemap_mode), .vram_bmaddr_out(bm_vram_addr[18:0]), .vram_databus(vram_databus_input[7:0]), .vreg_range(XLXN_5663), .vrt_in(vrt_line));
    or2 XLXI_1997 (.I0(cpu_address_bus[8]), .I1(vregs_selected_200_3ff), .O(XLXN_5663));
    nand5 XLXI_2856 (.I0(spr_ram_write_enable), .I1(video_ram_selected), .I2(XLXN_8273), .I3(vreg_reading), .I4(rom_selected), .O(XLXN_3165));
    or2b1 XLXI_2946 (.I0(cpu_read), .I1(XLXN_8271), .O(XLXN_8273));
    rom_select XLXI_1209 (.mreq_in(cpu_mreq), .a15_in(cpu_address_bus[15]), .a14_in(cpu_address_bus[14]), .a13_in(cpu_address_bus[13]), .a12_in(cpu_address_bus[12]), .a11_in(cpu_address_bus[11]), .a10_in(cpu_address_bus[10]), .a9_in(cpu_address_bus[9]), .rom_selected(XLXN_8067));
    and4 XLXI_2945 (.I0(palette_selected_000_1ff), .I1(vregs_selected_200_3ff), .I2(spr_regs_selected_400_5ff), .I3(maths_table_selected_600_7ff), .O(XLXN_8271));
    bank_select_02 XLXI_3019 (.any_page(any_page_mode), .cpua15(cpu_address_bus[15]), .hi_bank(high_bank[3:0]), .inhibits(XLXN_3165), .lo_bank(low_bank[3:0]), .mreq(cpu_mreq), .sysram_a15(non_dma_sysram_a15), .sysram_a16(non_dma_sysram_a16), .sysram_a17(non_dma_sysram_a17), .sysram_a18(non_dma_sysram_a18), .sysram_cs(non_dma_sysram_cs), .write_bank_en(XLXN_6421), .wr_bank(write_bank[3:0]));
    and2 XLXI_2308 (.I0(cpu_read), .I1(alt_write_bank), .O(XLXN_6421));
    video_selects_4 XLXI_3337 (.addra11(cpu_address_bus[11]), .addra12(cpu_address_bus[12]), .addra13(cpu_address_bus[13]), .addra14(cpu_address_bus[14]), .addra15(cpu_address_bus[15]), .all_vram_wr_mode(all_writes_to_vram), .cpumreq(cpu_mreq), .cpurd(cpu_read), .page_in_sprite_ram(page_in_sprite_bank), .page_in_vram(page_in_video_bank), .sprite_ram_select(XLXN_9819), .video_registers_select(loram_selected_000_7ff), .vram_loc(vram_location[2:0]), .vram_selected(video_ram_selected));
    or2b1 XLXI_1223 (.I0(cpu_read), .I1(XLXN_9819), .O(spr_ram_write_enable));
    fd4ce XLXI_3100 (.C(delayed_cpu_wr), .CE(port_9_selected), .CLR(XLXN_8990), .D0(cpu_databus_in[0]), .D1(cpu_databus_in[1]), .D2(XLXN_8990), .D3(XLXN_8990), .Q0(disable_nmi), .Q1(disable_reset), .Q2(), .Q3());
    gnd XLXI_3101 (.G(XLXN_8990));
    fde #(.INIT(1'b1)) XLXI_3367 (.C(delayed_cpu_wr), .CE(port_21_selected), .D(cpu_databus_in[0]), .Q(vram_location[0]));
    fde XLXI_3368 (.C(delayed_cpu_wr), .CE(port_21_selected), .D(cpu_databus_in[1]), .Q(vram_location[1]));
    fde XLXI_3369 (.C(delayed_cpu_wr), .CE(port_21_selected), .D(cpu_databus_in[2]), .Q(vram_location[2]));
    fd8ce XLXI_2141 (.C(delayed_cpu_wr), .CE(port_b_selected), .CLR(clocked_reset), .D(cpu_databus_in[7:0]), .Q(port_b_bits[7:0]));
    buf_x XLXI_2144 (.I(port_b_bits[2]), .O(write_bank[2]));
    buf_x XLXI_2305 (.I(port_b_bits[3]), .O(write_bank[3]));
    buf_x XLXI_2143 (.I(port_b_bits[1]), .O(write_bank[1]));
    buf_x XLXI_2142 (.I(port_b_bits[0]), .O(write_bank[0]));
    buf_x XLXI_2853 (.I(port_b_bits[7]), .O(sysram_at_200_7ff));
    buf_x XLXI_3020 (.I(port_b_bits[5]), .O(any_page_mode));
    buf_x XLXI_3309 (.I(port_b_bits[6]), .O(sysram_at_000_1ff));
    fd4ce XLXI_3012 (.C(delayed_cpu_wr), .CE(port_20_selected), .CLR(XLXN_8992), .D0(cpu_databus_in[0]), .D1(cpu_databus_in[1]), .D2(cpu_databus_in[2]), .D3(cpu_databus_in[3]), .Q0(low_bank[0]), .Q1(low_bank[1]), .Q2(low_bank[2]), .Q3(low_bank[3]));
    gnd XLXI_3014 (.G(XLXN_8992));
    buf_x XLXI_3370 (.I(port_b_bits[4]), .O(wr_palette_rd_sysram));
    and2b1 XLXI_2884 (.I0(linecop_busy), .I1(XLXN_8153), .O(XLXN_8106));
    or3 XLXI_2905 (.I0(XLXN_8106), .I1(cpu_address_bus[9]), .I2(cpu_address_bus[10]), .O(palette_selected_000_1ff));
    or2 XLXI_2906 (.I0(XLXN_9885), .I1(loram_selected_000_7ff), .O(XLXN_8153));
    and2b1 XLXI_3371 (.I0(wr_palette_rd_sysram), .I1(sysram_at_000_1ff), .O(XLXN_9885));
    or3 XLXI_3376 (.I0(XLXN_8067), .I1(sysram_at_000_1ff), .I2(wr_palette_rd_sysram), .O(rom_selected));
    pixel_priority503 XLXI_3405 (.bgnd_pixel_in(background_pixel[7:0]), .cpu_addr(cpu_address_bus[3:0]), .cpu_databus(cpu_databus_in[1:0]), .interleave_mode(sprite_priority_mode), .paletteindex(palette_index[7:0]), .priority_reg_range(XLXN_10097), .slb_read_addr(slb_addr[7:3]), .sprite_cols_low(sprite_priority_option), .spr_pixel_in(sprite_pixel[7:0]), .sys_clock_in(clock_16mhz_dist), .wideborder_in(wide_border), .write_clock(cpu_write), .xstartcoarse_in(xstart_coarse[3:0]), .xstopcoarse_in(xstop_coarse[3:0]), .xwindow_out(xwindow));
    and2b1 XLXI_3408 (.I0(vregs_selected_200_3ff), .I1(cpu_address_bus[7]), .O(XLXN_10097));
    fde XLXI_3409 (.C(delayed_cpu_wr), .CE(port_e_selected), .D(cpu_databus_in[0]), .Q(XLXN_10150));
    fde XLXI_3410 (.C(delayed_cpu_wr), .CE(port_e_selected), .D(cpu_databus_in[1]), .Q(XLXN_10151));
    obuft XLXI_1335 (.I(XLXN_10151), .T(exp_pin_b_dir), .O(expansion_pin_b));
    ibuf XLXI_1336 (.I(expansion_pin_b), .O(expansion_pins_in[1]));
    ibuf XLXI_1332 (.I(expansion_pin_a), .O(expansion_pins_in[0]));
    obuft XLXI_1331 (.I(XLXN_10150), .T(exp_pin_a_dir), .O(expansion_pin_a));
    fde #(.INIT(1'b0)) XLXI_3421 (.C(delayed_cpu_wr), .CE(port_f_selected), .D(cpu_databus_in[1]), .Q(exp_pin_b_dir));
    fde #(.INIT(1'b0)) XLXI_3422 (.C(delayed_cpu_wr), .CE(port_f_selected), .D(cpu_databus_in[0]), .Q(exp_pin_a_dir));
    buf_x XLXI_3423 (.I(sdc_cs), .O(expansion_pins_in[2]));
    buf_x XLXI_3260 (.I(sdc_pow), .O(expansion_pins_in[3]));
    obuf XLXI_1749 (.I(XLXN_4871), .O(z80_nmi));
    or2 XLXI_1701 (.I0(expansion_pins_in[7]), .I1(disable_nmi), .O(XLXN_4871));
    ibuf XLXI_1750 (.I(jumper_nmi), .O(expansion_pins_in[7]));
    ibuf XLXI_1926 (.I(jumper_reset), .O(expansion_pins_in[6]));
    or2 XLXI_1927 (.I0(expansion_pins_in[6]), .I1(disable_reset), .O(reset_req));
    inv XLXI_2440 (.I(XLXN_6706), .O(vga_mode));
    ibuf XLXI_2441 (.I(jumper_vga), .O(XLXN_6706));
    buf_x XLXI_132 [14:0] (.I(audio_addr[14:0]), .O(audio_dma_addr[14:0]));
    buft16 XLXI_2511 (.I(audio_dma_addr[15:0]), .T(linecop_busy), .O(XLXN_7011_tb0[15:0]));
    assign z80_addr_o = XLXN_7011[15:0];
    assign incoming_cpu_address[15:0] = z80_addr_i;
    bufe16 XLXI_2512 (.E(linecop_busy), .I(linecop_pc[15:0]), .O(XLXN_7011_tb1[15:0]));
    gnd XLXI_133 (.G(audio_dma_addr[15]));
    m2_1 XLXI_2345 (.D0(XLXN_10198), .D1(non_dma_sysram_a17), .S0(cpu_busack), .O(system_ram_a17));
    m2_1 XLXI_2346 (.D0(XLXN_10191), .D1(non_dma_sysram_a18), .S0(cpu_busack), .O(system_ram_a18));
    m2_1 XLXI_115 (.D0(XLXN_7051), .D1(non_dma_sysram_a16), .S0(cpu_busack), .O(system_ram_a16));
    m2_1 XLXI_121 (.D0(XLXN_7332), .D1(non_dma_sysram_a15), .S0(cpu_busack), .O(system_ram_a15));
    m2_1 XLXI_2604 (.D0(audio_addr[15]), .D1(linecop_pc[15]), .S0(linecop_busy), .O(XLXN_7332));
    obuf XLXI_3330 (.I(incoming_cpu_address[14]), .O(system_ram_a14));
    buft16 XLXI_2558 (.I(incoming_cpu_address[15:0]), .T(linecop_busy), .O(cpu_address_bus_tb0[15:0]));
    bufe16 XLXI_2559 (.E(linecop_busy), .I(linecop_reg_addr[15:0]), .O(cpu_address_bus_tb1[15:0]));
    gnd XLXI_2568 [4:0] (.G(linecop_reg_addr[15:11]));
    assign cpu_ioreq = z80_ioreq_i;
    assign z80_ioreq_o = XLXN_3221;
    assign cpu_mreq = z80_mreq_i;
    assign XLXN_7132 = z80_write_i;
    assign z80_mreq_o = XLXN_3221;
    assign z80_write_o = XLXN_3221;
    assign cpu_read = z80_read_i;
    assign z80_read_o = XLXN_6993;
    and2 XLXI_2348 (.I0(cpu_busack), .I1(non_dma_sysram_cs), .O(system_ram_cs));
    vcc XLXI_31 (.P(XLXN_3221));
    gnd XLXI_2499 (.G(XLXN_6993));
    and2 XLXI_2569 (.I0(linecop_wr), .I1(XLXN_7132), .O(cpu_write));
    inv XLXI_460 (.I(cpu_write), .O(XLXN_2527));
    fd XLXI_1059 (.C(clock_16mhz_dist), .D(XLXN_2527), .Q(delayed_cpu_wr));
    obuf XLXI_3402 (.I(clock_16mhz_dist), .O(z80_clock));
    D5_32E XLXI_3456 (.A0(cpu_address_bus[0]), .A1(cpu_address_bus[1]), .A2(cpu_address_bus[2]), .A3(cpu_address_bus[3]), .A4(cpu_address_bus[5]), .E(XLXN_8594), .D0(port_0_selected), .D1(port_1_selected), .D2(port_2_selected), .D3(port_3_selected), .D4(port_4_selected), .D5(port_5_selected), .D6(port_6_selected), .D7(port_7_selected), .D8(port_8_selected), .D9(port_9_selected), .D10(port_a_selected), .D11(port_b_selected), .D12(port_c_selected), .D13(port_d_selected), .D14(port_e_selected), .D15(port_f_selected), .D16(port_20_selected), .D17(port_21_selected), .D18(port_22_selected), .D19(), .D20(XLXN_10312), .D21(XLXN_10314), .D22(XLXN_10315), .D23(XLXN_10316), .D24(port_28_selected), .D25(port_29_selected), .D26(port_2a_selected), .D27(), .D28(), .D29(), .D30(), .D31());
    or5b1 XLXI_3029 (.I0(XLXN_8599), .I1(cpu_ioreq), .I2(cpu_address_bus[7]), .I3(cpu_address_bus[6]), .I4(cpu_address_bus[4]), .O(sys_ports_selected));
    ibuf XLXI_1712 (.I(z80_m1), .O(XLXN_8599));
    inv XLXI_3023 (.I(sys_ports_selected), .O(XLXN_8594));
    and2b1 XLXI_2022 (.I0(tilemap_mode), .I1(dualpf_en), .O(XLXN_10293));
    bglinebuffer504 XLXI_3458 (.bgnd_pixel(background_pixel[7:0]), .bitmap_pixel(bm_pixel[7:0]), .bm_bufwren_in(bm_lbwren), .bm_latchdest_in(init_gfx_line_build), .bm_lbaddr_inc_en_in(bm_lbaddrincen), .chunky_mode_on(XLXN_10293), .flood_mode(pfbbufsel), .linebuffaddr_out(lb_build_addr[8:0]), .linecount_lsb(line_count[0]), .slb_byte_select(slb_latch_byte_select), .slb_enable(slb_blkram_en), .slb_outword_addr(slb_addr[7:0]), .slb_wrzero_en(slb_zero_wr_en), .sys_clock_16mhz(clock_16mhz_dist), .tile_mode_on(tilemap_mode), .tm_bufwren_in(tm_lbwren), .tm_latchdest_in(tm_latchdest), .tm_lbaddr_inc_en_in(tm_lbaddrincen), .vram_databus(vram_databus_input[7:0]), .xstartcoarse_in(xstart_coarse[3:0]), .xstartfine_in(xhws[3:0]));
    or4 XLXI_3457 (.I0(XLXN_10316), .I1(XLXN_10315), .I2(XLXN_10314), .I3(XLXN_10312), .O(port_24_27_selected));
    ofd XLXI_2692 (.C(clock_16mhz_dist), .D(XLXN_7677), .Q(audio_left));
    ofd XLXI_2691 (.C(clock_16mhz_dist), .D(XLXN_7676), .Q(audio_right));
    sound_system_3_07 XLXI_3483 (.audio_irq(audio_irq_flag), .audio_ram_address(audio_addr[18:0]), .aud_chan_status(port_8_values[7:0]), .aud_out_l(XLXN_7677), .aud_out_r(XLXN_7676), .begin_audio_ops(commence_dma_ops), .chans_enable_wr_en(port_8_selected), .cpu_addr0(cpu_address_bus[0]), .cpu_addr1(cpu_address_bus[1]), .cpu_addr2(cpu_address_bus[2]), .cpu_addr3(cpu_address_bus[3]), .cpu_addr_hi(cpu_address_bus[15:8]), .cpu_write_in(delayed_cpu_wr), .databus_in(cpu_databus_in[7:0]), .dma_done(audio_dma_done), .loc_extend_regs(port_24_27_selected), .master_clock(clock_16mhz_dist), .new_scanline(scanline_tc), .pan_reg_selected(port_22_selected), .select_aud_regs(XLXN_10526), .sel_clr_loop_regs(port_2_selected));
    or5b1 XLXI_1465 (.I0(cpu_address_bus[4]), .I1(cpu_address_bus[5]), .I2(cpu_address_bus[6]), .I3(cpu_address_bus[7]), .I4(cpu_ioreq), .O(XLXN_10526));
    m2_1 XLXI_3484 (.D0(audio_addr[16]), .D1(linecop_pc[16]), .S0(linecop_busy), .O(XLXN_7051));
    m2_1 XLXI_3485 (.D0(audio_addr[17]), .D1(linecop_pc[17]), .S0(linecop_busy), .O(XLXN_10198));
    m2_1 XLXI_3486 (.D0(audio_addr[18]), .D1(linecop_pc[18]), .S0(linecop_busy), .O(XLXN_10191));
    line_cop_04 XLXI_3488 (.cpu_databus(cpu_databus_in[7:0]), .last_sl_cycles(last_sixteen_clocks), .linecop_addr(linecop_addr[18:0]), .linecop_busy(linecop_busy), .linecop_start(start_linecop), .lsrw_pc(linecop_pc[18:0]), .main_clock(clock_16mhz_dist), .reg_addr(linecop_reg_addr[10:0]), .reg_wr(linecop_wr), .scanline(line_count[8:0]), .vrt_last_cycle(XLXN_10553));
    and2 XLXI_2599 (.I0(scanline_tc), .I1(vrt_line), .O(XLXN_10553));
    fde #(.INIT(1'b0)) XLXI_3517 (.C(delayed_cpu_wr), .CE(port_c_selected), .D(XLXN_10577), .Q(baud_sel_a));
    fde #(.INIT(1'b0)) XLXI_3518 (.C(delayed_cpu_wr), .CE(port_c_selected), .D(cpu_databus_in[1]), .Q(baud_sel_b));
    inv XLXI_3534 (.I(cpu_databus_in[0]), .O(XLXN_10577));
    serial_508 XLXI_3535 (.baudrate_a(baud_sel_a), .baudrate_b(baud_sel_b), .byte_out(received_serial_byte[7:0]), .clock_16mhz(clock_16mhz_dist), .cpu_databus_in(cpu_databus_in[7:0]), .cpu_read(cpu_read), .delayed_wr(delayed_cpu_wr), .rec_byte_rdy(serial_byte_rec_flag), .rx_input(XLXN_4808), .sending_frame(serial_out_busy), .serial_port_selected(port_4_selected), .tx_output(XLXN_5673));
    obuf XLXI_1718 (.I(XLXN_5673), .O(serial_tx_pin));
    ibuf XLXI_1713 (.I(serial_rx_pin), .O(XLXN_4808));
    or2 XLXI_3556 (.I0(port_3_outputs[4]), .I1(keyboard_irq_flag), .O(XLXN_10660));
    or2 XLXI_3557 (.I0(mouse_irq_flag), .I1(port_3_outputs[6]), .O(XLXN_10664));
    obuf XLXI_1356 (.I(XLXN_10660), .O(ps2_kb_clock_out));
    obuf XLXI_1354 (.I(XLXN_10664), .O(ps2_ms_clock_out));
    ibuf XLXI_1777 (.I(ps2_ms_data_in), .O(mouse_data_in));
    and3 XLXI_3494 (.I0(delayed_cpu_wr), .I1(port_2_selected), .I2(cpu_databus_in[1]), .O(XLXN_10569));
    and3 XLXI_3493 (.I0(delayed_cpu_wr), .I1(port_2_selected), .I2(cpu_databus_in[0]), .O(XLXN_10568));
    ps2interface506 XLXI_3575 (.data_out(keyboard_data[7:0]), .irq_clr(XLXN_10568), .irq_out(keyboard_irq_flag), .main_divider_tc(main_counter_tc), .manual_clock(port_3_outputs[4]), .ps2_clk(keyboard_clock_in), .ps2_data(keyboard_data_in), .sys_clk(clock_16mhz_dist));
    ibuf XLXI_1775 (.I(ps2_kb_data_in), .O(keyboard_data_in));
    ibuf XLXI_3583 (.I(ps2_kb_clock_in), .O(keyboard_clock_in));
    ps2interface506 XLXI_3585 (.data_out(mouse_data[7:0]), .irq_clr(XLXN_10569), .irq_out(mouse_irq_flag), .main_divider_tc(main_counter_tc), .manual_clock(port_3_outputs[6]), .ps2_clk(mouse_clock_in), .ps2_data(mouse_data_in), .sys_clk(clock_16mhz_dist));
    ibuf XLXI_1776 (.I(ps2_ms_clock_in), .O(mouse_clock_in));
    fdse XLXI_3310 (.C(clock_16mhz_dist), .CE(scanline_tc), .D(XLXN_9663), .S(reset_req), .Q(XLXN_9656));
    fdse XLXI_3311 (.C(clock_16mhz_dist), .CE(scanline_tc), .D(XLXN_9656), .S(reset_req), .Q(XLXN_9666));
    and2b2 XLXI_3315 (.I0(XLXN_9666), .I1(XLXN_9656), .O(XLXN_9668));
    gnd XLXI_3316 (.G(XLXN_9663));
    obuf XLXI_1773 (.I(sys_reset), .O(system_reset_out));
    inv XLXI_3317 (.I(clocked_reset), .O(sys_reset));
    fde #(.INIT(1'b1)) XLXI_3319 (.C(clock_16mhz_dist), .CE(scanline_tc), .D(XLXN_9668), .Q(clocked_reset));
    cb8ce XLXI_1022 (.C(clock_16mhz_dist), .CE(XLXN_2458), .CLR(clocked_reset), .CEO(), .Q(), .TC(main_counter_tc));
    vcc XLXI_1023 (.P(XLXN_2458));
    and2 XLXI_901 (.I0(keyboard_irq_enable), .I1(keyboard_irq_flag), .O(XLXN_3814));
    and2 XLXI_902 (.I0(timer_irq_enable), .I1(timer_irq_flag), .O(XLXN_7973));
    and2 XLXI_1442 (.I0(mouse_irq_flag), .I1(mouse_irq_enable), .O(XLXN_3813));
    and2 XLXI_3547 (.I0(serial_byte_rec_flag), .I1(serial_irq_enable), .O(XLXN_10855));
    and2 XLXI_2812 (.I0(audio_irq_enable), .I1(audio_irq_flag), .O(XLXN_10852));
    and2 XLXI_3605 (.I0(video_irq_enable), .I1(raster_line_match), .O(XLXN_10851));
    nor7 XLXI_3609 (.I0(XLXN_10856), .I1(XLXN_10855), .I2(XLXN_10852), .I3(XLXN_10851), .I4(XLXN_7973), .I5(XLXN_3813), .I6(XLXN_3814), .O(XLXN_4828));
    obuf XLXI_1721 (.I(XLXN_4828), .O(z80_int));
    buf_x XLXI_1477 (.I(port_1_outputs[0]), .O(keyboard_irq_enable));
    buf_x XLXI_1478 (.I(port_1_outputs[1]), .O(mouse_irq_enable));
    buf_x XLXI_1479 (.I(port_1_outputs[2]), .O(timer_irq_enable));
    buf_x XLXI_3548 (.I(port_1_outputs[4]), .O(audio_irq_enable));
    buf_x XLXI_3631 (.I(port_1_outputs[3]), .O(video_irq_enable));
    buf_x XLXI_3632 (.I(port_1_outputs[6]), .O(serial_irq_enable));
    buf_x XLXI_1480 (.I(port_1_outputs[7]), .O(legacy_master_irq_en));
    video_registers_659 XLXI_3640 (.allow_virq(legacy_video_irq_en), .cpuaccvideopage_out(cpus_vram_page[5:0]), .cpu_addr_in(cpu_address_bus[7:0]), .cpu_databus(cpu_databus_in[7:0]), .cpu_sel_spr_ctrl(cpu_sel_vreg_sprctrl), .cpu_sprite_base_addr(cpu_sprite_bank[4:0]), .cpu_wr_line(cpu_write), .dualpfen_out(dualpf_en), .global_video_enable(video_enable), .hi_res(hi_res_mode), .interlace(interlace_mode), .latchayhws_out(latchyhws_a), .latchbyhws_out(latchyhws_b), .linecop_addr(linecop_addr[18:0]), .linecount_in(line_count[8:0]), .live_palette(live_palette), .main_clock_in(clock_16mhz_dist), .new_scanline_in(init_gfx_line_build), .palette_wr_sel(palette_write_select), .pfablockbanksel_out(pfabanksel), .pfabufbmbufsel_out(pfabmbufsel), .pfbblockbanksel_out(pfbbanksel), .pfbbufsel_out(pfbbufsel), .playfield1req_in(playfield), .rasterirq_status_out(raster_line_match), .tilemodeen_out(tilemap_mode), .tile_extend(extended_tile_mode), .tile_pri_swap(switch_tile_priority), .vidreg_range_in(vregs_selected_200_3ff), .wideborder_out(wide_border), .xhws_out(xhws[3:0]), .xstartcoarse_out(xstart_coarse[3:0]), .xstopcoarse_out(xstop_coarse[3:0]), .yhwsavalue(yhws_a[3:0]), .yhwsbvalue(yhws_b[3:0]), .y_window_position(y_window_pos[7:0]));
    and3 XLXI_3641 (.I0(legacy_master_irq_en), .I1(legacy_video_irq_en), .I2(raster_line_match), .O(XLXN_10856));
    spi_sch5 XLXI_2015 (.busy(spi_busy), .byte_received(received_spi_byte[7:0]), .byte_to_write(cpu_databus_in[7:0]), .clock_16mhz(clock_16mhz_dist), .cpu_wr(delayed_cpu_wr), .port_selected(port_a_selected), .speed_select(spi_speed), .spi_clock(spi_clock_out), .spi_input(XLXN_6347), .spi_out(XLXN_6506));
    ibuf XLXI_2288 (.I(sdc_dout), .O(XLXN_6347));
    and2 XLXI_2349 (.I0(spi_data_enable), .I1(XLXN_6506), .O(XLXN_6507));
    obuf XLXI_2290 (.I(XLXN_6507), .O(sdc_din));
    obuf XLXI_2289 (.I(spi_clock_out), .O(sdc_clk));
    maths_assist_102 XLXI_3644 (.address(cpu_address_bus[8:0]), .data_in(cpu_databus_in[7:0]), .latch_blockram(XLXN_5609), .math_reg_range(scale_range_sel), .port_28_sel(port_28_selected), .port_29_sel(port_29_selected), .port_2a_sel(port_2a_selected), .reg_wr_clock(maths_wr), .scaled(mulres[15:0]), .sys_clock(clock_16mhz_dist));
    inv XLXI_2902 (.I(maths_table_selected_600_7ff), .O(XLXN_5609));
    and4b4 XLXI_1793 (.I0(cpu_address_bus[4]), .I1(cpu_address_bus[5]), .I2(cpu_address_bus[6]), .I3(cpu_address_bus[7]), .O(cabhnzero));
    and3b1 XLXI_1910 (.I0(vregs_selected_200_3ff), .I1(XLXN_5004), .I2(cabhnzero), .O(scale_range_sel));
    and2b1 XLXI_1916 (.I0(cpu_address_bus[2]), .I1(cpu_address_bus[3]), .O(XLXN_5004));
    m2_1 XLXI_3652 (.D0(XLXN_10900), .D1(delayed_cpu_wr), .S0(cpu_mreq), .O(maths_wr));
    inv XLXI_3653 (.I(cpu_write), .O(XLXN_10900));
    or3 XLXI_3654 (.I0(XLXN_10908), .I1(port_28_selected), .I2(port_29_selected), .O(XLXN_10907));
    and3b1 XLXI_1845 (.I0(cpu_address_bus[3]), .I1(cpu_address_bus[2]), .I2(cabhnzero), .O(XLXN_5309));
    or2 XLXI_1844 (.I0(videosys_to_cpu_databus_en), .I1(vreg_reading), .O(XLXN_5105));
    assign outgoing_data_for_vram[0] = outgoing_data_for_vram_tb0[0] | outgoing_data_for_vram_tb1[0] | outgoing_data_for_vram_tb2[0];
    assign outgoing_data_for_vram[1] = outgoing_data_for_vram_tb0[1] | outgoing_data_for_vram_tb1[1] | outgoing_data_for_vram_tb2[1];
    assign outgoing_data_for_vram[2] = outgoing_data_for_vram_tb0[2] | outgoing_data_for_vram_tb1[2] | outgoing_data_for_vram_tb2[2];
    assign outgoing_data_for_vram[3] = outgoing_data_for_vram_tb0[3] | outgoing_data_for_vram_tb1[3] | outgoing_data_for_vram_tb2[3];
    assign outgoing_data_for_vram[4] = outgoing_data_for_vram_tb0[4] | outgoing_data_for_vram_tb1[4] | outgoing_data_for_vram_tb2[4];
    assign outgoing_data_for_vram[5] = outgoing_data_for_vram_tb0[5] | outgoing_data_for_vram_tb1[5] | outgoing_data_for_vram_tb2[5];
    assign outgoing_data_for_vram[6] = outgoing_data_for_vram_tb0[6] | outgoing_data_for_vram_tb1[6] | outgoing_data_for_vram_tb2[6];
    assign outgoing_data_for_vram[7] = outgoing_data_for_vram_tb0[7] | outgoing_data_for_vram_tb1[7] | outgoing_data_for_vram_tb2[7];
    assign spraddr[0] = spraddr_tb0[0] | spraddr_tb2[0];
    assign spraddr[1] = spraddr_tb0[1] | spraddr_tb2[1];
    assign spraddr[2] = spraddr_tb0[2] | spraddr_tb2[2];
    assign spraddr[3] = spraddr_tb0[3] | spraddr_tb2[3];
    assign spraddr[4] = spraddr_tb0[4] | spraddr_tb2[4];
    assign spraddr[5] = spraddr_tb0[5] | spraddr_tb2[5];
    assign spraddr[6] = spraddr_tb0[6] | spraddr_tb2[6];
    assign spraddr[7] = spraddr_tb0[7] | spraddr_tb2[7];
    assign spraddr[8] = spraddr_tb0[8] | spraddr_tb2[8];
    assign spraddr[9] = spraddr_tb0[9] | spraddr_tb2[9];
    assign spraddr[10] = spraddr_tb0[10] | spraddr_tb2[10];
    assign spraddr[11] = spraddr_tb0[11] | spraddr_tb2[11];
    assign spraddr[12] = spraddr_tb0[12] | spraddr_tb2[12];
    assign spraddr[13] = spraddr_tb0[13] | spraddr_tb2[13];
    assign spraddr[14] = spraddr_tb0[14] | spraddr_tb2[14];
    assign spraddr[15] = spraddr_tb0[15] | spraddr_tb2[15];
    assign spraddr[16] = spraddr_tb1 | spraddr_tb3;
    assign XLXN_6544[0] = XLXN_6544_tb0[0] | XLXN_6544_tb1[0] | XLXN_6544_tb2[0] | XLXN_6544_tb3[0] | XLXN_6544_tb4[0];
    assign XLXN_6544[1] = XLXN_6544_tb0[1] | XLXN_6544_tb1[1] | XLXN_6544_tb2[1] | XLXN_6544_tb3[1] | XLXN_6544_tb4[1];
    assign XLXN_6544[2] = XLXN_6544_tb0[2] | XLXN_6544_tb1[2] | XLXN_6544_tb2[2] | XLXN_6544_tb3[2] | XLXN_6544_tb4[2];
    assign XLXN_6544[3] = XLXN_6544_tb0[3] | XLXN_6544_tb1[3] | XLXN_6544_tb2[3] | XLXN_6544_tb3[3] | XLXN_6544_tb4[3];
    assign XLXN_6544[4] = XLXN_6544_tb0[4] | XLXN_6544_tb1[4] | XLXN_6544_tb2[4] | XLXN_6544_tb3[4] | XLXN_6544_tb4[4];
    assign XLXN_6544[5] = XLXN_6544_tb0[5] | XLXN_6544_tb1[5] | XLXN_6544_tb2[5] | XLXN_6544_tb3[5] | XLXN_6544_tb4[5];
    assign XLXN_6544[6] = XLXN_6544_tb0[6] | XLXN_6544_tb1[6] | XLXN_6544_tb2[6] | XLXN_6544_tb3[6] | XLXN_6544_tb4[6];
    assign XLXN_6544[7] = XLXN_6544_tb0[7] | XLXN_6544_tb1[7] | XLXN_6544_tb2[7] | XLXN_6544_tb3[7] | XLXN_6544_tb4[7];
    assign XLXN_6544[8] = XLXN_6544_tb0[8] | XLXN_6544_tb1[8] | XLXN_6544_tb2[8] | XLXN_6544_tb3[8] | XLXN_6544_tb4[8];
    assign XLXN_6544[9] = XLXN_6544_tb0[9] | XLXN_6544_tb1[9] | XLXN_6544_tb2[9] | XLXN_6544_tb3[9] | XLXN_6544_tb4[9];
    assign XLXN_6544[10] = XLXN_6544_tb0[10] | XLXN_6544_tb1[10] | XLXN_6544_tb2[10] | XLXN_6544_tb3[10] | XLXN_6544_tb4[10];
    assign XLXN_6544[11] = XLXN_6544_tb0[11] | XLXN_6544_tb1[11] | XLXN_6544_tb2[11] | XLXN_6544_tb3[11] | XLXN_6544_tb4[11];
    assign XLXN_6544[12] = XLXN_6544_tb0[12] | XLXN_6544_tb1[12] | XLXN_6544_tb2[12] | XLXN_6544_tb3[12] | XLXN_6544_tb4[12];
    assign XLXN_6544[13] = XLXN_6544_tb0[13] | XLXN_6544_tb1[13] | XLXN_6544_tb2[13] | XLXN_6544_tb3[13] | XLXN_6544_tb4[13];
    assign XLXN_6544[14] = XLXN_6544_tb0[14] | XLXN_6544_tb1[14] | XLXN_6544_tb2[14] | XLXN_6544_tb3[14] | XLXN_6544_tb4[14];
    assign XLXN_6544[15] = XLXN_6544_tb0[15] | XLXN_6544_tb1[15] | XLXN_6544_tb2[15] | XLXN_6544_tb3[15] | XLXN_6544_tb4[15];
    assign XLXN_6544[16] = XLXN_6544_tb0[16] | XLXN_6544_tb1[16] | XLXN_6544_tb2[16] | XLXN_6544_tb3[16] | XLXN_6544_tb4[16];
    assign XLXN_6544[17] = XLXN_6544_tb0[17] | XLXN_6544_tb1[17] | XLXN_6544_tb2[17] | XLXN_6544_tb3[17] | XLXN_6544_tb4[17];
    assign XLXN_6544[18] = XLXN_6544_tb0[18] | XLXN_6544_tb1[18] | XLXN_6544_tb2[18] | XLXN_6544_tb3[18] | XLXN_6544_tb4[18];
    assign data_for_cpu_multiplex[0] = data_for_cpu_multiplex_tb0[0] | data_for_cpu_multiplex_tb1[0] | data_for_cpu_multiplex_tb2[0] | data_for_cpu_multiplex_tb3[0] | data_for_cpu_multiplex_tb4[0] | data_for_cpu_multiplex_tb5[0] | data_for_cpu_multiplex_tb6[0] | data_for_cpu_multiplex_tb7[0] | data_for_cpu_multiplex_tb8[0] | data_for_cpu_multiplex_tb9[0] | data_for_cpu_multiplex_tb10[0] | data_for_cpu_multiplex_tb11[0] | data_for_cpu_multiplex_tb12[0] | data_for_cpu_multiplex_tb13[0] | data_for_cpu_multiplex_tb14[0] | data_for_cpu_multiplex_tb15[0] | data_for_cpu_multiplex_tb16[0];
    assign data_for_cpu_multiplex[1] = data_for_cpu_multiplex_tb0[1] | data_for_cpu_multiplex_tb1[1] | data_for_cpu_multiplex_tb2[1] | data_for_cpu_multiplex_tb3[1] | data_for_cpu_multiplex_tb4[1] | data_for_cpu_multiplex_tb5[1] | data_for_cpu_multiplex_tb6[1] | data_for_cpu_multiplex_tb7[1] | data_for_cpu_multiplex_tb8[1] | data_for_cpu_multiplex_tb9[1] | data_for_cpu_multiplex_tb10[1] | data_for_cpu_multiplex_tb11[1] | data_for_cpu_multiplex_tb12[1] | data_for_cpu_multiplex_tb13[1] | data_for_cpu_multiplex_tb14[1] | data_for_cpu_multiplex_tb15[1] | data_for_cpu_multiplex_tb16[1];
    assign data_for_cpu_multiplex[2] = data_for_cpu_multiplex_tb0[2] | data_for_cpu_multiplex_tb1[2] | data_for_cpu_multiplex_tb2[2] | data_for_cpu_multiplex_tb3[2] | data_for_cpu_multiplex_tb4[2] | data_for_cpu_multiplex_tb5[2] | data_for_cpu_multiplex_tb6[2] | data_for_cpu_multiplex_tb7[2] | data_for_cpu_multiplex_tb8[2] | data_for_cpu_multiplex_tb9[2] | data_for_cpu_multiplex_tb10[2] | data_for_cpu_multiplex_tb11[2] | data_for_cpu_multiplex_tb12[2] | data_for_cpu_multiplex_tb13[2] | data_for_cpu_multiplex_tb14[2] | data_for_cpu_multiplex_tb15[2] | data_for_cpu_multiplex_tb16[2];
    assign data_for_cpu_multiplex[3] = data_for_cpu_multiplex_tb0[3] | data_for_cpu_multiplex_tb1[3] | data_for_cpu_multiplex_tb2[3] | data_for_cpu_multiplex_tb3[3] | data_for_cpu_multiplex_tb4[3] | data_for_cpu_multiplex_tb5[3] | data_for_cpu_multiplex_tb6[3] | data_for_cpu_multiplex_tb7[3] | data_for_cpu_multiplex_tb8[3] | data_for_cpu_multiplex_tb9[3] | data_for_cpu_multiplex_tb10[3] | data_for_cpu_multiplex_tb11[3] | data_for_cpu_multiplex_tb12[3] | data_for_cpu_multiplex_tb13[3] | data_for_cpu_multiplex_tb14[3] | data_for_cpu_multiplex_tb15[3] | data_for_cpu_multiplex_tb16[3];
    assign data_for_cpu_multiplex[4] = data_for_cpu_multiplex_tb0[4] | data_for_cpu_multiplex_tb1[4] | data_for_cpu_multiplex_tb2[4] | data_for_cpu_multiplex_tb3[4] | data_for_cpu_multiplex_tb4[4] | data_for_cpu_multiplex_tb5[4] | data_for_cpu_multiplex_tb6[4] | data_for_cpu_multiplex_tb7[4] | data_for_cpu_multiplex_tb8[4] | data_for_cpu_multiplex_tb9[4] | data_for_cpu_multiplex_tb10[4] | data_for_cpu_multiplex_tb11[4] | data_for_cpu_multiplex_tb12[4] | data_for_cpu_multiplex_tb13[4] | data_for_cpu_multiplex_tb14[4] | data_for_cpu_multiplex_tb15[4] | data_for_cpu_multiplex_tb16[4];
    assign data_for_cpu_multiplex[5] = data_for_cpu_multiplex_tb0[5] | data_for_cpu_multiplex_tb1[5] | data_for_cpu_multiplex_tb2[5] | data_for_cpu_multiplex_tb3[5] | data_for_cpu_multiplex_tb4[5] | data_for_cpu_multiplex_tb5[5] | data_for_cpu_multiplex_tb6[5] | data_for_cpu_multiplex_tb7[5] | data_for_cpu_multiplex_tb8[5] | data_for_cpu_multiplex_tb9[5] | data_for_cpu_multiplex_tb10[5] | data_for_cpu_multiplex_tb11[5] | data_for_cpu_multiplex_tb12[5] | data_for_cpu_multiplex_tb13[5] | data_for_cpu_multiplex_tb14[5] | data_for_cpu_multiplex_tb15[5] | data_for_cpu_multiplex_tb16[5];
    assign data_for_cpu_multiplex[6] = data_for_cpu_multiplex_tb0[6] | data_for_cpu_multiplex_tb1[6] | data_for_cpu_multiplex_tb2[6] | data_for_cpu_multiplex_tb3[6] | data_for_cpu_multiplex_tb4[6] | data_for_cpu_multiplex_tb5[6] | data_for_cpu_multiplex_tb6[6] | data_for_cpu_multiplex_tb7[6] | data_for_cpu_multiplex_tb8[6] | data_for_cpu_multiplex_tb9[6] | data_for_cpu_multiplex_tb10[6] | data_for_cpu_multiplex_tb11[6] | data_for_cpu_multiplex_tb12[6] | data_for_cpu_multiplex_tb13[6] | data_for_cpu_multiplex_tb14[6] | data_for_cpu_multiplex_tb15[6] | data_for_cpu_multiplex_tb16[6];
    assign data_for_cpu_multiplex[7] = data_for_cpu_multiplex_tb0[7] | data_for_cpu_multiplex_tb1[7] | data_for_cpu_multiplex_tb2[7] | data_for_cpu_multiplex_tb3[7] | data_for_cpu_multiplex_tb4[7] | data_for_cpu_multiplex_tb5[7] | data_for_cpu_multiplex_tb6[7] | data_for_cpu_multiplex_tb7[7] | data_for_cpu_multiplex_tb8[7] | data_for_cpu_multiplex_tb9[7] | data_for_cpu_multiplex_tb10[7] | data_for_cpu_multiplex_tb11[7] | data_for_cpu_multiplex_tb12[7] | data_for_cpu_multiplex_tb13[7] | data_for_cpu_multiplex_tb14[7] | data_for_cpu_multiplex_tb15[7] | data_for_cpu_multiplex_tb16[7];
    assign XLXN_7011[0] = XLXN_7011_tb0[0] | XLXN_7011_tb1[0];
    assign XLXN_7011[1] = XLXN_7011_tb0[1] | XLXN_7011_tb1[1];
    assign XLXN_7011[2] = XLXN_7011_tb0[2] | XLXN_7011_tb1[2];
    assign XLXN_7011[3] = XLXN_7011_tb0[3] | XLXN_7011_tb1[3];
    assign XLXN_7011[4] = XLXN_7011_tb0[4] | XLXN_7011_tb1[4];
    assign XLXN_7011[5] = XLXN_7011_tb0[5] | XLXN_7011_tb1[5];
    assign XLXN_7011[6] = XLXN_7011_tb0[6] | XLXN_7011_tb1[6];
    assign XLXN_7011[7] = XLXN_7011_tb0[7] | XLXN_7011_tb1[7];
    assign XLXN_7011[8] = XLXN_7011_tb0[8] | XLXN_7011_tb1[8];
    assign XLXN_7011[9] = XLXN_7011_tb0[9] | XLXN_7011_tb1[9];
    assign XLXN_7011[10] = XLXN_7011_tb0[10] | XLXN_7011_tb1[10];
    assign XLXN_7011[11] = XLXN_7011_tb0[11] | XLXN_7011_tb1[11];
    assign XLXN_7011[12] = XLXN_7011_tb0[12] | XLXN_7011_tb1[12];
    assign XLXN_7011[13] = XLXN_7011_tb0[13] | XLXN_7011_tb1[13];
    assign XLXN_7011[14] = XLXN_7011_tb0[14] | XLXN_7011_tb1[14];
    assign XLXN_7011[15] = XLXN_7011_tb0[15] | XLXN_7011_tb1[15];
    assign cpu_address_bus[0] = cpu_address_bus_tb0[0] | cpu_address_bus_tb1[0];
    assign cpu_address_bus[1] = cpu_address_bus_tb0[1] | cpu_address_bus_tb1[1];
    assign cpu_address_bus[2] = cpu_address_bus_tb0[2] | cpu_address_bus_tb1[2];
    assign cpu_address_bus[3] = cpu_address_bus_tb0[3] | cpu_address_bus_tb1[3];
    assign cpu_address_bus[4] = cpu_address_bus_tb0[4] | cpu_address_bus_tb1[4];
    assign cpu_address_bus[5] = cpu_address_bus_tb0[5] | cpu_address_bus_tb1[5];
    assign cpu_address_bus[6] = cpu_address_bus_tb0[6] | cpu_address_bus_tb1[6];
    assign cpu_address_bus[7] = cpu_address_bus_tb0[7] | cpu_address_bus_tb1[7];
    assign cpu_address_bus[8] = cpu_address_bus_tb0[8] | cpu_address_bus_tb1[8];
    assign cpu_address_bus[9] = cpu_address_bus_tb0[9] | cpu_address_bus_tb1[9];
    assign cpu_address_bus[10] = cpu_address_bus_tb0[10] | cpu_address_bus_tb1[10];
    assign cpu_address_bus[11] = cpu_address_bus_tb0[11] | cpu_address_bus_tb1[11];
    assign cpu_address_bus[12] = cpu_address_bus_tb0[12] | cpu_address_bus_tb1[12];
    assign cpu_address_bus[13] = cpu_address_bus_tb0[13] | cpu_address_bus_tb1[13];
    assign cpu_address_bus[14] = cpu_address_bus_tb0[14] | cpu_address_bus_tb1[14];
    assign cpu_address_bus[15] = cpu_address_bus_tb0[15] | cpu_address_bus_tb1[15];

    assign linecop_pc_o = linecop_pc[18:0];
    assign dbg_core = {cpu_databus_in[7:0], XLXN_2825, XLXN_7421, XLXN_2828, background_pixel, ywindow, xwindow, rgb_oe, palette_index};
    assign dbg_pal = {colour_select[8], palette_wr_addr[8]};
    assign dbg_pdata = {dbg_pd1, dbg_pd0};
endmodule
