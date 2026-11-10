#!/usr/bin/env python3
"""Core files (.kg) of the Z80 test programs for the board: each one is the bitstream of core.json with the test's flat RAM image
as its ROM (loaded at 0 while the core is held in reset; the boot ROM jumps to $1010, the image has a JP there).

Two kinds of tests:
  hex - the image the simulation runs (sim/roms/...): the programs with data tables computed offline (video modes, line copper,
        sound), the board gets exactly what the regression checked;
  asm - assembled here (sjasmplus) with the board's parameters (the interrupt test over 50 frames, the retention test over all
        the pages, ...): code at its org, JP org at $1010, optionally JP <irq> at $0A00 (the target of the ROM's IRQ vector).
Output: tests/out/<name>.bin, <name>.json, <name>.kg (copy the .kg files to the SD card).

usage: make_test_cores.py [--make-core PATH] [--sjasm PATH] [--only a,b] [--list]      (run from src/)
"""
import argparse, json, os, re, subprocess, sys

TESTS = [
    # name,          kind,  source,                                    defines,               irq
    ('irq',          'asm', 'tests/system/irq_test.asm',               ['NFR=50'],            0x5003),
    ('maths',        'asm', 'tests/system/maths_test.asm',             [],                    None),
    ('sysram',       'asm', 'tests/system/sysram_test.asm',            [],                    None),
    ('retention',    'asm', 'tests/system/sysram_retention.asm',       [],                    None),
    ('lc_alt',       'asm', 'tests/linecop/lc_alt.asm',                [],                    None),
    ('audio_hi',     'asm', 'tests/sound/audio_hi.asm',                [],                    None),
    ('audio_load',   'asm', 'tests/sound/audio_load.asm',              [],                    None),
    ('lc_only',      'hex', 'sim/roms/lc_images/lc_only_ram_image.hex',   None, None),
    ('lc_audio',     'hex', 'sim/roms/lc_images/lc_audio_ram_image.hex',  None, None),
    ('lc_stress',    'hex', 'sim/roms/lc_images/lc_stress_ram_image.hex', None, None),
    ('lc_zoom',      'hex', 'sim/roms/lc_images/lc_zoom_ram_image.hex',   None, None),
    ('audio',        'hex', 'sim/roms/audio_ram_image.hex',             None, None),
    ('sprites',      'hex', 'sim/roms/spr_ram_image.hex',               None, None),
    ('chunky_blit',  'hex', 'sim/roms/modes/chunky_blit/ram_image.hex', None, None),
    ('cpu_vram',     'hex', 'sim/roms/modes/cpu_vram/ram_image.hex',    None, None),
    ('linedraw',     'hex', 'sim/roms/modes/linedraw/ram_image.hex',    None, None),
    ('planar4',      'hex', 'sim/roms/modes/planar4/ram_image.hex',     None, None),
    ('sprites2',     'hex', 'sim/roms/modes/sprites2/ram_image.hex',    None, None),
    ('tiles16',      'hex', 'sim/roms/modes/tiles16/ram_image.hex',     None, None),
]

def jp(a):
    return bytes([0xC3, a & 0xFF, a >> 8])

def from_hex(path):
    img = bytes(int(l, 16) for l in open(path) if l.strip())
    return img.rstrip(b'\x00')                       # the tail of the image is zeros (the RAM is not cleared by the loader)

def from_asm(path, defines, irq, sjasm, work):
    src = open(path).read()
    m = re.search(r'(?im)^\s*org\s+(0x[0-9a-f]+|\$[0-9a-f]+|\d+)', src)
    org = int(m.group(1).replace('$', '0x'), 0)
    out = os.path.join(work, os.path.basename(path).replace('.asm', '.raw'))
    r = subprocess.run([sjasm, '--nologo', '--raw=' + out] + ['-D' + d for d in defines] + [path], capture_output=True, text=True)
    if r.returncode != 0 or not os.path.exists(out):
        sys.exit('%s: sjasmplus failed\n%s%s' % (path, r.stdout, r.stderr))
    code = open(out, 'rb').read()
    img = bytearray(org + len(code))
    img[0x1010:0x1013] = jp(org)
    if irq is not None:
        img[0x0A00:0x0A03] = jp(irq)
    img[org:] = code
    return bytes(img)

def main():
    here = os.path.dirname(os.path.abspath(__file__))
    ap = argparse.ArgumentParser()
    ap.add_argument('--make-core', default=os.path.join(here, '..', '..', '..', 'karabas-go-tools', 'make_core', 'make_core.py'))
    ap.add_argument('--sjasm', default='sjasmplus')
    ap.add_argument('--python', default=sys.executable)
    ap.add_argument('--only', default='')
    ap.add_argument('--list', action='store_true')
    a = ap.parse_args()
    if a.list:
        for t in TESTS: print('%-12s %s %s' % (t[0], t[1], t[2]))
        return
    only = [x for x in a.only.split(',') if x]
    base = json.load(open('core.json'))
    work = os.path.join('tests', 'out')
    os.makedirs(work, exist_ok=True)
    for i, (name, kind, src, defines, irq) in enumerate(TESTS):
        if only and name not in only:
            continue
        img = from_hex(src) if kind == 'hex' else from_asm(src, defines, irq, a.sjasm, work)
        assert img[0x1010] == 0xC3, '%s: no JP at $1010' % name
        bin_path = os.path.join(work, name + '.bin').replace('\\', '/')
        open(bin_path, 'wb').write(img)
        core = dict(base)
        core['id'] = 'v6z80p_t_' + name
        core['name'] = 'V6Z80 test ' + name
        core['order'] = 200 + i
        core['roms'] = [{'filename': bin_path, 'address': 0}]
        js = os.path.join(work, name + '.json')
        json.dump(core, open(js, 'w'), indent=4)
        kg = os.path.join(work, name + '.kg')
        r = subprocess.run([a.python, a.make_core, js, kg], capture_output=True, text=True)
        if r.returncode != 0:
            sys.exit('%s: make_core failed\n%s%s' % (name, r.stdout, r.stderr))
        print('%-12s %-4s %6d bytes  -> %s' % (name, kind, len(img), kg))

if __name__ == '__main__':
    main()
