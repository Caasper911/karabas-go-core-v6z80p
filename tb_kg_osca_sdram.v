`timescale 1ns / 1ps
// Unit test of kg_osca_sdram against the behavioural SDRAM model: CPU-like and DMA-like traffic with refresh.
module tb_kg_osca_sdram;
    reg clk = 0; always #5.2083 clk = ~clk;                       // 96 MHz
    reg reset = 1;
    reg [18:0] addr = 0; reg [18:0] hint = 0; reg cs_n = 1, wr_n = 1; reg [7:0] wdata = 0; reg block_refresh = 0;
    wire [7:0] rdata; wire rd_valid, wr_pending, init_done;
    wire [1:0] ba, dqm; wire [12:0] sa; wire ras_n, cas_n, we_n; wire [15:0] dq;
    kg_osca_sdram #(.INIT_WAIT(16'd200)) dut (.clk(clk), .reset(reset), .addr(addr), .cs_n(cs_n), .wr_n(wr_n), .wdata(wdata),
        .cap_late(1'b0), .block_refresh(block_refresh), .hint_addr(hint), .rdata(rdata), .rd_valid(rd_valid), .wr_pending(wr_pending), .init_done(init_done),
        .sd_ba(ba), .sd_a(sa), .sd_dqm(dqm), .sd_ras_n(ras_n), .sd_cas_n(cas_n), .sd_we_n(we_n), .sd_dq(dq));
    tb_sdram_model sdram (.clk(clk), .ba(ba), .a(sa), .dqm(dqm), .ras_n(ras_n), .cas_n(cas_n), .we_n(we_n), .dq(dq));

    reg [7:0] ref_mem [0:524287];
    integer seed = 12345, i, n, errs = 0, reads = 0, lat, maxlat_cpu = 0, maxlat_dma = 0, over9 = 0, over11 = 0, tick = 0;
    always @(posedge clk) tick <= tick + 1;
    initial for (i = 0; i < 524288; i = i + 1) ref_mem[i] = 8'h00;

    task wait_ticks(input integer k); begin repeat (k) @(posedge clk); end endtask
    // OPLOG: every operation that touches the word of the failing address
    task oplog(input [255:0] what, input [18:0] ad, input [7:0] dt); begin if (ad[18:1] == 18'h874D) $display("  OP t=%0d %0s addr=%05h data=%02h rd_valid=%b", tick, what, ad, dt, rd_valid); end endtask
    task do_write(input [18:0] ad, input [7:0] dt); begin
        @(posedge clk); #1; addr = ad; wdata = dt; cs_n = 0; wr_n = 0; ref_mem[ad] = dt; oplog("WRITE", ad, dt); if ($time > 55000 && $time < 62000) $display("  TBW t=%0t addr=%05h data=%02h", $time, ad, dt); ring_add(1, ad, dt);
        wait_ticks(6); #1; wr_n = 1; cs_n = 1;
    end endtask
    // read: change the address, count ticks until rd_valid, compare
    task do_read(input [18:0] ad, input integer is_dma); integer t0; begin
        @(posedge clk); #1; addr = ad; cs_n = 0; t0 = tick;
        @(posedge clk);
        while (!rd_valid) @(posedge clk);
        lat = tick - t0; reads = reads + 1; oplog("READ ", ad, rdata); ring_add(0, ad, rdata);
        if (rdata !== ref_mem[ad]) begin errs = errs + 1; if (errs < 3) begin $display("MISMATCH addr %05h got %02h exp %02h  | dut rd_wa=%0h rd_word=%04h rd_ok=%b", ad, rdata, ref_mem[ad], dut.rd_wa, dut.rd_word, dut.rd_ok); ring_dump; end end
        if (is_dma) begin if (lat > maxlat_dma) maxlat_dma = lat; if (lat > 11) over11 = over11 + 1; end
        else begin if (lat > maxlat_cpu) maxlat_cpu = lat; if (lat > 9) over9 = over9 + 1; end
    end endtask

    // RING: last operations
    reg [18:0] ring_a [0:7]; reg [7:0] ring_d [0:7]; reg ring_w [0:7]; integer ring_i = 0;
    task ring_add(input w, input [18:0] ad, input [7:0] dt); begin ring_a[ring_i%8]=ad; ring_d[ring_i%8]=dt; ring_w[ring_i%8]=w; ring_i = ring_i + 1; end endtask
    task ring_dump; integer k; begin for (k = ring_i-8; k < ring_i; k = k + 1) if (k >= 0) $display("   ring: %s addr=%05h word=%0h data=%02h", ring_w[k%8] ? "W" : "R", ring_a[k%8], ring_a[k%8][18:1], ring_d[k%8]); end endtask
    // CMDLOG
    always @(posedge clk) if ($time > 59900 && $time < 60250 && {ras_n,cas_n,we_n} != 3'b111) $display("  CMD t=%0t cmd=%b ba=%0d a=%04h dqm=%b | dut state=%0d pw=%b pw_addr=%05h acc_wa=%05h addr=%05h", $time, {ras_n,cas_n,we_n}, ba, sa, dqm, dut.state, dut.pw, dut.pw_addr, dut.acc_wa, addr);
    reg [18:0] ad;
    initial begin
        #200 reset = 0;
        wait (init_done);
        wait_ticks(20);
        // ---- CPU-like traffic: random reads and writes with 12..40 tick gaps (block_refresh = 0)
        for (n = 0; n < 3000; n = n + 1) begin
            ad = {$random(seed)} % 4096 + (({$random(seed)} % 3) * 19'h10000);      // some locality, three regions
            if ({$random(seed)} % 3 == 0) do_write(ad, $random(seed)); else do_read(ad, 0);
            wait_ticks(12 + {$random(seed)} % 28);
        end
        $display("CPU-like: %0d reads, mismatches=%0d, max latency=%0d ticks, reads above 9 ticks=%0d (WAIT_n would be needed)", reads, errs, maxlat_cpu, over9);
        // ---- DMA-like: sequential reads every 12 ticks inside windows with refresh blocked; windows separated by idle time
        reads = 0;
        for (n = 0; n < 40; n = n + 1) begin
            block_refresh = 1;
            for (i = 0; i < 60; i = i + 1) begin do_read(19'h6000 + n * 64 + i, 1); wait_ticks(11); end
            block_refresh = 0;
            wait_ticks(2000);
        end
        $display("DMA-like: %0d reads, mismatches=%0d, max latency=%0d ticks, reads above 11 ticks=%0d", reads, errs, maxlat_dma, over11);
        // ---- HINT-STREAM: line-copper-like sequential reads (a word = 2 bytes, 12 ticks apart); the PC and the request move together,
        //      the read-ahead hint is PC + 2
        for (i = 0; i < 600; i = i + 1) begin do_write(19'h6400 + i, $random(seed)); wait_ticks(12); end
        wait_ticks(100);
        begin : hs
            integer w, slow, mx, e0; slow = 0; mx = 0; e0 = errs;
            block_refresh = 1; hint = 19'h6400; wait_ticks(200);
            for (w = 0; w < 300; w = w + 1) begin
                hint = 19'h6400 + 2*w;                                  // PC = 2w   (changes together with the address)
                do_read(19'h6400 + 2*w, 1);     if (lat > mx) mx = lat; if (lat > 1) slow = slow + 1;
                wait_ticks(11);
                hint = 19'h6400 + 2*w + 1;                              // PC = 2w+1
                do_read(19'h6400 + 2*w + 1, 1); if (lat > mx) mx = lat; if (lat > 1) slow = slow + 1;
                wait_ticks(11);
            end
            block_refresh = 0;
            $display("HINT-STREAM: 600 sequential reads, mismatches=%0d, max latency=%0d ticks, reads slower than 1 tick=%0d", errs - e0, mx, slow);
        end
        sdram.report;
        if (errs == 0 && sdram.viol == 0 && over11 == 0) $display("PASS"); else $display("FAIL");
        $finish;
    end
    initial begin #400000000; $display("TIMEOUT"); $finish; end
endmodule
