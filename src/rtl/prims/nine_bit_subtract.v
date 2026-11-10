// generated from nine_bit_subtract.sch
module nine_bit_subtract (
    input wire [8:0] input_a,
    input wire [8:0] input_b,
    output wire [8:0] output_c,
    output wire active_lo_carry
);

    wire XLXN_15;
    wire XLXN_3;
    wire XLXN_4;
    wire XLXN_5;
    wire XLXN_8;

    adsu8 XLXI_1 (.A(input_a[8:1]), .ADD(XLXN_8), .B(input_b[8:1]), .CI(XLXN_5), .CO(active_lo_carry), .OFL(), .S(output_c[8:1]));
    xor2 XLXI_2 (.I0(input_b[0]), .I1(input_a[0]), .O(output_c[0]));
    nand2b1 XLXI_3 (.I0(input_a[0]), .I1(input_b[0]), .O(XLXN_5));
    gnd XLXI_4 (.G(XLXN_8));

endmodule
