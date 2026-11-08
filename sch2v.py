#!/usr/bin/env python3
"""ISE schematic (.sch, VERSION 6) -> structural Verilog.

Connectivity in these files is explicit (BEGIN BLOCK ... PIN name signal), so
no geometry is needed.  Each .sch becomes one module; library primitives are
provided separately by kg_prims.v.
"""
import re, sys, os, glob, collections

KEYWORDS = set("""always and assign begin buf case default else end endcase endmodule for
function if initial inout input integer module nand nor not or output parameter reg
supply0 supply1 task tri wire xnor xor wait while real time event force release
casex casez defparam disable edge fork join large medium notif0 notif1 small strong0
strong1 weak0 weak1 pull0 pull1 pulldown pullup table endtable signed unsigned""".split())


def vid(name):
    if re.match(r'^[A-Za-z_][A-Za-z0-9_$]*$', name) and name not in KEYWORDS:
        return name
    return '\\' + name + ' '


def split_sig(s):
    """'foo(7:0)' -> ('foo', 7, 0); 'foo(3)' -> ('foo',3,3); 'foo' -> ('foo',None,None)"""
    m = re.match(r'^(.*?)\((\d+)(?::(\d+))?\)$', s)
    if not m:
        return s, None, None
    msb = int(m.group(2))
    lsb = int(m.group(3)) if m.group(3) is not None else msb
    return m.group(1), msb, lsb


class Module:
    def __init__(self, name, path):
        self.name, self.path = name, path
        self.ports = []        # (dir, base, msb, lsb) in order
        self.signals = {}      # lower -> [spelling, msb, lsb]
        self.insts = []        # dict(name, range, sym, pins[(pin,sig)], attrs{})


def parse_sch(path):
    t = open(path, encoding='latin1').read().replace('\r', '')
    mod = Module(os.path.splitext(os.path.basename(path))[0].lower(), path)
    # only netlist + BLOCK sections matter
    nl = re.search(r'BEGIN NETLIST\n(.*?)END NETLIST', t, re.S)
    if not nl:
        raise SystemExit('no NETLIST in ' + path)
    for line in nl.group(1).split('\n'):
        line = line.strip()
        if line.startswith('SIGNAL '):
            note(mod, line[7:].strip())
        elif line.startswith('PORT '):
            d, rest = line[5:].split(None, 1)
            base, msb, lsb = split_sig(rest.strip())
            note(mod, rest.strip(), port=True)
            mod.ports.append((d, base, msb, lsb))
    for m in re.finditer(r'^\s*BEGIN BLOCK (\S+?)(\((\d+):(\d+)\))? (\S+)\n(.*?)^\s*END BLOCK',
                         t, re.S | re.M):
        iname, _, r1, r2, sym, body = m.groups()
        inst = dict(name=iname, range=(int(r1), int(r2)) if r1 else None, sym=sym.lower(),
                    pins=[], attrs={})
        for a in re.finditer(r'BEGIN ATTR (\S+) "([^"]*)"\n(.*?)END ATTR', body, re.S):
            vt = re.search(r'VALUETYPE BitVector (\d+)', a.group(3))
            inst['attrs'][a.group(1)] = (a.group(2), int(vt.group(1)) if vt else None)
        for p in re.finditer(r'^\s*PIN (\S+)(?: (\S+))?\s*$', body, re.M):
            pin, sig = p.group(1), p.group(2)
            if sig:
                note(mod, sig)
            inst['pins'].append((pin, sig))
        mod.insts.append(inst)
    return mod


def note(mod, sig, port=False):
    if ',' in sig and not port:
        for part in sig.split(','):
            note(mod, part.strip())
        return None
    base, msb, lsb = split_sig(sig)
    if msb is not None and msb < lsb:
        msb, lsb = lsb, msb            # ascending range: only the declaration is normalised here
    key = base.lower()
    e = mod.signals.get(key)
    if e is None:
        mod.signals[key] = e = [base, msb, lsb]
    else:
        if msb is not None:
            if e[1] is None:
                e[1], e[2] = msb, lsb
            else:
                e[1], e[2] = max(e[1], msb), min(e[2], lsb)
    return e


def canon(mod, sig):
    """Verilog expression for a signal reference."""
    if ',' in sig:
        return '{' + ', '.join(canon(mod, p.strip()) for p in sig.split(',')) + '}'
    base, msb, lsb = split_sig(sig)
    spelled = vid(mod.signals[base.lower()][0])
    if msb is None:
        return spelled
    if msb == lsb:
        return '%s[%d]' % (spelled, msb)
    if msb < lsb:                      # ECS ascending bus x(0:7) = {x[0], x[1], ... x[7]}
        return '{' + ', '.join('%s[%d]' % (spelled, b) for b in range(msb, lsb + 1)) + '}'
    return '%s[%d:%d]' % (spelled, msb, lsb)


TRI_SYMS = {'bufe','bufe8','bufe16','buft','buft8','buft16','bufe18','bufe19','buft18','buft19'}

def eliminate_tristates(mod):
    """Internal tri-state buses -> wired-OR of drivers that output 0 when disabled
    (Spartan-6 has no internal tri-states).  Returns the extra assign lines."""
    drivers = collections.defaultdict(list)       # lower base -> [(inst, sig)]
    for i in mod.insts:
        if i['sym'] in TRI_SYMS:
            for k, (pin, sig) in enumerate(i['pins']):
                if split_sig(pin)[0] in ('O', 'out_bus') and sig and ',' not in sig:
                    drivers[split_sig(sig)[0].lower()].append((i, k, sig))
    lines = []
    for base, drv in drivers.items():
        if len(drv) < 2:
            continue
        spell = mod.signals[base][0]
        bits = collections.defaultdict(list)       # bit -> [wire expr]
        scalar = []
        for n, (inst, k, sig) in enumerate(drv):
            b, msb, lsb = split_sig(sig)
            nm = '%s_tb%d' % (spell, n)
            w = 1 if msb is None else msb - lsb + 1
            mod.signals[nm.lower()] = [nm, (w - 1) if w > 1 else None, 0 if w > 1 else None]
            inst['pins'][k] = (inst['pins'][k][0], nm + ('(%d:0)' % (w - 1) if w > 1 else ''))
            if msb is None:
                scalar.append(nm)
            else:
                for bit in range(lsb, msb + 1):
                    bits[bit].append('%s[%d]' % (vid(nm), bit - lsb) if w > 1 else vid(nm))
        if scalar:
            lines.append('    assign %s = %s;' % (vid(spell), ' | '.join(vid(x) for x in scalar)))
        for bit in sorted(bits):
            lines.append('    assign %s[%d] = %s;' % (vid(spell), bit, ' | '.join(bits[bit])))
    return lines

def emit(mod, modnames, prims_known, out):
    extra = eliminate_tristates(mod)
    ports = {b.lower(): (d, b, msb, lsb) for d, b, msb, lsb in mod.ports}
    hdr = []
    for d, b, msb, lsb in mod.ports:
        e = mod.signals[b.lower()]
        # widen declared port if a reference exceeds it
        if msb is not None:
            msb, lsb = max(msb, e[1]), min(lsb, e[2])
        dd = {'Input': 'input', 'Output': 'output', 'BiDirectional': 'inout'}[d]
        r = '' if msb is None else ' [%d:%d]' % (msb, lsb)
        hdr.append('    %s wire%s %s' % (dd, r, vid(e[0])))
    out.write('// generated from %s\n' % os.path.basename(mod.path))
    out.write('module %s (\n%s\n);\n\n' % (vid(mod.name), ',\n'.join(hdr)))
    for key, (spell, msb, lsb) in sorted(mod.signals.items()):
        if key in ports:
            continue
        r = '' if msb is None else ' [%d:%d]' % (msb, lsb)
        out.write('    wire%s %s;\n' % (r, vid(spell)))
    out.write('\n')
    missing = set()
    for i in mod.insts:
        sym = i['sym']
        real = modnames.get(sym)
        if real is None:
            missing.add(sym)
            real = sym
        params = ''
        if i['attrs']:
            ps = []
            for k, (v, w) in i['attrs'].items():
                if w:
                    ps.append(".%s(%d'h%s)" % (k, w, v))
                elif re.fullmatch(r'[01]+', v) and len(v) == 1:
                    ps.append(".%s(1'b%s)" % (k, v))
                else:
                    ps.append('.%s(%s)' % (k, "'h" + v if re.fullmatch(r'[0-9a-fA-F]+', v) else '"%s"' % v))
            params = ' #(%s)' % ', '.join(ps)
        rng = '' if i['range'] is None else ' [%d:%d]' % i['range']
        conns = []
        for pin, sig in i['pins']:
            pbase = split_sig(pin)[0]
            conns.append('.%s(%s)' % (vid(pbase), canon(mod, sig) if sig else ''))
        out.write('    %s%s %s%s (%s);\n' % (vid(real), params, vid(i['name']), rng,
                                              ', '.join(conns)))
    for l in extra:
        out.write(l + '\n')
    out.write('\nendmodule\n')
    return missing


def main(src, dst, top):
    os.makedirs(dst, exist_ok=True)
    mods = {}
    for f in sorted(glob.glob(os.path.join(src, '*.sch'))):
        m = parse_sch(f)
        mods[m.name] = m
    # block-RAM contents that ISE takes from the UCF:  INST "name" INIT_xx = hex;
    ucf_init = collections.defaultdict(dict)
    for u in glob.glob(os.path.join(src, '*.ucf')):
        for mm in re.finditer(r'INST\s+"([^"]+)"\s+(INIT_[0-9A-Fa-f]{2})\s*=\s*([0-9A-Fa-f]+)\s*;',
                              open(u, encoding='latin1').read()):
            ucf_init[mm.group(1).lower()][mm.group(2).upper()] = mm.group(3)
    rb = os.environ.get('OSCA_ROM_BIN')
    if rb:                                         # replace the stage-1 boot ROM (512 bytes) with our own
        rom = open(rb, 'rb').read(); rom += bytes(512 - len(rom))
        ucf_init['rom_data_a'] = {'INIT_%02X' % k: rom[32*k:32*k+32][::-1].hex().upper() for k in range(16)}
        print('boot ROM replaced from', rb)
    applied = 0
    for m in mods.values():
        for i in m.insts:
            if i['name'].lower() in ucf_init:
                for k, v in ucf_init[i['name'].lower()].items():
                    i['attrs'][k] = (v, 4 * len(v))
                applied += 1
    print('UCF INIT applied to', applied, 'instance(s)')
    modnames = {k: m.name for k, m in mods.items()}
    # hand-written / macro verilog already in the project
    vfiles = glob.glob(os.path.join(src, '*.v'))
    for f in vfiles:
        for mm in re.finditer(r'^\s*module\s+(\w+)', open(f, encoding='latin1').read(), re.M):
            modnames[mm.group(1).lower()] = mm.group(1)
    modnames['buf'] = 'buf_x'   # 'buf' is a Verilog keyword
    allmissing = collections.Counter()
    for name, m in mods.items():
        with open(os.path.join(dst, name + '.v'), 'w') as o:
            for s in emit(m, modnames, None, o):
                allmissing[s] += 1
    for f in vfiles:
        open(os.path.join(dst, os.path.basename(f)), 'w').write(
            open(f, encoding='latin1').read())
    print('modules:', len(mods), ' .v copied:', len(vfiles))
    print('library symbols needed (not local):', len(allmissing))
    open(os.path.join(dst, 'needed_prims.txt'), 'w').write(
        '\n'.join(sorted(allmissing)) + '\n')


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else 'osca_pal')
