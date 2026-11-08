`timescale 1ns / 1ps
// kg_sdram_check against kg_osca_sdram + the SDRAM model: loader-style writes, then the calibration matrix.
// +corrupt=N flips one bit of byte N on the SDRAM write path while cap_o == 0 (so the matrix has bad cells and the best variant is cap 1).
module tb_sdram_check;
    reg clk = 0; always #5.2083 clk = ~clk;
    reg reset0 = 1;
    integer corrupt = -1;
    reg [18:0] l_addr = 0; reg [7:0] l_data = 0; reg l_wr = 0; reg l_active = 1;
    wire chk_run, chk_wr, chk_rst, chk_pol, chk_cap, chk_done, mdone, tmo; wire [18:0] chk_addr; wire [7:0] chk_data, cok, cbad, fe, fact; wire [15:0] efin, fa;
    wire [18:0] addr = chk_run ? chk_addr : l_addr;
    wire cs_n = ~(l_active | chk_run);
    wire wr_n = chk_run ? ~chk_wr : ~l_wr;
    wire [7:0] wdata0 = chk_run ? chk_data : l_data;
    wire [7:0] wdata = (corrupt >= 0 && addr == corrupt && !chk_cap) ? (wdata0 ^ 8'h10) : wdata0;
    wire [7:0] rdata; wire rd_valid, wr_pending, init_done;
    wire [1:0] ba, dqm; wire [12:0] sa; wire ras_n, cas_n, we_n; wire [15:0] dq;
    kg_osca_sdram #(.INIT_WAIT(16'd200)) dut (.clk(clk), .reset(reset0 | chk_rst), .addr(addr), .cs_n(cs_n), .wr_n(wr_n), .wdata(wdata),
        .cap_late(chk_cap), .block_refresh(1'b0), .hint_addr(19'd0), .rdata(rdata), .rd_valid(rd_valid), .wr_pending(wr_pending), .init_done(init_done),
        .sd_ba(ba), .sd_a(sa), .sd_dqm(dqm), .sd_ras_n(ras_n), .sd_cas_n(cas_n), .sd_we_n(we_n), .sd_dq(dq));
    tb_sdram_model sdram (.clk(clk), .ba(ba), .a(sa), .dqm(dqm), .ras_n(ras_n), .cas_n(cas_n), .we_n(we_n), .dq(dq));
    reg loader_done = 0;
    kg_sdram_check chk (.clk(clk), .wr_i(l_wr), .addr_i(l_addr[14:0]), .data_i(l_data), .go(loader_done), .init_done(init_done), .run(chk_run),
        .addr_o(chk_addr), .wr_o(chk_wr), .data_o(chk_data), .rst_o(chk_rst), .pol_o(chk_pol), .cap_o(chk_cap),
        .rd_valid(rd_valid), .rdata(rdata), .done(chk_done), .matrix_done(mdone), .timeout(tmo), .cell_ok(cok), .cell_bad(cbad),
        .err_final(efin), .first_addr(fa), .first_exp(fe), .first_act(fact));
    integer i, seed = 7; reg [7:0] d;
    initial begin
        if ($value$plusargs("corrupt=%d", corrupt)) ;
        #200 reset0 = 0; wait (init_done); repeat (50) @(posedge clk);
        for (i = 0; i < 20142; i = i + 1) begin
            d = $random(seed);
            @(posedge clk); l_addr <= i; l_data <= d; l_wr <= 1;
            @(posedge clk); l_wr <= 0;
            repeat (14) @(posedge clk);
        end
        repeat (50) @(posedge clk);
        l_active <= 0; loader_done <= 1;
        wait (chk_done); repeat (5) @(posedge clk);
        $display("CHK done: matrix=%b timeout=%b cell_ok=%b cell_bad=%b final: pol=%b cap=%b errors=%0d first addr=%0d exp=%02h act=%02h", mdone, tmo, cok, cbad, chk_pol, chk_cap, efin, fa, fe, fact);
        $finish;
    end
endmodule
