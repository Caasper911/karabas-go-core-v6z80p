`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// kg_osca_sdram - OSCA system RAM (512 KB, 8 bit, asynchronous-SRAM style port) on the 32 MB SDRAM of Karabas Go, clk = 96 MHz
//
// Based on the access sequence of fastram_sdram.v of the NanoMig port (ACTIVE, READ/WRITE with auto-precharge, CAS latency 2, one 16 bit
// word per access, nothing stays open) with the clocks re-counted for 10.4 ns:
//    clock 0 ACTIVE   1 NOP   2 READ / WRITE (A10 = auto-precharge)   3..5 NOP   6 read data captured   7 next command allowed
//    (tRCD 20 ns = 2 clocks, tRC / tRFC 66 ns = 7 clocks; an access is 7 clocks = 73 ns)
//
// Port behaviour (the core's view of an asynchronous SRAM):
//   * READ  : speculative.  Whenever the word address changes a read of that 16 bit word is started; rdata / rd_valid follow
//             (byte select by addr[0]).  The CPU needs WAIT_n while  !cs_n && read strobe && !rd_valid  (the SoC builds it).
//   * WRITE : a low period of (cs_n, wr_n) captures {addr, wdata} once and executes it when the controller is free (the read
//             data word is kept coherent), so the writer can continue immediately.
//   * REFRESH: a counter makes debt every REF_PERIOD clocks (max 8); a refresh is issued when idle and block_refresh = 0
//             (block_refresh = 1 while the FPGA owns / requests the bus: audio and line copper DMA cannot be stalled);
//             at debt 7 it is forced.
// Latency from an address change to rd_valid: 8 clocks when idle (registered address + 7; the completing read goes into the output register on its last clock), + up to 7 behind a running access, + 7 behind a refresh.  A hit: 1 clock (registered output).
//
// Physical notes: SDR_CLK should be a copy of clk, phase-adjusted for the board (the chip needs its data valid ~5 ns after its clock
// edge, which at 96 MHz is marginal with a plain copy: a DCM/PLL phase-shifted clock is probably needed).  Not verified here.
//////////////////////////////////////////////////////////////////////////////////
module kg_osca_sdram #(
    parameter INIT_WAIT  = 16'd9800,       // > 100 us of clocks after power-up
    parameter REF_PERIOD = 10'd720         // 7.5 us
)(
    input  wire        clk,
    input  wire        reset,              // 1 until the clock is stable
    input  wire [18:0] addr,
    input  wire        cs_n,
    input  wire        wr_n,
    input  wire [7:0]  wdata,
    input  wire        block_refresh,
    input  wire        dma_owns,           // 1 while the FPGA (audio / line copper DMA) owns the bus: reads start from the bus address at once (that DMA cannot wait)
    input  wire        cap_late,           // 0: read data taken from the pins at clock 6 (access = 7 clocks); 1: from the IOB flip-flop at clock 7 (access = 8 clocks)
    input  wire [18:0] hint_addr,          // address the FPGA will read next (line copper PC + 2): read ahead in the background
    output wire [7:0]  rdata,
    output wire        rd_valid,
    output wire        wr_pending,
    output wire        init_done,

    (* IOB = "TRUE" *) output reg  [1:0]  sd_ba    = 2'b00,
    (* IOB = "TRUE" *) output reg  [12:0] sd_a     = 13'd0,
    (* IOB = "TRUE" *) output reg  [1:0]  sd_dqm   = 2'b11,
    (* IOB = "TRUE" *) output reg         sd_ras_n = 1'b1,
    (* IOB = "TRUE" *) output reg         sd_cas_n = 1'b1,
    (* IOB = "TRUE" *) output reg         sd_we_n  = 1'b1,
    inout  wire [15:0] sd_dq
);
    localparam CMD_NOP = 3'b111, CMD_ACTIVE = 3'b011, CMD_READ = 3'b101, CMD_WRITE = 3'b100,
               CMD_PRECHARGE = 3'b010, CMD_REFRESH = 3'b001, CMD_MODE = 3'b000;
    localparam [12:0] MODE = 13'b000_0_00_010_0_000;          // CAS 2, burst length 1
    localparam ST_INIT = 2'd0, ST_IDLE = 2'd1, ST_ACC = 2'd2, ST_REF = 2'd3;

    reg [1:0]  state = ST_INIT;
    reg [2:0]  step = 3'd0;
    reg [15:0] wait_cnt = 16'd0;
    reg [3:0]  init_step = 4'd0;
    reg [9:0]  ref_cnt = 10'd0;
    reg [3:0]  ref_debt = 4'd0;
    assign init_done = (state != ST_INIT);

    // ---------------- data register / read bookkeeping
    reg [15:0] rd_word = 16'd0;
    reg [17:0] rd_wa = 18'd0;
    reg        rd_ok = 1'b0;
    wire [17:0] wa = addr[18:1];
    // two read-ahead words: the words of the hint address (PC) and of the next one.  The line copper (and any sequential DMA) finds both
    // already loaded: the word it is about to read AND the one after it.
    reg [15:0] e0_word = 16'd0, e1_word = 16'd0;
    reg [17:0] e0_cwa = 18'd0, e1_cwa = 18'd0;
    reg        e0_ok = 1'b0, e1_ok = 1'b0;
    reg  [18:0] hint_q = 19'd0;                 // the line copper's PC comes from clk16 registers: registered (a read ahead does not mind the tick)
    always @(posedge clk) hint_q <= hint_addr;
    wire [17:0] t0 = hint_q[18:1];
    wire [17:0] t1 = t0 + 18'd1;
    wire hit_rd   = rd_ok && rd_wa == wa;
    wire hit_e0   = e0_ok && e0_cwa == wa;
    wire hit_e1   = e1_ok && e1_cwa == wa;
    wire hit_hint = hit_e0 || hit_e1;
    wire need_read = !(hit_rd || hit_hint);
    // the state machine starts reads from a registered copy of the address (the CPU bus comes through long decoders: a read started from the
    // bus itself could see a half-settled address on the tick after a change).  rdata / rd_valid are registers (see below).
    reg  [18:0] addr_q = 19'd0;
    // Both the CPU's and the DMA's address come through OSCA's decoders (the DMA's from clk16 registers): too long for one tick into sd_a.
    always @(posedge clk) addr_q <= addr;
    wire [17:0] wa_q = addr_q[18:1];
    // No read ahead between the FPGA's bus request and the moment it owns the bus: the first read of the DMA (audio: data taken 12 ticks after the
    // address change, no wait possible) would have to wait for it (seen in the simulation with the T80pa bus model).  Registered: BUSAK# comes from a T80 register.
    reg br_q = 1'b0, dma_q = 1'b0;
    always @(posedge clk) begin br_q <= block_refresh; dma_q <= dma_owns; end
    wire hint_ok = !(br_q && !dma_q);
    wire hitq_rd = rd_ok && rd_wa == wa_q, hitq_e0 = e0_ok && e0_cwa == wa_q, hitq_e1 = e1_ok && e1_cwa == wa_q, hitq_hint = hitq_e0 || hitq_e1;
    wire need_read_q = !(hitq_rd || hitq_hint);
    wire [15:0] hint_hit_word = hit_e0 ? e0_word : e1_word;
    wire [17:0] hint_hit_cwa  = hit_e0 ? e0_cwa  : e1_cwa;
    wire [15:0] hit_word = hit_rd ? rd_word : hint_hit_word;
    // what is missing and where it can go
    wire have_t0 = (rd_ok && rd_wa == t0) || (e0_ok && e0_cwa == t0) || (e1_ok && e1_cwa == t0);
    wire have_t1 = (rd_ok && rd_wa == t1) || (e0_ok && e0_cwa == t1) || (e1_ok && e1_cwa == t1);
    wire v0 = !e0_ok || (e0_cwa != t0 && e0_cwa != t1);
    wire v1 = !e1_ok || (e1_cwa != t0 && e1_cwa != t1);
    wire want_hint = (!have_t0 || !have_t1) && (v0 || v1);
    wire [17:0] hint_target = !have_t0 ? t0 : t1;
    wire hint_victim = v0 ? 1'b0 : 1'b1;
    // the read-ahead decision is registered (it is not urgent): it comes from the slot tags through comparators, too long for one tick in front of
    // the command / sd_a.  It is used only when the controller was idle on the tick before as well (the slots did not change under it).
    reg        want_hint_q = 1'b0, hint_victim_q = 1'b0, idle_prev = 1'b0;
    reg [17:0] hint_target_q = 18'd0;
    always @(posedge clk) begin want_hint_q <= want_hint; hint_target_q <= hint_target; hint_victim_q <= hint_victim; idle_prev <= (state == ST_IDLE); end
    wire want_hint_r = want_hint_q && idle_prev;

    // ---------------- pending write (captured once per low period of the strobe)
    reg        pw = 1'b0, wdone = 1'b0;
    reg [18:0] pw_addr = 19'd0;
    reg [7:0]  pw_data = 8'd0;
    wire       act = !cs_n && !wr_n;
    assign wr_pending = pw;
    // A captured write is visible at once: while it waits (pw = 1) its byte is merged into every cached copy of its word, and a read of that
    // word completing meanwhile stores the merged word (without this a hit returned the old byte until the write reached the SDRAM, up to ~14 clocks).
    function [15:0] pw_merge; input [15:0] w; input [17:0] tag;
        pw_merge = (pw && pw_addr[18:1] == tag) ? (pw_addr[0] ? {pw_data, w[7:0]} : {w[15:8], pw_data}) : w;
    endfunction

    // ---------------- current access
    reg        acc_wr = 1'b0;
    reg        acc_hint = 1'b0, acc_hidx = 1'b0;
    reg [17:0] acc_wa = 18'd0;
    reg [7:0]  acc_data = 8'd0;
    reg        acc_odd = 1'b0;
    (* IOB = "TRUE" *) reg [15:0] dq_out = 16'd0;
    (* IOB = "TRUE" *) reg        dq_oe = 1'b0;
    // the data pins are also sampled by a flip-flop in the IOB every clock (nothing between the pad and its D input)
    (* IOB = "TRUE" *) reg [15:0] dq_iob = 16'd0;
    always @(posedge clk) dq_iob <= sd_dq;
    wire [15:0] cap_word = cap_late ? dq_iob : sd_dq;
    wire        acc_last = cap_late ? (step == 3'd7) : (step == 3'd6);
    // rdata is a register (the consumers are clk16 registers of the core, e.g. the audio DMA: a path from the address comparison into them is longer than
    // one tick).  When a read of the CURRENT word completes, the word goes into it straight from the pins, on the same tick as into rd_word: the read
    // latency does not grow.  Otherwise it follows the cached word of the current address one tick later (a hit; the consumers take the data many ticks later).
    reg  [7:0]  rdata_q = 8'd0;
    wire        rd_done_now = (state == ST_ACC) && (step >= 3'd4) && acc_last && !acc_wr;
    wire [15:0] next_word = (rd_done_now && acc_wa == wa) ? pw_merge(cap_word, acc_wa) : hit_word;
    reg         valid_q = 1'b0;
    always @(posedge clk) begin
        rdata_q <= addr[0] ? next_word[15:8] : next_word[7:0];
        valid_q <= (rd_done_now && acc_wa == wa) || !need_read;
    end
    assign rdata = rdata_q;
    // rd_valid goes with rdata_q: valid for the address of the previous tick, and only while the address has not changed since
    assign rd_valid = valid_q && (addr == addr_q);
    assign sd_dq = dq_oe ? dq_out : 16'bzzzzzzzzzzzzzzzz;

    task cmd; input [2:0] c; begin {sd_ras_n, sd_cas_n, sd_we_n} <= c; end endtask

    always @(posedge clk) begin
        cmd(CMD_NOP);
        dq_oe <= 1'b0;

        // refresh debt
        if (ref_cnt == REF_PERIOD - 1) begin ref_cnt <= 10'd0; if (ref_debt != 4'd8) ref_debt <= ref_debt + 4'd1; end
        else ref_cnt <= ref_cnt + 10'd1;

        // a pending write patches the cached copies of its word (the assignments below that replace a whole word merge it as well)
        if (pw) begin rd_word <= pw_merge(rd_word, rd_wa); e0_word <= pw_merge(e0_word, e0_cwa); e1_word <= pw_merge(e1_word, e1_cwa); end
        // a request served from the read-ahead word is promoted to the current word (the hint word is overwritten by the next read-ahead)
        // (from the REGISTERED address: the bus address comes through long decoders and the promotion is not urgent - the read data path uses the slots directly)
        if (hitq_hint && !hitq_rd) begin rd_word <= pw_merge(hitq_e0 ? e0_word : e1_word, hitq_e0 ? e0_cwa : e1_cwa); rd_wa <= hitq_e0 ? e0_cwa : e1_cwa; rd_ok <= 1'b1; end

        // write capture
        if (!act) wdone <= 1'b0;
        if (act && !wdone) begin pw <= 1'b1; pw_addr <= addr; pw_data <= wdata; end

        if (reset) begin
            state <= ST_INIT; init_step <= 4'd0; wait_cnt <= 16'd0; sd_dqm <= 2'b11; rd_ok <= 1'b0; e0_ok <= 1'b0; e1_ok <= 1'b0; ref_debt <= 4'd0;
        end
        else case (state)
        ST_INIT: begin
            wait_cnt <= wait_cnt + 16'd1;
            if ((init_step == 4'd0 && wait_cnt == INIT_WAIT) || (init_step != 4'd0 && wait_cnt[2:0] == 3'd7)) begin
                wait_cnt <= 16'd0;
                init_step <= init_step + 4'd1;
                case (init_step)
                    4'd0: begin cmd(CMD_PRECHARGE); sd_a <= 13'b0_0100_0000_0000; end      // all banks
                    4'd1, 4'd2: cmd(CMD_REFRESH);
                    4'd3: begin cmd(CMD_MODE); sd_ba <= 2'b00; sd_a <= MODE; end
                    default: begin ref_debt <= 4'd0; state <= ST_IDLE; end
                endcase
            end
        end

        ST_IDLE: begin
            if (pw || need_read_q || (ref_debt != 4'd0) || (want_hint_r && hint_ok)) begin
                if (pw) begin                                           // 1) write
                    cmd(CMD_ACTIVE);
                    sd_ba <= pw_addr[11:10];
                    sd_a <= {6'b000000, pw_addr[18:12]};                // row = addr[18:12] (7 bits), the rest 0
                    acc_wr <= 1'b1; acc_hint <= 1'b0; acc_wa <= pw_addr[18:1]; acc_data <= pw_data; acc_odd <= pw_addr[0];
                    pw <= 1'b0; wdone <= act;
                    step <= 3'd1; state <= ST_ACC;
                end
                else if (ref_debt >= 4'd7 || (ref_debt != 4'd0 && !need_read_q && !block_refresh)) begin   // 3) refresh (forced or idle)
                    cmd(CMD_REFRESH);
                    ref_debt <= ref_debt - 4'd1;
                    step <= 3'd1; state <= ST_REF;
                end
                else if (need_read_q) begin                             // 2) read of the current word (registered address)
                    cmd(CMD_ACTIVE);
                    sd_ba <= wa_q[10:9]; sd_a <= {6'b000000, wa_q[17:11]};
                    acc_wr <= 1'b0; acc_hint <= 1'b0; acc_wa <= wa_q;
                    step <= 3'd1; state <= ST_ACC;
                end
                else if (want_hint_r && hint_ok) begin                  // 4) read ahead (nothing else to do)
                    cmd(CMD_ACTIVE);
                    sd_ba <= hint_target_q[10:9]; sd_a <= {6'b000000, hint_target_q[17:11]};
                    acc_wr <= 1'b0; acc_hint <= 1'b1; acc_hidx <= hint_victim_q; acc_wa <= hint_target_q;
                    step <= 3'd1; state <= ST_ACC;
                end
            end
        end

        ST_ACC: begin
            step <= step + 3'd1;
            case (step)
                3'd1: ;
                3'd2: begin
                    cmd(acc_wr ? CMD_WRITE : CMD_READ);
                    sd_a <= {4'b0010, acc_wa[8:0]};                    // A10 = auto precharge, column
                    sd_dqm <= acc_wr ? (acc_odd ? 2'b01 : 2'b10) : 2'b00;
                    dq_out <= {acc_data, acc_data};
                    dq_oe <= acc_wr;
                end
                3'd3: sd_dqm <= 2'b11;
                default: if (acc_last) begin
`ifdef KG_SDRAM_LOG
                    if (acc_wa[17:8] == 10'h030) $display("SDLOG t=%0t %s wa=%05h data=%04h odd=%b  rd_ok=%b rd_wa=%05h e0=%b/%05h e1=%b/%05h  bus addr=%05h addr_q=%05h",
                        $time, acc_wr ? "WRITE" : acc_hint ? "HINT " : "READ ", acc_wa, acc_wr ? {acc_data, acc_data} : cap_word, acc_odd, rd_ok, rd_wa, e0_ok, e0_cwa, e1_ok, e1_cwa, addr, addr_q);
`endif
                    if (!acc_wr && !acc_hint) begin rd_word <= pw_merge(cap_word, acc_wa); rd_wa <= acc_wa; rd_ok <= 1'b1; end
                    else if (!acc_wr && acc_hint) begin
                        if (acc_hidx == 1'b0) begin e0_word <= pw_merge(cap_word, acc_wa); e0_cwa <= acc_wa; e0_ok <= 1'b1; end
                        else                  begin e1_word <= pw_merge(cap_word, acc_wa); e1_cwa <= acc_wa; e1_ok <= 1'b1; end
                    end
                    else begin                                           // keep all cached words coherent with the write
                        if (rd_ok && rd_wa == acc_wa) begin if (acc_odd) rd_word[15:8] <= acc_data; else rd_word[7:0] <= acc_data; end
                        if (e0_ok && e0_cwa == acc_wa) begin if (acc_odd) e0_word[15:8] <= acc_data; else e0_word[7:0] <= acc_data; end
                        if (e1_ok && e1_cwa == acc_wa) begin if (acc_odd) e1_word[15:8] <= acc_data; else e1_word[7:0] <= acc_data; end
                    end
                    state <= ST_IDLE;
                end
            endcase
        end

        ST_REF: begin
            step <= step + 3'd1;
            if (step == 3'd6) state <= ST_IDLE;
        end
        endcase
    end
endmodule
