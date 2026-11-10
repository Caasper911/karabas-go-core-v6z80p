`timescale 1ns / 1ps
// the whole board-side chain in simulation: kg_sram_test (slow tests, zero fill) -> kg_vram_test (through kg_osca_mem) -> kg_sram_test (direct verify of the pattern)
module tb_vram_full;
    reg clk96 = 0; always #5.2083 clk96 = ~clk96;
    wire clk16;
    wire [20:0] ma; wire [15:0] md_o; wire md_oe; wire [1:0] mwr_n, mrd_n; wire [7:0] r1, r2;
    wire [18:0] t_addr; wire t_wr_n; wire [7:0] t_wd; wire vrun, vdone; wire [15:0] es, er; wire [63:0] a0;
    reg [7:0] sram0 [0:2097151];
    wire [15:0] md = md_oe ? md_o : {8'hzz, mrd_n[0] ? 8'hzz : sram0[ma]};
    always @(posedge mwr_n[0]) sram0[ma] <= md[7:0];
    wire srun, sdone, alias0; wire [20:0] sma, amask; wire [15:0] smd; wire soe; wire [1:0] swr, srd; wire [7:0] dm0, dm1;
    wire sv_done; wire [15:0] sv_err; wire [7:0] sv0, sv1;
    kg_osca_mem mem (.clk_mem(clk96), .clk16(clk16), .vram_addr(t_addr), .vram_wr_n(t_wr_n), .vram_wdata(t_wd), .vram_rdata1(r1), .vram_rdata2(r2),
        .spr_addr(17'd0), .spr_wr_n(1'b1), .spr_wdata(8'd0), .spr_rdata(), .ma(ma), .md_o(md_o), .md_oe(md_oe), .md_i(md), .mwr_n(mwr_n), .mrd_n(mrd_n),
        .t_en(srun), .t_ma(sma), .t_md(smd), .t_oe(soe), .t_wr_n(swr), .t_rd_n(srd));
    reg go = 0;
    kg_sram_test st (.clk(clk96), .go(go), .run(srun), .ma(sma), .md(smd), .oe(soe), .wr_n(swr), .rd_n(srd), .md_i(md), .done(sdone),
        .dmask0(dm0), .dmask1(dm1), .amask(amask), .alias0(alias0), .vgo(vdone), .vdone(sv_done), .verr(sv_err), .vact0(sv0), .vact1(sv1));
    kg_vram_test vt (.clk16(clk16), .go(sdone), .run(vrun), .addr(t_addr), .wr_n(t_wr_n), .wdata(t_wd), .rdata1(r1), .rdata2(r2), .done(vdone),
        .err_s(es), .err_r(er), .act(a0));
    initial begin #1000 go = 1; wait (sv_done); #1000;
        $display("CHAIN: sram basic dmask=%b/%b amask=%0d alias0=%b | vram stream errors=%0d rdata2 errors=%0d first=%h | direct verify errors=%0d first=%02h %02h",
            dm0, dm1, amask, alias0, es, er, a0, sv_err, sv0, sv1);
        $finish; end
endmodule
