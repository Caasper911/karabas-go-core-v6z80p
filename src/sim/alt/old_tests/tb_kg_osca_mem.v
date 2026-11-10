`timescale 1ns / 1ps
`ifndef OUT_DLY
 `define OUT_DLY 6.0     // FPGA clock -> pad (IOB register + output buffer)
`endif
`ifndef IN_DLY
 `define IN_DLY 2.5      // pad -> IOB input register setup
`endif
`ifndef NOPS
 `define NOPS 1500
`endif

// One logical memory port driven like the OSCA core would: every operation lasts two
// 16 MHz cycles; a write strobe is low for the first cycle only.
module stim #(parameter AW = 19, SEED = 1, LATE = 0, NA = 40, HALF = 0) (
    input  wire clk16, input wire start,
    output reg [AW-1:0] addr, output reg wr_n, output reg cs_n, output reg rd_n, output reg [7:0] wdata,
    input  wire [7:0] rdata, output reg done, output reg [31:0] errors, output reg [31:0] checks
);
    reg [AW-1:0] tab [0:NA-1];
    reg [7:0]    ref_ [0:NA-1];
    reg          val  [0:NA-1];
    integer i, n, k, kind, seed;
    reg rd_op;
    initial begin
        errors = 0; checks = 0; done = 0; wr_n = 1; cs_n = 1; rd_n = 1; addr = 0; wdata = 0;
        seed = SEED;
        for (i = 0; i < NA; i = i + 1) begin val[i] = 0; tab[i] = $random(seed); end
        tab[0] = 0; tab[1] = {AW{1'b1}}; tab[2] = 1 << (AW-1);
        wait (start);
        for (n = 0; n < `NOPS; n = n + 1) begin
            @(posedge clk16); #2;
            kind = {$random(seed)} % 4;          // 0 idle, 1/3 read, 2 write
            k    = {$random(seed)} % NA;
            rd_op = (kind == 1 || kind == 3);
            rd_n = rd_op ? 1'b0 : 1'b1;                 // OE# low only in read cycles
            if (kind != 0) begin
                addr = tab[k]; cs_n = 0;
                if (kind == 2) begin wdata = $random(seed); if (!HALF) wr_n = 0; ref_[k] = wdata; val[k] = 1; end
            end
            if (HALF) begin #30; if (kind == 2) wr_n = 0; #27; end   // half-cycle strobe: from the clk16 falling edge
            else #57;
            if (rd_op && val[k] && LATE == 0) begin
                checks = checks + 1;
                if (rdata !== ref_[k]) begin errors = errors + 1;
                    if (errors < 6) $display("ERR %m cycle1 addr=%h got=%h exp=%h t=%0t", addr, rdata, ref_[k], $time); end
            end
            @(posedge clk16); #1; wr_n = 1; #1;
            if (LATE == 2) begin #57; @(posedge clk16); #2; end   // LATE=2: one more cycle (access displaced by a video write)
            #57;
            if (rd_op && val[k]) begin
                checks = checks + 1;
                if (rdata !== ref_[k]) begin errors = errors + 1;
                    if (errors < 6) $display("ERR %m cycle2 addr=%h got=%h exp=%h t=%0t", addr, rdata, ref_[k], $time); end
            end
        end
        done = 1;
    end
endmodule

module tb_kg_osca_mem;
    reg clk_mem = 0;
    always #5.208333 clk_mem = ~clk_mem;           // 96 MHz
    wire clk16;
    reg  start = 0;

    wire [18:0] vram_addr; wire vram_wr_n, vram_cs_n, vram_rd_n; wire spr_rd_n, sys_rd_n; wire [7:0] vram_wdata, vram_rdata;
    wire [16:0] spr_addr;  wire spr_wr_n,  spr_cs_n;  wire [7:0] spr_wdata,  spr_rdata;
    wire [18:0] sys_addr;  wire sys_wr_n,  sys_cs_n;  wire [7:0] sys_wdata,  sys_rdata;
    wire [20:0] ma; wire [15:0] md_o; wire md_oe; wire [15:0] md_i; wire [1:0] mwr_n, mrd_n;

    kg_osca_mem dut (
        .clk_mem(clk_mem), .clk16(clk16),
        .vram_addr(vram_addr), .vram_wr_n(vram_wr_n), .vram_wdata(vram_wdata), .vram_rdata(vram_rdata),
        .spr_addr(spr_addr),   .spr_wr_n(spr_wr_n),   .spr_wdata(spr_wdata),   .spr_rdata(spr_rdata),
        .sys_addr(sys_addr),   .sys_cs_n(sys_cs_n),   .sys_wr_n(sys_wr_n),     .sys_wdata(sys_wdata), .sys_rdata(sys_rdata),
        .ma(ma), .md_o(md_o), .md_oe(md_oe), .md_i(md_i), .mwr_n(mwr_n), .mrd_n(mrd_n));

    wire dv, ds, dy; wire [31:0] ev, es, ey, cv_, cs_, cy_;
    stim #(19, 11, 0, 40, 1) sv (clk16, start, vram_addr, vram_wr_n, vram_cs_n, vram_rd_n, vram_wdata, vram_rdata, dv, ev, cv_);
    stim #(17, 22, 2) ss (clk16, start, spr_addr,  spr_wr_n,  spr_cs_n,  spr_rd_n,  spr_wdata,  spr_rdata,  ds, es, cs_);
    stim #(19, 33, 1) sy (clk16, start, sys_addr,  sys_wr_n,  sys_cs_n,  sys_rd_n,  sys_wdata,  sys_rdata,  dy, ey, cy_);

    // ------------------------------------------------------------ pads + 10 ns async SRAM (low-byte chip)
    wire [20:0] pad_ma;  assign #(`OUT_DLY) pad_ma  = ma;
    wire [15:0] pad_mdo; assign #(`OUT_DLY) pad_mdo = md_o;
    wire        pad_oe;  assign #(`OUT_DLY) pad_oe  = md_oe;
    wire        pad_we0; assign #(`OUT_DLY) pad_we0 = mwr_n[0];
    wire        pad_rd0; assign #(`OUT_DLY) pad_rd0 = mrd_n[0];
    wire [15:0] md_bus;
    assign md_bus = pad_oe ? pad_mdo : 16'bz;

    reg [7:0] mem0 [0:2097151];
    reg [7:0] do_r = 8'hxx;
    always @(pad_ma) begin do_r <= #2 8'hxx; do_r <= #10 mem0[pad_ma]; end
    assign md_bus[7:0] = (!pad_rd0 && pad_we0) ? do_r : 8'bz;
    assign #(`IN_DLY) md_i = md_bus;

    // physical checks of the write cycle
    integer phys_err = 0;
    real t_fall = 0, t_a = 0, t_d = 0; reg [20:0] a_fall = 0; integer wcount = 0;
    always @(pad_ma)       t_a = $realtime;
    always @(md_bus[7:0])  t_d = $realtime;
    always @(negedge pad_we0) begin
        t_fall = $realtime; a_fall = pad_ma;
        if ($realtime - t_a < 3.0) begin phys_err = phys_err + 1; $display("PHYS addr setup %0f", $realtime - t_a); end
        if (!md_oe && pad_oe !== 1'b1) ; // (data driven by FPGA is checked at the rising edge)
    end
    always @(posedge pad_we0) if (t_fall != 0) begin
        wcount = wcount + 1;
        if ($realtime - t_fall < 8.0) begin phys_err = phys_err + 1; $display("PHYS WE# pulse %0f ns", $realtime - t_fall); end
        if (pad_ma !== a_fall)        begin phys_err = phys_err + 1; $display("PHYS addr moved under WE#"); end
        if (md_bus[7:0] === 8'bx || pad_oe !== 1'b1) begin phys_err = phys_err + 1; $display("PHYS no data on write"); end
        mem0[a_fall] = md_bus[7:0];
    end

    // ------------------------------------------------------------ run
    initial begin
        #300 start = 1;
        wait (dv && ds && dy);
        #200;
        $display("vram: %0d checks, %0d errors | spr: %0d / %0d | sys: %0d / %0d | SRAM writes %0d | phys errors %0d",
                 cv_, ev, cs_, es, cy_, ey, wcount, phys_err);
        if (ev + es + ey + phys_err == 0) $display("PASS"); else $display("FAIL");
        $finish;
    end
endmodule
