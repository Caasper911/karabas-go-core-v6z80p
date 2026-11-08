// generated from video_selects_4.sch
module video_selects_4 (
    input wire addra13,
    input wire addra12,
    input wire addra15,
    input wire addra14,
    input wire cpumreq,
    input wire cpurd,
    input wire all_vram_wr_mode,
    input wire page_in_vram,
    output wire vram_selected,
    input wire [2:0] vram_loc,
    input wire addra11,
    input wire page_in_sprite_ram,
    output wire video_registers_select,
    output wire sprite_ram_select
);

    wire first_4kb_inhibit;
    wire vram_loc_matches;
    wire XLXN_113;
    wire XLXN_116;
    wire XLXN_117;
    wire XLXN_118;
    wire XLXN_300;
    wire XLXN_302;
    wire XLXN_323;
    wire XLXN_381;
    wire XLXN_410;
    wire XLXN_413;
    wire XLXN_416;

    m2_1 XLXI_118 (.D0(XLXN_302), .D1(XLXN_323), .S0(all_vram_wr_mode), .O(XLXN_300));
    or2 XLXI_121 (.I0(XLXN_300), .I1(cpumreq), .O(vram_selected));
    or2b1 XLXI_123 (.I0(page_in_vram), .I1(vram_loc_matches), .O(XLXN_302));
    xnor2 XLXI_35 (.I0(addra13), .I1(XLXN_413), .O(XLXN_116));
    xnor2 XLXI_36 (.I0(addra14), .I1(vram_loc[1]), .O(XLXN_117));
    xnor2 XLXI_37 (.I0(addra15), .I1(vram_loc[2]), .O(XLXN_118));
    nand3 XLXI_88 (.I0(XLXN_116), .I1(XLXN_117), .I2(XLXN_118), .O(vram_loc_matches));
    or2b1 XLXI_131 (.I0(cpurd), .I1(first_4kb_inhibit), .O(XLXN_323));
    and2b1 XLXI_32 (.I0(page_in_vram), .I1(all_vram_wr_mode), .O(XLXN_113));
    and2 XLXI_151 (.I0(page_in_vram), .I1(XLXN_381), .O(first_4kb_inhibit));
    nor4 XLXI_84 (.I0(addra12), .I1(addra13), .I2(addra14), .I3(addra15), .O(XLXN_381));
    or4 XLXI_155 (.I0(XLXN_410), .I1(XLXN_113), .I2(addra12), .I3(addra11), .O(video_registers_select));
    or4b2 XLXI_156 (.I0(page_in_sprite_ram), .I1(addra12), .I2(all_vram_wr_mode), .I3(XLXN_410), .O(sprite_ram_select));
    or4 XLXI_153 (.I0(cpumreq), .I1(addra15), .I2(addra14), .I3(addra13), .O(XLXN_410));
    nor2 XLXI_157 (.I0(addra15), .I1(addra14), .O(XLXN_416));
    or2 XLXI_158 (.I0(vram_loc[0]), .I1(XLXN_416), .O(XLXN_413));

endmodule
