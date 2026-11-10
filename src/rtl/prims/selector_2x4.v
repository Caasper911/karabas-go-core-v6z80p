// generated from selector_2x4.sch
module selector_2x4 (
    input wire [3:0] input_a,
    input wire [3:0] input_b,
    output wire [3:0] output_c,
    input wire select_ab
);

    wire XLXN_31;

    m2_1 XLXI_719 (.D0(input_a[0]), .D1(input_b[0]), .S0(select_ab), .O(output_c[0]));
    m2_1 XLXI_720 (.D0(input_a[1]), .D1(input_b[1]), .S0(select_ab), .O(output_c[1]));
    m2_1 XLXI_721 (.D0(input_a[2]), .D1(input_b[2]), .S0(select_ab), .O(output_c[2]));
    m2_1 XLXI_722 (.D0(input_a[3]), .D1(input_b[3]), .S0(select_ab), .O(output_c[3]));

endmodule
