`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// karabas_go_osca_top - OSCA (V6Z80P+ v1.1, converted schematics) on Karabas Go.
//
// STATUS: reviewed and lint-checked with yosys, NOT built with ISE / not run on hardware.
//   done   : clocks (96 MHz DCM_CLKGEN + 16 MHz from the memory wrapper), soft Z80, three-SRAM wrapper,
//            VGA out (4 bit -> 8 bit), audio (1 bit -> PCM5102), SD card (direct SPI), USB keyboard
//            through the MCU (PS/2 device emulation), boot: a replacement boot ROM jumps to FLOS, which the
//            MCU ROM loader has written into system RAM at $1000 (no PIC / EEPROM needed)
//   NOT done: joystick serial protocol (serjoy2), PS/2 mouse (MCU MS_* -> PS/2 packets), second SD, RTC
//////////////////////////////////////////////////////////////////////////////////
module karabas_go_osca_top (
    input  wire        CLK_50MHZ,
    // SRAM
    output wire [20:0] MA,
    inout  wire [15:0] MD,
    output wire [1:0]  MWR_N,
    output wire [1:0]  MRD_N,
    // video / audio
    output wire [7:0]  VGA_R, VGA_G, VGA_B,
    output wire        VGA_HS, VGA_VS,
    output wire        V_CLK,                // pixel clock of the VGA DAC
    output wire        FT_OE_N, FT_SPI_CS_N, FT_SPI_SCK,   // FT812 video: FT_OE_N = 1 keeps it off the VGA bus
    output wire        DAC_LRCK, DAC_DAT, DAC_BCK, DAC_MUTE,
    // SD card
    output wire        SD_CS_N, SD_DI, SD_CLK,
    input  wire        SD_DO,
    // MCU (USB keyboard / mouse / joysticks)
    input  wire        MCU_MOSI, MCU_SCK, MCU_CS_N,
    output wire        MCU_MISO,
    // SDRAM (system RAM); CS_N and CKE are tied on the board
    output wire        SDR_CLK, SDR_RAS_N, SDR_CAS_N, SDR_WE_N,
    output wire [1:0]  SDR_BA,
    output wire [12:0] SDR_A,
    output wire [1:0]  SDR_DQM,
    inout  wire [15:0] SDR_DQ
);
    // ---------------------------------------------------------------- clocks
    wire clk96_raw, dcm_locked, clk96, clk16_gen, clk16;
    DCM_CLKGEN #(
        .CLKFX_DIVIDE(25), .CLKFX_MULTIPLY(48),      // 50 MHz * 48 / 25 = 96 MHz = 6 * 16 MHz
        .CLKIN_PERIOD(20.0), .SPREAD_SPECTRUM("NONE"), .STARTUP_WAIT("FALSE"),
        .CLKFXDV_DIVIDE(2), .CLKFX_MD_MAX(0.0)
    ) u_dcm (
        .CLKIN(CLK_50MHZ), .CLKFX(clk96_raw), .CLKFX180(), .CLKFXDV(), .LOCKED(dcm_locked), .STATUS(),
        .PROGCLK(1'b0), .PROGDATA(1'b0), .PROGEN(1'b0), .PROGDONE(), .FREEZEDCM(1'b0), .RST(1'b0));
    BUFG u_bufg96 (.I(clk96_raw), .O(clk96));
    BUFG u_bufg16 (.I(clk16_gen), .O(clk16));        // 16 MHz made by kg_osca_mem's tick counter

    // reset: keep OSCA in reset until the DCM has locked (jumper_reset = 0 requests a reset)
    reg [3:0] lock_sr = 4'h0;
    always @(posedge clk16) lock_sr <= {lock_sr[2:0], dcm_locked};
    wire run = lock_sr[3];
    wire        romloader_active;
    wire        sram_run, sram_done, sram_alias0;  wire [20:0] s_ma, s_amask;  wire [15:0] s_md;  wire s_oe;  wire [1:0] s_wr_n, s_rd_n;  wire [7:0] s_dm0, s_dm1;
    wire chk_run, chk_done, chk_mdone, chk_tmo, chk_wr, chk_rst, chk_pol, chk_cap;  wire [18:0] chk_addr;  wire [7:0] chk_data, chk_cok, chk_cbad, chk_fe, chk_fact;  wire [15:0] chk_efin, chk_fa;
    // hold OSCA in reset while the MCU writes the boot image (romloader_active is a clk96 signal)
    reg [1:0] load_s = 2'b00;
    always @(posedge clk16) load_s <= {load_s[0], romloader_active | chk_run | sram_run};
    reg [1:0] init_s = 2'b00;
    always @(posedge clk16) init_s <= {init_s[0], sd_init};

    // ---------------------------------------------------------------- MCU: USB keyboard scan codes
    wire [7:0] kb_scancode;  wire kb_scancode_upd;
    wire [2:0] unused_ms_b;
    wire        rom_wr;
    wire [31:0] rom_addr;
    wire [7:0]  rom_data;
    wire sd_init;
    reg  sd_init_ever = 1'b0;                       // the SDRAM may be re-initialised later by the self test: the MCU link must not be reset then
    always @(posedge clk96) if (sd_init) sd_init_ever <= 1'b1;
    kg_mcu #(.ENABLE_RTC(0), .ENABLE_UART(0), .ENABLE_MATRIX(0), .ENABLE_FILE(1), .FILE_TO_ROM(1), .ENABLE_FT(0), .ENABLE_SD2(0)) u_mcu (
        .CLK(clk96), .N_RESET(dcm_locked & sd_init_ever),   // the loader must not start before the SDRAM is initialised
        .MCU_MOSI(MCU_MOSI), .MCU_MISO(MCU_MISO), .MCU_SCK(MCU_SCK), .MCU_SS(MCU_CS_N),
        .MCU_SPI_FT_SS(1'b1), .MCU_SPI_SD2_SS(1'b1), .MCU_BURST_CS_N(1'b1), .MCU_BURST_READY(),
        .MS_X(), .MS_Y(), .MS_B(unused_ms_b), .MS_Z(), .MS_UPD(),
        .KB_STATUS(), .KB_DAT0(), .KB_DAT1(), .KB_DAT2(), .KB_DAT3(), .KB_DAT4(), .KB_DAT5(),
        .KB_SCANCODE(kb_scancode), .KB_SCANCODE_UPD(kb_scancode_upd), .XT_SCANCODE(), .XT_SCANCODE_UPD(),
        .PS2_COMMAND(16'h0000), .PS2_COMMAND_WR(1'b0),
        .JOY_L(), .JOY_R(), .BTNS(),
        .RTC_A(8'h00), .RTC_DI(8'h00), .RTC_DO(), .RTC_CS(1'b0), .RTC_WR_N(1'b1),
        .UART_RX_DATA(), .UART_RX_IDX(), .UART_TX_DATA(8'h00), .UART_TX_WR(1'b0), .UART_TX_MODE(1'b0),
        .UART_DLM(8'h00), .UART_DLL(8'h00), .UART_DLM_WR(1'b0), .UART_DLL_WR(1'b0),
        .FT_MISO(1'b0), .SD2_MISO(1'b0), .MATRIX_CMD(24'h000000), .MATRIX_CMD_WR(1'b0),
        .DEBUG_ADDR(16'h0000), .DEBUG_DATA(16'h0000), .IMG_Q_WR(1'b0), .IMG_Q_DI(24'h000000),
        .FDD_CHNG_REQ(1'b0), .FDD_CHNG_DS(2'b00), .ESP_UART_RX_DATA(8'h00), .ESP_UART_RX_WR(1'b0),
        .ROMLOADER_ACTIVE(romloader_active), .ROMLOAD_ADDR(rom_addr), .ROMLOAD_DATA(rom_data), .ROMLOAD_WR(rom_wr),
        .FLASHBOOT_START(1'b0), .FLASHBOOT_COREID(5'h00), .PRN_DATA(8'h00), .PRN_WR(1'b0));

    // clk96 -> clk16 crossing of the (rare) scan code bytes: hold the byte, toggle a flag
    reg [7:0] kb_hold = 8'h00; reg kb_tog = 1'b0;
    always @(posedge clk96) if (kb_scancode_upd) begin kb_hold <= kb_scancode; kb_tog <= ~kb_tog; end
    reg [2:0] kb_tog_s = 3'b000;
    always @(posedge clk16) kb_tog_s <= {kb_tog_s[1:0], kb_tog};
    wire kb_stb = kb_tog_s[2] ^ kb_tog_s[1];

    // ---------------------------------------------------------------- SoC
    wire [20:0] ma;  wire [15:0] md_o;  wire md_oe;
    wire col_red_a, col_red_b, col_red_c, col_red_d, col_green_a, col_green_b, col_green_c, col_green_d;
    wire col_blue_a, col_blue_b, col_blue_c, col_blue_d, horizontal_sync, tv_sync, audio_left, audio_right;
    wire kb_clk_pull, kb_dat_pull, kb_clk_line, kb_dat_line;
    wire sdc_clk, sdc_cs, sdc_din, sdc_pow, system_reset_out;

    // the port of the loader / self test into the SDRAM controller: registered (one clk96 later, all four signals alike) to keep the controller's address path short
    reg        ld_act_r = 1'b0, ld_wr_r = 1'b0;  reg [31:0] ld_addr_r = 32'd0;  reg [7:0] ld_data_r = 8'd0;
    always @(posedge clk96) begin
        ld_act_r  <= romloader_active | chk_run;
        ld_addr_r <= chk_run ? {13'd0, chk_addr} : rom_addr;
        ld_data_r <= chk_run ? chk_data : rom_data;
        ld_wr_r   <= chk_run ? chk_wr : rom_wr;
    end
    wire [32:0] dbg;
    wire [26:0] dbg2;  wire [29:0] dbg3;  wire [1:0] dbg4;
    wire [7:0] chk_rdata;  wire chk_rdvalid;
    kg_osca_soc soc (
        .clk_mem(clk96), .clk16_gen(clk16_gen), .clk16(clk16),
        .ma(ma), .md_o(md_o), .md_oe(md_oe), .md_i(MD), .mwr_n(MWR_N), .mrd_n(MRD_N),
        .col_red_a(col_red_a), .col_red_b(col_red_b), .col_red_c(col_red_c), .col_red_d(col_red_d),
        .col_green_a(col_green_a), .col_green_b(col_green_b), .col_green_c(col_green_c), .col_green_d(col_green_d),
        .col_blue_a(col_blue_a), .col_blue_b(col_blue_b), .col_blue_c(col_blue_c), .col_blue_d(col_blue_d),
        .horizontal_sync(horizontal_sync), .tv_sync(tv_sync),
        .audio_left(audio_left), .audio_right(audio_right),
        .ps2_kb_clock_in(kb_clk_line), .ps2_kb_data_in(kb_dat_line),
        .ps2_ms_clock_in(1'b1), .ps2_ms_data_in(1'b1),
        .ps2_kb_clock_out(kb_clk_pull), .ps2_kb_data_out(kb_dat_pull),
        .ps2_ms_clock_out(), .ps2_ms_data_out(),
        .sdc_clk(sdc_clk), .sdc_cs(sdc_cs), .sdc_din(sdc_din), .sdc_pow(sdc_pow), .sdc_dout(SD_DO),
        .serial_tx_pin(), .serial_rx_pin(1'b1),
        .joystick_clock_out(), .joystick_data_in(1'b1),        // TODO: serjoy2 protocol
        .ld_active(ld_act_r), .ld_addr(ld_addr_r), .ld_data(ld_data_r), .ld_wr(ld_wr_r),   // boot image from the MCU
        .jumper_nmi(1'b1), .jumper_reset(run & ~load_s[1] & init_s[1]), .jumper_vga(1'b0),   // 0 = VGA video mode
        .expansion_pin_a(), .expansion_pin_b(),
        .system_reset_out(system_reset_out),
        .sdram_reset(~dcm_locked | chk_rst), .sdram_cap_late(chk_cap), .sdram_init_done(sd_init),
        .sd_ba(SDR_BA), .sd_a(SDR_A), .sd_dqm(SDR_DQM), .sd_ras_n(SDR_RAS_N), .sd_cas_n(SDR_CAS_N), .sd_we_n(SDR_WE_N), .sd_dq(SDR_DQ),
        .dbg(dbg), .chk_rdata(chk_rdata), .chk_rdvalid(chk_rdvalid), .dbg2(dbg2), .dbg3(dbg3), .dbg4(dbg4),
        .t_en(sram_run), .t_ma(s_ma), .t_md(s_md), .t_oe(s_oe), .t_wr_n(s_wr_n), .t_rd_n(s_rd_n));

    // SDRAM clock: a copy of clk96 (a phase-shifted copy will probably be needed on the board, see kg_osca_sdram.v)
    wire clk96_n = ~clk96;
    ODDR2 #(.DDR_ALIGNMENT("NONE"), .INIT(1'b0), .SRTYPE("SYNC")) u_sdrclk (.Q(SDR_CLK), .C0(clk96), .C1(clk96_n), .CE(1'b1), .D0(~chk_pol), .D1(chk_pol), .R(1'b0), .S(1'b0));

    // SRAM pads
    assign MA = ma;
    assign MD = md_oe ? md_o : 16'bz;

    // PS/2 keyboard device (open drain: *_pull = 1 holds the line low - polarity to be confirmed on hardware)
    kg_osca_ps2dev u_kbd (.clk(clk16), .scan_in(kb_hold), .scan_stb(kb_stb),
                          .host_clk_pull(kb_clk_pull), .host_data_pull(kb_dat_pull),
                          .clk_line(kb_clk_line), .data_line(kb_dat_line));

    // video: OSCA's a..d are the 4 bits of each channel, a = MSB;  VGA-mode syncs: HS and (tv_sync) VS
    wire [7:0] osca_r = {col_red_a,   col_red_b,   col_red_c,   col_red_d,   col_red_a,   col_red_b,   col_red_c,   col_red_d};
    wire [7:0] osca_g = {col_green_a, col_green_b, col_green_c, col_green_d, col_green_a, col_green_b, col_green_c, col_green_d};
    wire [7:0] osca_b = {col_blue_a,  col_blue_b,  col_blue_c,  col_blue_d,  col_blue_a,  col_blue_b,  col_blue_c,  col_blue_d};

    // ---- bring-up status screen (kg_dbg_video), shown until OSCA has been running for ~2.8 s.  Independent of OSCA's own video.
    wire osca_run = run & ~load_s[1] & init_s[1];
    reg        ld_seen = 1'b0, ld_done = 1'b0, wr_seen = 1'b0;
    reg [15:0] ld_bytes = 16'd0;
    reg [31:0] dbg_hold = 32'd0;
    always @(posedge clk96) begin
        if (romloader_active) ld_seen <= 1'b1;
        if (ld_seen && !romloader_active) ld_done <= 1'b1;
        if (rom_wr) begin wr_seen <= 1'b1; if (ld_bytes != 16'hffff) ld_bytes <= ld_bytes + 16'd1; end
        if (osca_run) dbg_hold <= dbg_hold + 32'd1;
    end
    // SDRAM self test: read the loaded image back through the loader port (the core is still in reset), compare with a copy in BRAM
    kg_sdram_check u_chk (.clk(clk96), .wr_i(rom_wr), .addr_i(rom_addr[14:0]), .data_i(rom_data), .go(ld_seen & ~romloader_active), .init_done(sd_init), .run(chk_run),
        .addr_o(chk_addr), .wr_o(chk_wr), .data_o(chk_data), .rst_o(chk_rst), .pol_o(chk_pol), .cap_o(chk_cap),
        .rd_valid(chk_rdvalid), .rdata(chk_rdata), .done(chk_done), .matrix_done(chk_mdone), .timeout(chk_tmo), .cell_ok(chk_cok), .cell_bad(chk_cbad),
        .err_final(chk_efin), .first_addr(chk_fa), .first_exp(chk_fe), .first_act(chk_fact));
    // SRAM self test after the SDRAM self test (the core is still in reset)
    kg_sram_test u_sram (.clk(clk96), .go(chk_done), .run(sram_run), .ma(s_ma), .md(s_md), .oe(s_oe), .wr_n(s_wr_n), .rd_n(s_rd_n), .md_i(MD),
        .done(sram_done), .dmask0(s_dm0), .dmask1(s_dm1), .amask(s_amask), .alias0(sram_alias0));
    reg chk_seen = 1'b0;  always @(posedge clk96) if (chk_run) chk_seen <= 1'b1;
    wire [7:0] dbg_r, dbg_g, dbg_b;  wire dbg_hs, dbg_vs;
    // ---- measurements on OSCA's own video (clk16 domain): HS period, lines per frame, non-black pixels per frame, colour bits ever set
    reg hq16 = 1'b1, vq16 = 1'b1;  reg [15:0] hcnt = 16'd0, m_hs = 16'd0, m_lines = 16'd0, nbcnt = 16'd0, m_nb = 16'd0;  reg [15:0] lcnt = 16'd0;  reg [11:0] colacc = 12'd0, colv = 12'd0;
    wire [11:0] osca_rgb = {col_red_a, col_red_b, col_red_c, col_red_d, col_green_a, col_green_b, col_green_c, col_green_d, col_blue_a, col_blue_b, col_blue_c, col_blue_d};
    always @(posedge clk16) begin
        hq16 <= horizontal_sync;  vq16 <= tv_sync;
        hcnt <= hcnt + 16'd1;
        if (hq16 && !horizontal_sync) begin m_hs <= hcnt; hcnt <= 16'd1; lcnt <= lcnt + 16'd1; end
        if (osca_rgb != 12'd0 && nbcnt != 16'hffff) nbcnt <= nbcnt + 16'd1;
        colacc <= colacc | osca_rgb;
        if (vq16 && !tv_sync) begin m_lines <= lcnt; lcnt <= 16'd0; m_nb <= nbcnt; nbcnt <= 16'd0; colv <= colacc; colacc <= 12'd0; end
    end

    reg [26:0] hb27 = 27'd0;
    always @(posedge clk96) hb27 <= hb27 + 27'd1;
    // CPU activity for the status screen (clk16 domain; dbg = {reset_out, z80_wait, sdram_wait_n, busak_n, wr_n, rd_n, iorq_n, mreq_n, m1_n, d[7:0], a[15:0]})
    wire [15:0] c_a = dbg[15:0];   wire [7:0] c_d = dbg[23:16];
    wire c_m1_n = dbg[24], c_mreq_n = dbg[25], c_iorq_n = dbg[26], c_rd_n = dbg[27], c_wr_n = dbg[28], c_busak_n = dbg[29], c_sdwait_n = dbg[30], c_zwait_n = dbg[31], c_rst_ok = dbg[32];
    reg [15:0] pc_cur = 16'h0000, pc_snap = 16'h0000, pc_max = 16'h0000;  reg [7:0] op_cur = 8'h00, op_snap = 8'h00;
    reg [7:0]  f2 = 8'h00;  reg dvs_q = 1'b1;
    reg [15:0] pcmap_hi = 16'd0, pcmap_lo = 16'd0;   // sticky: opcode fetch seen in 4K page A[15:12] / in 1K block A[13:10] of 0000-3FFF
    wire fetch = ~c_m1_n & ~c_mreq_n & ~c_rd_n;
    always @(posedge clk16) begin
        dvs_q <= dbg_vs;
        if (fetch) begin pc_cur <= c_a; op_cur <= c_d; f2[7] <= 1'b1; if (c_a > pc_max) pc_max <= c_a;
            pcmap_hi[c_a[15:12]] <= 1'b1;  if (c_a[15:14] == 2'b00) pcmap_lo[c_a[13:10]] <= 1'b1; end
        if (dvs_q && !dbg_vs) begin pc_snap <= pc_cur; op_snap <= op_cur; end        // one sample per frame
        f2[0] <= ~(c_zwait_n & c_sdwait_n);
        if (!c_sdwait_n) f2[1] <= 1'b1;
        if (!c_zwait_n)  f2[2] <= 1'b1;
        if (!c_busak_n)  f2[3] <= 1'b1;
        if (!c_iorq_n && !c_wr_n) f2[4] <= 1'b1;
        if (!c_iorq_n && !c_rd_n && c_m1_n) f2[5] <= 1'b1;
        f2[6] <= c_rst_ok;
    end
    // ---- inside the running core (clk16 domain), per frame: rgb_oe high, x/y window both high, palette index non-zero, background pixel non-zero
    wire [7:0] k_pal = dbg3[7:0];  wire k_oe = dbg3[8], k_xw = dbg3[9], k_yw = dbg3[10];  wire [7:0] k_bg = dbg3[18:11];
    wire [7:0] k_cd = dbg3[29:22];  wire k_pclk = dbg3[21], k_pen1 = dbg3[20], k_pen0 = dbg3[19];
    wire k_pw = (k_pen0 | k_pen1) & ~k_pclk;          // palette write strobe (the palette RAM is clocked by the inverted cpu_write)
    reg pclk_q = 1'b0;  reg [15:0] k_m4 = 16'd0, k_m5 = 16'd0;  reg [17:0] k_c0 = 18'd0, k_c1 = 18'd0;  reg [15:0] k_c0q = 16'd0, k_c1q = 16'd0,  k_c2 = 16'd0, k_c3 = 16'd0, k_m0 = 16'd0, k_m1 = 16'd0, k_m2 = 16'd0, k_m3 = 16'd0;
    always @(posedge clk16) begin
        pclk_q <= k_pclk;
        if (k_pclk && !pclk_q && (k_pen0 | k_pen1)) begin                      // rising edge of the palette RAM clock with the write enabled = one write of the palette
            if (k_m4 != 16'hffff) k_m4 <= k_m4 + 16'd1;
            if (k_cd != 8'd0 && k_m5 != 16'hffff) k_m5 <= k_m5 + 16'd1;
        end
        if (k_oe) k_c0 <= k_c0 + 18'd1;                                         // rgb_oe high cycles per frame
        if (dbg4[1]) k_c1 <= k_c1 + 18'd1;                                      // cycles per frame in which the displayed palette page is 1
        if (k_pal != 8'd0 && k_c2 != 16'hffff) k_c2 <= k_c2 + 16'd1;
        if (k_bg != 8'd0 && k_c3 != 16'hffff) k_c3 <= k_c3 + 16'd1;
        if (vq16 && !tv_sync) begin k_m2 <= k_c2; k_c2 <= 16'd0; k_m3 <= k_c3; k_c3 <= 16'd0; k_c0q <= k_c0[17:2]; k_c0 <= 18'd0; k_c1q <= k_c1[17:2]; k_c1 <= 18'd0; end
    end
    kg_dbg_video u_dbg (.clk16(clk16),
        .flags({wr_seen, hb27[26], osca_run, ld_bytes >= 16'd20142, ld_done, ld_seen, sd_init, dcm_locked}), .flags2(f2),
        .flags3({chk_cap, chk_pol, chk_done, chk_done & (chk_efin == 16'd0), ~chk_tmo, chk_mdone, chk_seen & 1'b1, 1'b1}),
        .cell_ok(chk_cok), .cell_bad(chk_cbad), .err_final(chk_efin), .first_addr(k_m4), .first_ea(k_m5),
        .m_hs(m_hs), .m_lines(pcmap_hi), .m_nb(m_nb), .m_col(pcmap_lo),
        .bytes(ld_bytes), .pc_s(pc_snap), .pc_max(pc_max), .op_s(op_snap), .r(dbg_r), .g(dbg_g), .b(dbg_b), .hs(dbg_hs), .vs(dbg_vs));
    wire show_dbg = ~dbg_hold[29];   // bring-up: the status screen and OSCA's own picture alternate (5.6 s each) while OSCA runs after OSCA is released (bring-up)
    // The board has a VGA DAC clocked by V_CLK (as in the NanoMig / Profi cores): register RGB and syncs on the pixel clock and
    // give the DAC the inverted pixel clock (it samples in the middle of the pixel).  The FT812 is kept off the VGA bus.
    reg [7:0] vo_r = 8'h00, vo_g = 8'h00, vo_b = 8'h00;  reg vo_hs = 1'b1, vo_vs = 1'b1;
    always @(posedge clk16) begin
        vo_r  <= show_dbg ? dbg_r  : osca_r;
        vo_g  <= show_dbg ? dbg_g  : osca_g;
        vo_b  <= show_dbg ? dbg_b  : osca_b;
        vo_hs <= show_dbg ? dbg_hs : horizontal_sync;
        vo_vs <= show_dbg ? dbg_vs : tv_sync;
    end
    assign VGA_R = vo_r;  assign VGA_G = vo_g;  assign VGA_B = vo_b;  assign VGA_HS = vo_hs;  assign VGA_VS = vo_vs;
    wire clk16_n = ~clk16;
    ODDR2 #(.DDR_ALIGNMENT("NONE"), .INIT(1'b0), .SRTYPE("SYNC")) u_vclk (.Q(V_CLK), .C0(clk16), .C1(clk16_n), .CE(1'b1), .D0(1'b0), .D1(1'b1), .R(1'b0), .S(1'b0));
    assign FT_OE_N = 1'b1;  assign FT_SPI_CS_N = 1'b1;  assign FT_SPI_SCK = 1'b0;

    // audio
    wire [15:0] pcm_l, pcm_r;
    kg_osca_audio u_aud (.clk(clk16), .pdm_l(audio_left), .pdm_r(audio_right), .left(pcm_l), .right(pcm_r));
    kg_pcm5102 #(.DIV_BITS(1)) u_dac (.clk(clk16), .reset(~run), .left(pcm_l), .right(pcm_r),
                                      .din(DAC_DAT), .bck(DAC_BCK), .lrck(DAC_LRCK));
    assign DAC_MUTE = 1'b1;

    // SD card straight from the core's SPI engine (pow is ignored)
    assign SD_CLK  = sdc_clk;
    assign SD_CS_N = sdc_cs;
    assign SD_DI   = sdc_din;
endmodule
