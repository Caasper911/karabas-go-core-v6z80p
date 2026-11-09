`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// kg_osca_soc - OSCA core + soft Z80 + SRAM wrapper, ready for a Karabas Go top level
//
//   clk_mem   : 16 MHz * 6 = 96 MHz  (DCM_CLKGEN M=48 D=25 from CLK_50MHZ)
//   clk16_gen : 16 MHz made by the memory wrapper's tick counter -> put it through a BUFG and
//               feed the BUFG output back into `clk16` (in simulation connect them directly)
//   SRAM pins : ma / md_o / md_oe / md_i / mwr_n / mrd_n  (MD = md_oe ? md_o : 16'bz at the pads)
//   everything else is the OSCA peripheral set (video, audio, PS/2, SD card, serial, joystick,
//   PIC link) exactly as on the V6Z80P+ pins.
//////////////////////////////////////////////////////////////////////////////////
module kg_osca_soc (
    input  wire        clk_mem,
    output wire        clk16_gen,
    input  wire        clk16,

    // Karabas Go SRAM
    output wire [20:0] ma,
    output wire [15:0] md_o,
    output wire        md_oe,
    input  wire [15:0] md_i,
    output wire [1:0]  mwr_n,
    output wire [1:0]  mrd_n,
    input  wire        v_en,                // bring-up video RAM self test (kg_vram_test) drives the wrapper's video inputs while 1
    input  wire [18:0] v_addr,
    input  wire        v_wr_n,
    input  wire [7:0]  v_wd,
    input  wire        t_en,                // bring-up SRAM self test (kg_sram_test) drives the SRAM pins while 1
    input  wire [20:0] t_ma,
    input  wire [15:0] t_md,
    input  wire        t_oe,
    input  wire [1:0]  t_wr_n, t_rd_n,

    // video
    output wire col_red_a, col_red_b, col_red_c, col_red_d,
    output wire col_green_a, col_green_b, col_green_c, col_green_d,
    output wire col_blue_a, col_blue_b, col_blue_c, col_blue_d,
    output wire horizontal_sync, tv_sync,
    // audio
    output wire audio_left, audio_right,
    // PS/2 (separate in/out lines: out = 1 pulls the line low)
    input  wire ps2_kb_clock_in, ps2_kb_data_in, ps2_ms_clock_in, ps2_ms_data_in,
    output wire ps2_kb_clock_out, ps2_kb_data_out, ps2_ms_clock_out, ps2_ms_data_out,
    // SD card (SPI), serial, joystick, PIC link, EEPROM
    output wire sdc_clk, sdc_cs, sdc_din, sdc_pow,
    input  wire sdc_dout,
    output wire serial_tx_pin,
    input  wire serial_rx_pin,
    output wire joystick_clock_out,
    input  wire joystick_data_in,
    // MCU ROM loader (kg_mcu ROMLOAD_*, clk_mem domain): while ld_active the loader owns the system RAM
    // port and the core must be held in reset by the caller.  File offset = Z80 address ($1000 = FLOS).
    input  wire        ld_active,
    input  wire [31:0] ld_addr,
    input  wire [7:0]  ld_data,
    input  wire        ld_wr,
    // jumpers / expansion
    input  wire jumper_nmi, jumper_reset, jumper_vga,
    inout  wire expansion_pin_a, expansion_pin_b,
    output wire system_reset_out,
    // system RAM on the SDRAM (clk_mem domain)
    input  wire        sdram_reset,
    input  wire        sdram_cap_late,    // SDRAM read data capture variant (see kg_osca_sdram cap_late)
    output wire        sdram_init_done,
    output wire [1:0]  sd_ba,
    output wire [12:0] sd_a,
    output wire [1:0]  sd_dqm,
    output wire        sd_ras_n, sd_cas_n, sd_we_n,
    inout  wire [15:0] sd_dq,
    // bring-up debug bus: {system_reset_out, z80_wait, sdram_wait_n, busak_n, wr_n, rd_n, iorq_n, mreq_n, m1_n, d_bus[7:0], a_bus[15:0]}
    output wire [32:0] dbg,
    output wire [7:0]  chk_rdata,      // system RAM read data / valid (self test of the SDRAM through the loader port)
    output wire        chk_rdvalid,
    output wire [63:0] dbg8,
    input  wire        dbg_fixpal,      // fixed palette test (see osca_core)
    input  wire [8:0]  dbg_paddr,       // palette probe (see osca_core)
    output wire [15:0] dbg_pdata,
    output wire [19:0] dbg7,            // bus as seen by the core registers (see osca_core dbg_bus)
    output wire [4:0]  dbg6,            // write enables of the video registers (see osca_core dbg_wce)
    output wire [31:0] dbg5,            // video registers (see osca_core dbg_vr)
    output wire [1:0]  dbg4,            // palette pages (see osca_core dbg_pal)
    output wire [29:0] dbg3,            // OSCA core taps (see osca_core dbg_core)
    output wire [26:0] dbg2             // video RAM bus of the core: {vram_wr_n, vram_wdata[7:0], vram_rdata1[7:0] (display), vram_rdata2[7:0] (blitter / CPU)}
);
    // No config PIC / EEPROM on this board: the boot ROM was replaced (see README), tie the link off.
    wire eeprom_data_in = 1'b1;
    wire pic_link_rb7   = 1'b0;
    wire pic_link_rb1, pic_link_ra5;

    // ---------------------------------------------------------------- core <-> memory
    wire [7:0]  vram_wdata, spr_wdata;  wire vram_wdata_oe, spr_wdata_oe;
    wire [7:0]  vram_rdata, vram_rdata2, spr_rdata;
    (* keep = "true" *) wire [7:0] sys_rdata;   // kept so that ise/osca676p.ucf can name it (false path sys RAM read data -> VRAM write data)
    wire [18:0] vram_addr_out;  wire [16:0] spr_addrbus;
    wire        vram_wr, vram_rd, spr_ram_wr, spr_ram_rd;
    wire        system_ram_a14, system_ram_a15, system_ram_a16, system_ram_a17, system_ram_a18, system_ram_cs;

    // ---------------------------------------------------------------- core <-> Z80
    wire [15:0] z80_addr_o;   wire [7:0] z80_data_o;  wire z80_data_oe;
    wire        z80_mreq_o, z80_ioreq_o, z80_read_o, z80_write_o;
    wire        z80_wait, z80_busreq, z80_nmi, z80_int, z80_clock;
    wire [15:0] a_bus;        wire [7:0] d_bus;
    wire        mreq_n_bus, iorq_n_bus, rd_n_bus, wr_n_bus;
    wire        busak_n, m1_n;
    wire        sdram_wait_n;
    assign dbg = {system_reset_out, z80_wait, sdram_wait_n, busak_n, wr_n_bus, rd_n_bus, iorq_n_bus, mreq_n_bus, m1_n, d_bus, a_bus};
    wire [18:0] linecop_pc_o;

    osca_core core (
        .clk_fast(clk_mem),
        .dbg_core(dbg3), .dbg_vr(dbg5), .dbg_wce(dbg6), .dbg_bus(dbg7), .dbg_pal(dbg4), .dbg_paddr(dbg_paddr), .dbg_pdata(dbg_pdata), .dbg_fixpal(dbg_fixpal), .dbg_pwlog(dbg8),
        .vram_wdata(vram_wdata), .vram_wdata_oe(vram_wdata_oe), .vram_rdata(vram_rdata), .vram_rdata2(vram_rdata2), .linecop_pc_o(linecop_pc_o), .vram_addr_out(vram_addr_out),
        .spr_wdata(spr_wdata), .spr_wdata_oe(spr_wdata_oe), .spr_rdata(spr_rdata),
        .spr_ram_wr(spr_ram_wr), .spr_ram_rd(spr_ram_rd), .spr_addrbus(spr_addrbus),
        .vram_rd(vram_rd), .vram_wr(vram_wr),
        .tv_sync(tv_sync), .horizontal_sync(horizontal_sync),
        .col_red_a(col_red_a), .col_red_b(col_red_b), .col_red_c(col_red_c), .col_red_d(col_red_d),
        .col_green_a(col_green_a), .col_green_b(col_green_b), .col_green_c(col_green_c), .col_green_d(col_green_d),
        .col_blue_a(col_blue_a), .col_blue_b(col_blue_b), .col_blue_c(col_blue_c), .col_blue_d(col_blue_d),
        .z80_wait(z80_wait), .z80_busreq(z80_busreq), .z80_busack(busak_n), .z80_m1(m1_n),
        .z80_nmi(z80_nmi), .z80_int(z80_int), .z80_clock(z80_clock),
        .z80_addr_o(z80_addr_o), .z80_addr_i(a_bus),
        .z80_data_o(z80_data_o), .z80_data_oe(z80_data_oe), .z80_data_i(d_bus),
        .z80_mreq_o(z80_mreq_o), .z80_mreq_i(mreq_n_bus),
        .z80_ioreq_o(z80_ioreq_o), .z80_ioreq_i(iorq_n_bus),
        .z80_read_o(z80_read_o), .z80_read_i(rd_n_bus),
        .z80_write_o(z80_write_o), .z80_write_i(wr_n_bus),
        .system_ram_a14(system_ram_a14), .system_ram_a15(system_ram_a15), .system_ram_a16(system_ram_a16),
        .system_ram_a17(system_ram_a17), .system_ram_a18(system_ram_a18), .system_ram_cs(system_ram_cs),
        .clock_16mhz(clk16),
        .system_reset_out(system_reset_out),
        .audio_left(audio_left), .audio_right(audio_right),
        .ps2_kb_clock_in(ps2_kb_clock_in), .ps2_kb_data_in(ps2_kb_data_in),
        .ps2_ms_clock_in(ps2_ms_clock_in), .ps2_ms_data_in(ps2_ms_data_in),
        .ps2_kb_clock_out(ps2_kb_clock_out), .ps2_kb_data_out(ps2_kb_data_out),
        .ps2_ms_clock_out(ps2_ms_clock_out), .ps2_ms_data_out(ps2_ms_data_out),
        .sdc_clk(sdc_clk), .sdc_cs(sdc_cs), .sdc_din(sdc_din), .sdc_pow(sdc_pow), .sdc_dout(sdc_dout),
        .serial_tx_pin(serial_tx_pin), .serial_rx_pin(serial_rx_pin),
        .joystick_clock_out(joystick_clock_out), .joystick_data_in(joystick_data_in),
        .eeprom_data_in(eeprom_data_in), .pic_link_rb7(pic_link_rb7),
        .pic_link_rb1(pic_link_rb1), .pic_link_ra5(pic_link_ra5),
        .jumper_nmi(jumper_nmi), .jumper_reset(jumper_reset), .jumper_vga(jumper_vga),
        .expansion_pin_a(expansion_pin_a), .expansion_pin_b(expansion_pin_b));

    kg_osca_cpu cpu (
        .clk(clk16), .clk_fast(clk_mem), .clk16_raw(clk16_gen), .reset_n(system_reset_out), .wait_n(z80_wait), .ext_wait_n(sdram_wait_n), .int_n(z80_int), .nmi_n(z80_nmi),
        .busrq_n(z80_busreq), .busak_n(busak_n), .m1_n(m1_n),
        .fpga_a(z80_addr_o), .fpga_mreq_n(z80_mreq_o), .fpga_iorq_n(z80_ioreq_o),
        .fpga_rd_n(z80_read_o), .fpga_wr_n(z80_write_o),
        .fpga_d(z80_data_o), .fpga_d_oe(z80_data_oe),
        .ram_d(sys_rdata), .ram_cs_n(system_ram_cs),
        .a_bus(a_bus), .mreq_n_bus(mreq_n_bus), .iorq_n_bus(iorq_n_bus),
        .rd_n_bus(rd_n_bus), .wr_n_bus(wr_n_bus), .d_bus(d_bus));

`ifdef KG_NO_MEMTEST
    // the SRAM / video RAM self tests are left out (their multiplexers sit on the one-tick display fetch path into the SRAM address)
    wire v_en_i = 1'b0, t_en_i = 1'b0;
`else
    wire v_en_i = v_en, t_en_i = t_en;
`endif
    kg_osca_mem mem (
        .clk_mem(clk_mem), .clk16(clk16_gen), .clk16_ref(clk16),
        .vram_addr(v_en_i ? v_addr : vram_addr_out), .vram_wr_n(v_en_i ? v_wr_n : vram_wr), .vram_wdata(v_en_i ? v_wd : vram_wdata),
        .vram_rdata1(vram_rdata), .vram_rdata2(vram_rdata2),
        .spr_addr(spr_addrbus),    .spr_wr_n(spr_ram_wr), .spr_wdata(spr_wdata), .spr_rdata(spr_rdata),
        .ma(ma), .md_o(md_o), .md_oe(md_oe), .md_i(md_i), .mwr_n(mwr_n), .mrd_n(mrd_n),
        .t_en(t_en_i), .t_ma(t_ma), .t_md(t_md), .t_oe(t_oe), .t_wr_n(t_wr_n), .t_rd_n(t_rd_n));

    // System RAM on the SDRAM.  The MCU loader owns the port while ld_active.  (Define KG_SYSRAM_MODEL for the zero-latency model.)
    wire [18:0] sys_addr_m = ld_active ? ld_addr[18:0] : {system_ram_a18, system_ram_a17, system_ram_a16, system_ram_a15, system_ram_a14, a_bus[13:0]};
    wire        sys_cs_m   = ld_active ? 1'b0 : system_ram_cs;
    wire        sys_wr_m   = ld_active ? ~ld_wr : wr_n_bus;
    wire [7:0]  sys_wd_m   = ld_active ? ld_data : d_bus;
`ifdef KG_SYSRAM_MODEL
    kg_sysram_model sysram (.clk(clk_mem), .addr(sys_addr_m), .cs_n(sys_cs_m), .wr_n(sys_wr_m), .wdata(sys_wd_m), .dma(~busak_n), .rdata(sys_rdata));
    wire sdram_rd_valid = 1'b1;
    assign sdram_init_done = 1'b1;
    assign sd_ba = 2'b00; assign sd_a = 13'd0; assign sd_dqm = 2'b11; assign sd_ras_n = 1'b1; assign sd_cas_n = 1'b1; assign sd_we_n = 1'b1;
`else
    wire sdram_rd_valid, sdram_wr_pending;
    kg_osca_sdram sdram (
        .clk(clk_mem), .reset(sdram_reset),
        .addr(sys_addr_m), .cs_n(sys_cs_m), .wr_n(sys_wr_m), .wdata(sys_wd_m),
        .block_refresh(~z80_busreq | ~busak_n), .dma_owns(~busak_n), .cap_late(sdram_cap_late),
        .hint_addr(linecop_pc_o),                        // the line copper reads its list sequentially: keep its word and the next one loaded         // the DMA cannot be stalled: no refresh while the FPGA asks for / owns the bus
        .rdata(sys_rdata), .rd_valid(sdram_rd_valid), .wr_pending(sdram_wr_pending), .init_done(sdram_init_done),
        .sd_ba(sd_ba), .sd_a(sd_a), .sd_dqm(sd_dqm), .sd_ras_n(sd_ras_n), .sd_cas_n(sd_cas_n), .sd_we_n(sd_we_n), .sd_dq(sd_dq));
`endif
    // the CPU waits while it reads a system RAM word that is not there yet
    assign sdram_wait_n = ~(busak_n & ~ld_active & ~system_ram_cs & ~rd_n_bus & ~sdram_rd_valid);
    assign chk_rdata = sys_rdata;
    assign chk_rdvalid = sdram_rd_valid;
    assign dbg2 = {vram_wr, vram_wdata, vram_rdata, vram_rdata2};
endmodule
