`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// kg_osca_ps2dev - PS/2 keyboard *device* emulator for OSCA on Karabas Go
//
// The Karabas Go MCU turns USB keyboards into PS/2 set-2 scan codes (kg_mcu: KB_SCANCODE /
// KB_SCANCODE_UPD).  OSCA expects a real PS/2 keyboard on two open-drain lines, so this module
//   - queues the scan code bytes (16-deep FIFO) and clocks them out as 11-bit PS/2 frames
//     (start, 8 data LSB first, odd parity, stop), device-generated clock ~15.6 kHz;
//   - honours host inhibit (clock held low) and aborts/retries a frame that the host interrupts;
//   - receives host commands (clock low >= 60 us, data low, clock released) and ACKs them;
//     replies: FF -> FA AA,  F2 -> FA AB 83,  EE -> EE,  ED / F3 -> FA then FA for the parameter,
//     everything else -> FA.
//
// Lines are open drain: *_pull = 1 means "this side holds the line low".
// clk_line / data_line are the resolved line levels (feed ps2_kb_clock_in / ps2_kb_data_in).
//
// clk must be the 16 MHz OSCA clock (TQ = clocks per quarter bit; 256 -> 64 us per bit).
//////////////////////////////////////////////////////////////////////////////////
module kg_osca_ps2dev #(
    parameter TQ = 256
)(
    input  wire       clk,
    input  wire [7:0] scan_in,        // PS/2 set-2 byte from the MCU
    input  wire       scan_stb,
    input  wire       host_clk_pull,  // = ps2_kb_clock_out of the core
    input  wire       host_data_pull, // = ps2_kb_data_out of the core
    output wire       clk_line,
    output wire       data_line
);
    localparam TH = 2 * TQ;
    localparam INH_MIN = 4 * TQ;      // 64 us at TQ = 256 (spec says >= 100 us; we are lenient)

    reg dclk_pull = 1'b0, ddata_pull = 1'b0;
    assign clk_line  = ~(host_clk_pull  | dclk_pull);
    assign data_line = ~(host_data_pull | ddata_pull);

    // ---------------------------------------------------------------- FIFO
    reg [7:0] fifo [0:15];
    reg [4:0] wp = 5'd0, rp = 5'd0;
    wire      empty = (wp == rp);
    wire      full  = ((wp - rp) == 5'd16);
    reg       push = 1'b0;
    reg [7:0] push_d = 8'h00;
    reg       hold_v = 1'b0;          // MCU byte that arrived while a response was being pushed
    reg [7:0] hold_d = 8'h00;
    reg       pop = 1'b0;

    always @(posedge clk) begin
        if (push && !full) begin fifo[wp[3:0]] <= push_d; wp <= wp + 5'd1; end
        if (pop && !empty) rp <= rp + 5'd1;
    end

    // ---------------------------------------------------------------- response queue (up to 3 bytes)
    reg [1:0] rsp_n = 2'd0;
    reg [7:0] rsp0 = 8'h00, rsp1 = 8'h00, rsp2 = 8'h00;
    reg       expect_param = 1'b0;
    reg       rsp_start = 1'b0;
    reg [7:0] cmd = 8'h00;

    // ---------------------------------------------------------------- main state machine
    localparam S_IDLE = 4'd0, S_TXA = 4'd1, S_TXL = 4'd2, S_TXH = 4'd3,
               S_RXL = 4'd4, S_RXH = 4'd5, S_ACKL = 4'd6, S_ACKH = 4'd7, S_CMD = 4'd8;
    reg [3:0]  st = S_IDLE;
    reg [15:0] cnt = 16'd0;
    reg [15:0] idle_cnt = 16'd0, inh_cnt = 16'd0;
    reg        armed = 1'b0;
    reg        host_clk_q = 1'b0;
    reg [10:0] frame = 11'h7FF;
    reg [3:0]  bit_n = 4'd0;
    reg [7:0]  rx_sr = 8'h00;
    reg [7:0]  tx_byte = 8'h00;

    always @(posedge clk) begin
        push <= 1'b0;
        pop  <= 1'b0;
        host_clk_q <= host_clk_pull;

        // bytes from the MCU / queued responses share the single FIFO write port
        if (rsp_n != 2'd0) begin
            push   <= 1'b1;
            push_d <= rsp0;
            rsp0   <= rsp1;
            rsp1   <= rsp2;
            rsp_n  <= rsp_n - 2'd1;
            if (scan_stb) begin hold_v <= 1'b1; hold_d <= scan_in; end
        end
        else if (hold_v) begin
            push <= 1'b1; push_d <= hold_d; hold_v <= 1'b0;
            if (scan_stb) begin hold_v <= 1'b1; hold_d <= scan_in; end
        end
        else if (scan_stb) begin
            push <= 1'b1; push_d <= scan_in;
        end

        case (st)
        S_IDLE: begin
            // line idle time and host request-to-send detection
            if (!clk_line || !data_line) idle_cnt <= 16'd0;
            else if (idle_cnt != 16'hFFFF) idle_cnt <= idle_cnt + 16'd1;

            if (host_clk_pull) begin
                if (inh_cnt != 16'hFFFF) inh_cnt <= inh_cnt + 16'd1;
                if (inh_cnt >= INH_MIN) armed <= 1'b1;
            end
            else inh_cnt <= 16'd0;

            if (host_clk_q && !host_clk_pull) begin           // host just released the clock
                if (armed && host_data_pull) begin
                    st <= S_RXL; bit_n <= 4'd0; cnt <= TH; dclk_pull <= 1'b1;
                end
                armed <= 1'b0;
            end
            else if (!empty && !host_clk_pull && !host_data_pull && idle_cnt >= 5 * TQ) begin
                tx_byte <= fifo[rp[3:0]];
                frame   <= {1'b1, ~(^fifo[rp[3:0]]), fifo[rp[3:0]], 1'b0};
                bit_n   <= 4'd0;
                st      <= S_TXA;
                cnt     <= TQ;
                ddata_pull <= 1'b1;                             // start bit = 0 (line pulled low)
            end
        end

        // ---- device -> host
        S_TXA: begin                                           // data stable, clock still high
            if (host_clk_pull) begin ddata_pull <= 1'b0; st <= S_IDLE; idle_cnt <= 16'd0; end
            else if (cnt == 16'd1) begin dclk_pull <= 1'b1; cnt <= TH; st <= S_TXL; end
            else cnt <= cnt - 16'd1;
        end
        S_TXL: begin                                           // clock low
            if (cnt == 16'd1) begin dclk_pull <= 1'b0; cnt <= TQ; st <= S_TXH; end
            else cnt <= cnt - 16'd1;
        end
        S_TXH: begin                                           // clock high again
            if (!clk_line && !dclk_pull) begin                 // host pulled the clock: abort, retry later
                ddata_pull <= 1'b0; st <= S_IDLE; idle_cnt <= 16'd0;
            end
            else if (cnt == 16'd1) begin
                if (bit_n == 4'd10) begin
                    ddata_pull <= 1'b0; pop <= 1'b1; st <= S_IDLE; idle_cnt <= 16'd0;
                end
                else begin
                    bit_n   <= bit_n + 4'd1;
                    frame   <= {1'b1, frame[10:1]};
                    ddata_pull <= ~frame[1];                   // next bit (frame is shifted next cycle)
                    cnt     <= TQ; st <= S_TXA;
                end
            end
            else cnt <= cnt - 16'd1;
        end

        // ---- host -> device: 8 data + parity + stop clocked in on the rising clock edge
        S_RXL: begin
            if (cnt == 16'd1) begin
                dclk_pull <= 1'b0;                              // rising edge: sample
                if (bit_n < 4'd8) rx_sr <= {data_line, rx_sr[7:1]};
                cnt <= TH; st <= S_RXH;
            end
            else cnt <= cnt - 16'd1;
        end
        S_RXH: begin
            if (cnt == 16'd1) begin
                if (bit_n == 4'd9) begin                        // stop bit was the last clock: ACK
                    ddata_pull <= 1'b1; dclk_pull <= 1'b1; cnt <= TH; st <= S_ACKL;
                end
                else begin bit_n <= bit_n + 4'd1; dclk_pull <= 1'b1; cnt <= TH; st <= S_RXL; end
            end
            else cnt <= cnt - 16'd1;
        end
        S_ACKL: begin
            if (cnt == 16'd1) begin dclk_pull <= 1'b0; cnt <= TQ; st <= S_ACKH; end
            else cnt <= cnt - 16'd1;
        end
        S_ACKH: begin
            if (cnt == 16'd1) begin
                ddata_pull <= 1'b0; cmd <= rx_sr; st <= S_CMD;
            end
            else cnt <= cnt - 16'd1;
        end
        S_CMD: begin
            st <= S_IDLE; idle_cnt <= 16'd0;
            if (expect_param) begin
                expect_param <= 1'b0; rsp0 <= 8'hFA; rsp_n <= 2'd1;
            end
            else case (cmd)
                8'hFF:   begin rsp0 <= 8'hFA; rsp1 <= 8'hAA; rsp_n <= 2'd2; end
                8'hF2:   begin rsp0 <= 8'hFA; rsp1 <= 8'hAB; rsp2 <= 8'h83; rsp_n <= 2'd3; end
                8'hEE:   begin rsp0 <= 8'hEE; rsp_n <= 2'd1; end
                8'hED,
                8'hF3:   begin rsp0 <= 8'hFA; rsp_n <= 2'd1; expect_param <= 1'b1; end
                default: begin rsp0 <= 8'hFA; rsp_n <= 2'd1; end
            endcase
        end
        default: st <= S_IDLE;
        endcase
    end
endmodule
