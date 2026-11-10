`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// kg_osca_eeprom - emulates the V6Z80P+ config PIC + its EEPROM for the OSCA boot ROM
//
// The OSCA boot ROM (rom_617) and bootcode (bootcode_618) read the "EEPROM" through a PIC with a
// home-made serial protocol (see OSCA/ROM/rom_617.asm):
//   FPGA -> PIC : data bit on pic_link_rb1, clock on pic_link_ra5, MSB first, PIC samples on the rising edge
//                 each command is  $88, cmd, p0, p1, p2
//                    $88 $D4 a0 a1 a2   set EEPROM address (24 bit)
//                    $88 $E2 l0 l1 l2   set transfer length
//                    $88 $C9            begin transfer
//   PIC -> FPGA : after "begin transfer" every rising edge of ra5 prompts one byte: the PIC puts 8 bits on
//                 eeprom_data_in (MSB first) and clocks them into the FPGA with pic_link_rb7.  After
//                 `length` bytes the PIC is back in command mode.  A command that stalls for > 300 us is dropped.
//
// The image (64 KB, EEPROM addresses $0000-$FFFF, 0xFF = empty) lives in a block RAM that the Karabas Go MCU
// fills through its ROM loader (kg_mcu ROMLOAD_*, file offset = EEPROM address):
//   $0800  FLOS operating system file (*.OSF, header "Z80P*OS*")
//   $F000  bootcode (bootcode.epr, 3520 bytes incl. CRC)
// Everything the boot flow needs is therefore in ONE file on the SD card.
// Other PIC commands (EEPROM writes, reconfiguration, ...) are ignored.
//////////////////////////////////////////////////////////////////////////////////
module kg_osca_eeprom #(
    parameter BIT_CLKS = 16            // clk cycles per transferred bit (16 -> 1 us at 16 MHz)
)(
    input  wire        clk,            // 16 MHz OSCA clock
    input  wire        pic_data_i,     // pic_link_rb1
    input  wire        pic_clk_i,      // pic_link_ra5
    output reg         eeprom_data_o = 1'b1,   // -> eeprom_data_in
    output reg         pic_clk_o     = 1'b0,   // -> pic_link_rb7

    input  wire        clk_ld,         // MCU loader clock
    input  wire [31:0] ld_addr,
    input  wire [7:0]  ld_data,
    input  wire        ld_wr
);
    // ---------------------------------------------------------------- image RAM (dual clock)
    reg [7:0] img [0:65535];
    reg [7:0] img_q = 8'hFF;
    reg [15:0] ra = 16'h0000;
`ifdef KG_SIM
    initial $readmemh("eeprom_image.hex", img);
`endif
    always @(posedge clk_ld) if (ld_wr && ld_addr[31:16] == 16'h0000) img[ld_addr[15:0]] <= ld_data;
    always @(posedge clk) img_q <= img[ra];

    // ---------------------------------------------------------------- input synchronisers
    reg [2:0] ck_s = 3'b000;
    reg [1:0] dt_s = 2'b00;
    always @(posedge clk) begin ck_s <= {ck_s[1:0], pic_clk_i}; dt_s <= {dt_s[0], pic_data_i}; end
    wire ck_rise = ck_s[1] & ~ck_s[2];

    // ---------------------------------------------------------------- command / transfer state machine
    localparam M_SYNC = 3'd0, M_CMD = 3'd1, M_ARG = 3'd2, M_STREAM = 3'd3, M_SEND = 3'd4;
    reg [2:0]  mode = M_SYNC;
    reg [7:0]  sh = 8'h00;
    reg [3:0]  nbit = 4'd0;
    reg [7:0]  cmd = 8'h00;
    reg [1:0]  argn = 2'd0;
    reg [23:0] addr = 24'h000000, len = 24'h000000, arg = 24'h000000;
    reg [15:0] idle = 16'd0;

    // byte output engine
    reg [7:0]  out_b = 8'hFF;
    reg [3:0]  out_i = 4'd0;
    reg [7:0]  phase = 8'd0;
    reg [1:0]  fetch = 2'd0;

    wire [7:0] rx_byte = {sh[6:0], dt_s[1]};

    always @(posedge clk) begin
        if (ck_rise) idle <= 16'd0; else if (idle != 16'hFFFF) idle <= idle + 16'd1;

        case (mode)
        // ------------------------------------------------ receiving bytes from the FPGA
        M_SYNC, M_CMD, M_ARG: begin
            if (ck_rise) begin
                sh   <= rx_byte;
                nbit <= nbit + 4'd1;
                if (nbit == 4'd7) begin
                    nbit <= 4'd0;
                    case (mode)
                    M_SYNC: if (rx_byte == 8'h88) mode <= M_CMD;
                    M_CMD: begin
                        cmd <= rx_byte; argn <= 2'd0;
                        if (rx_byte == 8'hD4 || rx_byte == 8'hE2) mode <= M_ARG;
                        else if (rx_byte == 8'hC9) begin
                            if (len != 24'd0) begin mode <= M_STREAM; ra <= addr[15:0]; end
                            else mode <= M_SYNC;
                        end
                        else mode <= M_SYNC;
                    end
                    default: begin                                  // M_ARG: three little-endian bytes
                        arg <= {rx_byte, arg[23:8]};
                        argn <= argn + 2'd1;
                        if (argn == 2'd2) begin
                            if (cmd == 8'hD4) addr <= {rx_byte, arg[23:8]};
                            else              len  <= {rx_byte, arg[23:8]};
                            mode <= M_SYNC;
                        end
                    end
                    endcase
                end
            end
            else if (idle == 16'd4800 && (nbit != 4'd0 || mode != M_SYNC)) begin   // 300 us: abandon
                nbit <= 4'd0; mode <= M_SYNC;
            end
        end

        // ------------------------------------------------ transfer mode: every prompt = one byte
        M_STREAM: begin
            nbit <= 4'd0;
            if (ck_rise) begin
                ra    <= addr[15:0];
                fetch <= 2'd3;
                mode  <= M_SEND;
            end
        end

        M_SEND: begin
            if (fetch != 2'd0) begin
                fetch <= fetch - 2'd1;
                if (fetch == 2'd1) begin
                    out_b <= (addr[23:16] == 8'h00) ? img_q : 8'hFF;
                    out_i <= 4'd0; phase <= 8'd0;
                end
            end
            else begin
                phase <= phase + 8'd1;
                if (phase == 8'd0) eeprom_data_o <= out_b[7 - out_i[2:0]];          // data valid ...
                if (phase == (BIT_CLKS / 4))       pic_clk_o <= 1'b1;                // ... then clock high ...
                if (phase == (BIT_CLKS * 3 / 4))   pic_clk_o <= 1'b0;                // ... and low again
                if (phase == BIT_CLKS - 1) begin
                    phase <= 8'd0;
                    out_i <= out_i + 4'd1;
                    if (out_i == 4'd7) begin
                        eeprom_data_o <= 1'b1;
                        addr <= addr + 24'd1;
                        len  <= len - 24'd1;
                        mode <= (len == 24'd1) ? M_SYNC : M_STREAM;
                    end
                end
            end
        end
        default: mode <= M_SYNC;
        endcase
    end
endmodule
