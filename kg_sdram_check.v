`timescale 1ns / 1ps
// kg_sdram_check - SDRAM self test and calibration for the real board.
//
// A copy of the boot image is kept in a block RAM while the MCU loader writes it (wr_i / addr_i / data_i).  When the loader has finished
// (`go`) the core is still in reset and this module owns the SDRAM controller's loader port.  Two interface variants are tried:
//   pol_o : polarity of SDR_CLK  (0 = the same edge as clk96, 1 = inverted: the chip samples in the middle of the command window)
//   cap_o : read data capture   (0 = fabric flip-flop at clock 6, 1 = IOB flip-flop at clock 7)
// Matrix (cell index = W * 4 + R):  W = polarity the image was written with (0/1), R = one of four read variants (pol, cap) = (0,0) (0,1) (1,0) (1,1).
// Every operation that changes the polarity re-initialises the SDRAM (rst_o).  A cidx is "ok" when the whole image (sequential, then strided order)
// reads back without a mismatch, "bad" when it has >= 100 mismatches.  Then the variant with the fewest mismatches among the four cells with the
// same write and read polarity is chosen (ties: (1,0) > (1,1) > (0,1) > (0,0)), the image is written again with it and verified
// (err_final, first_*), and pol_o / cap_o stay at the chosen values for the normal operation of the core.
module kg_sdram_check #(
    parameter [15:0] N      = 16'd20142,
    parameter [15:0] STRIDE = 16'd7919
) (
    input  wire        clk,
    input  wire        wr_i,
    input  wire [14:0] addr_i,
    input  wire [7:0]  data_i,
    input  wire        go,                   // loader finished (level)
    input  wire        init_done,            // SDRAM controller initialised
    output wire        run,                  // 1 while this module owns the loader port of the SDRAM controller
    output reg  [18:0] addr_o = 19'd0,
    output reg         wr_o   = 1'b0,
    output reg  [7:0]  data_o = 8'd0,
    output reg         rst_o  = 1'b0,        // reset (re-initialise) the SDRAM controller
    output reg         pol_o  = 1'b0,
    output reg         cap_o  = 1'b0,
    input  wire        rd_valid,
    input  wire [7:0]  rdata,
    output reg         done = 1'b0,
    output reg         matrix_done = 1'b0,
    output reg         timeout = 1'b0,
    output reg  [7:0]  cell_ok  = 8'd0,      // cell finished with 0 mismatches
    output reg  [7:0]  cell_bad = 8'd0,      // cell finished with >= 100 mismatches
    output reg  [15:0] err_final = 16'd0,
    output reg  [15:0] first_addr = 16'd0,   // first mismatch of the first read test (cidx 0)
    output reg  [7:0]  first_exp = 8'd0,
    output reg  [7:0]  first_act = 8'd0
);
    reg [7:0] img [0:32767];
    reg [7:0] exp_q = 8'd0;
    always @(posedge clk) begin
        if (wr_i) img[addr_i] <= data_i;
        exp_q <= img[addr_o[14:0]];
    end

    reg [7:0] rd_q = 8'd0;
    reg       rv_q = 1'b0;
    always @(posedge clk) begin rd_q <= rdata; rv_q <= rd_valid; end   // registered: the SDRAM read data path from the address is long
    reg running = 1'b0;
    assign run = (go & ~done) | running;

    // ---- state
    localparam S_IDLE = 5'd0, S_SETUP = 5'd1, S_RI0 = 5'd2, S_RI1 = 5'd3, S_RI2 = 5'd4, S_RI3 = 5'd5,
               S_W0 = 5'd6, S_W1 = 5'd7, S_W2 = 5'd8, S_W3 = 5'd9, S_W4 = 5'd10,
               S_R0 = 5'd11, S_R1 = 5'd12, S_R2 = 5'd13, S_R3 = 5'd14, S_END = 5'd15, S_SEL = 5'd16, S_FIN = 5'd17, S_SEL1 = 5'd18, S_SEL2 = 5'd19, S_SEL3 = 5'd20;
    reg [4:0]  st = S_IDLE;
    reg [3:0]  sq = 4'd0;                    // step of the sequence
    reg [15:0] idx = 16'd0;                  // address (sequential) / current address (strided)
    reg [15:0] cnt = 16'd0;                  // addresses done in this pass
    reg        pass = 1'b0;                  // read: 0 sequential, 1 strided
    reg [15:0] tmo = 16'd0;
    reg [15:0] errc = 16'd0;
    reg        have_first = 1'b0;
    reg [15:0] e0 = 16'd0, e1 = 16'd0, e6 = 16'd0, e7 = 16'd0;   // errors of the cells with equal write / read polarity
    reg [2:0]  cidx = 3'd0;
    reg        new_pol = 1'b0, new_cap = 1'b0, is_write = 1'b0;
    reg [1:0]  best = 2'd0, b_r = 2'd0;
    reg [15:0] m_r = 16'd0;
    wire [16:0] nxt_sum = {1'b0, idx} + {1'b0, STRIDE};
    wire [15:0] nxt = (nxt_sum >= {1'b0, N}) ? (nxt_sum - {1'b0, N}) : nxt_sum[15:0];

    // sequence: sq -> (write?, polarity, capture, cidx)
    //   0 W p0   1 R p0c0 cell0   2 R p0c1 cell1   3 R p1c0 cell2   4 R p1c1 cell3
    //   5 W p1   6 R p0c0 cell4   7 R p0c1 cell5   8 R p1c0 cell6   9 R p1c1 cell7   10 select, W with the best   11 R best (final)
    task setup(input [3:0] q);
        begin
            case (q)
                4'd0:  begin is_write <= 1'b1; new_pol <= 1'b0; new_cap <= 1'b0; end
                4'd1:  begin is_write <= 1'b0; new_pol <= 1'b0; new_cap <= 1'b0; cidx <= 3'd0; end
                4'd2:  begin is_write <= 1'b0; new_pol <= 1'b0; new_cap <= 1'b1; cidx <= 3'd1; end
                4'd3:  begin is_write <= 1'b0; new_pol <= 1'b1; new_cap <= 1'b0; cidx <= 3'd2; end
                4'd4:  begin is_write <= 1'b0; new_pol <= 1'b1; new_cap <= 1'b1; cidx <= 3'd3; end
                4'd5:  begin is_write <= 1'b1; new_pol <= 1'b1; new_cap <= 1'b1; end
                4'd6:  begin is_write <= 1'b0; new_pol <= 1'b0; new_cap <= 1'b0; cidx <= 3'd4; end
                4'd7:  begin is_write <= 1'b0; new_pol <= 1'b0; new_cap <= 1'b1; cidx <= 3'd5; end
                4'd8:  begin is_write <= 1'b0; new_pol <= 1'b1; new_cap <= 1'b0; cidx <= 3'd6; end
                4'd9:  begin is_write <= 1'b0; new_pol <= 1'b1; new_cap <= 1'b1; cidx <= 3'd7; end
                default: ;
            endcase
        end
    endtask

    always @(posedge clk) begin
        if (go && !done && st == S_IDLE) running <= 1'b1;
        case (st)
        S_IDLE: if (go && !done) begin sq <= 4'd0; setup(4'd0); st <= S_SETUP; end

        // apply the variant: a polarity change re-initialises the SDRAM
        S_SETUP: begin
            cap_o <= new_cap;
            if (new_pol != pol_o) begin pol_o <= new_pol; tmo <= 16'd0; rst_o <= 1'b1; st <= S_RI0; end
            else begin tmo <= 16'd0; st <= S_RI3; end
        end
        S_RI0: begin tmo <= tmo + 16'd1; if (tmo == 16'd8) begin rst_o <= 1'b0; tmo <= 16'd0; st <= S_RI1; end end
        S_RI1: begin tmo <= tmo + 16'd1; if (tmo == 16'd32) begin tmo <= 16'd0; st <= S_RI2; end end
        S_RI2: begin tmo <= tmo + 16'd1; if (init_done) begin tmo <= 16'd0; st <= S_RI3; end else if (tmo == 16'hfff0) begin timeout <= 1'b1; st <= S_RI3; tmo <= 16'd0; end end
        S_RI3: begin                                           // settle, then start the operation
            tmo <= tmo + 16'd1;
            if (tmo == 16'd100) begin
                tmo <= 16'd0; idx <= 16'd0; cnt <= 16'd0; pass <= 1'b0; errc <= 16'd0; addr_o <= 19'd0;
                st <= is_write ? S_W0 : S_R0;
            end
        end

        // ---- write the image from the BRAM copy
        S_W0: begin addr_o <= {3'd0, idx}; tmo <= 16'd0; st <= S_W1; end
        S_W1: begin tmo <= tmo + 16'd1; if (tmo == 16'd3) begin data_o <= exp_q; st <= S_W2; end end
        S_W2: begin wr_o <= 1'b1; st <= S_W3; end
        S_W3: begin wr_o <= 1'b0; tmo <= 16'd0; st <= S_W4; end
        S_W4: begin
            tmo <= tmo + 16'd1;
            if (tmo == 16'd20) begin
                if (idx + 16'd1 >= N) begin tmo <= 16'd0; st <= S_END; end
                else begin idx <= idx + 16'd1; st <= S_W0; end
            end
        end

        // ---- read back and compare
        S_R0: begin addr_o <= {3'd0, idx}; tmo <= 16'd0; st <= S_R1; end
        S_R1: begin
            tmo <= tmo + 16'd1;
            if (tmo >= 16'd4 && rv_q) st <= S_R2;
            else if (tmo == 16'd250) begin timeout <= 1'b1; st <= S_R2; end
        end
        S_R2: begin
            if (rd_q !== exp_q || tmo == 16'd250) begin
                errc <= (errc == 16'hffff) ? errc : errc + 16'd1;
                if (sq == 4'd1 && !have_first) begin have_first <= 1'b1; first_addr <= addr_o[15:0]; first_exp <= exp_q; first_act <= rd_q; end
            end
            st <= S_R3;
        end
        S_R3: begin
            tmo <= 16'd0; st <= S_R0;
            if (cnt + 16'd1 >= N) begin
                cnt <= 16'd0;
                if (!pass) begin pass <= 1'b1; idx <= 16'd0; end
                else st <= S_END;
            end else begin
                cnt <= cnt + 16'd1;
                idx <= !pass ? idx + 16'd1 : nxt;
            end
        end

        // ---- end of an operation
        S_END: begin
            tmo <= tmo + 16'd1;
            if (tmo == 16'd40) begin
                tmo <= 16'd0;
                if (!is_write) begin
                    if (sq <= 4'd9) begin
                        if (errc == 16'd0) cell_ok[cidx] <= 1'b1;
                        if (errc >= 16'd100) cell_bad[cidx] <= 1'b1;
                        case (cidx) 3'd0: e0 <= errc; 3'd1: e1 <= errc; 3'd6: e6 <= errc; 3'd7: e7 <= errc; default: ; endcase
                    end else err_final <= errc;
                end
                if (sq == 4'd11) begin done <= 1'b1; running <= 1'b0; st <= S_FIN; end
                else if (sq == 4'd9) begin matrix_done <= 1'b1; st <= S_SEL; end
                else if (sq == 4'd10) begin sq <= 4'd11; is_write <= 1'b0; cidx <= 3'd0; st <= S_SETUP; end   // verify with the chosen variant (new_pol / new_cap stay)
                else begin sq <= sq + 4'd1; setup(sq + 4'd1); st <= S_SETUP; end
            end
        end

        // ---- choose the best variant (errors e0 / e1 with polarity 0, e6 / e7 with polarity 1), write the image again and verify
        S_SEL:  begin m_r <= e0; b_r <= 2'd0; st <= S_SEL1; end
        S_SEL1: begin if (e1 <= m_r) begin m_r <= e1; b_r <= 2'd1; end st <= S_SEL2; end
        S_SEL2: begin if (e7 <= m_r) begin m_r <= e7; b_r <= 2'd3; end st <= S_SEL3; end
        S_SEL3: begin                                           // ties: polarity 1 with the fabric capture first (the variant verified in the simulation regression)
            if (e6 <= m_r) begin best <= 2'd2; is_write <= 1'b1; new_pol <= 1'b1; new_cap <= 1'b0; end
            else           begin best <= b_r;  is_write <= 1'b1; new_pol <= b_r[1]; new_cap <= b_r[0]; end
            sq <= 4'd10; st <= S_SETUP;
        end

        default: ;                                              // S_FIN
        endcase

    end
endmodule
