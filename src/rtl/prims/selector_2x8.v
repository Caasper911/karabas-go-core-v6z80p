// generated from selector_2x8.sch
module selector_2x8 (
    input wire [7:0] input_a,
    input wire [7:0] input_b,
    output wire [7:0] output_c,
    input wire select_ab
);

    wire [7:0] XLXN_28;
    wire XLXN_29;

    m2_1 XLXI_719 (.D0(input_a[0]), .D1(input_b[0]), .S0(select_ab), .O(output_c[0]));
    m2_1 XLXI_720 (.D0(input_a[1]), .D1(input_b[1]), .S0(select_ab), .O(output_c[1]));
    m2_1 XLXI_721 (.D0(input_a[2]), .D1(input_b[2]), .S0(select_ab), .O(output_c[2]));
    m2_1 XLXI_722 (.D0(input_a[3]), .D1(input_b[3]), .S0(select_ab), .O(output_c[3]));
    m2_1 XLXI_723 (.D0(input_a[4]), .D1(input_b[4]), .S0(select_ab), .O(output_c[4]));
    m2_1 XLXI_724 (.D0(input_a[5]), .D1(input_b[5]), .S0(select_ab), .O(output_c[5]));
    m2_1 XLXI_725 (.D0(input_a[6]), .D1(input_b[6]), .S0(select_ab), .O(output_c[6]));
    m2_1 XLXI_726 (.D0(input_a[7]), .D1(input_b[7]), .S0(select_ab), .O(output_c[7]));

endmodule
