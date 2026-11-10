`timescale 1ns / 1ps
// kg_sram_test - bring-up self test of the board's SRAM (two 2Mx8 chips: low byte MD[7:0] = chip 0, high byte MD[15:8] = chip 1) with slow,
// conservative cycles (write pulse 62 ns, read access 100 ns).  The pins are driven through kg_osca_mem's own IOB flip-flops (t_* ports).
//   data test   (both chips): walking one, walking zero, 00, FF at one address; every bit that ever reads wrong is set in dmask0 / dmask1
//   address test (chip 0)   : a different byte at address 0 and at each of the 21 single-bit addresses; every address line k whose byte
//                             does not read back (aliasing / stuck line) is set in amask[k]
// run is 1 from `go` until `done`; the core must be held in reset meanwhile.
module kg_sram_test (
    input  wire        clk,
    input  wire        go,
    output wire        run,
    output reg  [20:0] ma = 21'd0,
    output reg  [15:0] md = 16'd0,
    output reg         oe = 1'b0,
    output reg  [1:0]  wr_n = 2'b11,
    output reg  [1:0]  rd_n = 2'b11,
    input  wire [15:0] md_i,
    output reg         done = 1'b0,
    output reg  [7:0]  dmask0 = 8'd0,
    output reg  [7:0]  dmask1 = 8'd0,
    output reg  [20:0] amask = 21'd0,
    output reg         alias0 = 1'b0,        // address 0 itself did not read back
    // second job: after the video RAM test (which wrote a pattern through the wrapper) read it back directly with the slow cycles
    input  wire        vgo,
    output reg         vdone = 1'b0,
    output reg  [15:0] verr = 16'd0,
    output reg  [7:0]  vact0 = 8'd0, vact1 = 8'd0
);
    reg running = 1'b0;
    assign run = (go & ~done) | running | (vgo & ~vdone);

    // ---------------- one SRAM access (op 0 = write, op 1 = read)
    reg        req_t = 1'b0, ack_t = 1'b0, op = 1'b0, olane = 1'b0;      // request = toggle of req_t, acknowledged by copying it to ack_t
    wire       req = req_t ^ ack_t;
    reg [20:0] oaddr = 21'd0;
    reg [7:0]  odata = 8'd0;
    reg [7:0]  rres = 8'd0;
    reg        obusy = 1'b0;
    reg [3:0]  ost = 4'd0;
    reg [4:0]  oc = 5'd0;
    always @(posedge clk) begin
        case (ost)
        4'd0: if (req) begin
                ack_t <= req_t; obusy <= 1'b1; ma <= oaddr; oc <= 5'd0;
                if (!op) begin md <= {odata, odata}; oe <= 1'b1; wr_n <= 2'b11; rd_n <= 2'b11; ost <= 4'd1; end   // write
                else     begin oe <= 1'b0; wr_n <= 2'b11; rd_n <= 2'b11; ost <= 4'd5; end                        // read
              end
        // write: address / data setup 4 clocks, WE# low 6 clocks, hold 4 clocks
        4'd1: begin oc <= oc + 5'd1; if (oc == 5'd4) begin wr_n <= olane ? 2'b01 : 2'b10; oc <= 5'd0; ost <= 4'd2; end end
        4'd2: begin oc <= oc + 5'd1; if (oc == 5'd6) begin wr_n <= 2'b11; oc <= 5'd0; ost <= 4'd3; end end
        4'd3: begin oc <= oc + 5'd1; if (oc == 5'd4) begin oe <= 1'b0; obusy <= 1'b0; ost <= 4'd0; end end
        // read: address setup 4 clocks, OE# low 10 clocks, sample, release 4 clocks
        4'd5: begin oc <= oc + 5'd1; if (oc == 5'd4) begin rd_n <= olane ? 2'b01 : 2'b10; oc <= 5'd0; ost <= 4'd6; end end
        4'd6: begin oc <= oc + 5'd1; if (oc == 5'd10) begin rres <= olane ? md_i[15:8] : md_i[7:0]; rd_n <= 2'b11; oc <= 5'd0; ost <= 4'd3; end end
        default: ost <= 4'd0;
        endcase
    end

    // ---------------- test sequence
    localparam T_IDLE = 5'd0, T_DW = 5'd1, T_DWW = 5'd2, T_DR = 5'd3, T_DRW = 5'd4, T_DCMP = 5'd5,
               T_A0W = 5'd6, T_A0WW = 5'd7, T_AKW = 5'd8, T_AKWW = 5'd9, T_A0R = 5'd10, T_A0RW = 5'd11, T_A0C = 5'd12,
               T_AKR = 5'd13, T_AKRW = 5'd14, T_AKC = 5'd15, T_FIN = 5'd16, T_AZR = 5'd17, T_AZRW = 5'd18, T_AZC = 5'd19, T_AK0 = 5'd20, T_AK0W = 5'd21, T_Z0 = 5'd22, T_Z0W = 5'd23, T_VW = 5'd24, T_V0 = 5'd25, T_V0W = 5'd26, T_VC = 5'd27, T_FIN2 = 5'd28;
    reg [4:0] ts = T_IDLE;
    reg       lane = 1'b0;
    reg [4:0] di = 5'd0;                     // data pattern index 0..17
    reg [4:0] k = 5'd0;                      // address bit
    reg [9:0] vi = 10'd0;  reg [1:0] vn = 2'd0;
    wire [20:0] vaddr = (vi < 10'd512) ? {12'd0, vi[8:0]} : (21'h40000 + {12'd0, vi[8:0]});     // 512 addresses at 0.. and 512 at 40000.. (written through the wrapper by kg_vram_test)
    wire [7:0] vexp = vaddr[7:0] ^ vaddr[15:8] ^ 8'h5a;
    reg [20:0] zaddr = 21'd0;                // zero fill of the video RAM (0..7FFFF) and the sprite RAM (100000..11FFFF) after the tests: the RAM keeps the previous run's contents
    wire [7:0] dpat = (di < 5'd8) ? (8'd1 << di[2:0]) : (di < 5'd16) ? ~(8'd1 << di[2:0]) : (di == 5'd16) ? 8'h00 : 8'hff;
    localparam [20:0] ADATA_ADDR = 21'h01234;

    always @(posedge clk) begin
        if (go && !done && ts == T_IDLE) running <= 1'b1;
        case (ts)
        T_IDLE: if (go && !done) begin lane <= 1'b0; di <= 5'd0; ts <= T_DW; end
        // ---- data test of one chip
        T_DW:  begin op <= 1'b0; olane <= lane; oaddr <= ADATA_ADDR; odata <= dpat; req_t <= ~req_t; ts <= T_DWW; end
        T_DWW: if (!req && !obusy && ost == 4'd0) begin op <= 1'b1; req_t <= ~req_t; ts <= T_DR; end
        T_DR:  ts <= T_DRW;
        T_DRW: if (!req && !obusy && ost == 4'd0) ts <= T_DCMP;
        T_DCMP: begin
                   if (!lane) dmask0 <= dmask0 | (rres ^ dpat); else dmask1 <= dmask1 | (rres ^ dpat);
                   if (di == 5'd17) begin
                       if (!lane) begin lane <= 1'b1; di <= 5'd0; ts <= T_DW; end
                       else begin lane <= 1'b0; k <= 5'd0; ts <= T_A0W; end
                   end else begin di <= di + 5'd1; ts <= T_DW; end
                end
        // ---- address test of chip 0: byte 5A at address 0, byte C0|k at address 1<<k
        T_A0W:  begin op <= 1'b0; olane <= 1'b0; oaddr <= 21'd0; odata <= 8'h5a; req_t <= ~req_t; ts <= T_A0WW; end
        T_A0WW: if (!req && !obusy && ost == 4'd0) begin k <= 5'd0; ts <= T_AK0; end
        T_AK0:  begin op <= 1'b0; olane <= 1'b0; oaddr <= 21'd0; odata <= 8'h5a; req_t <= ~req_t; ts <= T_AK0W; end   // restore 5A at address 0 before every line
        T_AK0W: if (!req && !obusy && ost == 4'd0) ts <= T_AKW;
        T_AKW:  begin op <= 1'b0; olane <= 1'b0; oaddr <= 21'd1 << k; odata <= 8'hc0 | {3'd0, k}; req_t <= ~req_t; ts <= T_AKWW; end
        T_AKWW: if (!req && !obusy && ost == 4'd0) begin op <= 1'b1; olane <= 1'b0; oaddr <= 21'd0; req_t <= ~req_t; ts <= T_AZR; end   // read address 0 back at once: still 5A?
        T_AZR:  ts <= T_AZRW;
        T_AZRW: if (!req && !obusy && ost == 4'd0) ts <= T_AZC;
        T_AZC:  begin
                    if (rres != 8'h5a) amask <= amask | (21'd1 << k);                    // writing 1<<k changed address 0: line k is aliased
                    if (k == 5'd20) ts <= T_A0R; else begin k <= k + 5'd1; ts <= T_AK0; end
                end
        T_A0R:  begin op <= 1'b1; olane <= 1'b0; oaddr <= 21'd0; req_t <= ~req_t; ts <= T_A0RW; end
        T_A0RW: if (!req && !obusy && ost == 4'd0) ts <= T_A0C;
        T_A0C:  begin if (rres != 8'h5a) alias0 <= 1'b1; k <= 5'd0; ts <= T_AKR; end
        T_AKR:  begin op <= 1'b1; olane <= 1'b0; oaddr <= 21'd1 << k; req_t <= ~req_t; ts <= T_AKRW; end
        T_AKRW: if (!req && !obusy && ost == 4'd0) ts <= T_AKC;
        T_AKC:  begin
                    if (rres != (8'hc0 | {3'd0, k})) amask <= amask | (21'd1 << k);
                    if (k == 5'd20) begin zaddr <= 21'd0; ts <= T_Z0; end else begin k <= k + 5'd1; ts <= T_AKR; end
                end
        T_Z0:   begin op <= 1'b0; olane <= 1'b0; oaddr <= zaddr; odata <= 8'h00; req_t <= ~req_t; ts <= T_Z0W; end
        T_Z0W:  if (!req && !obusy && ost == 4'd0) begin
                    if (zaddr == 21'h7ffff) begin zaddr <= 21'h100000; ts <= T_Z0; end
                    else if (zaddr == 21'h11ffff) ts <= T_FIN;
                    else begin zaddr <= zaddr + 21'd1; ts <= T_Z0; end
                end
        T_FIN:  begin done <= 1'b1; running <= 1'b0; ts <= T_VW; end
        T_VW:   if (vgo && !vdone) begin vi <= 10'd0; vn <= 2'd0; ts <= T_V0; end
        T_V0:   begin op <= 1'b1; olane <= 1'b0; oaddr <= vaddr; req_t <= ~req_t; ts <= T_V0W; end
        T_V0W:  if (!req && !obusy && ost == 4'd0) ts <= T_VC;
        T_VC:   begin
                    if (rres != vexp) verr <= (verr == 16'hffff) ? verr : verr + 16'd1;
                    if (vn == 2'd0) begin vact0 <= rres; vn <= 2'd1; end else if (vn == 2'd1) begin vact1 <= rres; vn <= 2'd2; end
                    if (vi == 10'd1023) begin vdone <= 1'b1; ts <= T_FIN2; end else begin vi <= vi + 10'd1; ts <= T_V0; end
                end
        T_FIN2: ;
        default: ;
        endcase
    end
endmodule
