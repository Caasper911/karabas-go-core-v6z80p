`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// !!! KNOWN LIMITATION (measured, see README): the video RAM of OSCA is a two-phase bus.  Its address changes on BOTH
// !!! clk16 edges (display fetch on the rising edge, blitter / CPU on the falling edge) and the core captures the data
// !!! half a cycle (31 ns) later.  Experiment: with video RAM data 2 ticks (21 ns @96 MHz) after the address the core draws
// !!! text, with 4 ticks (42 ns) it does not.  This wrapper delivers video data 4 ticks after launch, so it is NOT
// !!! sufficient for the video RAM.  It works for the system RAM (CPU) - see tb_kg_osca_soc.
// kg_osca_mem - memory wrapper for OSCA (V6Z80P+) on Karabas Go
//
// OSCA expects three independent asynchronous 8-bit SRAMs:
//     video RAM  512K  (vram_*)      sprite RAM 128K (spr_*)      system RAM 512K (system_ram_*)
// Karabas Go has ONE physical SRAM bus: MA[20:0], MD[15:0], MWR_N[1:0], MRD_N[1:0]
// (two 2Mx8 chips, common address, per-byte-lane strobes).  This module time-slices
// the three logical memories onto that bus, N slots per 16 MHz OSCA cycle:
//
//   clk_mem = 16 MHz * N   (default N = 6 -> 96 MHz, tick = 10.4 ns)
//   clk16   = generated here from the same tick counter (route it through a BUFG and
//             use it as OSCA's clock_16mhz) so the two clocks are exactly phase aligned.
//
//   One access takes 2 ticks.  Slot s = the clk_mem edge that BEGINS tick s of the cycle
//   (tick 0 starts on the rising edge of clk16).  Default slots 1 / 3 / 5.
//     launch  : address (and data, for a write) leave registers at the slot edge
//     write   : WE# is a 1-tick pulse made on the FALLING clk_mem edge in the middle of the
//               slot, so address/data are stable before it falls and held after it rises
//     read    : OE# low, data sampled in an IOB register LAT ticks after launch, then copied
//               into the logical read-data register one tick later
//
//   Reads are unconditional (no side effects): *_rdata always shows mem[*_addr] as of the
//   last slot.  Writes are captured every clk_mem tick while the logical WE# is low
//   (so pulses shorter than a 16 MHz cycle are not lost) and executed in the memory's slot.
//
// Logical-side contract (all signals belong to the clk16 domain):
//   vram : same-cycle read.  Address valid <= SLOT_VRAM ticks after the clk16 edge; data
//          valid SLOT_VRAM+LAT+1 ticks after the clk16 edge (< 1 cycle with defaults).
//   spr  : read data arrives in the NEXT 16 MHz cycle (SLOT_SPR+LAT+1 = 6 ticks with defaults)
//   sys  : read data arrives in the NEXT 16 MHz cycle  (SLOT_SYS+LAT+1 = 8 ticks)
//   The core (soft Z80 / sprite engine) must tolerate that; see the notes in the reply.
//
// Physical map (low-byte chip only, MD[7:0]; the high-byte chip is left idle):
//   vram  -> 0x000000 .. 0x07FFFF      sys -> 0x080000 .. 0x0FFFFF      spr -> 0x100000 .. 0x11FFFF
//
// Requirements: N <= 8, slots distinct and >= 2 ticks apart (mod N), LAT >= 1.
//////////////////////////////////////////////////////////////////////////////////
module kg_osca_mem #(
    parameter N         = 6,
    parameter LAT       = 2,
    parameter SLOT_VRAM = 1,
    parameter SLOT_SYS  = 3,
    parameter SLOT_SPR  = 5
)(
    input  wire        clk_mem,          // 16 MHz * N, from the PLL / DCM_CLKGEN
    output reg         clk16 = 1'b0,     // 16 MHz, phase aligned with the tick counter (-> BUFG)

    // video RAM (logical 512K x 8)
    input  wire [18:0] vram_addr,        // = vram_addr_out
    input  wire        vram_wr_n,        // = vram_wr    (active low)
    input  wire [7:0]  vram_wdata,
    output reg  [7:0]  vram_rdata = 8'h00,

    // sprite RAM (logical 128K x 8)
    input  wire [16:0] spr_addr,         // = spr_addrbus
    input  wire        spr_wr_n,         // = spr_ram_wr (active low)
    input  wire [7:0]  spr_wdata,
    output reg  [7:0]  spr_rdata = 8'h00,

    // system RAM (logical 512K x 8): {system_ram_a18..a14, Z80 A13..A0}
    input  wire [18:0] sys_addr,
    input  wire        sys_cs_n,         // = system_ram_cs (active low)
    input  wire        sys_wr_n,         // Z80 /WR on the shared bus (active low)
    input  wire [7:0]  sys_wdata,
    output reg  [7:0]  sys_rdata = 8'h00,

    // Karabas Go SRAM pins (use IOB registers; MD is inout at the pads: MD = md_oe ? md_o : 'Z)
    output reg  [20:0] ma     = 21'h0,
    output reg  [15:0] md_o   = 16'h0,
    output reg         md_oe  = 1'b0,
    input  wire [15:0] md_i,
    output wire [1:0]  mwr_n,
    output wire [1:0]  mrd_n
);
    // ---------------------------------------------------------------- tick counter / clk16
    reg  [2:0] tick = 3'd0;
    wire [2:0] tick_n = (tick == N-1) ? 3'd0 : tick + 3'd1;
    always @(posedge clk_mem) begin
        tick  <= tick_n;
        clk16 <= (tick_n < N/2);           // rises on the edge that begins tick 0
    end

    // Slots (edge that begins tick N of the cycle, tick 0 = clk16 rising edge; defaults 1 / 3 / 5):
    //   A (1): video RAM READ, speculative in every cycle (a read has no side effects; the core's video / blitter
    //          read strobe is a half-cycle pulse, so it cannot be used to decide)
    //   B (3): system RAM (CPU / DMA, read or write: its strobes cover the whole cycle)
    //   C (5): video RAM WRITE when its strobe is low (half-cycle pulse from the clk16 falling edge: it cannot be
    //          seen before tick 4), otherwise the sprite RAM
    // The core never reads and writes the video RAM in the same cycle, so the speculative read in A is harmless.
    wire go_a = (tick_n == SLOT_VRAM);
    wire go_b = (tick_n == SLOT_SYS);
    wire go_c = (tick_n == SLOT_SPR);

    // ---------------------------------------------------------------- write capture / execution
    // A write is executed in the slot of the SAME 16 MHz cycle when the logical strobe is already low at the slot
    // edge (the normal case: strobes follow the clk16 edge).  A strobe that starts later is captured on the fly
    // and executed in the next slot.  Each low period of a strobe (one address/data pair) is written exactly once.
    reg        pend_v = 0, pend_s = 0, pend_y = 0;
    reg        done_v = 0, done_s = 0, done_y = 0;        // the current strobe-low period has already been written
    reg [18:0] pa_v = 0, la_v = 0;  reg [7:0] pd_v = 0, ld_v = 0;
    reg [16:0] pa_s = 0, la_s = 0;  reg [7:0] pd_s = 0, ld_s = 0;
    reg [18:0] pa_y = 0, la_y = 0;  reg [7:0] pd_y = 0, ld_y = 0;

    wire act_v = !vram_wr_n;
    wire act_s = !spr_wr_n;
    wire act_y = !sys_cs_n && !sys_wr_n;
    // a write to do now: something captured earlier, or a strobe that is low right now and not yet written
    wire do_v = pend_v || (act_v && !done_v);
    wire do_s = pend_s || (act_s && !done_s);
    wire do_y = pend_y || (act_y && !done_y);
    wire [18:0] wa_v = pend_v ? pa_v : vram_addr;  wire [7:0] wd_v = pend_v ? pd_v : vram_wdata;
    wire [16:0] wa_s = pend_s ? pa_s : spr_addr;   wire [7:0] wd_s = pend_s ? pd_s : spr_wdata;
    wire [18:0] wa_y = pend_y ? pa_y : sys_addr;   wire [7:0] wd_y = pend_y ? pd_y : sys_wdata;

    // ---------------------------------------------------------------- read pipeline
    reg [LAT:0] cv = 0, cs = 0, cy = 0;    // "this launch was a read": capture when bit LAT is set
    reg  [7:0]  md_q = 8'h00;              // IOB input register on MD[7:0]
    reg         wr_pre = 1'b0;             // one tick long, high from the launch edge
    reg         mrd0_n = 1'b1;
    reg         mwr0_n = 1'b1;

    always @(posedge clk_mem) begin
        wr_pre <= 1'b0;

        // a strobe that has been released, or a new address/data pair, makes the next write a new one
        if (!act_v || vram_addr != la_v || vram_wdata != ld_v) done_v <= 1'b0;
        if (!act_s || spr_addr  != la_s || spr_wdata  != ld_s) done_s <= 1'b0;
        if (!act_y || sys_addr  != la_y || sys_wdata  != ld_y) done_y <= 1'b0;

        // capture while a strobe is low and its write has not been executed yet
        if (act_v && !done_v) begin pend_v <= 1'b1; pa_v <= vram_addr; pd_v <= vram_wdata; end
        if (act_s && !done_s) begin pend_s <= 1'b1; pa_s <= spr_addr;  pd_s <= spr_wdata;  end
        if (act_y && !done_y) begin pend_y <= 1'b1; pa_y <= sys_addr;  pd_y <= sys_wdata;  end

        // launch (these assignments win over the capture above when both happen at the same edge)
        if (go_a) begin                                             // video RAM read (speculative)
            ma <= {2'b00, vram_addr}; md_oe <= 1'b0; mrd0_n <= 1'b0;
        end
        if (go_b) begin                                             // system RAM
            if (do_y) begin
                ma <= {2'b01, wa_y}; md_o <= {8'h00, wd_y}; md_oe <= 1'b1; mrd0_n <= 1'b1; wr_pre <= 1'b1;
                pend_y <= 1'b0; done_y <= act_y; la_y <= wa_y; ld_y <= wd_y;
            end
            else begin ma <= {2'b01, sys_addr}; md_oe <= 1'b0; mrd0_n <= 1'b0; end
        end
        if (go_c) begin
            if (do_v) begin                                         // video RAM write
                ma <= {2'b00, wa_v}; md_o <= {8'h00, wd_v}; md_oe <= 1'b1; mrd0_n <= 1'b1; wr_pre <= 1'b1;
                pend_v <= 1'b0; done_v <= act_v; la_v <= wa_v; ld_v <= wd_v;
            end
            else if (do_s) begin                                    // sprite RAM write
                ma <= {4'b1000, wa_s}; md_o <= {8'h00, wd_s}; md_oe <= 1'b1; mrd0_n <= 1'b1; wr_pre <= 1'b1;
                pend_s <= 1'b0; done_s <= act_s; la_s <= wa_s; ld_s <= wd_s;
            end
            else begin ma <= {4'b1000, spr_addr}; md_oe <= 1'b0; mrd0_n <= 1'b0; end   // sprite RAM read
        end

        // read capture pipeline
        md_q <= md_i[7:0];
        cv <= {cv, go_a};
        cy <= {cy, go_b & ~do_y};
        cs <= {cs, go_c & ~do_v & ~do_s};
        if (cv[LAT]) vram_rdata <= md_q;
        if (cs[LAT]) spr_rdata  <= md_q;
        if (cy[LAT]) sys_rdata  <= md_q;
    end

    // WE# pulse on the falling edge: low for exactly one tick, in the middle of the slot
    always @(negedge clk_mem) mwr0_n <= ~wr_pre;

    assign mwr_n = {1'b1, mwr0_n};
    assign mrd_n = {1'b1, mrd0_n};
endmodule
