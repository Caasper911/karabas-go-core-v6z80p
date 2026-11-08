`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// kg_osca_mem (v2) - video RAM + sprite RAM of OSCA on the single Karabas Go SRAM
//
// The system RAM is NOT here any more (it goes to SDRAM, see kg_osca_soc).
//
// OSCA's video RAM is a two-phase bus: in the first half of a 16 MHz cycle the display fetch owns the address bus,
// in the second half the blitter / CPU / line draw do (their address changes on the clk16 FALLING edge and their strobes
// are half-cycle pulses).  Everything is captured on the clk16 rising edge.  Measured: the core tolerates ~2-3 ticks
// (96 MHz) of read latency, so the data of the second phase is delivered on a separate bus (vram_rdata2) and the
// consumers of that bus in the core capture half a cycle later (see patch_osca_top.py).
//
//   clk_mem = 16 MHz * 6 = 96 MHz.  tick 0 = clk16 rising edge.  Slots (2 ticks each, launch at the edge that begins the tick):
//     A (1): video RAM read, display fetch (address valid from tick 0)          -> vram_rdata1, valid from tick 4
//     B (3): sprite RAM read / write                                            -> spr_rdata,   valid from tick 5 (stable over the tick-6 edge)
//     C (5): video RAM write (strobe low) else video RAM read, blitter / CPU    -> vram_rdata2, valid from tick 8
//   Physical map (low-byte chip only):  vram 0x000000.., spr 0x100000..
//////////////////////////////////////////////////////////////////////////////////
module kg_osca_mem #(
    parameter N         = 6,
    parameter LAT       = 2,
    parameter SLOT_A    = 1,
    parameter SLOT_B    = 3,
    parameter SLOT_C    = 5
)(
    input  wire        clk_mem,
    output reg         clk16 = 1'b0,

    input  wire [18:0] vram_addr,
    input  wire        vram_wr_n,
    input  wire [7:0]  vram_wdata,
    output reg  [7:0]  vram_rdata1 = 8'h00,     // display fetch (first phase)
    output reg  [7:0]  vram_rdata2 = 8'h00,     // blitter / CPU (second phase)

    input  wire [16:0] spr_addr,
    input  wire        spr_wr_n,
    input  wire [7:0]  spr_wdata,
    output wire [7:0]  spr_rdata,               // = md_q, stable across the clk16 edge at tick 6 (see below)

    output reg  [20:0] ma     = 21'h0,
    output reg  [15:0] md_o   = 16'h0,
    output reg         md_oe  = 1'b0,
    input  wire [15:0] md_i,
    output wire [1:0]  mwr_n,
    output wire [1:0]  mrd_n
);
    reg  [2:0] tick = 3'd0;
    wire [2:0] tick_n = (tick == N-1) ? 3'd0 : tick + 3'd1;
    always @(posedge clk_mem) begin
        tick  <= tick_n;
        clk16 <= (tick_n < N/2);
    end
    wire go_a = (tick_n == SLOT_A);
    wire go_b = (tick_n == SLOT_B);
    wire go_c = (tick_n == SLOT_C);

    // ---------------- write capture / execution (each strobe-low period is written exactly once)
    reg        pend_v = 0, pend_s = 0, done_v = 0, done_s = 0;
    reg [18:0] pa_v = 0, la_v = 0;  reg [7:0] pd_v = 0, ld_v = 0;
    reg [16:0] pa_s = 0, la_s = 0;  reg [7:0] pd_s = 0, ld_s = 0;
    wire act_v = !vram_wr_n;
    wire act_s = !spr_wr_n;
    wire do_v = pend_v || (act_v && !done_v);
    wire do_s = pend_s || (act_s && !done_s);
    wire [18:0] wa_v = pend_v ? pa_v : vram_addr;  wire [7:0] wd_v = pend_v ? pd_v : vram_wdata;
    wire [16:0] wa_s = pend_s ? pa_s : spr_addr;   wire [7:0] wd_s = pend_s ? pd_s : spr_wdata;

    reg [LAT:0] c1 = 0, c2 = 0, cs = 0;
    reg  [7:0]  md_q = 8'h00;
    reg         wr_pre = 1'b0, mrd0_n = 1'b1, mwr0_n = 1'b1;

    always @(posedge clk_mem) begin
        wr_pre <= 1'b0;
        if (!act_v || vram_addr != la_v || vram_wdata != ld_v) done_v <= 1'b0;
        if (!act_s || spr_addr  != la_s || spr_wdata  != ld_s) done_s <= 1'b0;
        if (act_v && !done_v) begin pend_v <= 1'b1; pa_v <= vram_addr; pd_v <= vram_wdata; end
        if (act_s && !done_s) begin pend_s <= 1'b1; pa_s <= spr_addr;  pd_s <= spr_wdata;  end

        if (go_a) begin                                              // display fetch read (speculative)
            ma <= {2'b00, vram_addr}; md_oe <= 1'b0; mrd0_n <= 1'b0;
        end
        if (go_b) begin                                              // sprite RAM
            if (do_s) begin
                ma <= {4'b1000, wa_s}; md_o <= {8'h00, wd_s}; md_oe <= 1'b1; mrd0_n <= 1'b1; wr_pre <= 1'b1;
                pend_s <= 1'b0; done_s <= act_s; la_s <= wa_s; ld_s <= wd_s;
            end
            else begin ma <= {4'b1000, spr_addr}; md_oe <= 1'b0; mrd0_n <= 1'b0; end
        end
        if (go_c) begin                                              // video RAM write, else second-phase read
            if (do_v) begin
                ma <= {2'b00, wa_v}; md_o <= {8'h00, wd_v}; md_oe <= 1'b1; mrd0_n <= 1'b1; wr_pre <= 1'b1;
                pend_v <= 1'b0; done_v <= act_v; la_v <= wa_v; ld_v <= wd_v;
            end
            else begin ma <= {2'b00, vram_addr}; md_oe <= 1'b0; mrd0_n <= 1'b0; end
        end

        // md_q is loaded ONLY at the edge where a read launched LAT ticks ago has arrived.  The sprite read (launch tick 3)
        // is therefore sampled at tick 5 and md_q does not change at the clk16 edge (tick 6): the sprite engine, which
        // captures on that edge, sees the data in the same cycle, like with the original asynchronous SRAM.
        if (c1[LAT-1] | cs[LAT-1] | c2[LAT-1]) md_q <= md_i[7:0];
        c1 <= {c1, go_a};
        cs <= {cs, go_b & ~do_s};
        c2 <= {c2, go_c & ~do_v};
        if (c1[LAT]) vram_rdata1 <= md_q;
        if (c2[LAT]) vram_rdata2 <= md_q;
    end
    assign spr_rdata = md_q;
    always @(negedge clk_mem) mwr0_n <= ~wr_pre;
    assign mwr_n = {1'b1, mwr0_n};
    assign mrd_n = {1'b1, mrd0_n};
endmodule
