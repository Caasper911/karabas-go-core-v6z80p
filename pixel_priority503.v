// generated from pixel_priority503.sch
module pixel_priority503 (
    output wire xwindow_out,
    input wire wideborder_in,
    input wire [3:0] xstartcoarse_in,
    input wire [3:0] xstopcoarse_in,
    input wire sys_clock_in,
    input wire [4:0] slb_read_addr,
    input wire [7:0] bgnd_pixel_in,
    output wire [7:0] paletteindex,
    input wire [7:0] spr_pixel_in,
    input wire sprite_cols_low,
    input wire [3:0] cpu_addr,
    input wire write_clock,
    input wire priority_reg_range,
    input wire [1:0] cpu_databus,
    input wire interleave_mode
);

    wire modified_sprite_msb;
    wire pixel_select;
    wire XLXN_1497;
    wire XLXN_1498;
    wire XLXN_1499;
    wire XLXN_1500;
    wire XLXN_1502;
    wire XLXN_1522;
    wire XLXN_1523;
    wire XLXN_1526;
    wire XLXN_1707;
    wire XLXN_1708;
    wire XLXN_1772;
    wire XLXN_1776;
    wire xstopposnosync_out;

    comp4 XLXI_1 (.A0(XLXN_1497), .A1(XLXN_1498), .A2(XLXN_1499), .A3(XLXN_1500), .B0(slb_read_addr[0]), .B1(slb_read_addr[1]), .B2(slb_read_addr[2]), .B3(slb_read_addr[3]), .EQ(XLXN_1522));
    add4 XLXI_408 (.A0(xstartcoarse_in[0]), .A1(xstartcoarse_in[1]), .A2(xstartcoarse_in[2]), .A3(xstartcoarse_in[3]), .B0(wideborder_in), .B1(XLXN_1502), .B2(XLXN_1502), .B3(XLXN_1502), .CI(XLXN_1502), .CO(), .OFL(), .S0(XLXN_1497), .S1(XLXN_1498), .S2(XLXN_1499), .S3(XLXN_1500));
    gnd XLXI_409 (.G(XLXN_1502));
    comp4 XLXI_2 (.A0(xstopcoarse_in[0]), .A1(xstopcoarse_in[1]), .A2(xstopcoarse_in[2]), .A3(xstopcoarse_in[3]), .B0(slb_read_addr[0]), .B1(slb_read_addr[1]), .B2(slb_read_addr[2]), .B3(slb_read_addr[3]), .EQ(XLXN_1523));
    and2b1 XLXI_411 (.I0(slb_read_addr[4]), .I1(XLXN_1522), .O(XLXN_1526));
    and2 XLXI_412 (.I0(slb_read_addr[4]), .I1(XLXN_1523), .O(xstopposnosync_out));
    fdrs XLXI_858 (.C(sys_clock_in), .D(xwindow_out), .R(xstopposnosync_out), .S(XLXN_1526), .Q(xwindow_out));
    m2_1e XLXI_733 (.D0(spr_pixel_in[0]), .D1(bgnd_pixel_in[0]), .E(xwindow_out), .S0(pixel_select), .O(paletteindex[0]));
    m2_1e XLXI_734 (.D0(spr_pixel_in[1]), .D1(bgnd_pixel_in[1]), .E(xwindow_out), .S0(pixel_select), .O(paletteindex[1]));
    m2_1e XLXI_736 (.D0(spr_pixel_in[3]), .D1(bgnd_pixel_in[3]), .E(xwindow_out), .S0(pixel_select), .O(paletteindex[3]));
    m2_1e XLXI_735 (.D0(spr_pixel_in[2]), .D1(bgnd_pixel_in[2]), .E(xwindow_out), .S0(pixel_select), .O(paletteindex[2]));
    m2_1e XLXI_737 (.D0(spr_pixel_in[4]), .D1(bgnd_pixel_in[4]), .E(xwindow_out), .S0(pixel_select), .O(paletteindex[4]));
    m2_1e XLXI_738 (.D0(spr_pixel_in[5]), .D1(bgnd_pixel_in[5]), .E(xwindow_out), .S0(pixel_select), .O(paletteindex[5]));
    m2_1e XLXI_739 (.D0(spr_pixel_in[6]), .D1(bgnd_pixel_in[6]), .E(xwindow_out), .S0(pixel_select), .O(paletteindex[6]));
    m2_1e XLXI_740 (.D0(modified_sprite_msb), .D1(bgnd_pixel_in[7]), .E(xwindow_out), .S0(pixel_select), .O(paletteindex[7]));
    and2b1 XLXI_968 (.I0(sprite_cols_low), .I1(spr_pixel_in[7]), .O(modified_sprite_msb));
    nor8 XLXI_935 (.I0(spr_pixel_in[7]), .I1(spr_pixel_in[6]), .I2(spr_pixel_in[5]), .I3(spr_pixel_in[4]), .I4(spr_pixel_in[3]), .I5(spr_pixel_in[2]), .I6(spr_pixel_in[1]), .I7(spr_pixel_in[0]), .O(XLXN_1772));
    m2_1e XLXI_940 (.D0(XLXN_1707), .D1(XLXN_1708), .E(interleave_mode), .S0(spr_pixel_in[7]), .O(XLXN_1776));
    or2 XLXI_936 (.I0(XLXN_1776), .I1(XLXN_1772), .O(pixel_select));
    ram16x1d_1 #(.INIT(16'hFF00)) XLXI_969 (.A0(cpu_addr[0]), .A1(cpu_addr[1]), .A2(cpu_addr[2]), .A3(cpu_addr[3]), .D(cpu_databus[0]), .DPRA0(bgnd_pixel_in[4]), .DPRA1(bgnd_pixel_in[5]), .DPRA2(bgnd_pixel_in[6]), .DPRA3(bgnd_pixel_in[7]), .WCLK(write_clock), .WE(priority_reg_range), .DPO(XLXN_1707), .SPO());
    ram16x1d_1 XLXI_970 (.A0(cpu_addr[0]), .A1(cpu_addr[1]), .A2(cpu_addr[2]), .A3(cpu_addr[3]), .D(cpu_databus[1]), .DPRA0(bgnd_pixel_in[4]), .DPRA1(bgnd_pixel_in[5]), .DPRA2(bgnd_pixel_in[6]), .DPRA3(bgnd_pixel_in[7]), .WCLK(write_clock), .WE(priority_reg_range), .DPO(XLXN_1708), .SPO());

endmodule
