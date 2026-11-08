`timescale 1ns / 1ps
// kg_sdram_check - bring-up self test of the system RAM (SDRAM) on the real board.
// A copy of the boot image is kept in a block RAM while the MCU loader writes it (wr_i / addr_i / data_i, clk domain).  When the loader
// has finished (`go`), the image is read back through the SDRAM controller's loader port (the core is still in reset) and compared:
//   pass 1: sequential addresses, pass 2: addresses a(i+1) = a(i) + STRIDE mod N (row / bank changes, like CPU code and data).
// Address 0 is not compared (the loader never writes a byte that does not change the address, so a zero at address 0 stays unwritten).
// A mismatch that differs between the passes means a read problem (timing); the same mismatch in both means a write problem.
module kg_sdram_check #(
    parameter [15:0] N      = 16'd20142,
    parameter [15:0] STRIDE = 16'd7919
) (
    input  wire        clk,
    input  wire        wr_i,                 // loader write strobe
    input  wire [14:0] addr_i,
    input  wire [7:0]  data_i,
    input  wire        go,                   // loader finished: start (level, stays 1 until `done`)
    output wire        run,                  // 1 while the checker owns the SDRAM loader port
    output reg  [18:0] addr_o = 19'd0,
    input  wire        rd_valid,
    input  wire [7:0]  rdata,
    output reg         done     = 1'b0,
    output reg         pass1_ok = 1'b0,      // pass 1 finished
    output reg         pass2_ok = 1'b0,      // pass 2 finished
    output reg         timeout  = 1'b0,      // rd_valid never came
    output reg  [15:0] err1 = 16'd0,         // mismatches in pass 1
    output reg  [15:0] err2 = 16'd0,         // mismatches in pass 2
    output reg  [15:0] first_addr = 16'd0,
    output reg  [7:0]  first_exp  = 8'd0,
    output reg  [7:0]  first_act  = 8'd0
);
    reg [7:0] img [0:32767];
    reg [7:0] exp_q = 8'd0;
    always @(posedge clk) begin
        if (wr_i) img[addr_i] <= data_i;
        exp_q <= img[addr_o[14:0]];
    end

    reg        running = 1'b0;
    assign run = (go & ~done) | running;
    reg [2:0]  st = 3'd0;
    reg [15:0] idx = 16'd1;                  // pass 1: address, pass 2: current address
    reg        pass = 1'b0;
    reg [15:0] cnt = 16'd1;                  // pass 2: how many addresses are done
    reg [7:0]  tmo = 8'd0;
    reg        have_first = 1'b0;
    wire [16:0] nxt_sum = {1'b0, idx} + {1'b0, STRIDE};
    wire [15:0] nxt = (nxt_sum >= {1'b0, N}) ? (nxt_sum - {1'b0, N}) : nxt_sum[15:0];

    always @(posedge clk) begin
        if (go && !done) running <= 1'b1;
        case (st)
        3'd0: if (go && !done) begin                       // start
                addr_o <= 19'd1; idx <= 16'd1; pass <= 1'b0; cnt <= 16'd1; tmo <= 8'd0; st <= 3'd1;
              end
        3'd1: begin                                        // address is out; wait for the controller
                tmo <= tmo + 8'd1;
                if (tmo >= 8'd4 && rd_valid) st <= 3'd2;
                else if (tmo == 8'd250) begin timeout <= 1'b1; st <= 3'd2; end
              end
        3'd2: begin                                        // sample (exp_q is the BRAM word of addr_o)
                if (rdata !== exp_q || (tmo == 8'd250)) begin
                    if (!pass) err1 <= (err1 == 16'hffff) ? err1 : err1 + 16'd1; else err2 <= (err2 == 16'hffff) ? err2 : err2 + 16'd1;
                    if (!have_first) begin have_first <= 1'b1; first_addr <= addr_o[15:0]; first_exp <= exp_q; first_act <= rdata; end
                end
                st <= 3'd3;
              end
        3'd3: begin                                        // next address
                tmo <= 8'd0; st <= 3'd1;
                if (!pass) begin
                    if (idx + 16'd1 >= N) begin pass <= 1'b1; pass1_ok <= 1'b1; idx <= 16'd1; cnt <= 16'd1; addr_o <= 19'd1; end
                    else begin idx <= idx + 16'd1; addr_o <= {3'd0, idx + 16'd1}; end
                end else begin
                    if (cnt + 16'd1 >= N) begin pass2_ok <= 1'b1; done <= 1'b1; running <= 1'b0; st <= 3'd4; end
                    else begin cnt <= cnt + 16'd1; idx <= (nxt == 16'd0) ? STRIDE[15:0] : nxt; addr_o <= {3'd0, (nxt == 16'd0) ? STRIDE[15:0] : nxt}; end
                end
              end
        default: ;                                         // 4: finished
        endcase
    end
endmodule
