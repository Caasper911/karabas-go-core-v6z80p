`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// kg_osca_cpu - soft Z80 + shared-bus arbiter for OSCA on Karabas Go
//
// On V6Z80P+ the Z80, the system RAM and the FPGA share one bus.  When BUSACK# is high the
// Z80 owns the bus and the FPGA only listens; when the FPGA has requested the bus (audio /
// line-copper DMA) BUSACK# is low, the Z80 floats and the FPGA drives address, MREQ#=1,
// IORQ#=1, WR#=1, RD#=0 and reads data straight from the system RAM.
// Here there are no tri-states: this module resolves that bus into plain signals.
//
//   clk      = the 16 MHz OSCA clock (same clock as the core, so all T80 outputs are synchronous)
//   fpga_*   = what the core drives while it owns the bus (osca_core z80_*_o ports)
//   *_bus    = the resolved bus, to be fed back into the core (z80_*_i) and the RAM wrapper
//   ram_d    = system RAM read data (kg_osca_mem sys_rdata);  ram_cs_n = system_ram_cs
//
// The real board has pull-downs on the data bus, so an undriven bus reads 8'h00.
// The CPU write data is held for one more cycle after WR# rises: several OSCA registers
// are clocked by the (combinational) write strobe and need data that is stable past its edge.
//////////////////////////////////////////////////////////////////////////////////
module kg_osca_cpu (
    input  wire        clk,
    input  wire        clk_fast,     // 96 MHz: used to delay the falling edge of WR# (see below)
    input  wire        clk16_raw,    // the 16 MHz clock as a plain register output in the 96 MHz domain (phases of the Z80 clock for T80pa)
    input  wire        reset_n,      // system_reset_out
    input  wire        wait_n,       // z80_wait
    input  wire        ext_wait_n,   // extra wait (SDRAM not ready)
    input  wire        int_n,        // z80_int
    input  wire        nmi_n,        // z80_nmi
    input  wire        busrq_n,      // z80_busreq
    output wire        busak_n,      // -> z80_busack
    output wire        m1_n,         // -> z80_m1

    input  wire [15:0] fpga_a,       // z80_addr_o
    input  wire        fpga_mreq_n, fpga_iorq_n, fpga_rd_n, fpga_wr_n,
    input  wire [7:0]  fpga_d,       // z80_data_o
    input  wire        fpga_d_oe,    // z80_data_oe
    input  wire [7:0]  ram_d,
    input  wire        ram_cs_n,

    output wire [15:0] a_bus,
    output wire        mreq_n_bus, iorq_n_bus, rd_n_bus, wr_n_bus,
    output wire [7:0]  d_bus
);
    wire        cpu_wait_n = wait_n & ext_wait_n;
    wire [15:0] cpu_a;
    wire [7:0]  cpu_do;
    wire        cpu_mreq_n, cpu_iorq_n, cpu_rd_n, cpu_wr_n, cpu_rfsh_n, cpu_halt_n;

`ifdef KG_CPU_T80PA
    // T80pa (VHDL, from the t80se set of the Karabas Go cores): runs on the 96 MHz clock; CEN_p / CEN_n mark the rising / falling edge of the 16 MHz Z80 clock.  Its outputs (MREQ#, RD#,
    // WR#, IORQ#, the address, the data) come out with the phase relations of a real Z80, WAIT# is sampled at the falling edge, the data is latched in the middle of T3.
    reg c16_d = 1'b0;
    always @(posedge clk_fast) c16_d <= clk16_raw;
    wire cen_p = clk16_raw & ~c16_d;
    wire cen_n = ~clk16_raw & c16_d;
`ifdef KG_T80PA_GHDL
    T80pa u_z80 (          // the Verilog translation made by ghdl --synth has Mode = 0 built in
`else
    T80pa #(.Mode(0)) u_z80 (
`endif
        .RESET_n(reset_n), .CLK(clk_fast), .CEN_p(cen_p), .CEN_n(cen_n), .WAIT_n(cpu_wait_n), .INT_n(int_n), .NMI_n(nmi_n), .BUSRQ_n(busrq_n), .OUT0(1'b0),
        .DI(d_bus), .R800_mode(1'b0), .DIRSet(1'b0), .DIR(212'd0),
        .M1_n(m1_n), .MREQ_n(cpu_mreq_n), .IORQ_n(cpu_iorq_n), .RD_n(cpu_rd_n), .WR_n(cpu_wr_n), .RFSH_n(cpu_rfsh_n), .HALT_n(cpu_halt_n), .BUSAK_n(busak_n),
        .A(cpu_a), .DO(cpu_do), .REG());
`elsif KG_CPU_AZ80
    // A-Z80 (az80/): outputs with the phase relations of a real Z80 (WR# falls half a clock after MREQ# / the address), so the delay of WR# below is not used
    kg_az80 u_z80 (
        .clk(clk), .reset_n(reset_n), .wait_n(cpu_wait_n), .int_n(int_n), .nmi_n(nmi_n), .busrq_n(busrq_n),
        .m1_n(m1_n), .mreq_n(cpu_mreq_n), .iorq_n(cpu_iorq_n), .rd_n(cpu_rd_n), .wr_n(cpu_wr_n),
        .rfsh_n(cpu_rfsh_n), .halt_n(cpu_halt_n), .busak_n(busak_n), .a(cpu_a), .di(d_bus), .dout(cpu_do));
`elsif KG_CPU_T80S_SYNTH
    // the board's T80s (VHDL), translated to Verilog by `ghdl --synth --out=verilog` (build/t80/t80s_synth.v): simulation with the real CPU
    T80s u_z80 (
        .RESET_n(reset_n), .CLK(clk), .CEN(1'b1), .WAIT_n(cpu_wait_n), .INT_n(int_n), .NMI_n(nmi_n), .BUSRQ_n(busrq_n),
        .M1_n(m1_n), .MREQ_n(cpu_mreq_n), .IORQ_n(cpu_iorq_n), .RD_n(cpu_rd_n), .WR_n(cpu_wr_n),
        .RFSH_n(cpu_rfsh_n), .HALT_n(cpu_halt_n), .BUSAK_n(busak_n), .OUT0(1'b0),
        .A(cpu_a), .DI(d_bus), .DO(cpu_do));
`elsif KG_CPU_T80S
    // Daniel Wallner's T80s (VHDL, t80/): NOT used any more.  In simulation (ghdl --synth) it did not run FLOS with this bus, while the tv80 below does (11/11 regression).
    T80s #(.Mode(0), .T2Write(1), .IOWait(1)) u_z80 (
        .RESET_n(reset_n), .CLK(clk), .CEN(1'b1), .WAIT_n(cpu_wait_n), .INT_n(int_n), .NMI_n(nmi_n), .BUSRQ_n(busrq_n),
        .M1_n(m1_n), .MREQ_n(cpu_mreq_n), .IORQ_n(cpu_iorq_n), .RD_n(cpu_rd_n), .WR_n(cpu_wr_n),
        .RFSH_n(cpu_rfsh_n), .HALT_n(cpu_halt_n), .BUSAK_n(busak_n), .OUT0(1'b0),
        .A(cpu_a), .DI(d_bus), .DO(cpu_do));
`else
    // Verilog port of T80 (tv80/): the CPU of the simulation AND of the board (build with TV80_REFRESH defined, see ise/osca676p.xst) so that refresh cycles assert MREQ#
    // like the real Z80 does.
    tv80s #(.Mode(0), .T2Write(1), .IOWait(1)) u_z80 (
        .reset_n(reset_n), .clk(clk), .wait_n(cpu_wait_n), .int_n(int_n), .nmi_n(nmi_n), .busrq_n(busrq_n),
        .m1_n(m1_n), .mreq_n(cpu_mreq_n), .iorq_n(cpu_iorq_n), .rd_n(cpu_rd_n), .wr_n(cpu_wr_n),
        .rfsh_n(cpu_rfsh_n), .halt_n(cpu_halt_n), .busak_n(busak_n),
        .A(cpu_a), .di(d_bus), .dout(cpu_do));
`endif

    wire cpu_owns = busak_n;                       // BUSACK# high = the Z80 has the bus

    // A real Z80 changes its outputs some tens of ns AFTER the clock edge.  OSCA relies on it: many registers are clocked by the
    // write strobe delayed by one cycle (delayed_cpu_wr) and still expect the OLD address / data at that edge.  T80 changes
    // everything on the clock edge itself, so the outputs are staged through falling-edge registers (half a cycle later).
`ifdef KG_CPU_T80PA
    // no staging: T80pa already gives the phases of a real Z80
    wire [15:0] cpu_a_q = cpu_a;  wire [7:0] cpu_do_q = cpu_do;
    wire cpu_mreq_q = cpu_mreq_n, cpu_iorq_q = cpu_iorq_n, cpu_rd_q = cpu_rd_n, cpu_wr_q = cpu_wr_n;
    assign a_bus      = cpu_owns ? cpu_a_q      : fpga_a;
    assign mreq_n_bus = cpu_owns ? cpu_mreq_q   : fpga_mreq_n;
    assign iorq_n_bus = cpu_owns ? cpu_iorq_q   : fpga_iorq_n;
    assign rd_n_bus   = cpu_owns ? cpu_rd_q     : fpga_rd_n;
    assign wr_n_bus   = cpu_owns ? cpu_wr_q     : fpga_wr_n;
`else
    reg [15:0] cpu_a_q    = 16'h0000;
    reg [7:0]  cpu_do_q   = 8'h00;
    reg        cpu_mreq_q = 1'b1, cpu_iorq_q = 1'b1, cpu_rd_q = 1'b1, cpu_wr_q = 1'b1;
    always @(negedge clk) begin
        cpu_a_q <= cpu_a; cpu_do_q <= cpu_do;
        cpu_mreq_q <= cpu_mreq_n; cpu_iorq_q <= cpu_iorq_n; cpu_rd_q <= cpu_rd_n; cpu_wr_q <= cpu_wr_n;
    end
    // MREQ# / IORQ# are released half a cycle after WR# / RD# (the sprite register RAM is clocked by the write strobe and its
    // select includes MREQ#)
    reg mreq_hold_n = 1'b1, iorq_hold_n = 1'b1;
    always @(posedge clk) begin mreq_hold_n <= cpu_mreq_q; iorq_hold_n <= cpu_iorq_q; end

    // A real Z80 keeps the address valid for a while AFTER WR# goes inactive.  Many OSCA registers (video registers, sound, blitter, palette...) are clocked by the
    // inverted write strobe, i.e. they capture at the END of the write, and their select is decoded from the address.  Here the strobe and the (next cycle's) address
    // change at the same falling-edge register stage, and the clock of such a register arrives a few ns later than the address on the FPGA: it sees the NEW address.
    // So the address of the write is held for half a clock after the write has ended.
    reg [15:0] a_wr_q = 16'h0000;          // address during the write (sampled while WR# is low)
    reg        we_set = 1'b0, we_clr = 1'b0;
    always @(posedge clk) begin
        if (!cpu_wr_q) a_wr_q <= cpu_a_q;
        we_clr <= we_set;
    end
    always @(negedge clk) if (!cpu_wr_q && cpu_wr_n) we_set <= ~we_set;     // the write has just ended (cpu_wr_q is the old value, cpu_wr_n the new one)
    wire wr_end_hold = (we_set != we_clr);
    assign a_bus      = cpu_owns ? (wr_end_hold ? a_wr_q : cpu_a_q)  : fpga_a;
    assign mreq_n_bus = cpu_owns ? (cpu_mreq_q & mreq_hold_n)       : fpga_mreq_n;
    assign iorq_n_bus = cpu_owns ? (cpu_iorq_q & iorq_hold_n)       : fpga_iorq_n;
    assign rd_n_bus   = cpu_owns ? cpu_rd_q                         : fpga_rd_n;
    // A real Z80 lowers WR# half a clock AFTER the address, MREQ# / IORQ# and the data are valid (and OSCA's registers, clocked by the write strobe, rely on their select /
    // data being stable BEFORE that edge).  T80 changes everything at the same clock edge, and the falling-edge stage above keeps it that way, so on the FPGA the decode of the
    // select (a few LUTs) races against the clock edge that comes through the inversion of cpu_write, and the registers stay unwritten.  The falling edge of WR# is delayed
    // by two ticks of the 96 MHz clock (21 ns); the rising edge is not delayed.
    reg wr_d1 = 1'b1, wr_d2 = 1'b1;
    always @(posedge clk_fast) begin wr_d1 <= cpu_wr_q; wr_d2 <= wr_d1; end
`ifdef KG_CPU_AZ80
    wire cpu_wr_late = cpu_wr_q;
`else
    wire cpu_wr_late = cpu_wr_q | wr_d2;
`endif
    assign wr_n_bus   = cpu_owns ? cpu_wr_late                      : fpga_wr_n;

`endif

    // ---- data bus: FPGA (register reads) > CPU (writes) > RAM (reads, only while selected) > pull-down
    reg [7:0] do_q  = 8'h00;
    reg       lastw = 1'b0;
    always @(posedge clk) begin
        if (cpu_owns && !cpu_wr_q) do_q <= cpu_do_q;
        if (cpu_owns && !cpu_wr_q) lastw <= 1'b1;
        else if (!rd_n_bus || !cpu_owns) lastw <= 1'b0;
    end
    wire wr_now = cpu_owns && !cpu_wr_q;
    wire ram_oe = !ram_cs_n && !rd_n_bus;

    assign d_bus = fpga_d_oe           ? fpga_d :
                   wr_now              ? cpu_do_q :
                   (lastw && rd_n_bus) ? do_q   :
                   ram_oe              ? ram_d  : 8'h00;
endmodule
