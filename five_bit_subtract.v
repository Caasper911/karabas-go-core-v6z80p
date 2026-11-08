// generated from five_bit_subtract.sch
module five_bit_subtract (
    output wire active_lo_carry,
    output wire [4:0] output_c,
    input wire [4:0] input_b,
    input wire [4:0] input_a
);

    wire XLXN_5;
    wire XLXN_8;

    nand2b1 XLXI_3 (.I0(input_a[0]), .I1(input_b[0]), .O(XLXN_5));
    xor2 XLXI_2 (.I0(input_b[0]), .I1(input_a[0]), .O(output_c[0]));
    adsu4 XLXI_5 (.A0(input_a[1]), .A1(input_a[2]), .A2(input_a[3]), .A3(input_a[4]), .ADD(XLXN_8), .B0(input_b[1]), .B1(input_b[2]), .B2(input_b[3]), .B3(input_b[4]), .CI(XLXN_5), .CO(active_lo_carry), .OFL(), .S0(output_c[1]), .S1(output_c[2]), .S2(output_c[3]), .S3(output_c[4]));
    gnd XLXI_4 (.G(XLXN_8));

endmodule
