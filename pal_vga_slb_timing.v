// generated from pal_vga_slb_timing.sch
module pal_vga_slb_timing (
    output wire [7:0] slb_word_address,
    output wire blkram_en,
    input wire vga_mode,
    input wire scanline_tc,
    output wire zero_wr_en,
    input wire vga_scanline_tc,
    output wire latch_en_byte_select,
    input wire clock_16mhz
);

    wire XLXN_136;
    wire XLXN_198;
    wire XLXN_199;
    wire XLXN_227;
    wire XLXN_232;
    wire XLXN_282;
    wire XLXN_295;
    wire XLXN_299;
    wire XLXN_300;
    wire XLXN_301;
    wire XLXN_302;
    wire XLXN_303;
    wire XLXN_304;
    wire XLXN_317;
    wire XLXN_318;
    wire XLXN_320;
    wire XLXN_323;
    wire XLXN_333;
    wire XLXN_335;
    wire XLXN_42;
    wire XLXN_64;

    cb8re XLXI_3 (.C(clock_16mhz), .CE(XLXN_282), .R(XLXN_227), .CEO(), .Q(slb_word_address[7:0]), .TC());
    fdrs XLXI_126 (.C(clock_16mhz), .D(XLXN_232), .R(scanline_tc), .S(XLXN_295), .Q(XLXN_232));
    fdr XLXI_124 (.C(clock_16mhz), .D(XLXN_64), .R(XLXN_227), .Q(XLXN_42));
    fdre XLXI_125 (.C(clock_16mhz), .CE(XLXN_64), .D(XLXN_199), .R(XLXN_227), .Q(XLXN_136));
    inv XLXI_34 (.I(XLXN_136), .O(XLXN_199));
    or2 XLXI_123 (.I0(vga_mode), .I1(XLXN_199), .O(XLXN_198));
    and2 XLXI_35 (.I0(XLXN_42), .I1(XLXN_198), .O(XLXN_282));
    m2_1 XLXI_87 (.D0(XLXN_136), .D1(XLXN_42), .S0(vga_mode), .O(latch_en_byte_select));
    inv XLXI_33 (.I(XLXN_42), .O(XLXN_64));
    or2 XLXI_129 (.I0(scanline_tc), .I1(vga_scanline_tc), .O(XLXN_227));
    or2 XLXI_86 (.I0(XLXN_64), .I1(vga_mode), .O(blkram_en));
    or2b1 XLXI_157 (.I0(vga_mode), .I1(vga_scanline_tc), .O(XLXN_295));
    and2 XLXI_154 (.I0(latch_en_byte_select), .I1(XLXN_232), .O(zero_wr_en));

endmodule
