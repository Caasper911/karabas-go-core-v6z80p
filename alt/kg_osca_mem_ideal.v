`timescale 1ns / 1ps
// Ideal replacement for kg_osca_mem (simulation only): three independent asynchronous SRAMs with zero delay,
// exactly what the original board has.  Same ports and same clk16 generation as the real wrapper.
module kg_osca_mem #(parameter N = 6, parameter LAT = 2, parameter SLOT_VRAM = 1, parameter SLOT_SPR = 3, parameter SLOT_SYS = 5)(
    input  wire        clk_mem,
    output reg         clk16 = 1'b0,
    input  wire [18:0] vram_addr, input wire vram_wr_n, input wire [7:0] vram_wdata, output wire [7:0] vram_rdata,
    input  wire [16:0] spr_addr,  input wire spr_wr_n,  input wire [7:0] spr_wdata,  output wire [7:0] spr_rdata,
    input  wire [18:0] sys_addr,  input wire sys_cs_n,  input wire sys_wr_n, input wire [7:0] sys_wdata, output wire [7:0] sys_rdata,
    output wire [20:0] ma, output wire [15:0] md_o, output wire md_oe, input wire [15:0] md_i, output wire [1:0] mwr_n, output wire [1:0] mrd_n
);
    reg [2:0] tick = 3'd0;
    wire [2:0] tick_n = (tick == N-1) ? 3'd0 : tick + 3'd1;
    always @(posedge clk_mem) begin tick <= tick_n; clk16 <= (tick_n < N/2); end

    reg [7:0] vmem [0:524287];
    reg [7:0] smem [0:131071];
    reg [7:0] ymem [0:524287];
    integer i;
    initial begin
        for (i = 0; i < 524288; i = i + 1) begin vmem[i] = 8'h00; ymem[i] = 8'h00; end
        for (i = 0; i < 131072; i = i + 1) smem[i] = 8'h00;
    end
    assign vram_rdata = vmem[vram_addr];
    assign spr_rdata  = smem[spr_addr];
    assign sys_rdata  = ymem[sys_addr];
    always @(posedge clk_mem) begin
        if (!vram_wr_n)                 vmem[vram_addr] <= vram_wdata;
        if (!spr_wr_n)                  smem[spr_addr]  <= spr_wdata;
        if (!sys_cs_n && !sys_wr_n)     ymem[sys_addr]  <= sys_wdata;
    end
    assign ma = 21'h0; assign md_o = 16'h0; assign md_oe = 1'b0; assign mwr_n = 2'b11; assign mrd_n = 2'b11;
endmodule
