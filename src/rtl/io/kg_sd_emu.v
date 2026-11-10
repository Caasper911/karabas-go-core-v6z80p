`timescale 1ns / 1ps
// kg_sd_emu - an SD card on the SPI pins of OSCA's SD interface (spi_sch5), emulated on a hard disk image of the
// file mounter of the MCU (img_sdc of karabas-go-modules) instead of a physical card.
//
// The card is the state machine of nextor_sd.v of karabas-go-core-msx (Andy Karpov, GPL-3.0): an SDHC card (block
// addresses, OCR with CCS) of the size of the image, the commands CMD0/1/8/9/10/12/16/17/18/24/25/55/58 and ACMD23/41,
// the response after one FF byte (Ncr = 2: FLOS skips the first byte after the command),
// a sector through img_sdc (5-40 ms through the MCU: the card answers FF (no data token yet) or 00 (busy after a write)
// meanwhile).  FLOS (FLOS_sdcard_driver v1.13) uses CMD0, CMD8, CMD55 + ACMD41 with HCS, CMD58, CMD9, CMD10, CMD17, CMD24.
//
// Here the bus of the MSX interface is replaced by an SPI slave (mode 0, MSB first, as spi_sch5: MOSI changes on the
// falling edge of SCLK, the master samples MISO on the rising one; 8 MHz at most).  The SPI signals are registers of
// the clk16 domain of the core, this runs on clk (96 MHz, the same PLL): an edge is seen a clock after it, the next MISO
// bit is out 5 clocks before the master samples it.  Each 8 bits are an exchange: the byte the card gives (out, from its
// state before the byte) goes out while the master's byte comes in, then the card takes that byte (xfer), as in
// nextor_sd.  Bytes clocked with CS high deselect the card (it drops what it was doing; the dummy clocks before CMD0).
//
// Sector cache: 32 sectors (16 KB of block RAM), direct mapped, write through.  The line of a sector is lba[4:0] ^ lba[9:5] ^
// lba[14:10]: FAT16 puts its structures at sectors 32 * 2^n apart (MBR 0, root directory 128), they would share lba[4:0].  Each sector of the MCU takes
// 5-40 ms, and FLOS reads the same sectors again and again (the boot sector, the FAT, the directory): a sector that is
// in the cache is ready a few clocks after its command.  A sector read or written through img_sdc becomes valid at its
// end (not after an error); a new image (img_mounted) empties the cache.
module kg_sd_emu (
	input wire clk,
	input wire reset,             // the reset of the core: the card is idle (the driver starts with CMD0 again)
	// the SPI master of the core
	input wire sclk,
	input wire mosi,
	input wire cs_n,
	output wire miso,
	// the image (img_sdc)
	input wire img_mounted,       // a pulse: img_size is the new size (0 = none)
	input wire [31:0] img_size,
	output reg hd_rd = 1'b0,
	output reg hd_wr = 1'b0,
	output reg [31:0] hd_lba = 32'd0,
	input wire hd_busy,           // img_sdc took the request
	input wire hd_done,           // its end
	input wire hd_error,          // with hd_done: the request failed (a read gave zero bytes): the sector is not cached
	input wire hd_byte_in_strobe, // a byte of a read sector
	input wire [8:0] hd_byte_addr,
	input wire [7:0] hd_byte_in_data,
	output wire [7:0] hd_byte_out_data,
	// the card waits for img_sdc (a read sector, the end of a write): the board holds the CPU (WAIT) on its reads of the SPI
	// port meanwhile.  FLOS polls the data token only 8000 times (~80 ms), the MCU can take longer for a sector of the image.
	output wire waiting
);

// ------------------------------------------------------------------ the SPI slave

reg sclk_d = 1'b0, cs_d = 1'b1;
reg [2:0] bitcnt = 3'd0;      // bits of the current byte received
reg [6:0] rx_sr = 7'd0;
reg [7:0] miso_sr = 8'hFF;
reg xfer = 1'b0;              // one clock: the card takes tx
reg xfer_cs_n = 1'b1;         // CS of that byte
reg [7:0] tx = 8'hFF;
wire [7:0] out;               // the byte the card gives in the next exchange (below)

assign miso = cs_n ? 1'b1 : miso_sr[7];

// The card's next byte is taken into the MISO register once, 3 clocks after a byte (the card has taken it then) or after a
// change of CS, not continuously: a change of the card between the bytes (a sector became ready) then goes out whole in the
// next byte, never as the first bit of the old value and the rest of the new one.  (The next rising edge comes 12 clocks
// after a byte at the fastest.)
reg [1:0] load_cnt = 2'd0;
reg [7:0] sent = 8'hFF;       // the byte that goes out in this exchange (the card's decisions follow it, not its state now)
always @(posedge clk) begin
	sclk_d <= sclk;
	cs_d <= cs_n;
	xfer <= 1'b0;
	if (load_cnt != 2'd0)
		load_cnt <= load_cnt - 2'd1;
	if (cs_n != cs_d) begin
		bitcnt <= 3'd0;           // a change of CS starts a new byte
		load_cnt <= 2'd3;
	end else if (sclk & ~sclk_d) begin // rising edge: a bit in
		rx_sr <= { rx_sr[5:0], mosi };
		bitcnt <= bitcnt + 3'd1;
		if (bitcnt == 3'd7) begin
			tx <= { rx_sr, mosi };
			xfer_cs_n <= cs_n;
			xfer <= 1'b1;
			load_cnt <= 2'd3;
		end
	end else if (~sclk & sclk_d & bitcnt != 3'd0)
		miso_sr <= { miso_sr[6:0], 1'b1 };   // falling edge inside a byte: the next bit out
	if (load_cnt == 2'd1) begin
		miso_sr <= out;
		sent <= out;
	end
end

// ------------------------------------------------------------------ the sector buffer

// the request to img_sdc: pending until its end; a request whose block nobody wants any more
// (CMD12, a deselect, a reset) is stale: its end is not taken as the data of a new one
reg pending = 1'b0;
reg stale = 1'b0;

// port a: the card (the sector of hd_lba, buf_addr), port b: img_sdc (the sector of the request, rq_line: a read
// sector in, a written one out). The bytes of a stale read are not taken.
reg [8:0] buf_addr = 9'd0;    // the byte of the card (read: the next one out, write: the next one in)
wire [7:0] buf_q;
reg buf_we = 1'b0;
reg [7:0] buf_wd = 8'h00;
function [4:0] line_of(input [31:0] lba);
	line_of = lba[4:0] ^ lba[9:5] ^ lba[14:10];
endfunction
wire [4:0] card_line = line_of(hd_lba);
reg [4:0] rq_line = 5'd0;     // the cache line of the request to img_sdc
reg [31:0] rq_tag = 32'd0;
kg_tdpram #(.DW(8), .AW(14)) sector (
	.clka(clk), .ena(1'b1), .wea(buf_we), .addra({ card_line, buf_addr }), .dina(buf_wd), .douta(buf_q),
	.clkb(clk), .enb(1'b1), .web(hd_byte_in_strobe & ~stale), .addrb({ rq_line, hd_byte_addr }), .dinb(hd_byte_in_data),
	.doutb(hd_byte_out_data)
);

// the tags of the cache lines (distributed RAM) and their valid bits
reg [31:0] tag [0:31];
reg [31:0] valid = 32'd0;
reg tag_we = 1'b0;
reg [4:0] tag_wa = 5'd0;
reg [31:0] tag_wd = 32'd0;
always @(posedge clk)
	if (tag_we)
		tag[tag_wa] <= tag_wd;
reg hit = 1'b0;               // the sector of hd_lba is in the cache (a clock after hd_lba)
always @(posedge clk)
	hit <= valid[card_line] && tag[card_line] == hd_lba;
reg lookup = 1'b0;            // a read of hd_lba: the cache first, then img_sdc
reg [1:0] look_cnt = 2'd0;
reg inval = 1'b0;             // a new image came while a request was out: its sector is not cached

// ------------------------------------------------------------------ the card (nextor_sd.v)

localparam S_IDLE = 4'd0, S_CMD = 4'd1, S_RESP = 4'd2, S_RD_WAIT = 4'd3, S_RD_DATA = 4'd4,
	S_RD_CRC = 4'd5, S_WR_TOKEN = 4'd6, S_WR_DATA = 4'd7, S_WR_CRC = 4'd8, S_WR_RESP = 4'd9,
	S_WR_BUSY = 4'd10, S_NCR = 4'd11;

reg [3:0] state = S_IDLE;
reg [5:0] cmd = 6'd0;
reg [31:0] arg = 32'd0;
reg [2:0] cnt = 3'd0;         // the bytes of a command
reg [4:0] ridx = 5'd0;        // the byte of a response
reg idle = 1'b1;              // the idle bit of R1 (until ACMD41 / CMD1)
reg app = 1'b0;               // CMD55 before: an ACMD
reg acmd = 1'b0;              // the command is an ACMD
reg multi = 1'b0;             // CMD18 / CMD25
reg crc1 = 1'b0;              // the first CRC byte of a block was there

reg ready = 1'b0;             // the block of the read is in the buffer / the write is done
reg want = 1'b0;              // a request to make when img_sdc is free of the stale one
reg want_wr = 1'b0;

// C_SIZE of the CSD (version 2): (size / 512 KB) - 1
reg [31:0] size = 32'd0;
always @(posedge clk)
	if (img_mounted)
		size <= img_size;
wire [21:0] c_size = size[31:19] == 13'd0 ? 22'd0 : { 9'd0, size[31:19] } - 22'd1;

// (a continuous assignment: an always @* of cmd would not run in a simulation while cmd keeps its initial value, CMD0)
wire cmd_bad = !(cmd == 6'd0 || cmd == 6'd1 || cmd == 6'd8 || cmd == 6'd9 || cmd == 6'd10 || cmd == 6'd12 || cmd == 6'd16 ||
	cmd == 6'd17 || cmd == 6'd18 || cmd == 6'd24 || cmd == 6'd25 || cmd == 6'd55 || cmd == 6'd58);
wire [7:0] r1 = { 5'd0, (acmd ? 1'b0 : cmd_bad), 1'b0, idle };

// the bytes of a response after R1 (ridx 1..): R7, OCR, the CSD / CID with their token and CRC
reg [7:0] resp;
reg [4:0] resp_len;           // the bytes of the response, R1 included
always @* begin
	resp = 8'hFF;
	resp_len = 5'd1;
	if (!acmd) case (cmd)
		6'd8: begin
			resp_len = 5'd5;
			case (ridx)
				5'd3: resp = { 4'd0, arg[11:8] };
				5'd4: resp = arg[7:0];
				default: resp = 8'h00;
			endcase
		end
		6'd58: begin
			resp_len = 5'd5;
			case (ridx)
				5'd1: resp = 8'hC0;   // powered up, CCS (SDHC)
				5'd2: resp = 8'hFF;
				5'd3: resp = 8'h80;
				default: resp = 8'h00;
			endcase
		end
		6'd9: begin
			resp_len = 5'd20;
			case (ridx)
				5'd1: resp = 8'hFE;
				5'd2: resp = 8'h40;   // CSD version 2
				5'd3: resp = 8'h0E;
				5'd4: resp = 8'h00;
				5'd5: resp = 8'h32;
				5'd6: resp = 8'h5B;
				5'd7: resp = 8'h59;   // READ_BL_LEN 9
				5'd8: resp = 8'h00;
				5'd9: resp = { 2'd0, c_size[21:16] };
				5'd10: resp = c_size[15:8];
				5'd11: resp = c_size[7:0];
				5'd12: resp = 8'h7F;
				5'd13: resp = 8'h80;
				5'd14: resp = 8'h0A;
				5'd15: resp = 8'h40;  // WRITE_BL_LEN 9
				5'd16: resp = 8'h00;
				5'd17: resp = 8'h01;
				default: resp = 8'hFF;
			endcase
		end
		6'd10: begin
			resp_len = 5'd20;
			case (ridx)
				5'd1: resp = 8'hFE;
				5'd2: resp = 8'h00;   // MID
				5'd3: resp = "K";     // OID
				5'd4: resp = "G";
				5'd5: resp = "V";     // PNM
				5'd6: resp = "6";
				5'd7: resp = "Z";
				5'd8: resp = "8";
				5'd9: resp = "0";
				5'd10: resp = 8'h10;  // PRV 1.0
				5'd15: resp = 8'h01;  // MDT
				5'd16: resp = 8'h6A;
				5'd17: resp = 8'h01;
				5'd18, 5'd19: resp = 8'hFF;
				default: resp = 8'h00;
			endcase
		end
		default: ;
	endcase
end

// the byte the card gives in the exchange
reg [7:0] out_r;
always @* begin
	case (state)
		S_RESP: out_r = ridx == 5'd0 ? r1 : resp;
		S_RD_WAIT: out_r = ready ? 8'hFE : 8'hFF;
		S_RD_DATA: out_r = buf_q;
		S_WR_RESP: out_r = 8'h05;
		S_WR_BUSY: out_r = ready ? 8'hFF : 8'h00;
		default: out_r = 8'hFF;
	endcase
end
assign out = out_r;

wire is_cmd = tx[7:6] == 2'b01;

always @(posedge clk) begin
	buf_we <= 1'b0;
	tag_we <= 1'b0;
	// the cache: a read looks up hd_lba (hit is good two clocks after it changed)
	if (lookup) begin
		look_cnt <= look_cnt + 2'd1;
		if (look_cnt == 2'd2) begin
			lookup <= 1'b0;
			if (hit)
				ready <= 1'b1;
			else begin
				want <= 1'b1;
				want_wr <= 1'b0;
			end
		end
	end
	// img_sdc
	if (hd_busy) begin
		hd_rd <= 1'b0;
		hd_wr <= 1'b0;
	end
	if (hd_done) begin
		pending <= 1'b0;
		if (!stale)
			ready <= 1'b1;
		if (!stale && !inval && !hd_error) begin
			// the sector of the request is in its line now (read from the image, or written to it)
			tag_we <= 1'b1;
			tag_wa <= rq_line;
			tag_wd <= rq_tag;
			valid[rq_line] <= 1'b1;
		end
		stale <= 1'b0;
		inval <= 1'b0;
	end
	if (want && !pending) begin
		want <= 1'b0;
		pending <= 1'b1;
		ready <= 1'b0;
		rq_line <= card_line;
		rq_tag <= hd_lba;
		valid[card_line] <= 1'b0;   // the line gets the sector of the request
		if (want_wr) hd_wr <= 1'b1; else hd_rd <= 1'b1;
	end
	if (img_mounted) begin
		valid <= 32'd0;
		if (pending)
			inval <= 1'b1;
	end

	if (reset) begin
		state <= S_IDLE;
		idle <= 1'b1;
		app <= 1'b0;
		if (pending && !ready)
			stale <= 1'b1;
		want <= 1'b0;
		lookup <= 1'b0;
	end else if (xfer) begin
		if (xfer_cs_n) begin
			// deselected: the card drops what it was doing
			state <= S_IDLE;
			if (pending && !ready)
				stale <= 1'b1;
			want <= 1'b0;
			lookup <= 1'b0;
		end else case (state)
			S_IDLE, S_RD_WAIT: begin
				if (state == S_RD_WAIT && sent == 8'hFE && !is_cmd) begin
					// the token went out (in this exchange; ready may have come after the byte was taken): the data from byte 0 (buf_q)
					state <= S_RD_DATA;
				end else if (is_cmd) begin
					if (state == S_RD_WAIT) begin
						// CMD12 in a multiple block read: the block on its way is not wanted
						if (pending)
							stale <= 1'b1;
						want <= 1'b0;
						lookup <= 1'b0;
					end
					cmd <= tx[5:0];
					acmd <= app;
					app <= 1'b0;
					cnt <= 3'd1;
					state <= S_CMD;
				end
			end
			S_CMD: begin
				if (cnt <= 3'd4)
					arg <= { arg[23:0], tx };
				if (cnt == 3'd5) begin
					// the CRC: the command is complete
					// the response after one FF byte (Ncr = 2): FLOS skips the first byte after the CRC without looking at it
					// ("skip first byte of nCR. A quirk of the OSCA V6 SD card interface?", sd_send_command_string)
					ridx <= 5'd0;
					state <= S_NCR;
					if (!acmd) case (cmd)
						6'd0: idle <= 1'b1;
						6'd1: idle <= 1'b0;
						6'd55: app <= 1'b1;
						default: ;
					endcase
					else if (cmd == 6'd41)
						idle <= 1'b0;
				end
				cnt <= cnt + 3'd1;
			end
			S_RESP: begin
				if (ridx == resp_len - 5'd1) begin
					state <= S_IDLE;
					if (!acmd && (cmd == 6'd17 || cmd == 6'd18)) begin
						hd_lba <= arg;
						multi <= cmd == 6'd18;
						lookup <= 1'b1;
						look_cnt <= 2'd0;
						ready <= 1'b0;
						buf_addr <= 9'd0;
						state <= S_RD_WAIT;
					end
					if (!acmd && (cmd == 6'd24 || cmd == 6'd25)) begin
						hd_lba <= arg;
						multi <= cmd == 6'd25;
						state <= S_WR_TOKEN;
					end
				end
				ridx <= ridx + 5'd1;
			end
			S_RD_DATA: begin
				buf_addr <= buf_addr + 9'd1;
				if (buf_addr == 9'd511) begin
					// the last byte went out: the CRC
					crc1 <= 1'b0;
					state <= S_RD_CRC;
				end
			end
			S_RD_CRC: begin
				crc1 <= 1'b1;
				if (crc1) begin
					if (multi) begin
						hd_lba <= hd_lba + 32'd1;
						lookup <= 1'b1;
						look_cnt <= 2'd0;
						ready <= 1'b0;
						buf_addr <= 9'd0;
						state <= S_RD_WAIT;
					end else
						state <= S_IDLE;
				end
			end
			S_WR_TOKEN: begin
				if (tx == 8'hFE || (multi && tx == 8'hFC)) begin
					buf_addr <= 9'd0;
					valid[card_line] <= 1'b0;     // the data of the write goes into the line of hd_lba
					state <= S_WR_DATA;
				end else if (multi && tx == 8'hFD)
					state <= S_IDLE;
				else if (is_cmd) begin
					cmd <= tx[5:0];
					acmd <= app;
					app <= 1'b0;
					cnt <= 3'd1;
					state <= S_CMD;
				end
			end
			S_WR_DATA: begin
				buf_wd <= tx;
				buf_we <= 1'b1;
				if (buf_addr == 9'd511) begin
					crc1 <= 1'b0;
					state <= S_WR_CRC;
				end
			end
			S_WR_CRC: begin
				crc1 <= 1'b1;
				if (crc1) begin
					want <= 1'b1;
					want_wr <= 1'b1;
					ready <= 1'b0;
					state <= S_WR_RESP;
				end
			end
			S_NCR: state <= S_RESP;
			S_WR_RESP: state <= S_WR_BUSY;
			S_WR_BUSY: begin
				if (ready) begin
					hd_lba <= hd_lba + 32'd1;
					state <= multi ? S_WR_TOKEN : S_IDLE;
				end
			end
			default: state <= S_IDLE;
		endcase
	end
	// the byte written above goes to buf_addr, then the address moves on
	if (buf_we)
		buf_addr <= buf_addr + 9'd1;
end

assign waiting = (state == S_RD_WAIT || state == S_WR_BUSY) && !ready;

endmodule
