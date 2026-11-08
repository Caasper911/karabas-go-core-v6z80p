`timescale 1ns / 1ps
// kg_osca_audio - OSCA's 1-bit audio outputs -> 16-bit PCM for the Karabas Go PCM5102 DAC.
// Boxcar average (count of ones over WINDOW clk16 cycles) = a ~48 kHz sample.  Simple first version:
// a better decimation filter (CIC) can replace it without touching anything else.
module kg_osca_audio #(parameter WINDOW = 333) (
    input  wire        clk,            // 16 MHz
    input  wire        pdm_l, pdm_r,   // audio_left / audio_right of the core
    output reg  [15:0] left  = 16'h0000,   // two's complement
    output reg  [15:0] right = 16'h0000
);
    reg [8:0]  cnt = 9'd0;
    reg [8:0]  acc_l = 9'd0, acc_r = 9'd0;
    wire [16:0] tl = (acc_l + pdm_l) * 17'd196;      // 333 * 196 = 65268 -> fits 16 bits
    wire [16:0] tr = (acc_r + pdm_r) * 17'd196;
    always @(posedge clk) begin
        if (cnt == WINDOW - 1) begin
            cnt   <= 9'd0;
            left  <= {~tl[15], tl[14:0]};            // unsigned 0..65268 -> signed (minus 32768)
            right <= {~tr[15], tr[14:0]};
            acc_l <= 9'd0; acc_r <= 9'd0;
        end else begin
            cnt   <= cnt + 9'd1;
            acc_l <= acc_l + pdm_l;
            acc_r <= acc_r + pdm_r;
        end
    end
endmodule
