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
    input  wire        clk16_ref,              // KG_PLL16: the board's clk16 from the PLL; the tick counter follows it (unused in simulation)

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
    output wire [1:0]  mrd_n,
    // bring-up SRAM self test: when t_en = 1 the pins are driven by these (through the same IOB flip-flops)
    input  wire        t_en,
    input  wire [20:0] t_ma,
    input  wire [15:0] t_md,
    input  wire        t_oe,
    input  wire [1:0]  t_wr_n,
    input  wire [1:0]  t_rd_n
);
    reg  [2:0] tick = 3'd0;
    wire [2:0] tick_inc = (tick == N-1) ? 3'd0 : tick + 3'd1;
`ifdef KG_PLL16
    // clk16 comes from the PLL with its rising edges on clk_mem rising edges: a toggle on clk16 is sampled on the clk_mem FALLING edge (half a
    // period away from both clocks' edges) and the counter is set to tick 1 on the clk_mem edge that follows the clk16 edge.
    reg t16 = 1'b0;
    always @(posedge clk16_ref) t16 <= ~t16;
    // (the comparison uses two rising-edge registers: the falling-edge register feeds nothing but them, half a period is enough for that)
    reg t16_n = 1'b0, t16_p = 1'b0, t16_q = 1'b0;
    always @(negedge clk_mem) t16_n <= t16;
    always @(posedge clk_mem) begin t16_p <= t16_n; t16_q <= t16_p; end
    wire [2:0] tick_n = (t16_p != t16_q) ? 3'd2 : tick_inc;           // one tick later than the first sight: this edge starts tick 2
`else
    wire [2:0] tick_n = tick_inc;
`endif
    always @(posedge clk_mem) begin
        tick  <= tick_n;
        clk16 <= (tick_n < N/2);
    end
    wire go_a = (tick_n == SLOT_A);
    wire go_b = (tick_n == SLOT_B);
    wire go_c = (tick_n == SLOT_C);

    // ---------------- writes: decided at fixed ticks only (the inputs come from clk16 registers through OSCA's logic, or from the CPU:
    // each one is used at least 2 ticks after it can change, see the UCF).  Measured in the simulation (T80pa bus model, KG_MEMLOG):
    //   vram_addr / spr_addr change at ticks 0, 1 (CPU, CEN_p) and 3 (second phase);
    //   video RAM strobe, kind 1 (CPU, blitter): low in ticks 0..3 (some 0..9);  kind 2: low in ticks 3..5;
    //   sprite RAM strobe: low in ticks 0..3.
    // The video RAM bus has two phases: ticks 0..2 carry the display fetch address, the write address (CPU, blitter) appears at tick 3.
    // Tick 3 (slot B): only the FACT that a kind-1 strobe is low is noted (pend_v); the sprite RAM is written or read.
    // Tick 5 (slot C): a write (pend_v or a low strobe) with address / data taken from the inputs now (second phase, stable since tick 3), else a read.
    reg        pend_v = 1'b0;
    wire wr_b = !spr_wr_n;                       // used at tick 3 only
    wire wr_c = pend_v | !vram_wr_n;             // used at tick 5 only
    wire [20:0] ma_bc = t_en ? t_ma : go_b ? {4'b1000, spr_addr} : {2'b00, vram_addr};   // slots B / C and the self test

    reg [LAT:0] c1 = 0, c2 = 0, cs = 0;
`ifdef KG_MEMLOG
    // statistics for the input timing: tick (0..5, 0 = clk16 rising edge) at which each strobe falls / rises and at which the addresses change
    integer h_vf [0:5], h_vr [0:5], h_sf [0:5], h_sr [0:5], h_va [0:5], h_sa [0:5], h_vd [0:5], h_len [0:15];
    integer hi, vlen = 0;
    reg pv = 1'b1, ps = 1'b1;  reg [18:0] pva = 0;  reg [16:0] psa = 0;  reg [7:0] pvd = 0;
    initial for (hi = 0; hi < 6; hi = hi + 1) begin h_vf[hi] = 0; h_vr[hi] = 0; h_sf[hi] = 0; h_sr[hi] = 0; h_va[hi] = 0; h_sa[hi] = 0; h_vd[hi] = 0; end
    initial for (hi = 0; hi < 16; hi = hi + 1) h_len[hi] = 0;
    always @(posedge clk_mem) begin
        pv <= vram_wr_n; ps <= spr_wr_n; pva <= vram_addr; psa <= spr_addr; pvd <= vram_wdata;
        if (pv && !vram_wr_n) begin h_vf[tick] = h_vf[tick] + 1; vlen = 0; end
        if (!vram_wr_n) vlen = vlen + 1;
        if (!pv && vram_wr_n) begin h_vr[tick] = h_vr[tick] + 1; h_len[vlen > 15 ? 15 : vlen] = h_len[vlen > 15 ? 15 : vlen] + 1; end
        if (ps && !spr_wr_n) h_sf[tick] = h_sf[tick] + 1;
        if (!ps && spr_wr_n) h_sr[tick] = h_sr[tick] + 1;
        if (pva != vram_addr) h_va[tick] = h_va[tick] + 1;
        if (psa != spr_addr) h_sa[tick] = h_sa[tick] + 1;
        if (!vram_wr_n && pvd != vram_wdata) h_vd[tick] = h_vd[tick] + 1;
    end
    final begin
        $display("MEMLOG ticks 0..5 (tick = value of the counter in the clk_mem cycle where the new value is first seen)");
        $display("MEMLOG vram_wr_n fall: %0d %0d %0d %0d %0d %0d", h_vf[0], h_vf[1], h_vf[2], h_vf[3], h_vf[4], h_vf[5]);
        $display("MEMLOG vram_wr_n rise: %0d %0d %0d %0d %0d %0d", h_vr[0], h_vr[1], h_vr[2], h_vr[3], h_vr[4], h_vr[5]);
        $display("MEMLOG vram low length (ticks) 0..15: %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d", h_len[0], h_len[1], h_len[2], h_len[3], h_len[4], h_len[5], h_len[6], h_len[7], h_len[8], h_len[9], h_len[10], h_len[11], h_len[12], h_len[13], h_len[14], h_len[15]);
        $display("MEMLOG vram_wdata change while writing: %0d %0d %0d %0d %0d %0d", h_vd[0], h_vd[1], h_vd[2], h_vd[3], h_vd[4], h_vd[5]);
        $display("MEMLOG spr_wr_n fall: %0d %0d %0d %0d %0d %0d", h_sf[0], h_sf[1], h_sf[2], h_sf[3], h_sf[4], h_sf[5]);
        $display("MEMLOG spr_wr_n rise: %0d %0d %0d %0d %0d %0d", h_sr[0], h_sr[1], h_sr[2], h_sr[3], h_sr[4], h_sr[5]);
        $display("MEMLOG vram_addr change: %0d %0d %0d %0d %0d %0d", h_va[0], h_va[1], h_va[2], h_va[3], h_va[4], h_va[5]);
        $display("MEMLOG spr_addr change: %0d %0d %0d %0d %0d %0d", h_sa[0], h_sa[1], h_sa[2], h_sa[3], h_sa[4], h_sa[5]);
    end
`endif
    reg  [7:0]  md_q = 8'h00;
    reg         wr_pre = 1'b0, mrd0_n = 1'b1, mwr0_n = 1'b1, mrd1_n = 1'b1, mwr1_n = 1'b1;

    always @(posedge clk_mem) begin
        wr_pre <= 1'b0;
        // ma: the display fetch address (slot A, one tick after the clk16 edge) enters the last multiplexer stage; the other sources (slots B / C,
        // the self test) have two ticks or are static
        if (go_a && !t_en) ma <= {2'b00, vram_addr};
        else if (go_b || go_c || t_en) ma <= ma_bc;
        if (go_a) begin                                              // display fetch read (speculative)
            md_oe <= 1'b0; mrd0_n <= 1'b0;
        end
        if (go_b) begin                                              // sprite RAM; capture of a kind-1 video RAM write
            pend_v <= !vram_wr_n;
            if (wr_b) begin md_o <= {8'h00, spr_wdata}; md_oe <= 1'b1; mrd0_n <= 1'b1; wr_pre <= 1'b1; end
            else      begin md_oe <= 1'b0; mrd0_n <= 1'b0; end
        end
        if (go_c) begin                                              // video RAM write, else second-phase read
            pend_v <= 1'b0;
            if (wr_c) begin md_o <= {8'h00, vram_wdata}; md_oe <= 1'b1; mrd0_n <= 1'b1; wr_pre <= 1'b1; end
            else      begin md_oe <= 1'b0; mrd0_n <= 1'b0; end
        end

        // md_q is loaded ONLY at the edge where a read launched LAT ticks ago has arrived.  The sprite read (launch tick 3)
        // is therefore sampled at tick 5 and md_q does not change at the clk16 edge (tick 6): the sprite engine, which
        // captures on that edge, sees the data in the same cycle, like with the original asynchronous SRAM.
        if (c1[LAT-1] | cs[LAT-1] | c2[LAT-1]) md_q <= md_i[7:0];
        c1 <= {c1, go_a};
        cs <= {cs, go_b & ~wr_b};
        c2 <= {c2, go_c & ~wr_c};
        if (t_en) begin md_o <= t_md; md_oe <= t_oe; end
        if (t_en) mrd0_n <= t_rd_n[0];
        mrd1_n <= t_en ? t_rd_n[1] : 1'b1;
        if (c1[LAT]) vram_rdata1 <= md_q;
        if (c2[LAT]) vram_rdata2 <= md_q;
    end
    assign spr_rdata = md_q;
    always @(negedge clk_mem) begin mwr0_n <= t_en ? t_wr_n[0] : ~wr_pre; mwr1_n <= t_en ? t_wr_n[1] : 1'b1; end
    assign mwr_n = {mwr1_n, mwr0_n};
    assign mrd_n = {mrd1_n, mrd0_n};
endmodule
