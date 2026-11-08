`timescale 1ns / 1ps
// kg_az80 - adapter of the A-Z80 core (Goran Devic, az80/, GPL) to the interface of kg_osca_cpu: separate data in / out, plain outputs.
// A-Z80 has a bidirectional data bus D.  It drives D itself while it writes; while it reads (RD# low) or acknowledges an interrupt (M1# and IORQ# low) this adapter drives D with di.
module kg_az80 (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        wait_n, int_n, nmi_n, busrq_n,
    output wire        m1_n, mreq_n, iorq_n, rd_n, wr_n, rfsh_n, halt_n, busak_n,
    output wire [15:0] a,
    input  wire [7:0]  di,
    output wire [7:0]  dout
);
    wire [7:0] D;
    wire       rd_phase = ~rd_n | (~iorq_n & ~m1_n);
    assign D = rd_phase ? di : 8'bz;
    z80_top_direct_n u_az80 (
        .nM1(m1_n), .nMREQ(mreq_n), .nIORQ(iorq_n), .nRD(rd_n), .nWR(wr_n), .nRFSH(rfsh_n), .nHALT(halt_n), .nBUSACK(busak_n),
        .nWAIT(wait_n), .nINT(int_n), .nNMI(nmi_n), .nRESET(reset_n), .nBUSRQ(busrq_n),
        .CLK(clk), .A(a), .D(D));
    assign dout = D;
endmodule
