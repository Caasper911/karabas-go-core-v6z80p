`timescale 1ns / 1ps
// Bring-up test for Karabas Go: VGA colour bars only.  800x525 timing (31.25 kHz / 59.5 Hz, HS/VS active low, 640x480 style).
//   USE_DCM = 0: pixel clock = CLK_50MHZ / 2 (no DCM at all)
//   USE_DCM = 1: DCM_CLKGEN 50 MHz * 48 / 25 = 96 MHz as in the OSCA core, pixel clock = 96 / 4 = 24 MHz (31.5/... kHz); black screen if the DCM does not lock
module kg_bringup_top #(parameter USE_DCM = 0) (
    input  wire       CLK_50MHZ,
    output reg  [7:0] VGA_R, VGA_G, VGA_B,
    output reg        VGA_HS, VGA_VS,
    output reg        V_CLK,                 // pixel clock of the VGA DAC (registered, rises in the middle of the pixel)
    output wire       FT_OE_N, FT_SPI_CS_N, FT_SPI_SCK   // FT812 off the VGA bus
);
    wire clk, locked;
    generate if (USE_DCM) begin : g_dcm
        wire raw;
        DCM_CLKGEN #(.CLKFX_DIVIDE(25), .CLKFX_MULTIPLY(48), .CLKIN_PERIOD(20.0), .SPREAD_SPECTRUM("NONE"), .STARTUP_WAIT("FALSE"),
                     .CLKFXDV_DIVIDE(2), .CLKFX_MD_MAX(0.0)) u_dcm (
            .CLKIN(CLK_50MHZ), .CLKFX(raw), .CLKFX180(), .CLKFXDV(), .LOCKED(locked), .STATUS(),
            .PROGCLK(1'b0), .PROGDATA(1'b0), .PROGEN(1'b0), .PROGDONE(), .FREEZEDCM(1'b0), .RST(1'b0));
        BUFG u_bufg (.I(raw), .O(clk));
    end else begin : g_nodcm
        BUFG u_bufg (.I(CLK_50MHZ), .O(clk));
        assign locked = 1'b1;
    end endgenerate
    reg [1:0] div = 2'd0;
    wire ce = USE_DCM ? (div == 2'd3) : div[0];
    reg [9:0] px = 10'd0, ln = 10'd0;
    assign FT_OE_N = 1'b1;  assign FT_SPI_CS_N = 1'b1;  assign FT_SPI_SCK = 1'b0;
    always @(posedge clk) V_CLK <= USE_DCM ? (div == 2'd1 || div == 2'd2) : ~div[0];
    always @(posedge clk) begin
        div <= div + 2'd1;
        if (ce) begin
            if (px == 10'd799) begin px <= 10'd0; ln <= (ln == 10'd524) ? 10'd0 : ln + 10'd1; end
            else px <= px + 10'd1;
        end
    end
    wire act = (px >= 10'd144) && (px < 10'd784) && (ln >= 10'd35) && (ln < 10'd515) && locked;
    wire [9:0] x = px - 10'd144;
    wire [2:0] bar = x[9:7] > 3'd4 ? 3'd7 : x[9:7] == 3'd0 ? 3'd1 : x[9:7] == 3'd1 ? 3'd2 : x[9:7] == 3'd2 ? 3'd3 : x[9:7] == 3'd3 ? 3'd4 : 3'd5;
    always @(posedge clk) if (ce) begin
        VGA_HS <= ~(px < 10'd96);
        VGA_VS <= ~(ln < 10'd2);
        VGA_R <= (act && ln > 10'd200 ? {8{bar[2]}} : act ? 8'hff : 8'h00);
        VGA_G <= (act && ln > 10'd200 ? {8{bar[1]}} : act ? 8'h00 : 8'h00);
        VGA_B <= (act && ln > 10'd200 ? {8{bar[0]}} : 8'h00);
    end
endmodule
