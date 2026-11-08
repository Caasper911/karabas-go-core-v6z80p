`timescale 1ns / 1ps
// kg_dbg_video - bring-up status screen, independent of OSCA and of the memory wrapper's clk16.
// Runs on the 16 MHz pixel clock, standard VGA 640x480@60 style timing:
//   508 clocks per line (31.496 kHz), 524 lines (60.1 Hz), HS low 60 clocks, VS low 2 lines, both active low (same as OSCA's VGA mode).
// Picture: 8 flag blocks (green = true, red = false), a progress bar of the boot-image bytes received (white tick = expected end),
// and 8 colour bars (checks the RGB wiring).  Flags (left to right):
//   0 DCM locked   1 SDRAM init done   2 ROM loader started   3 ROM loader finished   4 all bytes received
//   5 OSCA released from reset   6 1 Hz heartbeat   7 at least one byte received
module kg_dbg_video #(
    parameter [15:0] IMG_BYTES = 16'd20142
) (
    input  wire       clk16,
    input  wire [7:0] flags,
    input  wire [15:0] bytes,      // bytes received so far (saturating counter)
    output reg  [7:0] r, g, b,
    output reg        hs, vs
);
    reg [8:0] px = 9'd0;
    reg [9:0] ln = 10'd0;
    always @(posedge clk16) begin
        if (px == 9'd507) begin
            px <= 9'd0;
            ln <= (ln == 10'd523) ? 10'd0 : ln + 10'd1;
        end else px <= px + 9'd1;
    end
    wire [7:0] f = {flags[7], flags[6], flags[5], flags[4], flags[3], flags[2], flags[1], flags[0]};
    // active area: px 120..503 (384 wide, 8 blocks of 48), lines 40..519
    wire act_x = (px >= 9'd120) && (px < 9'd504);
    wire act_y = (ln >= 10'd40) && (ln < 10'd520);
    wire [8:0] x = px - 9'd120;
    wire [2:0] blk = x < 9'd48 ? 3'd0 : x < 9'd96 ? 3'd1 : x < 9'd144 ? 3'd2 : x < 9'd192 ? 3'd3 :
                     x < 9'd240 ? 3'd4 : x < 9'd288 ? 3'd5 : x < 9'd336 ? 3'd6 : 3'd7;
    wire gap = (x == 9'd0) || (x == 9'd48) || (x == 9'd96) || (x == 9'd144) || (x == 9'd192) || (x == 9'd240) || (x == 9'd288) || (x == 9'd336);
    wire [8:0] bar_w = bytes[15:6];                         // 0..313 for 20142 bytes (1 pixel = 64 bytes)
    wire [8:0] bar_end = IMG_BYTES[15:6];
    always @(posedge clk16) begin
        hs <= ~(px < 9'd60);
        vs <= ~(ln < 10'd2);
        r <= 8'h00; g <= 8'h00; b <= 8'h00;
        if (act_x && act_y) begin
            if (ln < 10'd200) begin                               // flag blocks (1 px black gap between them)
                if (!gap) begin
                    if (f[blk]) begin g <= 8'hff; end else begin r <= 8'hff; end
                end
            end else if (ln >= 10'd240 && ln < 10'd300) begin     // progress bar
                if (x == bar_end) begin r <= 8'hff; g <= 8'hff; b <= 8'hff; end
                else if (x < bar_w) begin g <= 8'hff; b <= 8'hff; end
                else if (x < 9'd340) begin r <= 8'h20; g <= 8'h20; b <= 8'h20; end
            end else if (ln >= 10'd340) begin                     // colour bars
                r <= {8{blk[2]}}; g <= {8{blk[1]}}; b <= {8{blk[0]}};
            end
        end
    end
endmodule
