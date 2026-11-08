`timescale 1ns / 1ps
// kg_vram_test - bring-up self test of the video RAM path (kg_osca_mem wrapper + SRAM) at the real speed, run while the core is held in reset.
// It takes over the wrapper's video RAM inputs (vram_addr / vram_wr_n / vram_wdata) and reads back rdata1 / rdata2 like the core does:
//   write  : 16384 bytes (8192 at 00000.., 8192 at 40000..), data = f(address) = A[7:0] ^ A[15:8] ^ 5A, strobe low for 2 clk16 cycles   (through the wrapper)
//   stream : the address changes EVERY clk16 cycle (like the display fetch); rdata1 sampled at the next rising edge must be f(previous address)  -> err_s
//   slow   : rdata2 (the CPU / blitter read path) after the address was held for 6 cycles, 1024 sample addresses -> err_r
// act0 / act1 are the first two bytes the stream read (expected 5A, 5B).  After `done` the slow SRAM tester (kg_sram_test) reads the pattern back directly,
// which tells whether the WRITES through the wrapper arrived.
module kg_vram_test (
    input  wire        clk16,
    input  wire        go,
    output wire        run,
    output reg  [18:0] addr = 19'd0,
    output reg         wr_n = 1'b1,
    output reg  [7:0]  wdata = 8'd0,
    input  wire [7:0]  rdata1,
    input  wire [7:0]  rdata2,
    output reg         done = 1'b0,
    output reg  [15:0] err_s = 16'd0,
    output reg  [15:0] err_r = 16'd0,
    output reg  [7:0]  act0 = 8'd0, act1 = 8'd0
);
    reg running = 1'b0;
    assign run = (go & ~done) | running;
    localparam [14:0] NW = 15'd16384;
    function [18:0] amap(input [14:0] i);
        amap = (i < 15'd8192) ? {4'd0, i} : (19'h40000 + {4'd0, i - 15'd8192});
    endfunction
    function [7:0] fd(input [18:0] a);
        fd = a[7:0] ^ a[15:8] ^ 8'h5a;
    endfunction
    localparam S_IDLE = 4'd0, S_W0 = 4'd1, S_W1 = 4'd2, S_W2 = 4'd3, S_W3 = 4'd4, S_ST = 4'd5, S_ST_END = 4'd6, S_SL0 = 4'd7, S_SL1 = 4'd8, S_SL2 = 4'd9, S_FIN = 4'd10;
    reg [3:0]  st = S_IDLE;
    reg [14:0] i = 15'd0;
    reg [7:0]  e1 = 8'd0;
    reg        v1 = 1'b0;
    reg [2:0]  w = 3'd0;
    reg [1:0]  ncmp = 2'd0;
    always @(posedge clk16) begin
        case (st)
        S_IDLE: if (go && !done) begin running <= 1'b1; i <= 15'd0; st <= S_W0; end
        S_W0: begin addr <= amap(i); wdata <= fd(amap(i)); wr_n <= 1'b0; w <= 3'd0; st <= S_W1; end
        S_W1: begin w <= w + 3'd1; if (w == 3'd1) begin wr_n <= 1'b1; w <= 3'd0; st <= S_W2; end end
        S_W2: begin w <= w + 3'd1; if (w == 3'd1) st <= S_W3; end
        S_W3: begin if (i == NW - 15'd1) begin i <= 15'd0; v1 <= 1'b0; ncmp <= 2'd0; st <= S_ST; end else begin i <= i + 15'd1; st <= S_W0; end end
        S_ST: begin
            addr <= amap(i); e1 <= fd(amap(i)); v1 <= 1'b1;
            if (v1) begin
                if (rdata1 !== e1) err_s <= (err_s == 16'hffff) ? err_s : err_s + 16'd1;
                if (ncmp == 2'd0) begin act0 <= rdata1; ncmp <= 2'd1; end
                else if (ncmp == 2'd1) begin act1 <= rdata1; ncmp <= 2'd2; end
            end
            if (i == NW - 15'd1) begin i <= 15'd0; st <= S_ST_END; w <= 3'd0; end else i <= i + 15'd1;
        end
        S_ST_END: begin
            v1 <= 1'b0;
            if (v1 && rdata1 !== e1) err_s <= (err_s == 16'hffff) ? err_s : err_s + 16'd1;
            w <= w + 3'd1; if (w == 3'd3) begin i <= 15'd0; st <= S_SL0; end
        end
        S_SL0: begin addr <= amap({i[9:0], 4'd0} & 15'h3fff); w <= 3'd0; st <= S_SL1; end
        S_SL1: begin w <= w + 3'd1; if (w == 3'd5) st <= S_SL2; end
        S_SL2: begin
            if (rdata2 !== fd(addr)) err_r <= (err_r == 16'hffff) ? err_r : err_r + 16'd1;
            if (i == 15'd1023) st <= S_FIN; else begin i <= i + 15'd1; st <= S_SL0; end
        end
        S_FIN: begin done <= 1'b1; running <= 1'b0; end
        default: ;
        endcase
    end
endmodule
