`timescale 1ns / 1ps
// Behavioural SDR SDRAM (MT48LC16M16A2-like, CAS 2, burst 1, auto-precharge), simulation only.  Only 512 KB are modelled
// (4 banks x 128 rows x 512 columns x 16 bit).  Checks tRCD >= 20 ns, tRC >= 63 ns, tRFC >= 63 ns and closed rows at REFRESH;
// counts violations and the largest gap between refreshes.
module tb_sdram_model (
    input  wire        clk,
    input  wire [1:0]  ba,
    input  wire [12:0] a,
    input  wire [1:0]  dqm,
    input  wire        ras_n, cas_n, we_n,
    inout  wire [15:0] dq
);
    reg [15:0] mem [0:262143];
    integer i; initial for (i = 0; i < 262144; i = i + 1) mem[i] = 16'h0000;
    reg        open_r [0:3];
    real       t_act [0:3];
    reg [12:0] rowsave [0:3];
    real       t_ref = -1000.0, t_lastref = -1.0, max_gap = 0.0, t_now;
    integer    viol = 0, n_read = 0, n_write = 0, n_ref = 0, n_act = 0, mode_ok = 0, b;
    reg [15:0] p1 = 0, p2 = 0, dq_drv = 0; reg v1 = 0, v2 = 0, dq_en = 0;
    assign dq = dq_en ? dq_drv : 16'bzzzzzzzzzzzzzzzz;
    wire [2:0] cmd = {ras_n, cas_n, we_n};
    initial for (b = 0; b < 4; b = b + 1) begin open_r[b] = 1'b0; t_act[b] = -1000.0; rowsave[b] = 13'd0; end

    task violation; input [255:0] what; begin viol = viol + 1; if (viol <= 8) $display("SDRAM VIOLATION %0t: %0s", $time, what); end endtask

    reg [17:0] ix;
    always @(posedge clk) begin
        t_now = $realtime;
        // read data pipeline: CAS latency 2 (data driven after the second edge following the command)
        p2 <= p1; v2 <= v1; v1 <= 1'b0;
        dq_drv <= p2; dq_en <= v2;
        if (cmd != 3'b111 && cmd != 3'b001 && (t_now - t_ref) < 63.0) violation("command inside tRFC");
        case (cmd)
        3'b011: begin                                   // ACTIVE
            if (open_r[ba]) violation("ACTIVE on an open bank");
            if ((t_now - t_act[ba]) < 63.0) violation("tRC (ACTIVE to ACTIVE, same bank)");
            open_r[ba] = 1'b1; t_act[ba] = t_now; rowsave[ba] = a; n_act = n_act + 1;
        end
        3'b101, 3'b100: begin                           // READ / WRITE
            if (!open_r[ba]) violation("READ/WRITE to a closed bank");
            if ((t_now - t_act[ba]) < 20.0) violation("tRCD");
            ix = {ba, rowsave[ba][6:0], a[8:0]};
            if (cmd == 3'b101) begin p1 <= mem[ix]; v1 <= 1'b1; n_read = n_read + 1; end
            else begin
                if (!dqm[0]) mem[ix][7:0]  = dq[7:0];
                if (!dqm[1]) mem[ix][15:8] = dq[15:8];
                n_write = n_write + 1;
                if (ix == {2'd3, 7'd16, 9'h14D}) $display("  MODEL WRITE t=%0t ix=%0h dqm=%b dq=%04h  now=%04h", $time, ix, dqm, dq, mem[ix]);
            end
            if (a[10]) open_r[ba] = 1'b0;               // auto precharge
        end
        3'b001: begin                                   // REFRESH
            for (b = 0; b < 4; b = b + 1) begin
                if (open_r[b]) violation("REFRESH with an open bank");
                if ((t_now - t_act[b]) < 63.0) violation("REFRESH too soon after ACTIVE (tRC)");
            end
            if (t_lastref > 0 && (t_now - t_lastref) > max_gap) max_gap = t_now - t_lastref;
            t_lastref = t_now; t_ref = t_now; n_ref = n_ref + 1;
        end
        3'b000: if (a[6:4] == 3'b010 && a[2:0] == 3'b000) mode_ok = 1;   // CAS 2, burst length 1
        default: ;
        endcase
    end
    task report; begin
        $display("SDRAM model: ACTIVE=%0d READ=%0d WRITE=%0d REFRESH=%0d  violations=%0d  max gap between refreshes=%0.0f ns  mode register ok=%0d",
                 n_act, n_read, n_write, n_ref, viol, max_gap, mode_ok);
    end endtask
endmodule
