// generated from selector_2x3.sch
module selector_2x3 (
    input wire [2:0] input_a,
    input wire [2:0] input_b,
    output wire [2:0] output_c,
    input wire select_ab
);


    m2_1 XLXI_719 (.D0(input_a[0]), .D1(input_b[0]), .S0(select_ab), .O(output_c[0]));
    m2_1 XLXI_720 (.D0(input_a[1]), .D1(input_b[1]), .S0(select_ab), .O(output_c[1]));
    m2_1 XLXI_721 (.D0(input_a[2]), .D1(input_b[2]), .S0(select_ab), .O(output_c[2]));

endmodule
