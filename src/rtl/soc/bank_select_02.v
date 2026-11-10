// generated from bank_select_02.sch
module bank_select_02 (
    output wire sysram_a16,
    output wire sysram_a18,
    input wire write_bank_en,
    output wire sysram_a17,
    output wire sysram_a15,
    input wire cpua15,
    input wire [3:0] hi_bank,
    input wire [3:0] lo_bank,
    input wire inhibits,
    input wire mreq,
    output wire sysram_cs,
    input wire [3:0] wr_bank,
    input wire any_page
);

    wire banksel_norm_a;
    wire banksel_norm_b;
    wire banksel_norm_c;
    wire banksel_norm_d;
    wire XLXN_106;
    wire XLXN_110;
    wire XLXN_113;
    wire XLXN_125;
    wire XLXN_129;
    wire XLXN_132;
    wire XLXN_158;
    wire XLXN_162;
    wire XLXN_165;
    wire XLXN_183;
    wire XLXN_184;
    wire XLXN_185;
    wire XLXN_186;
    wire XLXN_195;
    wire XLXN_196;
    wire XLXN_197;
    wire XLXN_198;
    wire XLXN_199;
    wire XLXN_200;
    wire XLXN_202;
    wire XLXN_203;
    wire XLXN_204;
    wire XLXN_92;
    wire XLXN_93;

    or2 XLXI_41 (.I0(XLXN_92), .I1(XLXN_93), .O(sysram_a15));
    m2_1 XLXI_56 (.D0(lo_bank[0]), .D1(hi_bank[0]), .S0(cpua15), .O(banksel_norm_a));
    m2_1 XLXI_57 (.D0(lo_bank[1]), .D1(hi_bank[1]), .S0(cpua15), .O(banksel_norm_b));
    m2_1 XLXI_58 (.D0(lo_bank[2]), .D1(hi_bank[2]), .S0(cpua15), .O(banksel_norm_c));
    m2_1 XLXI_59 (.D0(lo_bank[3]), .D1(hi_bank[3]), .S0(cpua15), .O(banksel_norm_d));
    or2 XLXI_42 (.I0(inhibits), .I1(mreq), .O(sysram_cs));
    m2_1 XLXI_72 (.D0(banksel_norm_a), .D1(wr_bank[0]), .S0(XLXN_197), .O(XLXN_92));
    m2_1 XLXI_73 (.D0(banksel_norm_b), .D1(wr_bank[1]), .S0(XLXN_197), .O(sysram_a16));
    m2_1 XLXI_74 (.D0(banksel_norm_c), .D1(wr_bank[2]), .S0(XLXN_197), .O(sysram_a17));
    m2_1 XLXI_75 (.D0(banksel_norm_d), .D1(wr_bank[3]), .S0(XLXN_197), .O(sysram_a18));
    and2 XLXI_76 (.I0(cpua15), .I1(write_bank_en), .O(XLXN_197));
    and5b4 XLXI_77 (.I0(sysram_a16), .I1(sysram_a17), .I2(sysram_a18), .I3(any_page), .I4(cpua15), .O(XLXN_93));

endmodule
