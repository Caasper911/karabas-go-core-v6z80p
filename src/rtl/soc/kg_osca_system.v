`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// kg_osca_system - OSCA (V6Z80P+ v1.1, converted schematics) with what every Karabas board around it has: the clocks
// (DCM_CLKGEN + one PLL: 96, 16, 32 MHz), the SoC (core, soft Z80, SRAM wrapper, SDRAM system RAM), the MCU link (USB keyboard
// as a PS/2 device, joysticks, the ROM loader of FLOS, OSD switches and reset, the file mounter), the SD card (the card in the slot
// or the emulated card on an image, kg_sd_emu), the OSD overlay.  The board tops (karabas_<board>_osca_top.v) put the video
// (vid_*, clk32 domain) and the audio (pcm_*, clk16 domain) out on their DAC / HDMI and wire the burst lines of the MCU.
//
// The SRAM, SDRAM, SD and MCU pins are the same on Karabas Go, Mini and Mini G.  The instance of this module in the tops is "osca":
// the timing constraints of the .ucf files name its parts as osca/...
//////////////////////////////////////////////////////////////////////////////////
module kg_osca_system (
    input  wire        CLK_50MHZ,
    // SRAM
    output wire [20:0] MA,
    inout  wire [15:0] MD,
    output wire [1:0]  MWR_N,
    output wire [1:0]  MRD_N,
    // SD card
    output wire        SD_CS_N, SD_DI, SD_CLK,
    input  wire        SD_DO,
    // MCU (USB keyboard / mouse / joysticks, ROM loader, OSD, file mounter)
    input  wire        MCU_MOSI, MCU_SCK, MCU_CS_N,
    output wire        MCU_MISO,
    input  wire        mcu_burst_cs_n,        // bursts (karabas-go-firmware docs/burst_protocol.md): the pins differ per board
    output wire        mcu_burst_ready,
    // SDRAM (system RAM); CS_N and CKE are tied on the boards
    output wire        SDR_CLK, SDR_RAS_N, SDR_CAS_N, SDR_WE_N,
    output wire [1:0]  SDR_BA,
    output wire [12:0] SDR_A,
    output wire [1:0]  SDR_DQM,
    inout  wire [15:0] SDR_DQ,
    // clocks for the board top (one PLL, rising edges together)
    output wire        clk16,
    output wire        clk32,
    output wire        clk8,                  // 8 MHz (the FT812 clock of the Mini / Mini G)
    output wire        dvi_only,              // kg_mcu: the display takes DVI only (no HDMI audio)
    output wire        run,                   // the clocks have locked (clk16 domain)
    // video, clk32 domain (not registered): RGB with the OSD, the syncs (low active, VGA mode: 31.5 kHz)
    output wire [23:0] osd_rgb,
    output wire        mix_hs,
    output wire        mix_vs,
    output wire        vid_de,                // the display area (DE of HDMI), aligned with osd_rgb
    // audio, clk16 registers: the mixer sums of OSCA's sound system as signed 16 bit
    output reg  [15:0] pcm_l = 16'h0000,
    output reg  [15:0] pcm_r = 16'h0000
);
    // ---------------------------------------------------------------- clocks
    wire clk96_raw, dcm_locked, clk96, clk16_gen;
    DCM_CLKGEN #(
        .CLKFX_DIVIDE(25), .CLKFX_MULTIPLY(48),      // 50 MHz * 48 / 25 = 96 MHz = 6 * 16 MHz
        .CLKIN_PERIOD(20.0), .SPREAD_SPECTRUM("NONE"), .STARTUP_WAIT("FALSE"),
        .CLKFXDV_DIVIDE(2), .CLKFX_MD_MAX(0.0)
    ) u_dcm (
        .CLKIN(CLK_50MHZ), .CLKFX(clk96_raw), .CLKFX180(), .CLKFXDV(), .LOCKED(dcm_locked), .STATUS(),
        .PROGCLK(1'b0), .PROGDATA(1'b0), .PROGEN(1'b0), .PROGDONE(), .FREEZEDCM(1'b0), .RST(1'b0));
    // clk96 and clk16 both come from one PLL (VCO 576 MHz = 96 MHz * 6): their rising edges coincide, as in the simulation.  (clk16 used to be the
    // memory wrapper's divide-by-6 counter through a BUFG: its edges came ~half a 96 MHz period late, so every clk16 <-> clk96 transfer on the
    // board was shifted by a tick against the simulation, and ISE did not analyse these paths.)  kg_osca_mem (KG_PLL16) aligns its tick counter to clk16.
    wire pll_fb, clk96_pll, clk16_pll, clk32_pll, clk8_pll, pll_locked;
    PLL_BASE #(
        .BANDWIDTH("OPTIMIZED"), .CLK_FEEDBACK("CLKFBOUT"), .COMPENSATION("INTERNAL"),
        .DIVCLK_DIVIDE(1), .CLKFBOUT_MULT(6), .CLKFBOUT_PHASE(0.0), .CLKIN_PERIOD(10.417),
        .CLKOUT0_DIVIDE(6),  .CLKOUT0_PHASE(0.0), .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT1_DIVIDE(36), .CLKOUT1_PHASE(0.0), .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT2_DIVIDE(18), .CLKOUT2_PHASE(0.0), .CLKOUT2_DUTY_CYCLE(0.5),     // 32 MHz: the video output with the OSD (see below)
        .CLKOUT3_DIVIDE(72), .CLKOUT3_PHASE(0.0), .CLKOUT3_DUTY_CYCLE(0.5),     // 8 MHz: FT_CLK_OUT of the Mini (unused on the Go)
        .REF_JITTER(0.1)
    ) u_pll (
        .CLKIN(clk96_raw), .CLKFBIN(pll_fb), .CLKFBOUT(pll_fb), .RST(~dcm_locked), .LOCKED(pll_locked),
        .CLKOUT0(clk96_pll), .CLKOUT1(clk16_pll), .CLKOUT2(clk32_pll), .CLKOUT3(clk8_pll), .CLKOUT4(), .CLKOUT5());
    BUFG u_bufg96 (.I(clk96_pll), .O(clk96));
    BUFG u_bufg16 (.I(clk16_pll), .O(clk16));
    BUFG u_bufg32 (.I(clk32_pll), .O(clk32));
    BUFG u_bufg8  (.I(clk8_pll),  .O(clk8));

    // reset: keep OSCA in reset until the DCM has locked (jumper_reset = 0 requests a reset)
    reg [3:0] lock_sr = 4'h0;
    always @(posedge clk16) lock_sr <= {lock_sr[2:0], dcm_locked & pll_locked};
    assign run = lock_sr[3];
    wire        romloader_active;
    reg [15:0] f_a = 16'd0;  reg [7:0] f_d = 8'd0;                 // address / opcode of the current opcode fetch
    reg [31:0] dbg_hold = 32'd0;                       // counts while OSCA runs: bit 29 = status screen / OSCA picture, bit 30 = fixed palette test
`ifdef KG_DEBUG_SCREEN
    wire show_dbg = ~dbg_hold[29];   // bring-up: the status screen and OSCA's own picture alternate (5.6 s each) while OSCA runs
    wire dbg_fix  = dbg_hold[30];    // bring-up: every other OSCA picture with the fixed 8-colour palette
`else
    // normal build: OSCA's picture only; the status screen, its measurements and the palette / bus probes have no consumer and are trimmed
    wire show_dbg = 1'b0;
    wire dbg_fix  = 1'b0;
`endif
    wire        vram_run, vram_done;  wire [18:0] v_addr;  wire v_wr_n;  wire [7:0] v_wd;  wire [15:0] vt_es, vt_er, sv_err;  wire [63:0] vt_act;  wire [7:0] sv_a0, sv_a1;  wire sv_done;
    wire        sram_run, sram_done, sram_alias0;  wire [20:0] s_ma, s_amask;  wire [15:0] s_md;  wire s_oe;  wire [1:0] s_wr_n, s_rd_n;  wire [7:0] s_dm0, s_dm1;
    wire chk_run, chk_done, chk_mdone, chk_tmo, chk_wr, chk_rst, chk_pol, chk_cap;  wire [18:0] chk_addr;  wire [7:0] chk_fexp;  wire [7:0] chk_data, chk_cok, chk_cbad, chk_fe, chk_fact;  wire [15:0] chk_efin, chk_fa;
    // hold OSCA in reset while the MCU writes the boot image (romloader_active is a clk96 signal)
    reg [1:0] load_s = 2'b00;
    always @(posedge clk16) load_s <= {load_s[0], romloader_active | chk_run | sram_run | vram_run};
    reg [1:0] init_s = 2'b00;
    always @(posedge clk16) init_s <= {init_s[0], sd_init};

    // ---------------------------------------------------------------- MCU: USB keyboard scan codes
    wire [7:0] kb_scancode;  wire kb_scancode_upd;
    wire [12:0] joy_l, joy_r;            // kg_mcu: bit 0 on, 1 up, 2 down, 3 left, 4 right, 5 start, 6 a, 7 b, 8 c, 9 x, 10 y, 11 z, 12 mode
    reg  [11:0] joy_s1 = 12'd0, joy_s2 = 12'd0;      // kg_mcu runs on clk96: two clk16 registers before the core reads them
    always @(posedge clk16) begin joy_s1 <= {joy_r[7], joy_r[6], joy_r[4], joy_r[3], joy_r[2], joy_r[1], joy_l[7], joy_l[6], joy_l[4], joy_l[3], joy_l[2], joy_l[1]}; joy_s2 <= joy_s1; end
    wire [2:0] unused_ms_b;
    wire        rom_wr;
    wire [31:0] rom_addr;
    wire [7:0]  rom_data;
    wire sd_init;
    wire [1:0]  hw_btn;                  // the buttons of the board (kg_mcu BTNS): [0] reset
    wire [15:0] softsw_command, osd_command;
    wire        mcu_busy;
    reg  sd_init_ever = 1'b0;                      // the SDRAM may be re-initialised later by the self test: the MCU link must not be reset then
    always @(posedge clk96) if (sd_init) sd_init_ever <= 1'b1;
    // the file mounter (ENABLE_IMG): slot 0 = the image of the emulated SD card (kg_sd_emu, OSD item "SD image")
    wire [7:0]  img_mounted, img_data, img_result;  wire [63:0] img_size;  wire img_data_wr, img_result_wr, img_q_wr, img_q_ack;
    wire [8:0]  img_data_addr;  wire [15:0] img_sum;  wire [23:0] img_q_di;
    kg_mcu #(.ENABLE_RTC(0), .ENABLE_UART(0), .ENABLE_MATRIX(0), .ENABLE_FILE(1), .FILE_TO_ROM(1), .ENABLE_FT(0), .ENABLE_SD2(0), .ENABLE_IMG(1)) u_mcu (
        .CLK(clk96), .N_RESET(dcm_locked & pll_locked & sd_init_ever & chk_done),   // the loader starts after the SDRAM initialisation (and the calibration with KG_SDRAM_CAL): the image is written with the final settings
        .MCU_MOSI(MCU_MOSI), .MCU_MISO(MCU_MISO), .MCU_SCK(MCU_SCK), .MCU_SS(MCU_CS_N),
        .MCU_SPI_FT_SS(1'b1), .MCU_SPI_SD2_SS(1'b1), .MCU_BURST_CS_N(mcu_burst_cs_n), .MCU_BURST_READY(mcu_burst_ready),
        .MS_X(), .MS_Y(), .MS_B(unused_ms_b), .MS_Z(), .MS_UPD(),
        .KB_STATUS(), .KB_DAT0(), .KB_DAT1(), .KB_DAT2(), .KB_DAT3(), .KB_DAT4(), .KB_DAT5(),
        .KB_SCANCODE(kb_scancode), .KB_SCANCODE_UPD(kb_scancode_upd), .XT_SCANCODE(), .XT_SCANCODE_UPD(),
        .PS2_COMMAND(16'h0000), .PS2_COMMAND_WR(1'b0),
        .JOY_L(joy_l), .JOY_R(joy_r), .BTNS(hw_btn),
        .SOFTSW_COMMAND(softsw_command), .OSD_COMMAND(osd_command), .BUSY(mcu_busy), .DVI_ONLY(dvi_only),
        .RTC_A(8'h00), .RTC_DI(8'h00), .RTC_DO(), .RTC_CS(1'b0), .RTC_WR_N(1'b1),
        .UART_RX_DATA(), .UART_RX_IDX(), .UART_TX_DATA(8'h00), .UART_TX_WR(1'b0), .UART_TX_MODE(1'b0),
        .UART_DLM(8'h00), .UART_DLL(8'h00), .UART_DLM_WR(1'b0), .UART_DLL_WR(1'b0),
        .FT_MISO(1'b0), .SD2_MISO(1'b0), .MATRIX_CMD(24'h000000), .MATRIX_CMD_WR(1'b0),
        .DEBUG_ADDR(16'h0000), .DEBUG_DATA(16'h0000),
        .IMG_MOUNTED(img_mounted), .IMG_SIZE(img_size), .IMG_DATA_WR(img_data_wr), .IMG_DATA_ADDR(img_data_addr), .IMG_DATA(img_data),
        .IMG_RESULT_WR(img_result_wr), .IMG_RESULT(img_result), .IMG_SUM(img_sum), .IMG_Q_WR(img_q_wr), .IMG_Q_DI(img_q_di), .IMG_Q_ACK(img_q_ack),
        .FDD_CHNG_REQ(1'b0), .FDD_CHNG_DS(2'b00), .ESP_UART_RX_DATA(8'h00), .ESP_UART_RX_WR(1'b0),
        .ROMLOADER_ACTIVE(romloader_active), .ROMLOAD_ADDR(rom_addr), .ROMLOAD_DATA(rom_data), .ROMLOAD_WR(rom_wr),
        .FLASHBOOT_START(1'b0), .FLASHBOOT_COREID(5'h00), .PRN_DATA(8'h00), .PRN_WR(1'b0));

    // ---------------------------------------------------------------- OSD switches (core.json "osd": the items with a value, in their order)
    //   register 0: Reset (T, F12);  1: SD card (0 the card in the slot of the board, 1 the image of the OSD item "SD image")
    wire [2*8-1:0] softsw;
    kg_soft_switches #(.N(2)) u_softsw (.clk(clk96), .command(softsw_command), .regs(softsw), .upd());
    wire kb_reset = softsw[0];
    wire sd_img   = softsw[8];
    // reset of the core (as the cores of karabas-go: the OSD Reset, the reset button of the board, the MCU busy): OSCA's reset input
    // (jumper_reset, low = reset) is held while it is requested; then its boot ROM jumps to FLOS again ($1010, FLOS stays in RAM)
    reg [2:0] rst_req_s = 3'b000;
    always @(posedge clk16) rst_req_s <= {rst_req_s[1:0], kb_reset | hw_btn[0] | mcu_busy};
    wire rst_req = rst_req_s[2];

    // clk96 -> clk16 crossing of the (rare) scan code bytes: hold the byte, toggle a flag.  KB_SCANCODE_UPD of kg_mcu TOGGLES with every byte
    // (kg_mcu_hid.v): a new byte is any change of its level.  (It was taken as a pulse: bytes were repeated while it was 1 and lost while it was 0,
    // e.g. the break code F0 xx -> stuck keys.)
    reg [7:0] kb_hold = 8'h00; reg kb_tog = 1'b0; reg kb_upd_d = 1'b0;
    always @(posedge clk96) begin
        kb_upd_d <= kb_scancode_upd;
        if (kb_scancode_upd != kb_upd_d) begin kb_hold <= kb_scancode; kb_tog <= ~kb_tog; end
    end
    reg [2:0] kb_tog_s = 3'b000;
    always @(posedge clk16) kb_tog_s <= {kb_tog_s[1:0], kb_tog};
    wire kb_stb = kb_tog_s[2] ^ kb_tog_s[1];

    // ---------------------------------------------------------------- SoC
    wire [20:0] ma;  wire [15:0] md_o;  wire md_oe;
    wire col_red_a, col_red_b, col_red_c, col_red_d, col_green_a, col_green_b, col_green_c, col_green_d;
    wire rgb_oe;
    wire col_blue_a, col_blue_b, col_blue_c, col_blue_d, horizontal_sync, tv_sync, audio_left, audio_right;  wire [9:0] audio_pcm_l, audio_pcm_r;
    wire kb_clk_pull, kb_dat_pull, kb_clk_line, kb_dat_line;
    wire sdc_clk, sdc_cs, sdc_din, sdc_pow, system_reset_out;
    wire emu_miso, emu_wait;             // MISO of the emulated SD card (kg_sd_emu); it waits for the MCU (the CPU waits on the SPI port)

    // the port of the loader / self test into the SDRAM controller: registered (one clk96 later, all four signals alike) to keep the controller's address path short
    reg        ld_act_r = 1'b0, ld_wr_r = 1'b0;  reg [31:0] ld_addr_r = 32'd0;  reg [7:0] ld_data_r = 8'd0;
    always @(posedge clk96) begin
        ld_act_r  <= romloader_active | chk_run;
        ld_addr_r <= chk_run ? {13'd0, chk_addr} : rom_addr;
        ld_data_r <= chk_run ? chk_data : rom_data;
        ld_wr_r   <= chk_run ? chk_wr : rom_wr;
    end
    wire [32:0] dbg;
    wire [26:0] dbg2;  wire [29:0] dbg3;  wire [1:0] dbg4;  wire [31:0] dbg5;  wire [4:0] dbg6;  wire [19:0] dbg7;  wire [63:0] dbg8;  wire [15:0] pal_pdata;  reg [8:0] pal_probe = 9'd1;     // probe palette index 1 (FLOS writes FF FF there), alternating with index 200 (00 00)
    // palette entries 10..1F (FLOS's 16 colours) read through the probe port and compared with the values from the simulation (build/palrun, KG_PALLOG):
    // one entry per 2^20 ticks of 96 MHz; pmask bit 15 = entry 10 ... bit 0 = entry 1F differs; p17 / p18 = entries 17 (yellow, text) and 18 (white)
    reg [27:0] pal_alt = 28'd0;  reg [15:0] pmask = 16'd0, p17 = 16'd0, p18 = 16'd0, pfirst = 16'd0;  reg [3:0] pfirst_i = 4'd0;  reg pfound = 1'b0;
    wire [3:0] pk = pal_alt[23:20];
    reg  [15:0] pexp;
    always @(*) case (pk)
        4'h0: pexp = 16'h0007; 4'h1: pexp = 16'h0000; 4'h2: pexp = 16'h000f; 4'h3: pexp = 16'h0f00;
        4'h4: pexp = 16'h0f0f; 4'h5: pexp = 16'h00f0; 4'h6: pexp = 16'h00ff; 4'h7: pexp = 16'h0ff0;
        4'h8: pexp = 16'h0fff; 4'h9: pexp = 16'h0555; 4'ha: pexp = 16'h0999; 4'hb: pexp = 16'h0ccc;
        4'hc: pexp = 16'h0f71; 4'hd: pexp = 16'h007f; 4'he: pexp = 16'h0df8; default: pexp = 16'h0840;
    endcase
    always @(posedge clk96) begin
        pal_alt <= pal_alt + 28'd1;
        pal_probe <= {5'd1, pk};
        if (pal_alt[19:0] == 20'hf_fff0) begin
            pmask[4'd15 - pk] <= (pal_pdata != pexp);
            if (pk == 4'h7) p17 <= pal_pdata;
            if (pk == 4'h8) p18 <= pal_pdata;
            if ((pal_pdata != pexp) && !pfound) begin pfound <= 1'b1; pfirst <= pal_pdata; pfirst_i <= pk; end
            if (pk == 4'hf) pfound <= 1'b0;
        end
    end
    wire [7:0] chk_rdata;  wire chk_rdvalid;
    kg_osca_soc soc (
        .clk_mem(clk96), .clk16_gen(clk16_gen), .clk16(clk16),
        .ma(ma), .md_o(md_o), .md_oe(md_oe), .md_i(MD), .mwr_n(MWR_N), .mrd_n(MRD_N),
        .col_red_a(col_red_a), .col_red_b(col_red_b), .col_red_c(col_red_c), .col_red_d(col_red_d),
        .col_green_a(col_green_a), .col_green_b(col_green_b), .col_green_c(col_green_c), .col_green_d(col_green_d),
        .col_blue_a(col_blue_a), .col_blue_b(col_blue_b), .col_blue_c(col_blue_c), .col_blue_d(col_blue_d),
        .horizontal_sync(horizontal_sync), .tv_sync(tv_sync), .rgb_oe(rgb_oe),
        .audio_left(audio_left), .audio_right(audio_right), .audio_pcm_l(audio_pcm_l), .audio_pcm_r(audio_pcm_r),
        .ps2_kb_clock_in(kb_clk_line), .ps2_kb_data_in(kb_dat_line),
        .ps2_ms_clock_in(1'b1), .ps2_ms_data_in(1'b1),
        .ps2_kb_clock_out(kb_clk_pull), .ps2_kb_data_out(kb_dat_pull),
        .ps2_ms_clock_out(), .ps2_ms_data_out(),
        .sdc_clk(sdc_clk), .sdc_cs(sdc_cs), .sdc_din(sdc_din), .sdc_pow(sdc_pow), .sdc_dout(sd_img ? emu_miso : SD_DO), .sd_wait(sd_img & emu_wait),
        .serial_tx_pin(), .serial_rx_pin(1'b1),
        .joystick_clock_out(), .joystick_data_in(1'b1),        // the PIC link (serjoy2) is not used
        .joy_bits(joy_s2),   // OSCA port 1 = JOY_R, port 0 = JOY_L (synchronised to clk16)
        .ld_active(ld_act_r), .ld_addr(ld_addr_r), .ld_data(ld_data_r), .ld_wr(ld_wr_r),   // boot image from the MCU
        .jumper_nmi(1'b1), .jumper_reset(run & ~load_s[1] & init_s[1] & ~rst_req), .jumper_vga(1'b0),   // 0 = VGA video mode
        .expansion_pin_a(), .expansion_pin_b(),
        .system_reset_out(system_reset_out),
        .sdram_reset(~(dcm_locked & pll_locked) | chk_rst), .sdram_cap_late(chk_cap), .sdram_init_done(sd_init),
        .sd_ba(SDR_BA), .sd_a(SDR_A), .sd_dqm(SDR_DQM), .sd_ras_n(SDR_RAS_N), .sd_cas_n(SDR_CAS_N), .sd_we_n(SDR_WE_N), .sd_dq(SDR_DQ),
        .dbg(dbg), .chk_rdata(chk_rdata), .chk_rdvalid(chk_rdvalid), .dbg2(dbg2), .dbg3(dbg3), .dbg4(dbg4), .dbg5(dbg5), .dbg6(dbg6), .dbg7(dbg7), .dbg8(dbg8), .dbg_paddr(pal_probe), .dbg_fixpal(dbg_fix), .dbg_pdata(pal_pdata),
        .v_en(vram_run), .v_addr(v_addr), .v_wr_n(v_wr_n), .v_wd(v_wd), .t_en(sram_run), .t_ma(s_ma), .t_md(s_md), .t_oe(s_oe), .t_wr_n(s_wr_n), .t_rd_n(s_rd_n));

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
    always @(posedge clk96) begin
        if (romloader_active) ld_seen <= 1'b1;
        if (ld_seen && !romloader_active) ld_done <= 1'b1;
        if (rom_wr) begin wr_seen <= 1'b1; if (ld_bytes != 16'hffff) ld_bytes <= ld_bytes + 16'd1; end
        if (osca_run) dbg_hold <= dbg_hold + 32'd1;
    end
`ifdef KG_SDRAM_CAL
    // SDRAM self test and calibration (polarity of SDR_CLK, read capture) with a test pattern, BEFORE the MCU loader writes the boot image
    kg_sdram_check u_chk (.clk(clk96), .wr_i(rom_wr), .addr_i(rom_addr[14:0]), .data_i(rom_data), .go(sd_init_ever), .init_done(sd_init), .run(chk_run),
        .addr_o(chk_addr), .wr_o(chk_wr), .data_o(chk_data), .rst_o(chk_rst), .pol_o(chk_pol), .cap_o(chk_cap),
        .rd_valid(chk_rdvalid), .rdata(chk_rdata), .done(chk_done), .matrix_done(chk_mdone), .timeout(chk_tmo), .cell_ok(chk_cok), .cell_bad(chk_cbad),
        .err_final(chk_efin), .first_addr(chk_fa), .first_exp(chk_fe), .first_act(chk_fact), .fa_i(f_a[14:0]), .fe_o(chk_fexp));
`else
    // fixed SDRAM interface settings (what the calibration chose on the board, KG_SDRAM_CAL): SDR_CLK inverted, read data taken from the pins
    assign chk_pol = 1'b1;  assign chk_cap = 1'b0;  assign chk_done = sd_init_ever;
    assign chk_run = 1'b0;  assign chk_rst = 1'b0;  assign chk_wr = 1'b0;  assign chk_addr = 19'd0;  assign chk_data = 8'd0;
    assign chk_mdone = 1'b0;  assign chk_tmo = 1'b0;  assign chk_cok = 8'd0;  assign chk_cbad = 8'd0;  assign chk_efin = 16'd0;
    assign chk_fa = 16'd0;  assign chk_fe = 8'd0;  assign chk_fact = 8'd0;  assign chk_fexp = 8'd0;
`endif
    // SRAM self test after the SDRAM self test (the core is still in reset)
    kg_sram_test u_sram (.clk(clk96), .go(chk_done), .run(sram_run), .ma(s_ma), .md(s_md), .oe(s_oe), .wr_n(s_wr_n), .rd_n(s_rd_n), .md_i(MD),
        .done(sram_done), .dmask0(s_dm0), .dmask1(s_dm1), .amask(s_amask), .alias0(sram_alias0), .vgo(vram_done), .vdone(sv_done), .verr(sv_err), .vact0(sv_a0), .vact1(sv_a1));
    // video RAM self test (wrapper + SRAM at the real speed, the display-like stream): after the SRAM test, still in reset
    kg_vram_test u_vram (.clk16(clk16), .go(sram_done), .run(vram_run), .addr(v_addr), .wr_n(v_wr_n), .wdata(v_wd), .rdata1(dbg2[15:8]), .rdata2(dbg2[7:0]),
        .done(vram_done), .err_s(vt_es), .err_r(vt_er), .act(vt_act));
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
    // width of the palette write strobe (cpu_write high with the palette enabled) in clk96 ticks: last and minimum
    reg [15:0] sw_cnt = 16'd0, sw_last = 16'd0, sw_min = 16'hffff;  reg sw_q = 1'b0;
    wire sw_act = ~dbg3[21] & (dbg3[19] | dbg3[20]);
    always @(posedge clk96) begin
        sw_q <= sw_act;
        if (sw_act) begin if (sw_cnt != 16'hffff) sw_cnt <= sw_cnt + 16'd1; end
        else sw_cnt <= 16'd0;
        if (sw_q && !sw_act) begin sw_last <= sw_cnt; if (sw_cnt < sw_min) sw_min <= sw_cnt; end
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
    // where does the CPU run into a NOP slide?  The last three non-NOP opcode fetches before the first run of 16 NOP fetches are kept (address and opcode)
    reg [15:0] nn_pc0 = 16'd0, nn_pc1 = 16'd0, nn_pc2 = 16'd0;  reg [7:0] nn_op0 = 8'd0, nn_op1 = 8'd0, nn_op2 = 8'd0;
    reg [15:0] sl_pc0 = 16'd0, sl_pc1 = 16'd0, sl_pc2 = 16'd0;  reg [7:0] sl_op0 = 8'd0, sl_op1 = 8'd0, sl_op2 = 8'd0;
    reg [4:0]  nop_run = 5'd0;  reg slide_seen = 1'b0, fetch_q = 1'b0;  
    always @(posedge clk16) begin
        fetch_q <= fetch;
        if (fetch) begin f_a <= c_a; f_d <= c_d; end
        if (!fetch && fetch_q) begin                           // one count per opcode fetch, at its end (the data are valid then)
            if (f_d != 8'd0) begin
                nn_pc2 <= nn_pc1; nn_pc1 <= nn_pc0; nn_pc0 <= f_a;  nn_op2 <= nn_op1; nn_op1 <= nn_op0; nn_op0 <= f_d;  nop_run <= 5'd0;
            end else if (nop_run != 5'd31) begin
                nop_run <= nop_run + 5'd1;
                if (nop_run == 5'd15 && !slide_seen) begin
                    slide_seen <= 1'b1;
                    sl_pc0 <= nn_pc0; sl_pc1 <= nn_pc1; sl_pc2 <= nn_pc2; sl_op0 <= nn_op0; sl_op1 <= nn_op1; sl_op2 <= nn_op2;
                end
            end
        end
    end
    // the bus as the core's registers see it during CPU writes (96 MHz pipeline): every data / address bit that was ever 1 at the start of a write strobe, and the last write
    reg [19:0] bw1 = 20'd0, bw2 = 20'd0, bw3 = 20'd0;  reg [10:0] w_addr = 11'd0, a_or = 11'd0, w_addr_e = 11'd0;  reg [7:0] w_data = 8'd0, d_or = 8'd0, d_and = 8'hff, w_data_e = 8'd0;
    always @(posedge clk96) begin
        bw1 <= dbg7;  bw2 <= bw1;  bw3 <= bw2;
        if (bw2[19] != bw1[19]) begin                       // the write strobe of the core changed (either edge): the bus two ticks earlier
            if (!bw1[19]) begin w_addr <= bw3[18:8]; w_data <= bw3[7:0]; a_or <= a_or | bw3[18:8]; d_or <= d_or | bw3[7:0]; end   // falling edge: start of a write
            else          begin w_addr_e <= bw3[18:8]; w_data_e <= bw3[7:0]; end                                                      // rising edge: end of a write
        end
    end
    kg_dbg_video u_dbg (.clk16(clk16),
        .flags({wr_seen, hb27[26], osca_run, ld_bytes >= 16'd20142, ld_done, ld_seen, sd_init, dcm_locked & pll_locked}), .flags2(f2),
        .flags3({chk_cap, chk_pol, chk_done, chk_done & (chk_efin == 16'd0), ~chk_tmo, chk_mdone, chk_seen & 1'b1, 1'b1}),
        .cell_ok(chk_cok), .cell_bad(chk_cbad), .err_final(chk_efin), .first_addr(dbg5[15:0]), .first_ea(dbg5[31:16]),
        .m_hs(pmask), .m_lines(p17), .m_nb(p18), .m_col({pfirst_i, pfirst[11:0]}),
        .bytes(ld_bytes), .pc_s(pc_snap), .pc_max(pc_max), .op_s(op_snap), .r(dbg_r), .g(dbg_g), .b(dbg_b), .hs(dbg_hs), .vs(dbg_vs));
    // The OSD of the MCU (kg_osd_overlay of karabas-go-modules) is laid over the picture on a 32 MHz clock (the PLL, edges on those of clk16):
    // each 16 MHz pixel of OSCA is two clocks.  The overlay is made for a character cell of 16 clocks (two per OSD pixel); with OSCA's
    // line of 508 clocks of 16 MHz its 32 cells would be wider than the line, at 32 MHz (1016 clocks, H_DIV4_WIDTH above that: a counter
    // step per 2 clocks) the menu is 256 OSCA pixels wide.  Its position: H_OFFSET in OSCA pixels from the leading edge of HSYNC,
    // V_OFFSET in pairs of lines from that of VSYNC (the 524-line frame: a step per 2 lines), about the middle of OSCA's display window.
    wire [7:0] mix_r = show_dbg ? dbg_r  : osca_r;
    wire [7:0] mix_g = show_dbg ? dbg_g  : osca_g;
    wire [7:0] mix_b = show_dbg ? dbg_b  : osca_b;
    assign     mix_hs = show_dbg ? dbg_hs : horizontal_sync;     // low active
    assign     mix_vs = show_dbg ? dbg_vs : tv_sync;
    // DE: rgb_oe through a clk16 register, as the palette output register that clears the colours outside it (synchronous reset by ~rgb_oe)
    reg de16 = 1'b0;
    always @(posedge clk16) de16 <= rgb_oe;
    assign vid_de = show_dbg ? 1'b1 : de16;
    kg_osd_overlay #(.H_OFFSET(160), .V_OFFSET(27), .H_DIV4_WIDTH(2000)) u_osd (
        .clk(clk32), .rgb_i({mix_r, mix_g, mix_b}), .rgb_o(osd_rgb),
        .hsync_i(~mix_hs), .vsync_i(~mix_vs), .v_offset(11'd0), .osd_command(osd_command));

    // audio: the board's DAC gets the mixer sums of OSCA's sound system directly (4 channels, 512 = silence), not its 1-bit sigma-delta outputs converted back:
    // (sum - 512) * 32 = +-16384 (-6 dB of full scale)
    wire [10:0] pcm_dl = {1'b0, audio_pcm_l} - 11'd512, pcm_dr = {1'b0, audio_pcm_r} - 11'd512;
    always @(posedge clk16) begin pcm_l <= {pcm_dl, 5'b00000}; pcm_r <= {pcm_dr, 5'b00000}; end

    // SD card: the core's SPI engine (pow is ignored) on the card in the slot of the board, or on the emulated card on the image of the
    // file mounter (OSD "SD card" = Image; the card of the board is deselected then)
    assign SD_CLK  = sdc_clk;
    assign SD_CS_N = sd_img ? 1'b1 : sdc_cs;
    assign SD_DI   = sdc_din;

    // the reset of the core, for the emulated card (it starts idle again, as a card after a power cycle of the machine)
    reg [1:0] emu_rst_s = 2'b11;
    always @(posedge clk96) emu_rst_s <= {emu_rst_s[0], ~(run & ~load_s[1] & init_s[1] & ~rst_req)};
    wire        sdc_busy, sdc_done, sdc_error, sdc_byte_in_strobe, hd_rd, hd_wr;
    wire [2:0]  sdc_slot;  wire [8:0] sdc_byte_addr;  wire [7:0] sdc_byte_in_data, hd_byte_out_data, sdc_img_mounted;
    wire [63:0] sdc_img_size;  wire [31:0] hd_lba;
    // the sector interface of the file mounter: one requester (slot 0); TIMEOUT ~175 ms at 96 MHz (the MCU answers in 5-15 ms)
    img_sdc #(.OUT_LATENCY(3), .TIMEOUT(24'hFFFFFF)) u_sdc (
        .clk(clk96), .reset(1'b0),
        .img_mounted(img_mounted), .img_size(img_size), .img_data_wr(img_data_wr), .img_data_addr(img_data_addr), .img_data(img_data),
        .img_result_wr(img_result_wr), .img_result(img_result), .img_sum(img_sum), .img_q_wr(img_q_wr), .img_q_di(img_q_di), .img_q_ack(img_q_ack),
        .sdc_img_mounted(sdc_img_mounted), .sdc_img_size(sdc_img_size),
        .sdc_rd({7'd0, hd_rd}), .sdc_wr({7'd0, hd_wr}), .sdc_sector(hd_lba),
        .sdc_busy(sdc_busy), .sdc_done(sdc_done), .sdc_error(sdc_error), .sdc_slot(sdc_slot),
        .sdc_byte_in_strobe(sdc_byte_in_strobe), .sdc_byte_addr(sdc_byte_addr), .sdc_byte_in_data(sdc_byte_in_data),
        .sdc_byte_out_data(hd_byte_out_data), .active());
    kg_sd_emu u_sdemu (
        .clk(clk96), .reset(emu_rst_s[1]),
        .sclk(sdc_clk), .mosi(sdc_din), .cs_n(sdc_cs), .miso(emu_miso),
        .img_mounted(sdc_img_mounted[0]), .img_size(|sdc_img_size[63:32] ? 32'hFFFFFE00 : sdc_img_size[31:0]),
        .hd_rd(hd_rd), .hd_wr(hd_wr), .hd_lba(hd_lba), .hd_busy(sdc_busy), .hd_done(sdc_done), .hd_error(sdc_error),
        .hd_byte_in_strobe(sdc_byte_in_strobe), .hd_byte_addr(sdc_byte_addr), .hd_byte_in_data(sdc_byte_in_data),
        .hd_byte_out_data(hd_byte_out_data), .waiting(emu_wait));
endmodule

