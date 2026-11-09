`timescale 1ns / 1ps
// kg_vram_test against kg_osca_mem and a plain zero-delay SRAM model (low byte chip).
module tb_vram_test;
    reg clk96 = 0; always #5.2083 clk96 = ~clk96;
    wire clk16;
    wire [20:0] ma; wire [15:0] md_o; wire md_oe; wire [1:0] mwr_n, mrd_n; wire [7:0] r1, r2;
    wire [18:0] t_addr; wire t_wr_n; wire [7:0] t_wd; wire run, done; wire [15:0] es, er; wire [63:0] a0;
    reg [7:0] sram [0:2097151];
    wire [15:0] md = md_oe ? md_o : {8'hzz, mrd_n[0] ? 8'hzz : sram[ma]};
    always @(negedge mwr_n[0]) begin end
    always @(posedge mwr_n[0]) sram[ma] <= md[7:0];
    kg_osca_mem mem (.clk_mem(clk96), .clk16(clk16), .vram_addr(t_addr), .vram_wr_n(t_wr_n), .vram_wdata(t_wd), .vram_rdata1(r1), .vram_rdata2(r2),
        .spr_addr(17'd0), .spr_wr_n(1'b1), .spr_wdata(8'd0), .spr_rdata(), .ma(ma), .md_o(md_o), .md_oe(md_oe), .md_i(md), .mwr_n(mwr_n), .mrd_n(mrd_n),
        .t_en(1'b0), .t_ma(21'd0), .t_md(16'd0), .t_oe(1'b0), .t_wr_n(2'b11), .t_rd_n(2'b11));
    reg go = 0;
    kg_vram_test dut (.clk16(clk16), .go(go), .run(run), .addr(t_addr), .wr_n(t_wr_n), .wdata(t_wd), .rdata1(r1), .rdata2(r2), .done(done),
        .err_s(es), .err_r(er), .act(a0));
    initial begin #1000 go = 1; wait (done); #1000; $display("VRAM test: stream errors=%0d rdata2 errors=%0d first bytes %h", es, er, a0); $finish; end
endmodule
