`timescale 1ns / 1ps
// Unit test of kg_sd_emu (the SD card emulated on an image, karabas_go_osca_top): an SPI master as OSCA's spi_sch5 (mode 0,
// 8 MHz: SCLK toggles every 16 MHz clock, MOSI changes as SCLK falls, MISO is sampled as it rises), the command sequence of
// the FLOS driver (FLOS_sdcard_driver v1.13: dummy clocks, CMD0, CMD8, CMD55 + ACMD41 with HCS, CMD58, CMD9, CMD17, CMD24)
// and a stand-in for img_sdc (a sector: pattern lba + i, after a delay of the MCU; a write is taken from the card's buffer).
// iverilog: tb_kg_sd_emu.v ../rtl/io/kg_sd_emu.v ../../modules/rtl/mem/kg_tdpram.v
module tb_kg_sd_emu;
	reg clk = 0; always #5.2083 clk = ~clk;                 // 96 MHz
	reg [2:0] div = 0; reg clk16 = 0;
	always @(posedge clk) begin div <= div == 3'd5 ? 3'd0 : div + 3'd1; if (div == 3'd5 || div == 3'd2) clk16 <= ~clk16; end

	reg sclk = 0, mosi = 1, cs_n = 1;
	wire miso;
	reg img_mounted = 0; reg [31:0] img_size = 32'd64 * 1024 * 1024;
	wire hd_rd, hd_wr; wire [31:0] hd_lba;
	reg hd_busy = 0, hd_done = 0, hd_byte_in_strobe = 0; reg [8:0] hd_byte_addr = 0; reg [7:0] hd_byte_in_data = 0;
	wire [7:0] hd_byte_out_data;

	kg_sd_emu dut (.clk(clk), .reset(1'b0), .sclk(sclk), .mosi(mosi), .cs_n(cs_n), .miso(miso),
		.img_mounted(img_mounted), .img_size(img_size), .hd_rd(hd_rd), .hd_wr(hd_wr), .hd_lba(hd_lba),
		.hd_busy(hd_busy), .hd_done(hd_done), .hd_error(1'b0), .hd_byte_in_strobe(hd_byte_in_strobe), .hd_byte_addr(hd_byte_addr),
		.hd_byte_in_data(hd_byte_in_data), .hd_byte_out_data(hd_byte_out_data));

	// ---- img_sdc stand-in
	// a request: busy for a clock, the MCU's delay (~50 us here, 5-40 ms on the board), then a read gives 512 bytes
	// lba + i, a write takes the 512 bytes of the card's buffer (port b, OUT_LATENCY 3 as img_sdc), then done
	integer nreq = 0; reg [7:0] wsec [0:511]; reg [31:0] wlba = 0, l = 0; reg w = 0; reg [2:0] st = 0; integer cnt = 0, idx = 0, sub = 0;
	always @(posedge clk) begin
		hd_busy <= 0; hd_done <= 0; hd_byte_in_strobe <= 0;
		case (st)
			0: if (hd_rd || hd_wr) begin hd_busy <= 1; nreq <= nreq + 1; w <= hd_wr; l <= hd_lba; cnt <= 0; st <= 1; end
			1: begin cnt <= cnt + 1; if (cnt == 5000) begin idx <= 0; sub <= 0; st <= w ? 3 : 2; end end
			2: begin hd_byte_in_strobe <= 1; hd_byte_addr <= idx; hd_byte_in_data <= l[7:0] + idx[7:0]; idx <= idx + 1; if (idx == 511) st <= 4; end
			3: begin
				wlba <= l;
				if (sub == 0) hd_byte_addr <= idx;
				if (sub == 3) begin wsec[idx] <= hd_byte_out_data; idx <= idx + 1; if (idx == 511) st <= 4; end
				sub <= sub == 3 ? 0 : sub + 1;
			end
			4: begin hd_done <= 1; st <= 0; end
		endcase
	end

	// ---- SPI master (spi_sch5): the signals change after a 16 MHz edge, MISO is taken as the master's flip-flop takes it
	// at the rising edge of SCLK (the value before that 96 MHz edge: miso_q, taken at the falling 96 MHz edge before it)
	reg miso_q = 1; always @(negedge clk) miso_q <= miso;
	task xfer(input [7:0] b, output [7:0] r); integer i; begin
		for (i = 7; i >= 0; i = i - 1) begin
			@(posedge clk16); #1 sclk = 0; mosi = b[i];
			@(posedge clk16); r[i] = miso_q; #1 sclk = 1;
		end
		@(posedge clk16); #1 sclk = 0; mosi = 1;
	end endtask
	reg [7:0] r; integer errs = 0, n;
	task cmd(input [7:0] c, input [31:0] a, input [7:0] crc, output [7:0] r1); begin
		xfer(c, r); xfer(a[31:24], r); xfer(a[23:16], r); xfer(a[15:8], r); xfer(a[7:0], r); xfer(crc, r);
		n = 0; r1 = 8'hFF;
		while (r1 == 8'hFF && n < 16) begin xfer(8'hFF, r1); n = n + 1; end
	end endtask
	task chk(input [7:0] got, input [7:0] exp, input [8*24-1:0] what); begin
		if (got !== exp) begin errs = errs + 1; $display("MISMATCH %0s: got %02h expected %02h", what, got, exp); end
	end endtask

	reg [7:0] r1, b0, b1, b2, b3; reg [7:0] csd [0:15]; integer i;
	integer k, m, q0;
	task rd_sec(input [31:0] lba, input written); begin
		cmd(8'h51, lba, 8'h01, r1); chk(r1, 8'h00, "CMD17 R1");
		r = 8'hFF; m = 0; while (r == 8'hFF && m < 2000) begin xfer(8'hFF, r); m = m + 1; end
		chk(r, 8'hFE, "CMD17 token");
		for (k = 0; k < 512; k = k + 1) begin xfer(8'hFF, r); chk(r, written ? (8'h5A ^ k[7:0]) : (lba[7:0] + k[7:0]), "CMD17 data"); end
		xfer(8'hFF, r); xfer(8'hFF, r);
	end endtask
	initial begin
		repeat (20) @(posedge clk); #1 img_mounted = 1; @(posedge clk); #1 img_mounted = 0;
		for (i = 0; i < 10; i = i + 1) xfer(8'hFF, r);        // 80 clocks with CS high
		@(posedge clk16); #1 cs_n = 0;
		cmd(8'h40, 0, 8'h95, r1); chk(r1, 8'h01, "CMD0 R1");
		cmd(8'h48, 32'h1AA, 8'h87, r1); chk(r1, 8'h01, "CMD8 R1");
		xfer(8'hFF, b0); xfer(8'hFF, b1); xfer(8'hFF, b2); xfer(8'hFF, b3);
		chk(b2, 8'h01, "CMD8 voltage"); chk(b3, 8'hAA, "CMD8 pattern");
		cmd(8'h77, 0, 8'h01, r1); chk(r1, 8'h01, "CMD55 R1");
		cmd(8'h69, 32'h40000000, 8'h01, r1); chk(r1, 8'h00, "ACMD41 R1");
		cmd(8'h7A, 0, 8'h01, r1); chk(r1, 8'h00, "CMD58 R1");
		xfer(8'hFF, b0); chk(b0 & 8'h40, 8'h40, "CMD58 CCS");
		xfer(8'hFF, b1); xfer(8'hFF, b2); xfer(8'hFF, b3);
		cmd(8'h49, 0, 8'h01, r1); chk(r1, 8'h00, "CMD9 R1");
		r = 8'hFF; n = 0; while (r != 8'hFE && n < 16) begin xfer(8'hFF, r); n = n + 1; end
		for (i = 0; i < 16; i = i + 1) xfer(8'hFF, csd[i]);
		xfer(8'hFF, r); xfer(8'hFF, r);
		chk({csd[8], csd[9]}, 16'd127, "CSD C_SIZE");          // 64 MB: 64 MB / 512 KB - 1
		// read sector 7
		cmd(8'h51, 32'd7, 8'h01, r1); chk(r1, 8'h00, "CMD17 R1");
		r = 8'hFF; n = 0; while (r == 8'hFF && n < 2000) begin xfer(8'hFF, r); n = n + 1; end
		chk(r, 8'hFE, "CMD17 token");
		for (i = 0; i < 512; i = i + 1) begin xfer(8'hFF, r); chk(r, 8'd7 + i[7:0], "CMD17 data"); end
		xfer(8'hFF, r); xfer(8'hFF, r);
		// write sector 9
		cmd(8'h58, 32'd9, 8'h01, r1); chk(r1, 8'h00, "CMD24 R1");
		xfer(8'hFF, r); xfer(8'hFE, r);
		for (i = 0; i < 512; i = i + 1) xfer(8'h5A ^ i[7:0], r);
		xfer(8'hFF, r); xfer(8'hFF, r);                          // CRC
		xfer(8'hFF, r); chk(r & 8'h1F, 8'h05, "CMD24 data response");
		n = 0; r = 8'h00; while (r == 8'h00 && n < 2000) begin xfer(8'hFF, r); n = n + 1; end
		chk(r, 8'hFF, "CMD24 end of busy");
		if (wlba != 9) begin errs = errs + 1; $display("MISMATCH write lba %0d", wlba); end
		for (i = 0; i < 512; i = i + 1) if (wsec[i] !== (8'h5A ^ i[7:0])) begin errs = errs + 1; if (errs < 5) $display("MISMATCH write byte %0d: %02h", i, wsec[i]); end
		// the cache: sector 7 and the written sector 9 again without a request, sector 38 (the line of 7: 6 ^ 1) with one
		q0 = nreq; rd_sec(7, 0);  if (nreq != q0) begin errs = errs + 1; $display("MISMATCH sector 7 again: a request"); end
		q0 = nreq; rd_sec(9, 1);  if (nreq != q0) begin errs = errs + 1; $display("MISMATCH sector 9 after the write: a request"); end
		q0 = nreq; rd_sec(38, 0); if (nreq != q0 + 1) begin errs = errs + 1; $display("MISMATCH sector 38: %0d requests", nreq - q0); end
		q0 = nreq; rd_sec(7, 0);  if (nreq != q0 + 1) begin errs = errs + 1; $display("MISMATCH sector 7 after 38: %0d requests", nreq - q0); end
		@(posedge clk16); #1 cs_n = 1; xfer(8'hFF, r);
		$display("SD EMU: %0s (%0d errors)", errs == 0 ? "PASS" : "FAIL", errs);
		$finish;
	end
	initial begin #50000000; $display("TIMEOUT"); $finish; end
endmodule
