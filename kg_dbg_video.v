`timescale 1ns / 1ps
// kg_dbg_video - bring-up status screen, independent of OSCA's video.  Runs on the 16 MHz pixel clock, VGA 640x480@60 style timing:
//   508 clocks per line (31.496 kHz), 524 lines (60.1 Hz), HS low 60 clocks, VS low 2 lines, both active low (same as OSCA's VGA mode).
// Rows, top to bottom (green = true, red = false; bit patterns: white = 1, dark = 0):
//   flags    : 0 DCM locked  1 SDRAM init done  2 ROM loader started  3 ROM loader finished  4 all bytes received
//              5 OSCA released from reset  6 heartbeat (1 Hz)  7 at least one byte received
//   flags2   : 0 CPU waiting now  1 SDRAM WAIT seen  2 core WAIT seen  3 DMA (BUSACK) seen  4 IO write seen  5 IO read seen
//              6 system reset released  7 opcode fetch seen
//   progress : boot image bytes received (white tick = expected end)
//   pc_s     : address of an opcode fetch sampled once per frame (16 bits, bit 15 left)
//   op_s     : the opcode read there (8 bits)
//   pc_max   : highest opcode fetch address seen
//   flags3   : SDRAM calibration (kg_sdram_check), left to right: always green, started, matrix done, no timeout, final verify without errors, done,
//              chosen SDR_CLK polarity (green = 1), chosen capture (green = 1)
//   two rows of 4 cells: image written with SDR_CLK polarity 0 (upper) / 1 (lower), read back with variants (pol 0, cap 0) (0,1) (1,0) (1,1), left to right:
//              green = no mismatch, red = 100 or more, yellow = a few
//   rows 10..15 measured inside the running core: 10 (magenta) palette write strobe cycles into page 1 so far; 11 (orange) into page 0 so far;
//     12 HS period (508 = 0x1FC); 13 rgb_oe high cycles per frame / 4; 14 non-black output pixels per frame; 15 cycles per frame / 4 with displayed palette page 1
//   err_final : mismatches of the final verification (cyan);  first bad address of the first read test (magenta);  expected | read byte there (orange)
module kg_dbg_video #(
    parameter [15:0] IMG_BYTES = 16'd20142
) (
    input  wire        clk16,
    input  wire [7:0]  flags, flags2, flags3, cell_ok, cell_bad,
    input  wire [15:0] bytes, pc_s, pc_max, err_final, first_addr, first_ea,
    input  wire [15:0] m_hs, m_lines, m_nb, m_col,   // measured on OSCA's own video: HS period (clk16), lines per frame, non-black pixels per frame, colour bits ever set
    input  wire [7:0]  op_s,
    output reg  [7:0]  r, g, b,
    output reg         hs, vs
);
    reg [8:0] px = 9'd0;
    reg [9:0] ln = 10'd0;
    always @(posedge clk16) begin
        if (px == 9'd507) begin
            px <= 9'd0;
            ln <= (ln == 10'd523) ? 10'd0 : ln + 10'd1;
        end else px <= px + 9'd1;
    end
    // active area: px 120..503 (384 wide), lines 40..519
    wire act_x = (px >= 9'd120) && (px < 9'd504);
    wire act_y = (ln >= 10'd40) && (ln < 10'd520);
    wire [8:0] x = px - 9'd120;
    wire [2:0] blk8  = x < 9'd48 ? 3'd0 : x < 9'd96 ? 3'd1 : x < 9'd144 ? 3'd2 : x < 9'd192 ? 3'd3 :
                       x < 9'd240 ? 3'd4 : x < 9'd288 ? 3'd5 : x < 9'd336 ? 3'd6 : 3'd7;
    wire gap8  = (x == 9'd0) || (x == 9'd48) || (x == 9'd96) || (x == 9'd144) || (x == 9'd192) || (x == 9'd240) || (x == 9'd288) || (x == 9'd336);
    wire [1:0] blk4  = x < 9'd96 ? 2'd0 : x < 9'd192 ? 2'd1 : x < 9'd288 ? 2'd2 : 2'd3;
    wire gap4  = (x == 9'd0) || (x == 9'd96) || (x == 9'd192) || (x == 9'd288) || (x >= 9'd384);
    wire [9:0] ly = ln - 10'd40;                             // 16 rows of 30 lines (25 used)
    wire [3:0] row = ly / 10'd30;
    wire [5:0] rmod = ly % 10'd30;
    wire [3:0] blk16 = x / 9'd24;
    wire gap16 = (x % 9'd24) == 9'd0;
    wire [8:0] bar_w = bytes[15:6];                         // 0..313 for 20142 bytes (1 pixel = 64 bytes)
    wire [8:0] bar_end = IMG_BYTES[15:6];
    always @(posedge clk16) begin
        hs <= ~(px < 9'd60);
        vs <= ~(ln < 10'd2);
        r <= 8'h00; g <= 8'h00; b <= 8'h00;
        if (act_x && act_y) begin
            if (rmod < 6'd25) begin
                case (row)
                4'd0:  if (!gap8) begin if (flags[blk8]) g <= 8'hff; else r <= 8'hff; end
                4'd1:  if (!gap8) begin if (flags2[blk8]) g <= 8'hff; else r <= 8'hff; end
                4'd2:  begin                                          // progress bar
                           if (x == bar_end) begin r <= 8'hff; g <= 8'hff; b <= 8'hff; end
                           else if (x < bar_w) begin g <= 8'hff; b <= 8'hff; end
                           else if (x < 9'd340) begin r <= 8'h20; g <= 8'h20; b <= 8'h20; end
                       end
                4'd3:  if (!gap16) begin if (pc_s[15 - blk16]) begin r <= 8'hff; g <= 8'hff; b <= 8'hff; end else begin r <= 8'h30; g <= 8'h30; b <= 8'h30; end end
                4'd4:  if (!gap8)  begin if (op_s[7 - blk8])   begin r <= 8'hff; g <= 8'hff; b <= 8'hff; end else begin r <= 8'h30; g <= 8'h30; b <= 8'h30; end end
                4'd5:  if (!gap16) begin if (pc_max[15 - blk16]) begin r <= 8'hff; g <= 8'hff; end else begin r <= 8'h30; g <= 8'h30; end end
                4'd6:  if (!gap8) begin if (flags3[blk8]) g <= 8'hff; else r <= 8'hff; end
                4'd7:  if (!gap4) begin if (cell_ok[blk4]) g <= 8'hff; else if (cell_bad[blk4]) r <= 8'hff; else begin r <= 8'hff; g <= 8'hc0; end end
                4'd8:  if (!gap4) begin if (cell_ok[{1'b1, blk4}]) g <= 8'hff; else if (cell_bad[{1'b1, blk4}]) r <= 8'hff; else begin r <= 8'hff; g <= 8'hc0; end end
                4'd9:  if (!gap16) begin if (err_final[15 - blk16]) begin g <= 8'hff; b <= 8'hff; end else begin g <= 8'h30; b <= 8'h30; end end
                4'd10: if (!gap16) begin if (first_addr[15 - blk16]) begin r <= 8'hff; b <= 8'hff; end else begin r <= 8'h30; b <= 8'h30; end end
                4'd11: if (!gap16) begin if (first_ea[15 - blk16]) begin r <= 8'hff; g <= 8'h80; end else begin r <= 8'h30; g <= 8'h18; end end
                4'd12: if (!gap16) begin if (m_hs[15 - blk16])    begin r <= 8'h80; g <= 8'h80; b <= 8'hff; end else begin r <= 8'h18; g <= 8'h18; b <= 8'h30; end end
                4'd13: if (!gap16) begin if (m_lines[15 - blk16]) begin r <= 8'h80; g <= 8'h80; b <= 8'hff; end else begin r <= 8'h18; g <= 8'h18; b <= 8'h30; end end
                4'd14: if (!gap16) begin if (m_nb[15 - blk16])    begin r <= 8'hff; g <= 8'hff; b <= 8'h80; end else begin r <= 8'h30; g <= 8'h30; b <= 8'h18; end end
                4'd15: if (!gap16) begin if (m_col[15 - blk16])   begin r <= 8'hff; g <= 8'hff; b <= 8'h80; end else begin r <= 8'h30; g <= 8'h30; b <= 8'h18; end end
                default: ;
                endcase
            end
        end
    end
endmodule
