`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// karabas_mini_osca_top - OSCA (V6Z80P+ v1.1, converted schematics) on Karabas Mini (before rev. G).
//
// The system (clocks, SoC, MCU link, SD card, OSD) is kg_osca_system, as on the Go; the SRAM, SDRAM, SD and MCU pins are the same.
// The parts of the Mini (as karabas_mini_top.v of karabas-go-core-msx):
//   - video: HDMI only (zhdmi hdmi_tx, DVI when the MCU says dvi_only), pixel clock clk32 (each 16 MHz pixel of OSCA twice: the VGA
//     mode of OSCA, 1016 x 524 clocks at 60 Hz, 1016 x 628 at 50 Hz), the 5x serial clock and its inverse from a DCM on clk32;
//     DE = OSCA's display area (rgb_oe, kg_osca_system vid_de).  The VGA_* pins are the FT812's video INTO the FPGA: not used.
//   - audio: sigma-delta on AUDIO_L / AUDIO_R and the HDMI audio (48 kHz);
//   - the FT812 gets its 8 MHz clock on FT_CLK_OUT all the time (karabas-go-notes ft-clk-out-required) and is not reset;
//   - MCU link v2: MCU_IO<1> MCU_INT (F6), MCU_IO<0> an input (G6).  MCU_SCK is not on a clock pin (CLOCK_DEDICATED_ROUTE in the ucf).
//   - the CF card / extender port, ADC, tape, MIDI, ESP and the configuration flash are not used.
//////////////////////////////////////////////////////////////////////////////////
module karabas_mini_osca_top (
    input  wire        CLK_50MHZ,
    // ESP8266 UART (not used)
    inout  wire        UART_RX, UART_TX, UART_CTS, ESP_RESET_N, ESP_BOOT_N,
    // SRAM
    output wire [20:0] MA,
    inout  wire [15:0] MD,
    output wire [1:0]  MWR_N,
    output wire [1:0]  MRD_N,
    // SDRAM (system RAM)
    output wire [1:0]  SDR_BA,
    output wire [12:0] SDR_A,
    output wire        SDR_CLK,
    output wire [1:0]  SDR_DQM,
    output wire        SDR_WE_N, SDR_CAS_N, SDR_RAS_N,
    inout  wire [15:0] SDR_DQ,
    // SD card
    output wire        SD_CS_N, SD_CLK, SD_DI,
    input  wire        SD_DO,
    input  wire        SD_DET_N,
    // HDMI
    output wire [3:0]  TMDS_P,
    output wire [3:0]  TMDS_N,
    // FT812 (only its clock and its chip select)
    output wire        FT_SPI_CS_N, FT_SPI_SCK, FT_SPI_MOSI,
    output wire        FT_RESET,
    output wire        FT_CLK_OUT,
    // CF card / extender port (not used)
    output wire [2:0]  WA,
    output wire [1:0]  WCS_N,
    output wire        WRD_N, WWR_N, WRESET_N,
    inout  wire [15:0] WD,
    // analog
    output wire        TAPE_OUT,
    output wire        AUDIO_L, AUDIO_R,
    // ADC (not used)
    output wire        ADC_CLK,
    inout  wire        ADC_BCK, ADC_LRCK,
    // MCU
    input  wire        MCU_CS_N, MCU_SCK, MCU_MOSI,
    output wire        MCU_MISO,
    inout  wire [3:0]  MCU_IO,            // [0] IO0 (input), [1] MCU_INT, [2] SD2 CS_N, [3] FT CS_N (the last two not used)
    // MIDI (not used)
    output wire        MIDI_TX, MIDI_CLK, MIDI_RESET_N,
    // configuration flash (not used)
    output wire        FLASH_CS_N, FLASH_DI, FLASH_SCK, FLASH_WP_N, FLASH_HOLD_N
);
    // ---------------------------------------------------------------- unused
    assign UART_RX = 1'bz;  assign UART_TX = 1'bz;  assign UART_CTS = 1'bz;  assign ESP_RESET_N = 1'bz;  assign ESP_BOOT_N = 1'bz;
    assign WA = 3'b000;  assign WCS_N = 2'b11;  assign WRD_N = 1'b1;  assign WWR_N = 1'b1;  assign WRESET_N = 1'b1;  assign WD = 16'bz;
    assign TAPE_OUT = 1'b0;
    assign ADC_CLK = 1'b0;  assign ADC_BCK = 1'bz;  assign ADC_LRCK = 1'bz;
    assign MIDI_TX = 1'b1;  assign MIDI_CLK = 1'b1;  assign MIDI_RESET_N = 1'b1;
    assign FLASH_CS_N = 1'b1;  assign FLASH_DI = 1'b1;  assign FLASH_SCK = 1'b0;  assign FLASH_WP_N = 1'b1;  assign FLASH_HOLD_N = 1'b1;
    assign FT_SPI_CS_N = 1'b1;  assign FT_SPI_SCK = 1'b0;  assign FT_SPI_MOSI = 1'b0;  assign FT_RESET = 1'b1;

    // ---------------------------------------------------------------- the system
    wire clk16, clk32, clk8, run, dvi_only;
    wire [23:0] osd_rgb;  wire mix_hs, mix_vs, vid_de;
    wire [15:0] pcm_l, pcm_r;
    wire mcu_int;                        // MCU link v2: the interrupt line (IO1, the pin of the burst READY of v1)
    assign MCU_IO[1] = mcu_int;
    assign MCU_IO[0] = 1'bz;             // IO0 (the burst CS_N of v1): an input, not used
    assign MCU_IO[3:2] = 2'bzz;

    kg_osca_system osca (
        .CLK_50MHZ(CLK_50MHZ),
        .MA(MA), .MD(MD), .MWR_N(MWR_N), .MRD_N(MRD_N),
        .SD_CS_N(SD_CS_N), .SD_DI(SD_DI), .SD_CLK(SD_CLK), .SD_DO(SD_DO),
        .MCU_MOSI(MCU_MOSI), .MCU_SCK(MCU_SCK), .MCU_CS_N(MCU_CS_N), .MCU_MISO(MCU_MISO),
        .mcu_int(mcu_int),
        .SDR_CLK(SDR_CLK), .SDR_RAS_N(SDR_RAS_N), .SDR_CAS_N(SDR_CAS_N), .SDR_WE_N(SDR_WE_N),
        .SDR_BA(SDR_BA), .SDR_A(SDR_A), .SDR_DQM(SDR_DQM), .SDR_DQ(SDR_DQ),
        .clk16(clk16), .clk32(clk32), .clk8(clk8), .dvi_only(dvi_only), .run(run),
        .osd_rgb(osd_rgb), .mix_hs(mix_hs), .mix_vs(mix_vs), .vid_de(vid_de),
        .pcm_l(pcm_l), .pcm_r(pcm_r));

    // the clock of the FT812 (it must always have one)
    ODDR2 u_ft_clk (.Q(FT_CLK_OUT), .C0(clk8), .C1(~clk8), .CE(1'b1), .D0(1'b1), .D1(1'b0), .R(1'b0), .S(1'b0));

    // ---------------------------------------------------------------- HDMI
    // 5x the pixel clock (160 MHz) and its inverse for the serialisers of hdmi_tx (ODDR2)
    wire clk_hdmi, clk_hdmi_n, lockedx5;
    kg_dcm #(.CLKIN_PERIOD(31.25), .CLKFX_MULTIPLY(5), .CLKFX_DIVIDE(1)) u_pllx5 (
        .clk_in(clk32), .rst(~run), .clk_fx(clk_hdmi), .clk_fx180(clk_hdmi_n), .clk_0(), .locked(lockedx5));

    // the picture: registered on clk32 (osd_rgb, the syncs and DE come from the registers of the OSD overlay); the syncs are low active (VGA mode)
    reg [23:0] h_rgb = 24'd0;  reg h_hs = 1'b1, h_vs = 1'b1, h_de = 1'b0;
    always @(posedge clk32) begin
        h_rgb <= osd_rgb;
        h_hs  <= mix_hs;
        h_vs  <= mix_vs;
        h_de  <= vid_de;
    end

    // audio of HDMI: a 48 kHz strobe of clk32 (+3 per clock, modulo 2000: 32 MHz * 3 / 2000), the sample of OSCA's mixer (clk16
    // registers, one PLL) taken with it
    reg [10:0] aud_acc = 11'd0;  reg aud_stb = 1'b0;
    reg [23:0] hdmi_l = 24'd0, hdmi_r = 24'd0;
    always @(posedge clk32) begin
        aud_stb <= 1'b0;
        if (aud_acc >= 11'd1997) begin
            aud_acc <= aud_acc + 11'd3 - 11'd2000;
            aud_stb <= 1'b1;
            hdmi_l <= {pcm_l, 8'd0};
            hdmi_r <= {pcm_r, 8'd0};
        end else
            aud_acc <= aud_acc + 11'd3;
    end
    // dvi_only (kg_mcu2, clk96) gates the data islands: through two clk32 registers
    wire dvi_only_s;
    kg_sync u_dvi_sync (.clk(clk32), .d(dvi_only), .q(dvi_only_s));

    hdmi_tx #(.SAMPLE_FREQ(48000)) u_hdmi (
        .clk(clk32), .sclk(clk_hdmi), .sclk_n(clk_hdmi_n),
        .reset(~run | ~lockedx5),
        .rgb(h_rgb), .vsync(h_vs), .hsync(h_hs), .de(h_de),
        .audio_en(~dvi_only_s), .audio_l(hdmi_l), .audio_r(hdmi_r), .audio_clk(aud_stb),
        .tx_clk_n(TMDS_N[3]), .tx_clk_p(TMDS_P[3]), .tx_d_n(TMDS_N[2:0]), .tx_d_p(TMDS_P[2:0]));

    // ---------------------------------------------------------------- analog audio: sigma-delta (offset binary) on clk32
    reg [15:0] sd_l = 16'h8000, sd_r = 16'h8000;
    always @(posedge clk32) begin sd_l <= {~pcm_l[15], pcm_l[14:0]}; sd_r <= {~pcm_r[15], pcm_r[14:0]}; end
    kg_sigma_delta_dac #(.MSBI(15)) u_dac_l (.clk(clk32), .reset(~run), .din(sd_l), .dout(AUDIO_L));
    kg_sigma_delta_dac #(.MSBI(15)) u_dac_r (.clk(clk32), .reset(~run), .din(sd_r), .dout(AUDIO_R));
endmodule
