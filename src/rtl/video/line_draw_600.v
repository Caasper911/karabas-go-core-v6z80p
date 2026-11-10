// generated from line_draw_600.sch
module line_draw_600 (
    input wire clk_fast,          // Karabas Go port: the registers written by the CPU / line copper run on the fast clock,
    input wire wr_pulse,          // enabled by one pulse at the start of each write (they were clocked by the write strobe)
    output wire [18:0] vram_addr,
    input wire [7:0] cpu_databus,
    input wire main_clock,
    input wire cpu_write,
    output wire ld_has_bus,
    output wire ld_pending,
    input wire vram_datafetch,
    output wire vram_wr,
    input wire [4:0] addr_bus,
    input wire dev_selected
);

    wire [3:0] active_sel;
    wire [18:0] add_input;
    wire addr_chen;
    wire [15:0] d_accum_out;
    wire end_ld;
    wire force_reg_a;
    wire force_reg_c;
    wire force_reg_d;
    wire ld_running;
    wire lsb_wren;
    wire msb_wren;
    wire octant_code_a;
    wire octant_code_b;
    wire octant_code_c;
    wire phase_b;
    wire [3:0] readsel;
    wire reg_buffer_sel;
    wire [15:0] reg_values;
    wire [15:0] set_pixel_count;
    wire [3:0] setup_sel;
    wire vram_upden;
    wire XLXN_1031;
    wire XLXN_1086;
    wire XLXN_1142;
    wire XLXN_1143;
    wire XLXN_1146;
    wire [18:0] XLXN_1166;
    wire XLXN_1185;
    wire XLXN_1188;
    wire XLXN_1189;
    wire XLXN_119;
    wire XLXN_1190;
    wire XLXN_1199;
    wire XLXN_120;
    wire XLXN_231;
    wire XLXN_264;
    wire XLXN_288;
    wire [15:0] XLXN_35;
    wire XLXN_404;
    wire XLXN_554;
    wire XLXN_556;
    wire XLXN_637;
    wire XLXN_638;
    wire XLXN_639;
    wire XLXN_640;
    wire XLXN_641;
    wire XLXN_650;
    wire XLXN_672;
    wire XLXN_673;
    wire XLXN_856;
    wire XLXN_860;

    add16 XLXI_25 (.A(reg_values[15:0]), .B(d_accum_out[15:0]), .CI(XLXN_119), .CO(), .OFL(), .S(XLXN_35[15:0]));
    fd16re XLXI_27 (.C(main_clock), .CE(XLXN_404), .D(XLXN_35[15:0]), .R(force_reg_d), .Q(d_accum_out[15:0]));
    gnd XLXI_67 (.G(XLXN_119));
    gnd XLXI_68 (.G(XLXN_120));
    gnd XLXI_90 (.G(XLXN_231));
    cb16cled XLXI_114 (.C(main_clock), .CE(XLXN_860), .CLR(XLXN_231), .D(set_pixel_count[15:0]), .L(force_reg_d), .UP(XLXN_231), .CEO(), .Q(), .TC(end_ld));
    or2 XLXI_172 (.I0(XLXN_860), .I1(force_reg_a), .O(XLXN_404));
    buf_x XLXI_216 (.I(phase_b), .O(active_sel[3]));
    or2 XLXI_227 (.I0(addr_chen), .I1(force_reg_c), .O(vram_upden));
    fd XLXI_228 (.C(main_clock), .D(d_accum_out[15]), .Q(XLXN_1086));
    and2b1 XLXI_240 (.I0(phase_b), .I1(ld_running), .O(XLXN_860));
    fde XLXI_258 (.C(main_clock), .CE(XLXN_639), .D(XLXN_641), .Q(ld_has_bus));
    fdr XLXI_259 (.C(main_clock), .D(ld_has_bus), .R(XLXN_640), .Q(ld_running));
    fd XLXI_260 (.C(main_clock), .D(ld_running), .Q(XLXN_637));
    fd XLXI_261 (.C(main_clock), .D(XLXN_637), .Q(XLXN_638));
    nor3 XLXI_272 (.I0(ld_running), .I1(XLXN_637), .I2(XLXN_638), .O(XLXN_639));
    fdrs XLXI_257 (.C(main_clock), .D(ld_pending), .R(end_ld), .S(force_reg_a), .Q(ld_pending));
    and2b1 XLXI_262 (.I0(XLXN_650), .I1(ld_pending), .O(XLXN_641));
    inv XLXI_273 (.I(XLXN_641), .O(XLXN_640));
    or2 XLXI_274 (.I0(end_ld), .I1(vram_datafetch), .O(XLXN_650));
    inv XLXI_232 (.I(ld_running), .O(XLXN_556));
    fdr XLXI_230 (.C(main_clock), .D(XLXN_554), .R(XLXN_556), .Q(phase_b));
    inv XLXI_231 (.I(phase_b), .O(XLXN_554));
    nand2b1 XLXI_265 (.I0(XLXN_673), .I1(XLXN_672), .O(vram_wr));
    fd_1 XLXI_275 (.C(main_clock), .D(XLXN_672), .Q(XLXN_673));
    fdr XLXI_277 (.C(main_clock), .D(XLXN_856), .R(end_ld), .Q(XLXN_672));
    and2 XLXI_278 (.I0(XLXN_554), .I1(ld_running), .O(XLXN_856));
    fd XLXI_279 (.C(main_clock), .D(XLXN_860), .Q(addr_chen));
    ram_dual_8in16outx16 XLXI_322 (.data_in(cpu_databus[7:0]), .data_out(reg_values[15:0]), .lsb_wr_en(lsb_wren & wr_pulse), .msb_wr_en(msb_wren & wr_pulse), .read_addr(readsel[3:0]), .write_addr(addr_bus[4:1]), .write_clock(clk_fast));
    buf_x XLXI_326 (.I(force_reg_d), .O(setup_sel[0]));
    or2 XLXI_332 (.I0(force_reg_d), .I1(force_reg_c), .O(setup_sel[1]));
    selector_2x4 XLXI_334 (.input_a(setup_sel[3:0]), .input_b(active_sel[3:0]), .output_c(readsel[3:0]), .select_ab(ld_pending));
    buf_x XLXI_335 (.I(reg_buffer_sel), .O(setup_sel[2]));
    gnd XLXI_336 (.G(setup_sel[3]));
    m2_1 XLXI_340 (.D0(d_accum_out[15]), .D1(XLXN_1143), .S0(phase_b), .O(active_sel[0]));
    m2_1e XLXI_343 (.D0(octant_code_b), .D1(octant_code_c), .E(phase_b), .S0(XLXN_1086), .O(active_sel[1]));
    m2_1 XLXI_344 (.D0(reg_buffer_sel), .D1(XLXN_1086), .S0(phase_b), .O(active_sel[2]));
    buf_x XLXI_345 [8:0] (.I(reg_values[8:0]), .O(set_pixel_count[8:0]));
    gnd XLXI_346 [6:0] (.G(set_pixel_count[15:9]));
    inv XLXI_360 (.I(cpu_write), .O(XLXN_1142));
    m2_1 XLXI_361 (.D0(octant_code_a), .D1(octant_code_b), .S0(XLXN_1146), .O(XLXN_1143));
    and2 XLXI_362 (.I0(XLXN_1086), .I1(octant_code_c), .O(XLXN_1146));
    vcc XLXI_119 (.P(XLXN_264));
    fd XLXI_174 (.C(main_clock), .D(XLXN_288), .Q(force_reg_d));
    fd XLXI_175 (.C(main_clock), .D(force_reg_d), .Q(force_reg_c));
    fd XLXI_239 (.C(main_clock), .D(force_reg_c), .Q(force_reg_a));
    and2 XLXI_14 (.I0(dev_selected), .I1(addr_bus[0]), .O(msb_wren));
    and2b1 XLXI_13 (.I0(addr_bus[0]), .I1(dev_selected), .O(lsb_wren));
    fdce XLXI_328 (.C(clk_fast), .CE((XLXN_1031) & wr_pulse), .CLR(force_reg_d), .D(XLXN_264), .Q(XLXN_288));
    and4b1 XLXI_245 (.I0(addr_bus[4]), .I1(addr_bus[2]), .I2(addr_bus[1]), .I3(msb_wren), .O(XLXN_1031));
    fde XLXI_327 (.C(clk_fast), .CE((XLXN_1031) & wr_pulse), .D(addr_bus[3]), .Q(reg_buffer_sel));
    add19 XLXI_363 (.A(add_input[18:0]), .B(vram_addr[18:0]), .CI(XLXN_120), .C(XLXN_1166[18:0]));
    fd19re XLXI_364 (.C(main_clock), .CE(vram_upden), .D(XLXN_1166[18:0]), .Q(vram_addr[18:0]), .R(force_reg_d));
    buf_x XLXI_365 [15:0] (.I(reg_values[15:0]), .O(add_input[15:0]));
    fde XLXI_357 (.C(main_clock), .CE(force_reg_d), .D(reg_values[14]), .Q(octant_code_c));
    fde XLXI_358 (.C(main_clock), .CE(force_reg_d), .D(reg_values[13]), .Q(octant_code_b));
    fde XLXI_359 (.C(main_clock), .CE(force_reg_d), .D(reg_values[12]), .Q(octant_code_a));
    or2 XLXI_372 (.I0(reg_values[15]), .I1(reg_values[9]), .O(XLXN_1185));
    or2 XLXI_374 (.I0(XLXN_1199), .I1(XLXN_1188), .O(add_input[16]));
    or2 XLXI_375 (.I0(XLXN_1199), .I1(XLXN_1189), .O(add_input[17]));
    or2 XLXI_376 (.I0(XLXN_1199), .I1(XLXN_1190), .O(add_input[18]));
    and2 XLXI_377 (.I0(ld_pending), .I1(reg_values[15]), .O(XLXN_1199));
    fdre XLXI_378 (.C(main_clock), .CE(force_reg_d), .D(XLXN_1185), .R(force_reg_c), .Q(XLXN_1188));
    fdre XLXI_379 (.C(main_clock), .CE(force_reg_d), .D(reg_values[10]), .R(force_reg_c), .Q(XLXN_1189));
    fdre XLXI_380 (.C(main_clock), .CE(force_reg_d), .D(reg_values[11]), .R(force_reg_c), .Q(XLXN_1190));

endmodule
