`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// karabas_go_osca_top - OSCA (V6Z80P+ v1.1, converted schematics) on Karabas Go.
//
// The system (clocks, SoC, MCU link, SD card, OSD) is kg_osca_system, shared with the other boards; here are the parts of
// the Go: the VGA DAC (clocked by V_CLK), the FT812 kept off the VGA bus, the PCM5102 DAC, the burst lines of the MCU.
// Not done: the joystick serial protocol (serjoy2), PS/2 mouse, second SD, RTC.
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
    inout  wire [1:0]  MCU_SPI_IO,        // bursts (karabas-go-firmware docs/burst_protocol.md): [0] READY (N9), [1] burst CS_N (M11)
    // SDRAM (system RAM); CS_N and CKE are tied on the board
    output wire        SDR_CLK, SDR_RAS_N, SDR_CAS_N, SDR_WE_N,
    output wire [1:0]  SDR_BA,
    output wire [12:0] SDR_A,
    output wire [1:0]  SDR_DQM,
    inout  wire [15:0] SDR_DQ
);
    wire clk16, clk32, run;
    wire [23:0] osd_rgb;  wire mix_hs, mix_vs;
    wire [15:0] pcm_l, pcm_r;
    wire mcu_burst_ready;                // a sector read of the file mounter comes as one burst instead of 512 frames
    assign MCU_SPI_IO[0] = mcu_burst_ready;
    assign MCU_SPI_IO[1] = 1'bz;

    kg_osca_system osca (
        .CLK_50MHZ(CLK_50MHZ),
        .MA(MA), .MD(MD), .MWR_N(MWR_N), .MRD_N(MRD_N),
        .SD_CS_N(SD_CS_N), .SD_DI(SD_DI), .SD_CLK(SD_CLK), .SD_DO(SD_DO),
        .MCU_MOSI(MCU_MOSI), .MCU_SCK(MCU_SCK), .MCU_CS_N(MCU_CS_N), .MCU_MISO(MCU_MISO),
        .mcu_burst_cs_n(MCU_SPI_IO[1]), .mcu_burst_ready(mcu_burst_ready),
        .SDR_CLK(SDR_CLK), .SDR_RAS_N(SDR_RAS_N), .SDR_CAS_N(SDR_CAS_N), .SDR_WE_N(SDR_WE_N),
        .SDR_BA(SDR_BA), .SDR_A(SDR_A), .SDR_DQM(SDR_DQM), .SDR_DQ(SDR_DQ),
        .clk16(clk16), .clk32(clk32), .run(run),
        .osd_rgb(osd_rgb), .mix_hs(mix_hs), .mix_vs(mix_vs),
        .pcm_l(pcm_l), .pcm_r(pcm_r));

    // The board has a VGA DAC clocked by V_CLK (as in the NanoMig / Profi cores): RGB and syncs registered on the pixel clock (32 MHz,
    // in the IOBs) and the DAC gets the inverted pixel clock (it samples in the middle of the pixel).  The FT812 is kept off the VGA bus.
    reg [7:0] vo_r = 8'h00, vo_g = 8'h00, vo_b = 8'h00;  reg vo_hs = 1'b1, vo_vs = 1'b1;
    always @(posedge clk32) begin
        vo_r  <= osd_rgb[23:16];
        vo_g  <= osd_rgb[15:8];
        vo_b  <= osd_rgb[7:0];
        vo_hs <= mix_hs;
        vo_vs <= mix_vs;
    end
    assign VGA_R = vo_r;  assign VGA_G = vo_g;  assign VGA_B = vo_b;  assign VGA_HS = vo_hs;  assign VGA_VS = vo_vs;
    wire clk32_n = ~clk32;
    ODDR2 #(.DDR_ALIGNMENT("NONE"), .INIT(1'b0), .SRTYPE("SYNC")) u_vclk (.Q(V_CLK), .C0(clk32), .C1(clk32_n), .CE(1'b1), .D0(1'b0), .D1(1'b1), .R(1'b0), .S(1'b0));
    assign FT_OE_N = 1'b1;  assign FT_SPI_CS_N = 1'b1;  assign FT_SPI_SCK = 1'b0;

    // audio: the PCM5102
    kg_pcm5102 #(.DIV_BITS(1)) u_dac (.clk(clk16), .reset(~run), .left(pcm_l), .right(pcm_r),
                                      .din(DAC_DAT), .bck(DAC_BCK), .lrck(DAC_LRCK));
    assign DAC_MUTE = 1'b1;
endmodule
