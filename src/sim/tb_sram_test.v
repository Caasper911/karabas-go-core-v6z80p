`timescale 1ns / 1ps
// kg_sram_test against a simple model of the two 2Mx8 SRAM chips; +alias=K ties address line K to line 0 (aliasing), +stuck=B sticks data bit B of chip 1 at 0
module tb_sram_test;
    reg clk = 0; always #5.2083 clk = ~clk;
    reg go = 0;
    wire run, done, alias0; wire [20:0] ma, amask; wire [15:0] md; wire oe; wire [1:0] wr_n, rd_n; wire [7:0] dm0, dm1;
    wire [15:0] bus;
    integer alias = -1, stuck = -1;
    reg [7:0] m0 [0:2097151]; reg [7:0] m1 [0:2097151];
    wire [20:0] ea = (alias >= 0) ? (ma & ~(21'd1 << alias)) : ma;
    assign bus = oe ? md : {(rd_n[1] ? 8'hzz : m1[ea]), (rd_n[0] ? 8'hzz : m0[ea])};
    always @(posedge wr_n[0]) m0[ea] <= bus[7:0];
    always @(posedge wr_n[1]) m1[ea] <= (stuck >= 0) ? (bus[15:8] & ~(8'd1 << stuck)) : bus[15:8];
    kg_sram_test dut (.clk(clk), .go(go), .run(run), .ma(ma), .md(md), .oe(oe), .wr_n(wr_n), .rd_n(rd_n), .md_i(bus), .done(done),
                      .dmask0(dm0), .dmask1(dm1), .amask(amask), .alias0(alias0), .vgo(1'b0), .vdone(), .verr(), .vact0(), .vact1());
    initial begin
        if ($value$plusargs("alias=%d", alias)) ; if ($value$plusargs("stuck=%d", stuck)) ;
        #100 go = 1; wait (done); #100;
        $display("SRAM test: dmask0=%b dmask1=%b amask=%b alias0=%b", dm0, dm1, amask, alias0);
        $finish;
    end
endmodule
