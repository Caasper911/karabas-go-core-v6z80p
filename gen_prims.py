#!/usr/bin/env python3
"""Generate kg_prims.v: behavioural models of the Xilinx schematic library symbols
used by OSCA (Spartan-II era), written to be synthesisable on Spartan-6 (ISE 14.7 / XST)."""
import re
L = []
def w(s): L.append(s)

# ---------------------------------------------------------------- constants / buffers
w("module gnd(output G); assign G = 1'b0; endmodule")
w("module vcc(output P); assign P = 1'b1; endmodule")
w("module buf_x(input I, output O); assign O = I; endmodule")   # 'buf' is a Verilog keyword
w("module inv(input I, output O); assign O = ~I; endmodule")
for n in ("ibuf", "obuf", "ibufg"):
    w(f"module {n}(input I, output O); assign O = I; endmodule")
for n in ("ibuf8", "ibuf16"):
    k = int(n[4:]); w(f"module {n}(input [{k-1}:0] I, output [{k-1}:0] O); assign O = I; endmodule")
# 3-state: T=1 -> high-Z.   BUFE: E=1 -> enabled
w("module obuft(input I, input T, output O); assign O = T ? 1'bz : I; endmodule")
w("module buft(input I, input T, output O); assign O = T ? 1'b0 : I; endmodule")
w("module bufe(input I, input E, output O); assign O = E ? I : 1'b0; endmodule")
for k in (8, 16):
    w(f"module obuft{k}(input [{k-1}:0] I, input T, output [{k-1}:0] O); assign O = T ? {{{k}{{1'bz}}}} : I; endmodule")
    w(f"module buft{k}(input [{k-1}:0] I, input T, output [{k-1}:0] O); assign O = T ? {{{k}{{1'b0}}}} : I; endmodule")
    w(f"module bufe{k}(input [{k-1}:0] I, input E, output [{k-1}:0] O); assign O = E ? I : {{{k}{{1'b0}}}}; endmodule")

# ---------------------------------------------------------------- gates (bN = first N inputs inverted)
def gate(name, n, b, op, neg):
    ins = []
    for i in range(n):
        ins.append(f"~I{i}" if i < b else f"I{i}")
    expr = op.join(ins)
    if neg: expr = f"~({expr})"
    pins = ", ".join(f"I{i}" for i in range(n))
    w(f"module {name}(input {pins}, output O); assign O = {expr}; endmodule")
for nm in """and2 and2b1 and2b2 and3 and3b1 and3b2 and4 and4b1 and4b2 and4b4 and5 and5b1 and5b2 and5b3 and5b4
and6 and7 and8 and9 nand2b1 nand3 nand5 nor2 nor3 nor4 nor6 nor7 nor8 or12 or2 or2b1 or3 or3b1 or3b2 or4 or4b2
or5 or5b1 or8 or9 xor2 xnor2""".split():
    m = re.fullmatch(r'(and|nand|or|nor|xor|xnor)(\d+)(?:b(\d+))?', nm)
    kind, n, b = m.group(1), int(m.group(2)), int(m.group(3) or 0)
    op = {'and':'&','nand':'&','or':'|','nor':'|','xor':'^','xnor':'^'}[kind]
    gate(nm, n, b, op, kind in ('nand','nor','xnor'))

# ---------------------------------------------------------------- flip-flops
# (name, resets) ; Xilinx semantics: R/S synchronous, CLR async; R has priority over S; S over CE
def ff(name, clr=False, r=False, s=False, ce=False, neg=False, toggle=False, sprio=False):
    ports = ["input C"]
    if toggle: ports.append("input T")
    else: ports.append("input D")
    if ce: ports.append("input CE")
    if clr: ports.append("input CLR")
    if r: ports.append("input R")
    if s: ports.append("input S")
    ports.append("output reg Q")
    edge = "negedge" if neg else "posedge"
    sens = f"{edge} C" + (" or posedge CLR" if clr else "")
    body = []
    if clr: body.append("if (CLR) Q <= 1'b0;")
    sr = []
    if sprio:
        if s: sr.append("if (S) Q <= 1'b1;")
        if r: sr.append("else if (R) Q <= 1'b0;" if s else "if (R) Q <= 1'b0;")
    else:
        if r: sr.append("if (R) Q <= 1'b0;")
        if s: sr.append("else if (S) Q <= 1'b1;" if r else "if (S) Q <= 1'b1;")
    upd = ("Q <= ~Q;" if toggle else "Q <= D;")
    if toggle: cond = "CE & T" if ce else "T"
    else: cond = "CE" if ce else None
    chain = []
    chain += body
    for x in sr:
        chain.append(("else " + x) if (chain and not x.startswith("else")) else x)
    last = (f"if ({cond}) {upd}" if cond else upd)
    chain.append(("else " + last) if chain else last)
    w(f"module {name} #(parameter INIT = 1'b0) ({', '.join(ports)});\n"
      f"  initial Q = INIT;\n  always @({sens}) begin\n    " + "\n    ".join(chain) + "\n  end\nendmodule")
ff("fd"); ff("fde", ce=True); ff("fdr", r=True); ff("fdre", r=True, ce=True); ff("fds", s=True)
ff("fdse", s=True, ce=True); ff("fdrs", r=True, s=True); ff("fdrse", r=True, s=True, ce=True)
ff("fdc", clr=True); ff("fdce", clr=True, ce=True)
ff("fd_1", neg=True); ff("fde_1", ce=True, neg=True); ff("fdr_1", r=True, neg=True); ff("fds_1", s=True, neg=True)
ff("fdce_1", clr=True, ce=True, neg=True)
ff("ftrse", r=True, s=True, ce=True, toggle=True)                 # reset priority
ff("ftsre", r=True, s=True, ce=True, toggle=True, sprio=True)     # set priority
w("module ofd #(parameter INIT = 1'b0) (input C, input D, output reg Q); initial Q = INIT; always @(posedge C) Q <= D; endmodule")
# bus flip-flops: fd8ce fd8re fd16re fd4ce fd4re
def busff(name, k, clr):
    if k <= 4:
        di = ", ".join(f"input D{i}" for i in range(k)); qo = ", ".join(f"output Q{i}" for i in range(k))
    else:
        di = f"input [{k-1}:0] D"; qo = f"output [{k-1}:0] Q"
    rst = "input CLR" if clr else "input R"
    sens = "posedge C or posedge CLR" if clr else "posedge C"
    ctl = "if (CLR) q <= 0; else if (CE) q <= d;" if clr else "if (R) q <= 0; else if (CE) q <= d;"
    dd = "{" + ",".join(f"D{i}" for i in reversed(range(k))) + "}" if k <= 4 else "D"
    qa = "".join(f"  assign Q{i} = q[{i}];\n" for i in range(k)) if k <= 4 else "  assign Q = q;\n"
    w(f"module {name}(input C, input CE, {rst}, {di}, {qo});\n  reg [{k-1}:0] q = 0; wire [{k-1}:0] d = {dd};\n"
      f"  always @({sens}) {ctl}\n{qa}endmodule")
for nm, k, clr in (("fd4ce",4,1),("fd8ce",8,1),("fd4re",4,0),("fd8re",8,0),("fd16re",16,0)): busff(nm, k, clr)

# ---------------------------------------------------------------- counters  cbNce / cbNcle / cbNcled / cbNre / cc16re
def counter(name, k, kind):
    clr = kind in ("ce", "cle", "cled")
    load = kind in ("cle", "cled")
    ud = kind == "cled"
    ports = ["input C", "input CE"]
    ports.append("input CLR" if clr else "input R")
    if load: ports.append("input L")
    if ud: ports.append("input UP")
    if load:
        ports += [f"input D{i}" for i in range(k)] if k <= 4 else [f"input [{k-1}:0] D"]
    ports += [f"output Q{i}" for i in range(k)] if k <= 4 else [f"output [{k-1}:0] Q"]
    ports += ["output TC", "output CEO"]
    dd = "{" + ",".join(f"D{i}" for i in reversed(range(k))) + "}" if (load and k <= 4) else "D"
    sens = "posedge C or posedge CLR" if clr else "posedge C"
    lines = []
    if clr: lines.append("if (CLR) q <= 0;")
    else: lines.append("if (R) q <= 0;")
    if load: lines.append(f"else if (L) q <= {dd};")
    inc = "(UP ? q + 1'b1 : q - 1'b1)" if ud else "q + 1'b1"
    lines.append(f"else if (CE) q <= {inc};")
    tc = f"(UP ? &q : ~|q)" if ud else "&q"
    qa = "".join(f"  assign Q{i} = q[{i}];\n" for i in range(k)) if k <= 4 else "  assign Q = q;\n"
    w(f"module {name}({', '.join(ports)});\n  reg [{k-1}:0] q = 0;\n  always @({sens}) begin\n    " + "\n    ".join(lines) +
      f"\n  end\n{qa}  assign TC = {tc};\n  assign CEO = TC & CE;\nendmodule")
for nm in "cb2cle cb2re cb4ce cb4cle cb4cled cb4re cb8ce cb8cle cb8cled cb8re cb16cle cb16cled cb16re cc16re".split():
    m = re.fullmatch(r'c[bc](\d+)(ce|cle|cled|re)', nm); counter(nm, int(m.group(1)), m.group(2))

# ---------------------------------------------------------------- shift registers
def sreg(name, kind):
    clr = kind in ("ce", "cle"); load = kind == "cle"
    ports = ["input C", "input CE", "input CLR" if clr else "input R", "input SLI"]
    if load: ports += ["input L", "input [7:0] D"]
    ports.append("output [7:0] Q")
    sens = "posedge C or posedge CLR" if clr else "posedge C"
    ln = ["if (CLR) q <= 0;" if clr else "if (R) q <= 0;"]
    if load: ln.append("else if (L) q <= D;")
    ln.append("else if (CE) q <= {q[6:0], SLI};")
    w(f"module {name}({', '.join(ports)});\n  reg [7:0] q = 0;\n  always @({sens}) begin\n    " + "\n    ".join(ln) +
      "\n  end\n  assign Q = q;\nendmodule")
sreg("sr8ce", "ce"); sreg("sr8cle", "cle"); sreg("sr8re", "re")

# ---------------------------------------------------------------- arithmetic / compare / mux / decode
def adder(name, k, sub):
    if k <= 4:
        pa = ", ".join(f"input A{i}" for i in range(k)); pb = ", ".join(f"input B{i}" for i in range(k))
        ps = ", ".join(f"output S{i}" for i in range(k))
        av = "{" + ",".join(f"A{i}" for i in reversed(range(k))) + "}"; bv = "{" + ",".join(f"B{i}" for i in reversed(range(k))) + "}"
        so = "".join(f"  assign S{i} = s[{i}];\n" for i in range(k))
    else:
        pa, pb, ps = f"input [{k-1}:0] A", f"input [{k-1}:0] B", f"output [{k-1}:0] S"
        av, bv, so = "A", "B", "  assign S = s[%d:0];\n" % (k-1)
    add = "input ADD, " if sub else ""
    bx = f"(ADD ? {bv} : ~{bv})" if sub else bv
    w(f"module {name}({pa}, {pb}, {add}input CI, {ps}, output CO, output OFL);\n"
      f"  wire [{k-1}:0] a = {av}; wire [{k-1}:0] b = {bx};\n  wire [{k}:0] s = a + b + CI;\n{so}"
      f"  assign CO = s[{k}];\n  assign OFL = (a[{k-1}] == b[{k-1}]) & (s[{k-1}] != a[{k-1}]);\nendmodule")
for nm in "add4 add8 add16".split(): adder(nm, int(nm[3:]), False)
for nm in "adsu4 adsu8 adsu16".split(): adder(nm, int(nm[4:]), True)
w("module comp4(input A0,A1,A2,A3,B0,B1,B2,B3, output EQ); assign EQ = ({A3,A2,A1,A0} == {B3,B2,B1,B0}); endmodule")
w("module comp8(input [7:0] A, input [7:0] B, output EQ); assign EQ = (A == B); endmodule")
def dec(name, k):
    n = 1 << k
    ap = ", ".join(f"input A{i}" for i in range(k)); dp = ", ".join(f"output D{i}" for i in range(n))
    av = "{" + ",".join(f"A{i}" for i in reversed(range(k))) + "}"
    assigns = "".join(f"  assign D{i} = E & ({av} == {k}'d{i});\n" for i in range(n))
    w(f"module {name}({ap}, input E, {dp});\n{assigns}endmodule")
dec("d2_4e", 2); dec("d3_8e", 3); dec("d4_16e", 4)
w("module m2_1(input D0, D1, S0, output O); assign O = S0 ? D1 : D0; endmodule")
w("module m2_1e(input D0, D1, E, S0, output O); assign O = E & (S0 ? D1 : D0); endmodule")
w("module m4_1e(input D0,D1,D2,D3,E,S0,S1, output O); wire [3:0] d={D3,D2,D1,D0}; assign O = E & d[{S1,S0}]; endmodule")
w("module m8_1e(input D0,D1,D2,D3,D4,D5,D6,D7,E,S0,S1,S2, output O); wire [7:0] d={D7,D6,D5,D4,D3,D2,D1,D0}; assign O = E & d[{S2,S1,S0}]; endmodule")

# ---------------------------------------------------------------- LUT ROM / distributed RAM / SRL16
w("module rom16x1 #(parameter [15:0] INIT = 16'h0000)(input A0,A1,A2,A3, output O); assign O = INIT[{A3,A2,A1,A0}]; endmodule")
w("module rom32x1 #(parameter [31:0] INIT = 32'h0)(input A0,A1,A2,A3,A4, output O); assign O = INIT[{A4,A3,A2,A1,A0}]; endmodule")
w("module srl16 #(parameter [15:0] INIT = 16'h0000)(input A0,A1,A2,A3,CLK,D, output Q);\n"
  "  reg [15:0] sr = INIT; always @(posedge CLK) sr <= {sr[14:0], D}; assign Q = sr[{A3,A2,A1,A0}]; endmodule")
def ram16(name, k, dual, neg=False):
    sp = "SPO" if dual else "O"
    if k == 1:
        d, outs = "input D", []
        if dual: outs = ["output DPO", "output SPO"]
        else: outs = ["output O"]
        dv, rs = "D", ""
    elif k <= 4:
        d = ", ".join(f"input D{i}" for i in range(k))
        outs = ([f"output DPO{i}" for i in range(k)] + [f"output SPO{i}" for i in range(k)]) if dual else [f"output O{i}" for i in range(k)]
        dv = "{" + ",".join(f"D{i}" for i in reversed(range(k))) + "}"
    else:
        d = f"input [{k-1}:0] D"
        outs = [f"output [{k-1}:0] DPO", f"output [{k-1}:0] SPO"] if dual else [f"output [{k-1}:0] O"]
        dv = "D"
    ports = ["input A0, A1, A2, A3"] + ([ "input DPRA0, DPRA1, DPRA2, DPRA3"] if dual else []) + ["input WCLK, WE", d] + outs
    edge = "negedge" if neg else "posedge"
    body = [f"  reg [{k-1}:0] mem [0:15]; integer i; initial for (i=0;i<16;i=i+1) mem[i] = {{{k}{{INIT[i]}}}};",
            f"  wire [3:0] a = {{A3,A2,A1,A0}};",
            f"  always @({edge} WCLK) if (WE) mem[a] <= {dv};"]
    if dual: body.append("  wire [3:0] dpra = {DPRA3,DPRA2,DPRA1,DPRA0};")
    def asg(prefix, addr):
        if k == 1: return f"  assign {prefix} = mem[{addr}];"
        if k <= 4: return "\n".join(f"  assign {prefix}{i} = mem[{addr}][{i}];" for i in range(k))
        return f"  assign {prefix} = mem[{addr}];"
    if dual:
        body.append(asg("DPO", "dpra")); body.append(asg("SPO", "a"))
    else:
        body.append(asg("O", "a"))
    w(f"module {name} #(parameter [15:0] INIT = 16'h0000)({', '.join(ports)});\n" + "\n".join(body) + "\nendmodule")
ram16("ram16x1d", 1, True); ram16("ram16x1d_1", 1, True, neg=True); ram16("ram16x2d", 2, True)
ram16("ram16x4d", 4, True); ram16("ram16x8d", 8, True); ram16("ram16x2s", 2, False); ram16("ram16x8s", 8, False)

# ---------------------------------------------------------------- Spartan-II block RAM (4 Kbit), write-first
INITP = ", ".join(f"parameter [255:0] INIT_{i:02X} = 256'h0" for i in range(16))
def initblk(): return "  integer ii; initial begin\n" + "\n".join(f"    for (ii=0; ii<32; ii=ii+1) mem[{32*i}+ii] = INIT_{i:02X}[8*ii +: 8];" for i in range(16)) + "\n  end\n"
w("""module ramb4_s8 #(""" + INITP + """) (input [8:0] ADDR, input CLK, input [7:0] DI, input EN, input RST, input WE, output reg [7:0] DO);
  reg [7:0] mem [0:511];
""" + initblk() + """  always @(posedge CLK) if (EN) begin
    if (RST) DO <= 8'h00;
    else if (WE) begin mem[ADDR] <= DI; DO <= DI; end
    else DO <= mem[ADDR];
  end
endmodule""")
w("""module ramb4_s8_s8 #(""" + INITP + """) (input [8:0] ADDRA, input CLKA, input [7:0] DIA, input ENA, input RSTA, input WEA, output reg [7:0] DOA,
                   input [8:0] ADDRB, input CLKB, input [7:0] DIB, input ENB, input RSTB, input WEB, output reg [7:0] DOB);
  reg [7:0] mem [0:511];
""" + initblk() + """  always @(posedge CLKA) if (ENA) begin
    if (RSTA) DOA <= 8'h00; else if (WEA) begin mem[ADDRA] <= DIA; DOA <= DIA; end else DOA <= mem[ADDRA];
  end
  always @(posedge CLKB) if (ENB) begin
    if (RSTB) DOB <= 8'h00; else if (WEB) begin mem[ADDRB] <= DIB; DOB <= DIB; end else DOB <= mem[ADDRB];
  end
endmodule""")
# port A: 512x8 ; port B: 256x16, little endian (word n = {mem[2n+1], mem[2n]})
w("""module ramb4_s8_s16 #(""" + INITP + """) (input [8:0] ADDRA, input CLKA, input [7:0] DIA, input ENA, input RSTA, input WEA, output reg [7:0] DOA,
                    input [7:0] ADDRB, input CLKB, input [15:0] DIB, input ENB, input RSTB, input WEB, output reg [15:0] DOB);
  reg [7:0] mem [0:511];
""" + initblk() + """  always @(posedge CLKA) if (ENA) begin
    if (RSTA) DOA <= 8'h00; else if (WEA) begin mem[ADDRA] <= DIA; DOA <= DIA; end else DOA <= mem[ADDRA];
  end
  always @(posedge CLKB) if (ENB) begin
    if (RSTB) DOB <= 16'h0000;
    else if (WEB) begin mem[{ADDRB,1'b0}] <= DIB[7:0]; mem[{ADDRB,1'b1}] <= DIB[15:8]; DOB <= DIB; end
    else DOB <= {mem[{ADDRB,1'b1}], mem[{ADDRB,1'b0}]};
  end
endmodule""")

open('/home/claude/out_v/kg_prims.v', 'w').write("// Behavioural models of Xilinx schematic-library symbols used by OSCA.\n"
                                                  "// Generated by gen_prims.py\n`timescale 1ns/1ps\n\n" + "\n\n".join(L) + "\n")
print(len(L), "modules")
