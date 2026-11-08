// generated from rom_select.sch
module rom_select (
    input wire a11_in,
    input wire a12_in,
    input wire a13_in,
    input wire a14_in,
    input wire a15_in,
    input wire mreq_in,
    input wire a9_in,
    input wire a10_in,
    output wire rom_selected
);

    wire XLXN_2;
    wire XLXN_3;
    wire XLXN_4;

    or8 XLXI_3 (.I0(a9_in), .I1(a10_in), .I2(a11_in), .I3(a12_in), .I4(a13_in), .I5(a14_in), .I6(a15_in), .I7(mreq_in), .O(rom_selected));

endmodule
