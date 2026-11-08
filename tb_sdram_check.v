`timescale 1ns / 1ps
// kg_sdram_check against kg_osca_sdram + the SDRAM model: loader-style writes, then the read-back test.  +corrupt=N flips one bit of byte N in the SDRAM only.
module tb_sdram_check;
    reg clk = 0; always #5.2083 clk = ~clk;
    reg reset = 1;
    integer corrupt = -1;
    reg [18:0] l_addr = 0; reg [7:0] l_data = 0; reg l_wr = 0; reg l_active = 1;
    wire chk_run; wire [18:0] chk_addr; wire chk_done, p1, p2, tmo; wire [15:0] e1, e2, fa; wire [7:0] fe, fact;
    wire [18:0] addr = chk_run ? chk_addr : l_addr;
    wire cs_n = ~(l_active | chk_run) ? 1'b1 : 1'b0;
    wire wr_n = chk_run ? 1'b1 : ~l_wr;
    wire [7:0] wdata = (corrupt >= 0 && l_addr == corrupt) ? (l_data ^ 8'h10) : l_data;
    wire [7:0] rdata; wire rd_valid, wr_pending, init_done;
    wire [1:0] ba, dqm; wire [12:0] sa; wire ras_n, cas_n, we_n; wire [15:0] dq;
    kg_osca_sdram #(.INIT_WAIT(16'd200)) dut (.clk(clk), .reset(reset), .addr(addr), .cs_n(cs_n), .wr_n(wr_n), .wdata(wdata),
        .block_refresh(1'b0), .hint_addr(19'd0), .rdata(rdata), .rd_valid(rd_valid), .wr_pending(wr_pending), .init_done(init_done),
        .sd_ba(ba), .sd_a(sa), .sd_dqm(dqm), .sd_ras_n(ras_n), .sd_cas_n(cas_n), .sd_we_n(we_n), .sd_dq(dq));
    tb_sdram_model sdram (.clk(clk), .ba(ba), .a(sa), .dqm(dqm), .ras_n(ras_n), .cas_n(cas_n), .we_n(we_n), .dq(dq));
    reg loader_done = 0;
    kg_sdram_check chk (.clk(clk), .wr_i(l_wr), .addr_i(l_addr[14:0]), .data_i(l_data), .go(loader_done), .run(chk_run), .addr_o(chk_addr),
        .rd_valid(rd_valid), .rdata(rdata), .done(chk_done), .pass1_ok(p1), .pass2_ok(p2), .timeout(tmo), .err1(e1), .err2(e2),
        .first_addr(fa), .first_exp(fe), .first_act(fact));
    integer i, seed = 7; reg [7:0] d;
    initial begin
        if ($value$plusargs("corrupt=%d", corrupt)) ;
        #200 reset = 0; wait (init_done); repeat (50) @(posedge clk);
        for (i = 0; i < 20142; i = i + 1) begin
            d = $random(seed);
            @(posedge clk); l_addr <= i; l_data <= d; l_wr <= 1; 
            @(posedge clk); l_wr <= 0;
            repeat (14) @(posedge clk);
        end
        repeat (50) @(posedge clk);
        l_active <= 0; loader_done <= 1;
        wait (chk_done); repeat (5) @(posedge clk);
        $display("CHK done: pass1=%b pass2=%b timeout=%b err1=%0d err2=%0d first addr=%0d exp=%02h act=%02h", p1, p2, tmo, e1, e2, fa, fe, fact);
        $finish;
    end
    // corrupt the data seen by the controller for one address (write path) - the checker keeps the right copy
    initial begin #1; end
endmodule
