`timescale 1ns / 1ps
// kg_tv80pa - simulation model of T80pa (t80pa/T80pa.vhd, the phase-accurate wrapper used on the board) built on tv80_core, the Verilog
// port of the same T80 core.  The bus process below is a line-by-line translation of T80pa.vhd: one Z80 clock = one CEN_p pulse (rising
// edge of the Z80 clock) and one CEN_n pulse (falling edge), both one tick wide on the fast clock.  Used only with -DKG_CPU_TV80PA
// (Verilator cannot simulate the VHDL); the board builds the real T80pa.  tv80_core gives one-hot mc / ts: mc[0] = M1, ts[k] = Tk.
module kg_tv80pa (
    input  wire        RESET_n,
    input  wire        CLK,
    input  wire        CEN_p,
    input  wire        CEN_n,
    input  wire        WAIT_n,
    input  wire        INT_n,
    input  wire        NMI_n,
    input  wire        BUSRQ_n,
    output wire        M1_n,
    output reg         MREQ_n = 1'b1,
    output reg         IORQ_n = 1'b1,
    output reg         RD_n = 1'b1,
    output reg         WR_n = 1'b1,
    output wire        RFSH_n,
    output wire        HALT_n,
    output wire        BUSAK_n,
    output wire [15:0] A,
    input  wire [7:0]  DI,
    output wire [7:0]  DO
);
    wire       iorq, no_read, write, busak, intcycle_n;
    wire [6:0] mc, ts;
    reg        cen_pol = 1'b0;
    reg        wait_s = 1'b1;
    reg  [7:0] di_reg = 8'h00;
    reg  [1:0] intcycled_n = 2'b11;
    wire       cen = CEN_p & ~cen_pol;
    assign BUSAK_n = busak;

    tv80_core #(.Mode(0), .IOWait(1)) i_tv80_core (      // same instance name as in tv80s: tb_boot.sv looks inside it
        .reset_n(RESET_n), .clk(CLK), .cen(cen), .wait_n(wait_s), .int_n(INT_n), .nmi_n(NMI_n), .busrq_n(BUSRQ_n),
        .m1_n(M1_n), .iorq(iorq), .no_read(no_read), .write(write), .rfsh_n(RFSH_n), .halt_n(HALT_n), .busak_n(busak),
        .A(A), .dinst(DI), .di(di_reg), .dout(DO), .mc(mc), .ts(ts), .intcycle_n(intcycle_n), .IntE(), .stop());

    always @(posedge CLK) begin
        if (!RESET_n) begin
            WR_n <= 1'b1; RD_n <= 1'b1; IORQ_n <= 1'b1; MREQ_n <= 1'b1; di_reg <= 8'h00; cen_pol <= 1'b0;
        end else if (CEN_p && !cen_pol) begin
            cen_pol <= 1'b1;
            if (wait_s || !ts[2]) begin
                if (mc[0]) begin
                    if (ts[2]) begin IORQ_n <= 1'b1; MREQ_n <= 1'b1; RD_n <= 1'b1; end
                end else begin
                    if (ts[1] && iorq) begin WR_n <= ~write; RD_n <= write; IORQ_n <= 1'b0; end
                end
            end
        end else if (CEN_n && cen_pol) begin
            wait_s  <= WAIT_n;
            cen_pol <= 1'b0;
            if (ts[3] && busak) di_reg <= DI;
            if (mc[0]) begin
                if (ts[1]) begin
                    intcycled_n <= {intcycled_n[0], intcycle_n};
                    RD_n <= ~intcycle_n; MREQ_n <= ~intcycle_n; IORQ_n <= intcycled_n[1];
                end
                if (ts[3]) begin intcycled_n <= 2'b11; RD_n <= 1'b1; MREQ_n <= 1'b0; end
                if (ts[4]) MREQ_n <= 1'b1;
            end else begin
                if (!no_read && !iorq) begin
                    if (ts[1]) begin RD_n <= write; MREQ_n <= 1'b0; end
                end
                if (ts[2]) WR_n <= ~write;
                if (ts[3]) begin WR_n <= 1'b1; RD_n <= 1'b1; IORQ_n <= 1'b1; MREQ_n <= 1'b1; end
            end
        end
    end
endmodule
