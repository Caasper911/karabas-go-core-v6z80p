`timescale 1ns / 1ps
// System RAM model (simulation only): stand-in for the future SDRAM controller.
// Read data can be delayed at run time (clk_mem ticks, 96 MHz):  +sysdy=N for the CPU,  +dmady=N for cycles owned by the FPGA (DMA).
module kg_sysram_model (
    input  wire        clk,
    input  wire [18:0] addr,
    input  wire        cs_n, wr_n,
    input  wire [7:0]  wdata,
    input  wire        dma,            // 1 while the FPGA owns the bus (audio / line copper DMA)
    output wire [7:0]  rdata
);
    reg [7:0] mem [0:524287];
    integer i; initial for (i = 0; i < 524288; i = i + 1) mem[i] = 8'h00;
    reg [7:0] tap [1:31];
    integer dyv = 0, ddv = 0; reg [4:0] dy = 5'd0, dd = 5'd0;
    initial begin
        if ($value$plusargs("sysdy=%d", dyv)) dy = dyv[4:0];
        if ($value$plusargs("dmady=%d", ddv)) dd = ddv[4:0];
    end
    integer k;
    always @(posedge clk) begin
        tap[1] <= mem[addr];
        for (k = 2; k < 32; k = k + 1) tap[k] <= tap[k-1];
        if (!cs_n && !wr_n) mem[addr] <= wdata;
    end
    wire [4:0] d = dma ? dd : dy;
    assign rdata = (d == 5'd0) ? mem[addr] : tap[d];
endmodule
