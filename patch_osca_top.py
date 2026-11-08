#!/usr/bin/env python3
"""osca_pal.v (converted top) -> osca_core.v: replace the bidirectional vram/spr data pins
by unidirectional ports so the core can sit behind kg_osca_mem (no tri-states at this level)."""
import sys, re
src, dst = sys.argv[1], sys.argv[2]
t = open(src).read()
t = t.replace('module osca_pal (', 'module osca_core (', 1)
t = t.replace('    inout wire [7:0] vram_databus,',
              '    output wire [7:0] vram_wdata,\n    output wire vram_wdata_oe,\n    input wire [7:0] vram_rdata,')
t = t.replace('    inout wire [7:0] spr_databus,',
              '    output wire [7:0] spr_wdata,\n    output wire spr_wdata_oe,\n    input wire [7:0] spr_rdata,')
rep = [
 (r'    obuft8 XLXI_898 \(.*\);\n',
  '    assign vram_wdata = outgoing_data_for_vram[7:0];\n    assign vram_wdata_oe = ~XLXN_2593;\n'),
 (r'    ibuf8 XLXI_14 \(.*\);\n',
  '    assign vram_databus_input[7:0] = vram_rdata;\n'),
 (r'    obuft8 XLXI_851 \(.*\);\n',
  '    assign spr_wdata = cpu_databus_in[7:0];\n    assign spr_wdata_oe = ~sprite_system_busy;\n'),
 (r'    ibuf8 XLXI_793 \(.*\);\n',
  '    assign sprpixel_data_in[7:0] = spr_rdata;\n'),
]
for pat, new in rep:
    t, n = re.subn(pat, new, t)
    assert n == 1, pat
# ---- shared Z80 bus: split into unidirectional ports (arbitration lives in kg_osca_cpu)
for nm in ('mreq','ioreq','read','write'):
    t = t.replace('    inout wire z80_%s,' % nm, '    output wire z80_%s_o,\n    input wire z80_%s_i,' % (nm, nm))
t = t.replace('    inout wire [15:0] z80_address_bus,', '    output wire [15:0] z80_addr_o,\n    input wire [15:0] z80_addr_i,')
t = t.replace('    inout wire [7:0] z80_databus,', '    output wire [7:0] z80_data_o,\n    output wire z80_data_oe,\n    input wire [7:0] z80_data_i,')
rep2 = [
 (r'    obuft XLXI_43 \(.*\);\n', '    assign z80_ioreq_o = XLXN_3221;\n'),
 (r'    ibuf XLXI_39 \(.*\);\n',  '    assign cpu_ioreq = z80_ioreq_i;\n'),
 (r'    obuft XLXI_42 \(.*\);\n', '    assign z80_mreq_o = XLXN_3221;\n'),
 (r'    ibuf XLXI_38 \(.*\);\n',  '    assign cpu_mreq = z80_mreq_i;\n'),
 (r'    obuft XLXI_44 \(.*\);\n', '    assign z80_write_o = XLXN_3221;\n'),
 (r'    ibuf XLXI_40 \(.*\);\n',  '    assign XLXN_7132 = z80_write_i;\n'),
 (r'    obuft XLXI_41 \(.*\);\n', '    assign z80_read_o = XLXN_6993;\n'),
 (r'    ibuf XLXI_37 \(.*\);\n',  '    assign cpu_read = z80_read_i;\n'),
 (r'    obuft16 XLXI_131 \(.*\);\n', '    assign z80_addr_o = XLXN_7011[15:0];\n'),
 (r'    ibuf16 XLXI_130 \(.*\);\n',  '    assign incoming_cpu_address[15:0] = z80_addr_i;\n'),
 (r'    obuft8 XLXI_485 \(.*\);\n',  '    assign z80_data_o = data_for_cpu_multiplex[7:0];\n    assign z80_data_oe = ~XLXN_9400;\n'),
 (r'    ibuf8 XLXI_468 \(.*\);\n',   '    assign cpu_databus_in[7:0] = z80_data_i;\n'),
]
for pat, new in rep2:
    t, n = re.subn(pat, new, t)
    assert n == 1, pat
for bad in ('z80_databus','z80_address_bus','(z80_write)','(z80_read)','(z80_mreq)','(z80_ioreq)'):
    assert bad not in t, bad
assert 'vram_databus[' not in t and 'spr_databus[' not in t
open(dst, 'w').write(t)
print('ok ->', dst)
