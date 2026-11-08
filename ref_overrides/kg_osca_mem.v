`timescale 1ns / 1ps
// Ideal zero-delay replacement for kg_osca_mem v2 (simulation only): independent asynchronous video and sprite RAMs.
module kg_osca_mem #(parameter N = 6, parameter LAT = 2, parameter SLOT_A = 1, parameter SLOT_B = 3, parameter SLOT_C = 5)(
    input  wire        clk_mem,
    output reg         clk16 = 1'b0,
    input  wire [18:0] vram_addr, input wire vram_wr_n, input wire [7:0] vram_wdata,
    output wire [7:0]  vram_rdata1, output wire [7:0] vram_rdata2,
    input  wire [16:0] spr_addr,  input wire spr_wr_n,  input wire [7:0] spr_wdata, output wire [7:0] spr_rdata,
    output wire [20:0] ma, output wire [15:0] md_o, output wire md_oe, input wire [15:0] md_i, output wire [1:0] mwr_n, output wire [1:0] mrd_n
);
    reg [2:0] tick = 3'd0;
    wire [2:0] tick_n = (tick == N-1) ? 3'd0 : tick + 3'd1;
    always @(posedge clk_mem) begin tick <= tick_n; clk16 <= (tick_n < N/2); end
    reg [7:0] vmem [0:524287];
    reg [7:0] smem [0:131071];
    integer i;
    initial begin for (i = 0; i < 524288; i = i + 1) vmem[i] = 8'h00; for (i = 0; i < 131072; i = i + 1) smem[i] = 8'h00; end
    assign vram_rdata1 = vmem[vram_addr];
    assign vram_rdata2 = vmem[vram_addr];
    assign spr_rdata   = smem[spr_addr];
    always @(posedge clk_mem) begin
        if (!vram_wr_n) vmem[vram_addr] <= vram_wdata;
        if (!spr_wr_n)  smem[spr_addr]  <= spr_wdata;
    end
    assign ma = 21'h0; assign md_o = 16'h0; assign md_oe = 1'b0; assign mwr_n = 2'b11; assign mrd_n = 2'b11;
endmodule
