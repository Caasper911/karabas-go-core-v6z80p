// generated from line_cop_04.sch
module line_cop_04 (
    input wire vrt_last_cycle,
    input wire main_clock,
    input wire [7:0] cpu_databus,
    output wire linecop_busy,
    input wire linecop_start,
    output wire reg_wr,
    output wire [10:0] reg_addr,
    input wire [8:0] scanline,
    input wire last_sl_cycles,
    output wire [18:0] lsrw_pc,
    input wire [18:0] linecop_addr,
    input wire mem_ready            // Karabas Go port: 1 = the system RAM data of the current address is valid (the SDRAM controller's rd_valid)
);

    wire state_zero_r, state_one_r, stall;    // Karabas Go port: the wait for the SDRAM (see XLXI_25)
    wire [7:0] high_byte;
    wire inc_waitline;
    wire linecop_enabled;
    wire next_instruction;
    wire [15:0] set_lcpcaddr;
    wire set_waitline;
    wire state_one;
    wire state_two;
    wire state_zero;
    wire [7:0] waitline;
    wire waitline_msb;
    wire XLXN_158;
    wire XLXN_278;
    wire XLXN_304;
    wire XLXN_307;
    wire XLXN_309;
    wire XLXN_310;
    wire XLXN_313;
    wire XLXN_317;
    wire XLXN_318;
    wire XLXN_368;
    wire XLXN_369;
    wire XLXN_394;
    wire XLXN_402;
    wire XLXN_422;
    wire XLXN_423;
    wire XLXN_424;
    wire XLXN_453;
    wire XLXN_466;
    wire XLXN_473;
    wire XLXN_481;
    wire XLXN_494;
    wire XLXN_5;
    wire XLXN_513;
    wire XLXN_519;
    wire XLXN_547;
    wire XLXN_557;
    wire XLXN_559;
    wire XLXN_564;
    wire XLXN_566;
    wire XLXN_567;
    wire XLXN_568;
    wire [14:0] XLXN_570;
    wire [14:0] XLXN_571;
    wire XLXN_572;
    wire [14:0] XLXN_573;
    wire XLXN_576;
    wire XLXN_579;
    wire XLXN_580;
    wire XLXN_599;
    wire XLXN_60;
    wire XLXN_610;
    wire XLXN_615;
    wire XLXN_617;
    wire XLXN_618;
    wire XLXN_619;
    wire XLXN_62;
    wire XLXN_621;
    wire XLXN_622;
    wire XLXN_623;
    wire [15:0] XLXN_631;
    wire XLXN_633;
    wire XLXN_634;
    wire XLXN_67;
    wire XLXN_68;

    fd8re XLXI_26 (.C(main_clock), .CE(state_zero), .D(cpu_databus[7:0]), .R(vrt_last_cycle), .Q(high_byte[7:0]));
    and3 XLXI_34 (.I0(state_one), .I1(high_byte[7]), .I2(high_byte[6]), .O(set_waitline));
    fd XLXI_109 (.C(main_clock), .D(XLXN_310), .Q(reg_wr));
    and2b1 XLXI_111 (.I0(high_byte[7]), .I1(state_one), .O(XLXN_309));
    inv XLXI_117 (.I(XLXN_309), .O(XLXN_310));
    cb4cle XLXI_126 (.C(main_clock), .CE(XLXN_369), .CLR(XLXN_424), .D0(high_byte[0]), .D1(high_byte[1]), .D2(high_byte[2]), .D3(XLXN_424), .L(XLXN_158), .CEO(), .Q0(reg_addr[8]), .Q1(reg_addr[9]), .Q2(reg_addr[10]), .Q3(), .TC());
    and2 XLXI_128 (.I0(state_two), .I1(high_byte[6]), .O(XLXN_368));
    gnd XLXI_127 (.G(XLXN_424));
    cb8cle XLXI_125 (.C(main_clock), .CE(XLXN_368), .CLR(XLXN_424), .D(cpu_databus[7:0]), .L(XLXN_158), .CEO(XLXN_369), .Q(reg_addr[7:0]), .TC());
    and3b1 XLXI_67 (.I0(high_byte[6]), .I1(high_byte[7]), .I2(state_one), .O(XLXN_158));
    cb8cle XLXI_144 (.C(main_clock), .CE(inc_waitline), .CLR(XLXN_402), .D(cpu_databus[7:0]), .L(set_waitline), .CEO(XLXN_394), .Q(waitline[7:0]), .TC());
    fdrse XLXI_145 (.C(main_clock), .CE(set_waitline), .D(high_byte[0]), .R(vrt_last_cycle), .S(XLXN_394), .Q(waitline_msb));
    fd XLXI_149 (.C(main_clock), .D(vrt_last_cycle), .Q(XLXN_402));
    and2 XLXI_146 (.I0(state_two), .I1(high_byte[5]), .O(inc_waitline));
    comp8 XLXI_1 (.A(scanline[7:0]), .B(waitline[7:0]), .EQ(XLXN_5));
    fdrs #(.INIT(1'b1)) XLXI_22 (.C(main_clock), .D(XLXN_62), .R(XLXN_60), .S(XLXN_278), .Q(XLXN_62));
    inv XLXI_23 (.I(XLXN_62), .O(linecop_busy));
    and4 XLXI_118 (.I0(linecop_start), .I1(XLXN_318), .I2(XLXN_5), .I3(linecop_enabled), .O(XLXN_60));
    xor2 XLXI_3 (.I0(waitline_msb), .I1(scanline[8]), .O(XLXN_317));
    inv XLXI_121 (.I(XLXN_317), .O(XLXN_318));
    or4 XLXI_148 (.I0(inc_waitline), .I1(XLXN_313), .I2(set_waitline), .I3(linecop_start), .O(XLXN_278));
    and2 XLXI_120 (.I0(next_instruction), .I1(last_sl_cycles), .O(XLXN_313));
    cb2re XLXI_24 (.C(main_clock), .CE(linecop_busy & ~stall), .R(XLXN_307), .CEO(), .Q0(XLXN_67), .Q1(XLXN_68), .TC());
    // Karabas Go port: the list is in the SDRAM.  The original reads it in state 0 (high byte) and state 1 (low byte) with the data taken at the end
    // of the clk16 cycle (6 ticks of 96 MHz): a sequential list is read ahead by the controller, but after a jump (a write with restart, bit 12)
    // the word at the new PC needs a full SDRAM access.  The copper now waits there: while a read state has no valid data the state counter
    // stops and the state signals of the logic are held off (nothing is latched); the address (lsrw_pc) stays.
    assign stall = linecop_busy & (state_zero_r | state_one_r) & ~mem_ready;
    assign state_zero = state_zero_r & ~stall;
    assign state_one  = state_one_r & ~stall;
    d2_4e XLXI_25 (.A0(XLXN_67), .A1(XLXN_68), .E(linecop_busy), .D0(state_zero_r), .D1(state_one_r), .D2(state_two), .D3());
    or2 XLXI_116 (.I0(next_instruction), .I1(linecop_start), .O(XLXN_307));
    buf_x XLXI_122 (.I(state_zero_r), .O(lsrw_pc[0]));   // the address of the read state, also while it waits
    and2 XLXI_154 (.I0(high_byte[4]), .I1(state_two), .O(XLXN_422));
    and2 XLXI_87 (.I0(high_byte[7]), .I1(state_one), .O(XLXN_304));
    buf_x XLXI_196 (.I(linecop_addr[0]), .O(linecop_enabled));
    or2 XLXI_113 (.I0(XLXN_304), .I1(state_two), .O(next_instruction));
    or3b1 XLXI_214 (.I0(linecop_enabled), .I1(XLXN_422), .I2(vrt_last_cycle), .O(XLXN_423));
    cb16cle XLXI_216 (.C(main_clock), .CE(next_instruction), .CLR(XLXN_634), .D(set_lcpcaddr[15:0]), .L(XLXN_423), .CEO(XLXN_580), .Q(XLXN_631[15:0]), .TC());
    cb2cle XLXI_217 (.C(main_clock), .CE(XLXN_580), .CLR(XLXN_634), .D0(linecop_addr[17]), .D1(linecop_addr[18]), .L(XLXN_423), .CEO(), .Q0(lsrw_pc[17]), .Q1(lsrw_pc[18]), .TC());
    gnd XLXI_151 (.G(XLXN_634));
    buf_x XLXI_232 [0:15] (.I(linecop_addr[16:1]), .O(set_lcpcaddr[15:0]));
    buf_x XLXI_233 [15:0] (.I(XLXN_631[15:0]), .O(lsrw_pc[16:1]));

endmodule
