// generated from z80_video_interface.sch
module z80_video_interface (
    output wire vram_bus_switch_out,
    output wire reg_rd,
    input wire rd_cpu,
    output wire fpga_to_cpudatabus_oe,
    output wire fpga_to_vramdatabus_oe,
    input wire vram_access_in,
    output wire vram_rd_out,
    input wire ywindow_in,
    output wire vram_wren_out,
    input wire ok_to_start_gfx_line,
    output wire start_linegen_out,
    input wire vbusy_stop_in,
    input wire clock_cpu,
    input wire blitter_active,
    output wire cpu_wait_out,
    input wire selected_600_7ff,
    input wire cpu_a8
);

    wire blitter_blocks_cpu_vram_access;
    wire cpu_wait_for_blitter;
    wire vidsys_inhibits_cpu_vram_rw;
    wire vidsys_potential_wait;
    wire XLXN_248;
    wire XLXN_421;
    wire XLXN_448;
    wire XLXN_662;
    wire XLXN_667;
    wire XLXN_712;
    wire XLXN_713;
    wire XLXN_734;
    wire XLXN_769;
    wire XLXN_846;
    wire XLXN_847;

    and2 XLXI_22 (.I0(reg_rd), .I1(vram_access_in), .O(XLXN_846));
    or2 XLXI_43 (.I0(vram_access_in), .I1(rd_cpu), .O(XLXN_248));
    or2b1 XLXI_44 (.I0(XLXN_248), .I1(vram_bus_switch_out), .O(fpga_to_vramdatabus_oe));
    or2 XLXI_23 (.I0(XLXN_846), .I1(rd_cpu), .O(fpga_to_cpudatabus_oe));
    and2b1 XLXI_89 (.I0(vram_bus_switch_out), .I1(XLXN_712), .O(vram_rd_out));
    fdrs XLXI_16 (.C(clock_cpu), .D(vidsys_potential_wait), .R(XLXN_713), .S(XLXN_421), .Q(vidsys_potential_wait));
    fdrs XLXI_18 (.C(clock_cpu), .D(XLXN_769), .R(XLXN_847), .S(vidsys_inhibits_cpu_vram_rw), .Q(XLXN_769));
    fdrs XLXI_17 (.C(clock_cpu), .D(vidsys_inhibits_cpu_vram_rw), .R(XLXN_713), .S(vidsys_potential_wait), .Q(vidsys_inhibits_cpu_vram_rw));
    and2 XLXI_148 (.I0(ywindow_in), .I1(ok_to_start_gfx_line), .O(XLXN_421));
    and2b1 XLXI_155 (.I0(XLXN_448), .I1(vram_bus_switch_out), .O(start_linegen_out));
    fd XLXI_154 (.C(clock_cpu), .D(vram_bus_switch_out), .Q(XLXN_448));
    fd XLXI_198 (.C(clock_cpu), .D(blitter_active), .Q(XLXN_662));
    fd XLXI_199 (.C(clock_cpu), .D(XLXN_662), .Q(XLXN_734));
    or2 XLXI_208 (.I0(XLXN_248), .I1(blitter_blocks_cpu_vram_access), .O(XLXN_712));
    fd XLXI_210 (.C(clock_cpu), .D(vbusy_stop_in), .Q(XLXN_713));
    or3 XLXI_216 (.I0(XLXN_734), .I1(XLXN_662), .I2(blitter_active), .O(blitter_blocks_cpu_vram_access));
    or2b1 XLXI_110 (.I0(vidsys_potential_wait), .I1(vram_access_in), .O(XLXN_667));
    and2 XLXI_205 (.I0(cpu_wait_for_blitter), .I1(XLXN_667), .O(cpu_wait_out));
    or2b1 XLXI_219 (.I0(blitter_blocks_cpu_vram_access), .I1(vram_access_in), .O(cpu_wait_for_blitter));
    and2b1 XLXI_222 (.I0(blitter_active), .I1(XLXN_769), .O(vram_bus_switch_out));
    or3 XLXI_225 (.I0(blitter_blocks_cpu_vram_access), .I1(vidsys_inhibits_cpu_vram_rw), .I2(vram_access_in), .O(vram_wren_out));
    or2 XLXI_228 (.I0(XLXN_713), .I1(vbusy_stop_in), .O(XLXN_847));
    or3b1 XLXI_231 (.I0(cpu_a8), .I1(selected_600_7ff), .I2(rd_cpu), .O(reg_rd));

endmodule
