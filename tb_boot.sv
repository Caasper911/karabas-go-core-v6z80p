`timescale 1ns / 1ps
// Full boot test (Verilator --binary --timing): stage-1 ROM -> PIC/EEPROM emulation -> bootcode -> FLOS.
// Plain functional SRAM model (the pad timing is covered by tb_kg_osca_mem).
module tb_boot;
    parameter real SIM_MS = 3000.0;
    parameter integer SHOT_MS = 1400;
    parameter integer KEY_MS = 1000;

    reg clk_mem = 0;
    always #5.208333 clk_mem = ~clk_mem;
    wire clk16;
    wire [20:0] ma; wire [15:0] md_o; wire md_oe; wire [15:0] md_i; wire [1:0] mwr_n, mrd_n;
    wire kb_clk_pull, kb_dat_pull, kb_clk_line, kb_dat_line;
    wire horizontal_sync, tv_sync, audio_left, audio_right;
    wire col_red_a, col_red_b, col_red_c, col_red_d, col_green_a, col_green_b, col_green_c, col_green_d, col_blue_a, col_blue_b, col_blue_c, col_blue_d;
    wire sys_reset;
    wire exp_a, exp_b;
    wire [1:0] sd_ba, sd_dqm; wire [12:0] sd_a; wire sd_ras_n, sd_cas_n, sd_we_n; wire [15:0] sd_dq; wire sd_init; reg sd_rst = 1'b1;
    initial begin repeat (20) @(posedge clk_mem); sd_rst = 1'b0; end

    // ---------------- MCU ROM loader emulation: writes the RAM image (file offset = Z80 address) while the core is in reset
    parameter IMG_BYTES = 20142;
    reg [7:0] img [0:IMG_BYTES-1];
    // +simms=N ends the run after N ms of simulated time (default: the SIM_MS parameter)
    real sim_ms_eff; integer simms_i;
    initial begin sim_ms_eff = SIM_MS; if ($value$plusargs("simms=%d", simms_i)) sim_ms_eff = simms_i; end
    reg ld_active = 1'b1; reg [31:0] ld_addr = 32'h0; reg [7:0] ld_data = 8'h00; reg ld_wr = 1'b0;
    integer li;
    initial begin
        $readmemh("ram_image.hex", img);
        wait (sd_init);
        repeat (50) @(posedge clk_mem);
        for (li = 0; li < IMG_BYTES; li = li + 1) begin
            @(posedge clk_mem); ld_addr <= li; ld_data <= img[li]; ld_wr <= 1'b1;
            @(posedge clk_mem); ld_wr <= 1'b0;
            repeat (14) @(posedge clk_mem);
        end
        repeat (50) @(posedge clk_mem);
        ld_active <= 1'b0;
        $display("%0t ms: ROM loader finished (%0d bytes), core released", $time/1000000, IMG_BYTES);
    end

    kg_osca_soc dut (
        .clk_mem(clk_mem), .clk16_gen(clk16), .clk16(clk16),
        .ma(ma), .md_o(md_o), .md_oe(md_oe), .md_i(md_i), .mwr_n(mwr_n), .mrd_n(mrd_n),
        .horizontal_sync(horizontal_sync), .tv_sync(tv_sync),
        .col_red_a(col_red_a), .col_red_b(col_red_b), .col_red_c(col_red_c), .col_red_d(col_red_d),
        .col_green_a(col_green_a), .col_green_b(col_green_b), .col_green_c(col_green_c), .col_green_d(col_green_d),
        .col_blue_a(col_blue_a), .col_blue_b(col_blue_b), .col_blue_c(col_blue_c), .col_blue_d(col_blue_d), .audio_left(audio_left), .audio_right(audio_right),
        .ps2_kb_clock_in(kb_clk_line), .ps2_kb_data_in(kb_dat_line), .ps2_ms_clock_in(1'b1), .ps2_ms_data_in(1'b1),
        .ps2_kb_clock_out(kb_clk_pull), .ps2_kb_data_out(kb_dat_pull),
        .sdc_dout(1'b1), .serial_rx_pin(1'b1), .joystick_data_in(1'b1),
        .ld_active(ld_active), .ld_addr(ld_addr), .ld_data(ld_data), .ld_wr(ld_wr),
        .sdram_reset(sd_rst), .sdram_cap_late(1'b0), .sdram_init_done(sd_init), .sd_ba(sd_ba), .sd_a(sd_a), .sd_dqm(sd_dqm), .sd_ras_n(sd_ras_n), .sd_cas_n(sd_cas_n), .sd_we_n(sd_we_n), .sd_dq(sd_dq),
        .jumper_nmi(1'b1), .jumper_reset(~ld_active), .jumper_vga(1'b0),
        .expansion_pin_a(exp_a), .expansion_pin_b(exp_b), .system_reset_out(sys_reset));

    reg [7:0] kb_byte = 8'h00; reg kb_stb = 1'b0;
    tb_sdram_model sdr (.clk(clk_mem), .ba(sd_ba), .a(sd_a), .dqm(sd_dqm), .ras_n(sd_ras_n), .cas_n(sd_cas_n), .we_n(sd_we_n), .dq(sd_dq));

    kg_osca_ps2dev kbd (.clk(clk16), .scan_in(kb_byte), .scan_stb(kb_stb), .host_clk_pull(kb_clk_pull),
                        .host_data_pull(kb_dat_pull), .clk_line(kb_clk_line), .data_line(kb_dat_line));

    // ---------------- functional SRAM (low-byte chip)
    reg [7:0] mem0 [0:2097151];
    wire [7:0] sram_do = mem0[ma];
    assign md_i = md_oe ? md_o : {8'hFF, (!mrd_n[0] && mwr_n[0]) ? sram_do : 8'hFF};
    always @(posedge mwr_n[0]) mem0[ma] <= md_o[7:0];
    integer i;
    initial for (i = 0; i < 2097152; i = i + 1) mem0[i] = 8'h00;

    integer ms = 0;
    // ---------------- observers
    reg m1_prev = 1;
    reg [15:0] pcs;
    reg [63:0] page_seen [0:0];
    reg [255:0] seen = 256'b0;         // 256-byte pages of the Z80 address space fetched from
    integer fetches = 0;
    time t_first_bc = 0, t_first_flos = 0;
    reg [15:0] last_pc = 0;
    always @(posedge clk16) begin
        if (!dut.m1_n && !dut.rd_n_bus && !dut.mreq_n_bus && m1_prev) begin
            fetches = fetches + 1;
            pcs = dut.a_bus;
            if (!seen[pcs[15:8]]) begin
                seen[pcs[15:8]] = 1'b1;
                $display("%0t ms: first opcode fetch in page %02hxxx  (PC=%04h, fetch #%0d)", $time/1000000, pcs[15:8], pcs, fetches);
            end
            last_pc = pcs;
        end
        m1_prev <= dut.m1_n | dut.rd_n_bus | dut.mreq_n_bus;
    end

    function integer flos_pages(); integer p, n; begin n = 0; for (p = 16; p < 79; p = p + 1) if (seen[p]) n = n + 1; flos_pages = n; end endfunction

    // text in video RAM (SRAM 0x000000..0x07FFFF): printable runs, tile code = ASCII + delta, stride 1 or 2 bytes
    task dump_text; integer a, k, run, stride, delta, shown, nz; reg [8:0] c; begin
        nz = 0; for (a = 0; a < 524288; a = a + 1) if (mem0[a] != 8'h00) nz = nz + 1;
        $display("video RAM: %0d non-zero bytes of 524288", nz);
        for (delta = 0; delta <= 32; delta = delta + 32)
        for (stride = 1; stride <= 2; stride = stride + 1) begin
            shown = 0; run = 0;
            for (a = 0; a < 524288 && shown < 8; a = a + stride) begin
                c = {1'b0, mem0[a]} + delta;
                if (c >= 9'h20 && c < 9'h7f && mem0[a] != 8'h00 + 8'd0 - 8'd0) run = run + 1;
                else begin
                    if (run >= 6) begin
                        $write("text(delta %0d, stride %0d) @%05h: '", delta, stride, a - run*stride);
                        for (k = run; k > 0; k = k - 1) $write("%c", mem0[a - k*stride] + delta[7:0]);
                        $write("'\n"); shown = shown + 1;
                    end
                    run = 0;
                end
            end
        end
    end endtask


    // ---------------- "screenshot": one frame of the video output (a..d = 4 bits of each colour, a = MSB)
    reg [11:0] fb [0:1024*700-1];
    reg hs_q = 1, vs_q = 1; integer gx = 0, gy = 0, linelen = 0, frames = 0, f;
    wire [11:0] pix = {col_red_a, col_red_b, col_red_c, col_red_d, col_green_a, col_green_b, col_green_c, col_green_d,
                       col_blue_a, col_blue_b, col_blue_c, col_blue_d};
    integer nonblack = 0, shotn = 0, yellow = 0; reg want_shot = 1'b0;
    integer sx, sy;
    always @(posedge clk16) begin
        hs_q <= horizontal_sync; vs_q <= tv_sync;
        if (gx < 1024 && gy < 700) fb[gy*1024 + gx] <= pix;
        gx = gx + 1;
        if (hs_q && !horizontal_sync) begin linelen = gx; gx = 0; gy = gy + 1; end
        if (vs_q && !tv_sync) begin
            frames = frames + 1;
            if (want_shot && gy > 100) begin
                nonblack = 0; yellow = 0;
                f = $fopen($sformatf("frame_%0d.ppm", shotn), "w");
                $fwrite(f, "P3\n%0d %0d\n255\n", linelen, gy);
                for (sy = 0; sy < gy; sy = sy + 1) begin
                    for (sx = 0; sx < linelen; sx = sx + 1) begin
                        if (fb[sy*1024+sx] != 12'h000) nonblack = nonblack + 1;
                        if (fb[sy*1024+sx] == 12'hFF0) yellow = yellow + 1;
                        $fwrite(f, "%0d %0d %0d ", fb[sy*1024+sx][11:8]*17, fb[sy*1024+sx][7:4]*17, fb[sy*1024+sx][3:0]*17);
                    end
                    $fwrite(f, "\n");
                end
                $fclose(f);
                $display("SCREENSHOT frame_%0d.ppm at PC=%04h: %0dx%0d, %0d non-black pixels, YELLOW(text) pixels=%0d", shotn, last_pc, linelen, gy, nonblack, yellow); shotn = shotn + 1;
                want_shot = 1'b0;
            end
            gy = 0;
        end
    end


    // ---------------- debug of the video timing the OS waits for
    integer vrt_edges = 0, sl_tc = 0, vs_edges = 0, hs_edges = 0; reg vrt_q = 0, sltc_q = 0, vs_q2 = 0, hs_q2 = 0;
    always @(posedge clk16) begin
        vrt_q <= dut.core.vrt_line; sltc_q <= dut.core.scanline_tc; vs_q2 <= tv_sync; hs_q2 <= horizontal_sync;
        if (vrt_q != dut.core.vrt_line) vrt_edges = vrt_edges + 1;
        if (!sltc_q && dut.core.scanline_tc) sl_tc = sl_tc + 1;
        if (vs_q2 != tv_sync) vs_edges = vs_edges + 1;
        if (hs_q2 != horizontal_sync) hs_edges = hs_edges + 1;
    end


    // ---------------- PC histogram between HIST_A and HIST_B ms
    integer hist [0:65535]; integer hi, hms = 0;
    initial for (hi = 0; hi < 65536; hi = hi + 1) hist[hi] = 0;
    always @(posedge clk16) if (ms >= 1500 && ms < 1600 && !dut.m1_n && !dut.rd_n_bus && !dut.mreq_n_bus && m1_prev) hist[dut.a_bus] = hist[dut.a_bus] + 1;
    task dump_hist; integer p, shown; begin
        shown = 0;
        for (p = 0; p < 65536 && shown < 120; p = p + 1) if (hist[p] > 0) begin
            $display("HIST %04h %0d", p, hist[p]); shown = shown + 1; end
    end endtask


    // ---------------- when inside the 16 MHz cycle do the logical memory addresses change? (tick = dut.mem.tick)
    integer vch [0:5]; integer sch [0:5]; integer ych [0:5]; integer pi;
    initial for (pi = 0; pi < 6; pi = pi + 1) begin vch[pi] = 0; sch[pi] = 0; ych[pi] = 0; end
    reg [18:0] va_q = 0; reg [16:0] sa_q = 0; reg [18:0] ya_q = 0;
    wire [18:0] ya_now = {dut.system_ram_a18, dut.system_ram_a17, dut.system_ram_a16, dut.system_ram_a15, dut.system_ram_a14, dut.a_bus[13:0]};
    always @(posedge clk_mem) if (ms >= 5) begin
        va_q <= dut.vram_addr_out; sa_q <= dut.spr_addrbus; ya_q <= ya_now;
        if (va_q != dut.vram_addr_out) vch[dut.mem.tick] = vch[dut.mem.tick] + 1;
        if (sa_q != dut.spr_addrbus)   sch[dut.mem.tick] = sch[dut.mem.tick] + 1;
        if (ya_q != ya_now)            ych[dut.mem.tick] = ych[dut.mem.tick] + 1;
    end
    task dump_probe; begin
        $display("address changes seen at clk_mem edge (tick index, 0 = clk16 rising edge):");
        $display("  vram: %0d %0d %0d %0d %0d %0d", vch[0], vch[1], vch[2], vch[3], vch[4], vch[5]);
        $display("  spr : %0d %0d %0d %0d %0d %0d", sch[0], sch[1], sch[2], sch[3], sch[4], sch[5]);
        $display("  sys : %0d %0d %0d %0d %0d %0d", ych[0], ych[1], ych[2], ych[3], ych[4], ych[5]);
    end endtask


    task dump_vram_map; integer b, a, nz, shown; begin
        $display("VRAM 1KB blocks with data (block address: non-zero bytes):");
        shown = 0;
        for (b = 0; b < 512; b = b + 1) begin
            nz = 0; for (a = 0; a < 1024; a = a + 1) if (mem0[b*1024+a] != 8'h00) nz = nz + 1;
            if (nz > 0 && shown < 40) begin $write("  %05h:%0d", b*1024, nz); shown = shown + 1; end
        end
        $write("\n");
    end endtask
    task hexdump(input integer base, input integer n); integer a; begin
        $write("hex %05h:", base);
        for (a = 0; a < n; a = a + 1) $write(" %02h", mem0[base+a]);
        $write("\n");
    end endtask


    // ---------------- type a key (Enter, PS/2 set 2: 5A make, F0 5A break) at KEY_MS
    task kb_send(input [7:0] b); begin @(posedge clk16); #1; kb_byte = b; kb_stb = 1'b1; @(posedge clk16); #1; kb_stb = 1'b0; end endtask
    initial begin
        wait (ms >= KEY_MS);
        kb_send(8'h5A); kb_send(8'hF0); kb_send(8'h5A);
        $display("ms %0d: Enter sent to the keyboard device", ms);
    end


    // ---------------- is anything drawn into the text bitplane ($18000-$19FFF)?
    integer plane_wr = 0, plane_wr_nonff = 0, any_vram_wr = 0, pl;
    reg vwr_q = 1;
    always @(posedge clk_mem) begin
        vwr_q <= dut.vram_wr;
        if (vwr_q && !dut.vram_wr) begin                       // a logical write cycle starts
            any_vram_wr = any_vram_wr + 1;
            if (dut.vram_addr_out >= 19'h18000 && dut.vram_addr_out < 19'h1A000) begin
                plane_wr = plane_wr + 1;
                if (dut.vram_wdata != 8'hFF) plane_wr_nonff = plane_wr_nonff + 1;
            end
        end
    end
    task plane_report; integer k, nf, first; begin
        nf = 0; first = -1;
        for (k = 0; k < 8192; k = k + 1) if (mem0['h18000 + k] != 8'hFF) begin nf = nf + 1; if (first < 0) first = k; end
        $display("PLANE @ms %0d: %0d of 8192 bytes != FF (first at +%0d); writes into plane so far: %0d (non-FF data: %0d), all vram writes: %0d",
                 ms, nf, first, plane_wr, plane_wr_nonff, any_vram_wr);
    end endtask


    // ---------------- call stack of the idle loop: SP and the 12 words on top of it (system RAM = SRAM 0x080000 + Z80 address)
    task dump_stack; integer k; reg [15:0] w; reg [15:0] sp; begin
        sp = dut.cpu.u_z80.i_tv80_core.SP;
        $display("STACK @ms %0d: SP=%04h  PC=%04h", ms, sp, last_pc);
        $write("  return addresses:");
        for (k = 0; k < 12; k = k + 1) begin
            w = {mem0['h080000 + ((sp + 2*k + 1) & 16'h7FFF)], mem0['h080000 + ((sp + 2*k) & 16'h7FFF)]};
            $write(" %04h", w);
        end
        $write("\n");
    end endtask


    // ---------------- log interesting video RAM writes (not 00 / FF, not the font area)
    integer vlog_n = 0; reg vwr_q2 = 1;
    always @(posedge clk_mem) begin
        vwr_q2 <= dut.vram_wr;
        if (vwr_q2 && !dut.vram_wr && vlog_n < 70 && dut.vram_wdata != 8'h00 && dut.vram_wdata != 8'hFF &&
            !(dut.vram_addr_out >= 19'h1E400 && dut.vram_addr_out < 19'h1F000)) begin
            $display("VW t=%0t addr=%05h data=%02h  (cpu PC~%04h)", $time, dut.vram_addr_out, dut.vram_wdata, last_pc);
            vlog_n = vlog_n + 1;
        end
    end


    // ---------------- blitter activity (FLOS draws every character with the blitter)
    integer bw = 0, br = 0, bpend = 0, bbus = 0, lw = 0; reg bw_q = 1, br_q = 1, bp_q = 0, bb_q = 0, lw_q = 1;
    always @(posedge clk16) begin
        bw_q <= dut.core.blitter_vram_wr; br_q <= dut.core.blitter_vram_read; bp_q <= dut.core.blit_op_pending;
        bb_q <= dut.core.blitter_busmaster; lw_q <= dut.core.linedraw_wr;
        if (bw_q && !dut.core.blitter_vram_wr) bw = bw + 1;
        if (br_q && !dut.core.blitter_vram_read) br = br + 1;
        if (!bp_q && dut.core.blit_op_pending) bpend = bpend + 1;
        if (!bb_q && dut.core.blitter_busmaster) bbus = bbus + 1;
        if (lw_q && !dut.core.linedraw_wr) lw = lw + 1;
    end
    task blit_report; begin
        $display("BLITTER @ms %0d: ops started=%0d  busmaster rises=%0d  blitter vram writes=%0d  reads=%0d  linedraw writes=%0d", ms, bpend, bbus, bw, br, lw);
    end endtask


    // ---------------- how often are key FLOS routines entered?
    integer c15ea = 0, c162a = 0, c16bd = 0, c1b37 = 0, c19e4 = 0, c1831 = 0, c148f = 0, c2f73 = 0; reg m1_q3 = 1;
    time t15ea = 0, t162a = 0;
    always @(posedge clk16) begin
        if (!dut.m1_n && !dut.rd_n_bus && !dut.mreq_n_bus && m1_q3) begin
            case (dut.a_bus)
                16'h15ea: begin c15ea = c15ea + 1; if (t15ea == 0) t15ea = $time; end
                16'h162a: begin c162a = c162a + 1; if (t162a == 0) t162a = $time; end
                16'h16bd: c16bd = c16bd + 1;
                16'h1b37: c1b37 = c1b37 + 1;
                16'h19e4: c19e4 = c19e4 + 1;
                16'h1831: c1831 = c1831 + 1;
                16'h148f: c148f = c148f + 1;
                16'h2f73: c2f73 = c2f73 + 1;
                default: ;
            endcase
        end
        m1_q3 <= dut.m1_n | dut.rd_n_bus | dut.mreq_n_bus;
    end
    task pc_report; begin
        $display("FLOS entries @ms %0d: 1831=%0d 148f=%0d print_string(15ea)=%0d plot_char(162a)=%0d blit_wait(16bd)=%0d 2f73=%0d 1b37=%0d main_loop(19e4)=%0d  first15ea=%0t first162a=%0t",
                 ms, c1831, c148f, c15ea, c162a, c16bd, c2f73, c1b37, c19e4, t15ea, t162a);
    end endtask


    // ---------------- where does the blitter write? (first 36 writes with data not 00/FF after the first text, plus region totals)
    integer bwl = 0; integer reg_cnt [0:63]; integer rc; reg bwq = 1;
    initial for (rc = 0; rc < 64; rc = rc + 1) reg_cnt[rc] = 0;
    always @(posedge clk_mem) begin
        bwq <= dut.core.blitter_vram_wr;
        if (bwq && !dut.core.blitter_vram_wr && !dut.vram_wr) begin     // a blitter write cycle starts
            reg_cnt[dut.vram_addr_out[18:13]] = reg_cnt[dut.vram_addr_out[18:13]] + 1;
            if (t15ea != 0 && bwl < 36 && dut.vram_wdata != 8'h00 && dut.vram_wdata != 8'hFF) begin
                $display("BW addr=%05h data=%02h", dut.vram_addr_out, dut.vram_wdata); bwl = bwl + 1;
            end
        end
    end
    task bw_regions; integer k; begin
        $write("blitter writes per 8KB region (region start: count):");
        for (k = 0; k < 64; k = k + 1) if (reg_cnt[k] > 0) $write("  %05h:%0d", k*8192, reg_cnt[k]);
        $write("\n");
    end endtask


    // ---------------- does the blitter capture the right data?  (wrapper build: mem0 is the physical SRAM model)
    integer rd_chk = 0, rd_bad = 0, rd_shown = 0;
    always @(posedge clk16) begin
        if (dut.core.XLXN_3767 && ms >= 240) begin                // blitter data register captures vram data at this edge
            rd_chk = rd_chk + 1;
            if (dut.vram_rdata !== mem0[{2'b00, 1'b0, dut.vram_addr_out[18:0]} & 21'h07FFFF]) begin
                rd_bad = rd_bad + 1;
                if (rd_shown < 12) begin
                    $display("RDBAD t=%0t addr=%05h got=%02h expected=%02h  tick=%0d", $time, dut.vram_addr_out, dut.vram_rdata,
                             mem0[{2'b00, 1'b0, dut.vram_addr_out[18:0]} & 21'h07FFFF], dut.mem.tick);
                    rd_shown = rd_shown + 1;
                end
            end
        end
    end
    task rd_report; begin $display("BLITTER READ CHECK @ms %0d: %0d captures, %0d wrong", ms, rd_chk, rd_bad); end endtask


    // ---------------- when inside the 16 MHz cycle do the logical write strobes fall / rise?
    integer vf [0:5]; integer vr [0:5]; integer sf [0:5]; integer sr_ [0:5]; integer yf [0:5]; integer yr [0:5]; integer si;
    initial for (si = 0; si < 6; si = si + 1) begin vf[si]=0; vr[si]=0; sf[si]=0; sr_[si]=0; yf[si]=0; yr[si]=0; end
    reg vq = 1, sq = 1, yq = 1;
    wire y_act_n = !( !dut.system_ram_cs && !dut.wr_n_bus );
    always @(posedge clk_mem) if (ms >= 252) begin
        vq <= dut.vram_wr; sq <= dut.spr_ram_wr; yq <= y_act_n;
        if (vq && !dut.vram_wr)   vf[dut.mem.tick] = vf[dut.mem.tick] + 1;
        if (!vq && dut.vram_wr)   vr[dut.mem.tick] = vr[dut.mem.tick] + 1;
        if (sq && !dut.spr_ram_wr) sf[dut.mem.tick] = sf[dut.mem.tick] + 1;
        if (!sq && dut.spr_ram_wr) sr_[dut.mem.tick] = sr_[dut.mem.tick] + 1;
        if (yq && !y_act_n)       yf[dut.mem.tick] = yf[dut.mem.tick] + 1;
        if (!yq && y_act_n)       yr[dut.mem.tick] = yr[dut.mem.tick] + 1;
    end
    task strobe_report; begin
        $display("write strobe edges by tick (0 = clk16 rising edge):");
        $display("  vram fall: %0d %0d %0d %0d %0d %0d   rise: %0d %0d %0d %0d %0d %0d", vf[0],vf[1],vf[2],vf[3],vf[4],vf[5], vr[0],vr[1],vr[2],vr[3],vr[4],vr[5]);
        $display("  spr  fall: %0d %0d %0d %0d %0d %0d   rise: %0d %0d %0d %0d %0d %0d", sf[0],sf[1],sf[2],sf[3],sf[4],sf[5], sr_[0],sr_[1],sr_[2],sr_[3],sr_[4],sr_[5]);
        $display("  sys  fall: %0d %0d %0d %0d %0d %0d   rise: %0d %0d %0d %0d %0d %0d", yf[0],yf[1],yf[2],yf[3],yf[4],yf[5], yr[0],yr[1],yr[2],yr[3],yr[4],yr[5]);
    end endtask


    // ---------------- per 16 MHz cycle: is vram_rd (OE#) low when the wrapper launches (end of tick 0), and does vram_wr go low later?
    integer cm [0:3]; integer ci; reg rd_at_launch = 0; reg wr_in_cycle = 0; reg sys_at_launch = 0;
    integer sys_busy_cycles = 0, cyc_total = 0, spr_active_cycles = 0; reg spr_act = 0;
    initial for (ci = 0; ci < 4; ci = ci + 1) cm[ci] = 0;
    always @(posedge clk_mem) if (ms >= 252) begin
        if (dut.mem.tick == 0) rd_at_launch <= !dut.vram_rd;            // value the launch edge of tick 1 will see
        if (dut.mem.tick >= 3 && !dut.vram_wr) wr_in_cycle <= 1;
        if (dut.mem.tick == 5) begin                                    // end of the cycle: classify
            cm[{rd_at_launch, wr_in_cycle}] = cm[{rd_at_launch, wr_in_cycle}] + 1;
            wr_in_cycle <= 0; cyc_total = cyc_total + 1;
        end
    end
    task rdwr_report; begin
        $display("cycles by (vram_rd low at launch, vram_wr low in 2nd half): rd=0,wr=0:%0d  rd=0,wr=1:%0d  rd=1,wr=0:%0d  rd=1,wr=1:%0d  (total %0d)", cm[0], cm[1], cm[2], cm[3], cyc_total);
    end endtask


    // ---------------- per-tick trace of the wrapper around the first wrong blitter capture
    always @(posedge clk_mem) if ($time >= 249625700 && $time <= 249626050)
        $display("TR t=%0t tick=%0d a=%05h rdata=%02h | ma=%06h md_i=%02h mrd=%b mwr=%b oe=%b | vram_wr=%b act_ce=%b pend=%b | CE=%b",
                 $time, dut.mem.tick, dut.vram_addr_out, dut.vram_rdata, dut.ma, dut.md_i[7:0], dut.mrd_n[0], dut.mwr_n[0], dut.md_oe,
                 dut.vram_wr, dut.core.XLXN_3767, 1'b0, dut.core.XLXN_3767);


    // ---------------- SPRDIAG: is the sprite path alive?
    integer spw = 0, sprpix = 0, cpuwr_spr = 0, cpuwr_pal = 0, cpuwr_vreg = 0; reg spq = 1, cwq = 1;
    always @(posedge clk_mem) begin
        spq <= dut.spr_ram_wr; cwq <= dut.core.cpu_write;
        if (spq && !dut.spr_ram_wr) spw = spw + 1;
        if (cwq && !dut.core.cpu_write && !dut.core.cpu_mreq) begin
            if (dut.a_bus >= 16'h0400 && dut.a_bus < 16'h0600) cpuwr_spr = cpuwr_spr + 1;
            if (dut.a_bus < 16'h0200) cpuwr_pal = cpuwr_pal + 1;
            if (dut.a_bus >= 16'h0200 && dut.a_bus < 16'h0400) cpuwr_vreg = cpuwr_vreg + 1;
        end
    end
    always @(posedge clk16) if (dut.core.sprite_pixel != 8'h00) sprpix = sprpix + 1;
    task spr_diag; begin
        $display("SPRDIAG @ms %0d: spr_ram_wr pulses=%0d  CPU writes: sprite regs=%0d palette=%0d vregs=%0d  sprite_enable=%b  nonzero sprite_pixel cycles=%0d",
                 ms, spw, cpuwr_spr, cpuwr_pal, cpuwr_vreg, dut.core.sprite_enable, sprpix);
    end endtask


    // ---------------- SPRDIAG2: line-start conditions of the sprite engine
    integer cdo = 0, ywin_cyc = 0, busy_rise = 0, start_pulses = 0; reg cdq = 0, bq = 0, sq3 = 0;
    always @(posedge clk16) begin
        cdq <= dut.core.commence_dma_ops; bq <= dut.core.sprite_system_busy; sq3 <= dut.core.XLXN_3233;
        if (!cdq && dut.core.commence_dma_ops) cdo = cdo + 1;
        if (dut.core.ywindow) ywin_cyc = ywin_cyc + 1;
        if (!bq && dut.core.sprite_system_busy) busy_rise = busy_rise + 1;
        if (!sq3 && dut.core.XLXN_3233) start_pulses = start_pulses + 1;
    end
    task spr_diag2; begin
        $display("SPRDIAG2 @ms %0d: y_window_pos=%02h video_enable=%b ywindow_cycles=%0d commence_dma_ops=%0d sprite_busy_rises=%0d sprite_start_pulses=%0d line_count=%0d",
                 ms, dut.core.y_window_pos, dut.core.video_enable, ywin_cyc, cdo, busy_rise, start_pulses, dut.core.line_count);
    end endtask


    // ---------------- SPRMEM: contents of the sprite RAM (ideal model) and of the sprite register RAM
    task spr_mem_dump; integer k; begin
`ifdef IDEAL_MEM
        $write("SPRMEM sprite RAM [0..15]:");   for (k = 0; k < 16; k = k + 1) $write(" %02h", dut.mem.smem[k]); $write("\n");
        $write("SPRMEM sprite RAM [256..271]:");for (k = 256; k < 272; k = k + 1) $write(" %02h", dut.mem.smem[k]); $write("\n");
`endif
        $write("SPRMEM sprite regs [0..31]:");  for (k = 0; k < 32; k = k + 1) $write(" %02h", dut.core.XLXI_2849.sprite_control_reg_ram.mem[k]); $write("\n");
    end endtask


    // ---------------- SPRWR: look at CPU writes to the sprite registers at the moment the RAM clock (cpu_write) rises
    integer sw_n = 0;
    always @(posedge dut.core.cpu_write) if (ms >= 3 && dut.a_bus >= 16'h0400 && dut.a_bus < 16'h0410 && dut.d_bus != 8'h00 && sw_n < 12) begin
        $display("SPRWR t=%0t addr=%04h d_bus=%02h databus_in=%02h  ENA(cpu_sprite_reg_sel)=%b  reg_addr_in=%03h  mem[addr]=%02h",
                 $time, dut.a_bus, dut.d_bus, dut.core.cpu_databus_in, dut.core.XLXI_2849.cpu_sprite_reg_sel, dut.core.XLXI_2849.spr_reg_addr_in,
                 dut.core.XLXI_2849.sprite_control_reg_ram.mem[dut.a_bus[8:0]]);
        sw_n = sw_n + 1;
    end


    // ---------------- AUDHASH: checksum of the core's audio output over a window (compare runs with different +sysdy)
    reg [31:0] ah = 32'd0; integer a_ones = 0, a_cnt = 0;
    always @(posedge clk16) if (ms >= 20 && ms < 120) begin
        ah = ah * 32'd31 + {30'd0, audio_right, audio_left} + 32'd1;
        a_ones = a_ones + audio_left + audio_right; a_cnt = a_cnt + 1;
    end
    task aud_report; begin $display("AUDHASH %08h  ones=%0d  cycles=%0d", ah, a_ones, a_cnt); end endtask


    // ---------------- DMALOG: bus cycles owned by the FPGA (audio DMA, line copper): address / data
    integer dma_n = 0, dma_total = 0, busack_falls = 0; reg bak_q = 1;
    always @(posedge clk16) begin
        bak_q <= dut.busak_n;
        if (bak_q && !dut.busak_n) busack_falls = busack_falls + 1;
        if (!dut.busak_n && !dut.rd_n_bus && !dut.system_ram_cs && ms >= 12) begin
            dma_total = dma_total + 1;
            if (dma_n < 24) begin $display("DMA t=%0t addr=%04h(+bank %0h) data=%02h", $time, dut.a_bus, {dut.system_ram_a18,dut.system_ram_a17,dut.system_ram_a16,dut.system_ram_a15,dut.system_ram_a14}, dut.sys_rdata); dma_n = dma_n + 1; end
        end
    end
    task dma_report; begin $display("DMAREPORT @ms %0d: busack falls=%0d, FPGA-owned read cycles=%0d", ms, busack_falls, dma_total); end endtask


    // ---------------- IOWR: I/O writes of the test program seen at the strobe and at the delayed strobe
    integer iow_n = 0;
    always @(posedge dut.core.cpu_write) if (ms >= 3 && !dut.iorq_n_bus && dut.a_bus[7:0] >= 8'h08 && dut.a_bus[7:0] < 8'h20 && iow_n < 40)
        $display("IOWR strobe   t=%0t a=%04h d=%02h", $time, dut.a_bus, dut.d_bus);
    always @(posedge dut.core.delayed_cpu_wr) if (ms >= 3 && iow_n < 40 && !dut.iorq_n_bus && dut.a_bus[7:0] >= 8'h08 && dut.a_bus[7:0] < 8'h20) begin
        $display("IOWR delayed  t=%0t a=%04h d=%02h iorq_n=%b audio_regs_selected=%b port8=%b", $time, dut.a_bus, dut.d_bus, dut.iorq_n_bus,
                 dut.core.XLXI_3483.audio_regs_selected, dut.core.port_8_selected);
        iow_n = iow_n + 1;
    end


    // ---------------- SNDDIAG: inside the sound system
    integer sd_ss_chg = 0, sd_a_chg = 0, sd_b_chg = 0, sd_nz = 0; reg [7:0] sd_ss_q = 0, sd_a_q = 0, sd_b_q = 0;
    always @(posedge clk16) if (ms >= 15) begin
        sd_ss_q <= dut.core.XLXI_3483.scaled_sample; sd_a_q <= dut.core.XLXI_3483.chan_a; sd_b_q <= dut.core.XLXI_3483.chan_b;
        if (sd_ss_q != dut.core.XLXI_3483.scaled_sample) sd_ss_chg = sd_ss_chg + 1;
        if (sd_a_q != dut.core.XLXI_3483.chan_a) sd_a_chg = sd_a_chg + 1;
        if (sd_b_q != dut.core.XLXI_3483.chan_b) sd_b_chg = sd_b_chg + 1;
        if (dut.core.XLXI_3483.scaled_sample != 8'h00) sd_nz = sd_nz + 1;
    end
    task snd_diag; begin
        $display("SNDDIAG @ms %0d: audio_pan=%02h volume_level=%02h scaled_sample=%02h chan_a=%02h chan_b=%02h | changes: scaled=%0d chan_a=%0d chan_b=%0d  nonzero scaled cycles=%0d",
                 ms, dut.core.XLXI_3483.audio_pan, dut.core.XLXI_3483.volume_level, dut.core.XLXI_3483.scaled_sample,
                 dut.core.XLXI_3483.chan_a, dut.core.XLXI_3483.chan_b, sd_ss_chg, sd_a_chg, sd_b_chg, sd_nz);
    end endtask


    // ---------------- AUDWIN: density of ones of audio_left / audio_right per 640-cycle window (first 12 windows from 40 ms)
    integer aw_cnt = 0, aw_l = 0, aw_r = 0, aw_n = 0, aw_tr = 0; reg aw_q = 0;
    always @(posedge clk16) if (ms >= 40 && aw_n < 12) begin
        aw_l = aw_l + audio_left; aw_r = aw_r + audio_right; aw_cnt = aw_cnt + 1;
        if (audio_left != aw_q) aw_tr = aw_tr + 1; aw_q <= audio_left;
        if (aw_cnt == 640) begin
            $display("AUDWIN %0d: left ones=%0d right ones=%0d left transitions=%0d  chan_a=%02h chan_b=%02h", aw_n, aw_l, aw_r, aw_tr,
                     dut.core.XLXI_3483.chan_a, dut.core.XLXI_3483.chan_b);
            aw_cnt = 0; aw_l = 0; aw_r = 0; aw_tr = 0; aw_n = aw_n + 1;
        end
    end


    // ---------------- DMACHK / DMALAT / WAITCNT: system RAM on the SDRAM seen from the core
    integer dc_chk = 0, dc_err = 0, dl_n = 0, dl_max = 0, dl_over = 0, w_cpu = 0, w_cyc = 0;
    reg [15:0] dc_prev = 16'hFFFF; reg [7:0] dc_exp; reg [8:0] dc_i;
    always @(posedge clk16) begin
        if (!dut.busak_n && !dut.rd_n_bus && !dut.system_ram_cs && ms >= 12 && dut.a_bus >= 16'h6000 && dut.a_bus < 16'h6200) begin
            if (dut.a_bus == dc_prev) begin                       // second cycle of the two-cycle DMA read: the data are taken now
                dc_i = dut.a_bus[8:0];
                dc_exp = dc_i[8] ? (dc_i[7:0] ^ 8'h5A) : (({dc_i[7:0], 2'b00} + dc_i[7:0]) & 8'hFF);
                dc_chk = dc_chk + 1;
                if (dut.sys_rdata !== dc_exp) begin dc_err = dc_err + 1; if (dc_err < 6) $display("DMACHK mismatch addr=%04h got=%02h exp=%02h", dut.a_bus, dut.sys_rdata, dc_exp); end
            end
            dc_prev <= dut.a_bus;
        end else dc_prev <= 16'hFFFF;
        if (ms >= 12) begin w_cyc = w_cyc + 1; if (!dut.sdram_wait_n) w_cpu = w_cpu + 1; end
    end
    // latency from a system RAM address change (FPGA owns the bus) to rd_valid, in clk_mem ticks
    reg [18:0] dl_a = 0; integer dl_t = 0; reg dl_run = 0;
    always @(posedge clk_mem) if (ms >= 12) begin
        dl_a <= dut.sys_addr_m;
        if (!dut.busak_n && dut.sys_addr_m != dl_a && dut.sys_addr_m >= 19'h06000 && dut.sys_addr_m < 19'h06200) begin dl_run <= 1'b1; dl_t <= 1; end
        else if (dl_run) begin
            if (dut.sdram_rd_valid || dut.busak_n) begin dl_run <= 1'b0; dl_n = dl_n + 1; if (dl_t > dl_max) dl_max = dl_t; if (dl_t > 11) dl_over = dl_over + 1; end
            else dl_t <= dl_t + 1;
        end
    end
    task sdram_report; begin
        $display("DMACHK: %0d DMA reads checked against the expected sample, %0d wrong", dc_chk, dc_err);
        $display("DMALAT: %0d DMA address changes, max latency to rd_valid = %0d ticks, above 11 ticks: %0d", dl_n, dl_max, dl_over);
        $display("WAITCNT: CPU WAIT inserted in %0d of %0d clk16 cycles (%0d ppm)", w_cpu, w_cyc, (w_cpu * 1000000) / (w_cyc + 1));
    end endtask


    // ---------------- LCCHK / LCLAT: line copper list reads ($6400..$67FF) done by the FPGA, checked against the loaded image
    integer lc_chk = 0, lc_err = 0, lc_n = 0, lc_max = 0, lc_over = 0, lc_prev_valid = 0;
    reg [15:0] lc_prev = 16'hFFFF;
    always @(posedge clk16) begin
        if (!dut.busak_n && !dut.rd_n_bus && !dut.system_ram_cs && ms >= 12 && dut.a_bus >= 16'h6400 && dut.a_bus < 16'h6800) begin
            if (dut.a_bus == lc_prev) begin
                lc_chk = lc_chk + 1;
                if (dut.sys_rdata !== img[dut.a_bus]) begin lc_err = lc_err + 1; if (lc_err < 6) $display("LCCHK mismatch addr=%04h got=%02h exp=%02h", dut.a_bus, dut.sys_rdata, img[dut.a_bus]); end
            end
            lc_prev <= dut.a_bus;
        end else lc_prev <= 16'hFFFF;
    end
    reg [18:0] lcl_a = 0; integer lcl_t = 0; reg lcl_run = 0;
    always @(posedge clk_mem) if (ms >= 12) begin
        lcl_a <= dut.sys_addr_m;
        if (!dut.busak_n && dut.sys_addr_m != lcl_a && dut.sys_addr_m >= 19'h06400 && dut.sys_addr_m < 19'h06800) begin lcl_run <= 1'b1; lcl_t <= 1; end
        else if (lcl_run) begin
            if (dut.sdram_rd_valid || dut.busak_n) begin lcl_run <= 1'b0; lc_n = lc_n + 1; if (lcl_t > lc_max) lc_max = lcl_t; if (lcl_t > 11) lc_over = lc_over + 1; end
            else lcl_t <= lcl_t + 1;
        end
    end
    task lc_report; begin
        $display("LCCHK: %0d line copper list reads checked, %0d wrong", lc_chk, lc_err);
        $display("LCLAT: %0d list address changes, max latency to rd_valid = %0d ticks, above 11 ticks: %0d", lc_n, lc_max, lc_over);
    end endtask


    // ---------------- LCSEQ: every cycle of the first 60 FPGA-owned reads of the line copper list (address, data on the bus the core sees)
    integer lcs_n = 0;
    always @(posedge clk16) if (!dut.busak_n && !dut.rd_n_bus && !dut.system_ram_cs && ms >= 12 && dut.a_bus >= 16'h6400 && dut.a_bus < 16'h6800 && lcs_n < 80) begin
        $display("LCSEQ t=%0t pc=%04h d_bus=%02h  (cpu_databus_in=%02h) tick-rd_valid=%b", $time, dut.a_bus, dut.d_bus, dut.core.cpu_databus_in, dut.sdram_rd_valid);
        lcs_n = lcs_n + 1;
    end


    // ---------------- CPUVR: CPU reads of the video window ($2000..$21FF): print the ones that differ from the expected pattern
    integer cv_n = 0, cv_cnt = 0;
    reg [7:0] cv_exp;
    always @(posedge clk16) if (ms >= 9 && !dut.rd_n_bus && !dut.mreq_n_bus && dut.m1_n && dut.a_bus >= 16'h2000 && dut.a_bus < 16'h2200) begin
        cv_exp = 8'd1 + 8'd3 * dut.a_bus[7:0];
        cv_cnt = cv_cnt + 1;
        if (dut.d_bus !== cv_exp && cv_n < 14) begin
            $display("CPUVR mismatch #%0d t=%0t a=%04h d_bus=%02h exp=%02h vram_a=%05h rdata=%02h rdata2=%02h", cv_cnt, $time, dut.a_bus, dut.d_bus, cv_exp, dut.vram_addr_out, dut.vram_rdata, dut.vram_rdata2);
            cv_n = cv_n + 1;
        end
    end

    // ---------------- progress / end
    always #1000000 begin
        ms = ms + 1;
        if (ms == 1601) dump_hist();
        if (ms == 35 || ms == 290) dump_probe();
        if (ms == 121) aud_report();
        if (ms == 122) begin sdr.report; sdram_report(); end
        if (ms == 30) $display("REGDUMP D=%02h E=%02h H=%02h L=%02h B=%02h C=%02h (regs 0..2 H/L)", dut.cpu.u_z80.i_tv80_core.i_reg.RegsH[1], dut.cpu.u_z80.i_tv80_core.i_reg.RegsL[1], dut.cpu.u_z80.i_tv80_core.i_reg.RegsH[2], dut.cpu.u_z80.i_tv80_core.i_reg.RegsL[2], dut.cpu.u_z80.i_tv80_core.i_reg.RegsH[0], dut.cpu.u_z80.i_tv80_core.i_reg.RegsL[0]);
        if (ms == 290) begin lc_report(); sdram_report(); end
        if (ms == 30 || ms == 60) snd_diag();
        if (ms == 40 || ms == 121) dma_report();
        if (ms == 100 || ms == 290) begin spr_diag(); spr_diag2(); end
        if (ms == 290) spr_mem_dump();
        if (ms == 10 || ms == 300 || ms == 600 || ms == 950) begin blit_report(); pc_report(); bw_regions(); rd_report(); strobe_report(); rdwr_report(); end
        if (ms == 600 || ms == 950 || ms == 1100) plane_report();
        if (ms == 700 || ms == 950) dump_stack();
        if (ms == 950) begin dump_vram_map(); hexdump('h18000,48); hexdump('h19000,48); hexdump('h19f00,48); hexdump('h1c000,80); hexdump('h1e400,64); hexdump('h1e800,64); hexdump('h1ec00,64); end
        if (ms == 290 || ms == 950) want_shot = 1'b1;
        if (ms % 100 == 0) $display("    video: vrt_line edges=%0d scanline_tc=%0d vsync edges=%0d hsync edges=%0d line_count=%0d", vrt_edges, sl_tc, vs_edges, hs_edges, dut.core.line_count);
        if (ms % 100 == 0) $display("... %0d ms simulated, PC=%04h, reset=%b, fetches=%0d", ms, last_pc, sys_reset, fetches);
        if (ms >= sim_ms_eff) begin
            $display("END at %0d ms, last PC %04h, FLOS-range fetches seen: pages 10..4E = %0d", ms, last_pc, flos_pages());
            sdr.report; sdram_report(); dump_text();
            $finish;
        end
    end
endmodule
