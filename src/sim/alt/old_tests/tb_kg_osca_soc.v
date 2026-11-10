`timescale 1ns / 1ps
// System test: OSCA core + soft Z80 + SRAM wrapper + 10 ns async SRAM model.
// The boot ROM is replaced (defparam) by a test program that fills 32 bytes of system RAM at
// 0xC000, reads them back, and stores 0x55 (ok) / 0xAA (mismatch) at 0xC100, then HALTs.
module tb_kg_osca_soc;
    defparam dut.core.ROM_data_a.INIT_00 = 256'h3e0218553ef9103c230820be013e2006c00021fb103c2377013e2006c00021f3;
    defparam dut.core.ROM_data_a.INIT_01 = 256'h00000000000000000000000000000000000000000000000000000076c10032aa;
    reg clk_mem = 0;
    always #5.208333 clk_mem = ~clk_mem;
    wire clk16;
    wire [20:0] ma; wire [15:0] md_o; wire md_oe; wire [15:0] md_i; wire [1:0] mwr_n, mrd_n;
    wire expansion_pin_a, expansion_pin_b;
    pullup(expansion_pin_a); pullup(expansion_pin_b);
    wire sys_reset;

    kg_osca_soc dut (
        .clk_mem(clk_mem), .clk16_gen(clk16), .clk16(clk16),
        .ma(ma), .md_o(md_o), .md_oe(md_oe), .md_i(md_i), .mwr_n(mwr_n), .mrd_n(mrd_n),
        .ps2_kb_clock_in(1'b1), .ps2_kb_data_in(1'b1), .ps2_ms_clock_in(1'b1), .ps2_ms_data_in(1'b1),
        .sdc_dout(1'b1), .serial_rx_pin(1'b1), .joystick_data_in(1'b0),
        .ld_active(1'b0), .ld_addr(32'h0), .ld_data(8'h00), .ld_wr(1'b0), .jumper_nmi(1'b1), .jumper_reset(1'b1), .jumper_vga(1'b1),
        .expansion_pin_a(expansion_pin_a), .expansion_pin_b(expansion_pin_b),
        .system_reset_out(sys_reset));

    // ---------------- pads + 10 ns async SRAM (low-byte chip), as in tb_kg_osca_mem
    localparam OUT_DLY = 6.0, IN_DLY = 2.5;
    wire [20:0] pad_ma;  assign #(OUT_DLY) pad_ma  = ma;
    wire [15:0] pad_mdo; assign #(OUT_DLY) pad_mdo = md_o;
    wire        pad_oe;  assign #(OUT_DLY) pad_oe  = md_oe;
    wire        pad_we0; assign #(OUT_DLY) pad_we0 = mwr_n[0];
    wire        pad_rd0; assign #(OUT_DLY) pad_rd0 = mrd_n[0];
    wire [15:0] md_bus;  assign md_bus = pad_oe ? pad_mdo : 16'bz;
    reg [7:0] mem0 [0:2097151];
    reg [7:0] do_r = 8'hxx;
    always @(pad_ma) begin do_r <= #2 8'hxx; do_r <= #10 mem0[pad_ma]; end
    assign md_bus[7:0] = (!pad_rd0 && pad_we0) ? do_r : 8'bz;
    assign #(IN_DLY) md_i = md_bus;

    integer phys_err = 0, wr_sys = 0, wr_vram = 0, wr_spr = 0;
    real t_fall = 0; reg [20:0] a_fall = 0;
    always @(negedge pad_we0) begin t_fall = $realtime; a_fall = pad_ma; end
    always @(posedge pad_we0) if (t_fall != 0) begin
        if ($realtime - t_fall < 8.0) begin phys_err = phys_err + 1; $display("PHYS short WE# %0f", $realtime - t_fall); end
        if (pad_ma !== a_fall)        begin phys_err = phys_err + 1; $display("PHYS addr moved under WE#"); end
        if (pad_oe !== 1'b1)          begin phys_err = phys_err + 1; $display("PHYS write without data drive"); end
        mem0[a_fall] = md_bus[7:0];
        if (a_fall[20:19] == 2'b01) wr_sys = wr_sys + 1;
        else if (a_fall[20:19] == 2'b00) wr_vram = wr_vram + 1;
        else wr_spr = wr_spr + 1;
    end

    // ---------------- observers
    integer busreqs = 0, busaks = 0, base = -1, i, k, ok;
    always @(negedge dut.z80_busreq) busreqs = busreqs + 1;
    always @(negedge dut.busak_n)    busaks  = busaks + 1;
    reg halted = 0;
    always @(posedge clk16) if (!dut.cpu.cpu_halt_n) halted <= 1;

    initial begin
        for (i = 0; i < 2097152; i = i + 1) mem0[i] = 8'h00;
        #2000;
        $display("reset line after 2us: system_reset_out=%b", sys_reset);
        wait (halted || $time > 900000);   // ns
        #3000;
        $display("halted=%b at %0t ns, bus requests=%0d, bus acks=%0d", halted, $time, busreqs, busaks);
        // locate the pattern 01..20 in the system-RAM region (0x080000..0x0FFFFF)
        for (k = 21'h080000; k < 21'h100000 && base < 0; k = k + 1) begin
            ok = 1; for (i = 0; i < 32; i = i + 1) if (mem0[k+i] !== i+1) ok = 0;
            if (ok) base = k;
        end
        if (base < 0) begin $display("FAIL: pattern not found in system RAM region"); end
        else begin
            $display("pattern found at SRAM 0x%06h  (Z80 0xC000 -> A18..A14 = %b)", base, base[18:14]);
            $display("flag at 0xC100 = %02h  (55 = read-back ok)", mem0[base + 21'h100]);
            if (mem0[base + 21'h100] == 8'h55 && phys_err == 0) $display("PASS"); else $display("FAIL");
        end
        $display("SRAM writes: sys=%0d vram=%0d spr=%0d, phys errors=%0d", wr_sys, wr_vram, wr_spr, phys_err);
        $finish;
    end
endmodule
