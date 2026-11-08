#!/usr/bin/env python3
"""Regression of the OSCA port: every test image is run through build/<cfg>/Vtb_boot, the frame is compared pixel by pixel with
golden/<name>.png (frames of the reference run: ideal asynchronous memories, original blitter capture / sprite pipeline) and the
checks printed by the testbench (SDRAM model violations, DMA / line copper data checks) are evaluated.
Usage: regress.py [--root DIR] [--build DIR] [--cfg real|ref] [--only a,b,c] [--no-run]"""
import argparse, os, re, subprocess, sys
import numpy as np
from PIL import Image

# name, image, simulated ms, frame file (None = no frame), golden png, checks
TESTS = [
    ('flos',        'ram_image.hex',                          1000, 'frame_1.ppm', 'flos.png',        ['sdram']),
    ('sprites',     'spr_ram_image.hex',                       300, 'frame_0.ppm', 'sprites.png',     ['sdram']),
    ('audio',       'audio_ram_image.hex',                     125, None,          None,              ['sdram', 'dmachk']),
    ('lc_audio',    'lc_images/lc_audio_ram_image.hex',        300, 'frame_0.ppm', 'lc_audio.png',    ['sdram', 'lcchk', 'dmachk']),
    ('lc_only',     'lc_images/lc_only_ram_image.hex',         300, 'frame_0.ppm', 'lc_only.png',     ['sdram', 'lcchk']),
    ('chunky_blit', 'modes/img/chunky_blit/ram_image.hex',     300, 'frame_0.ppm', 'chunky_blit.png', ['sdram']),
    ('planar4',     'modes/img/planar4/ram_image.hex',         300, 'frame_0.ppm', 'planar4.png',     ['sdram']),
    ('tiles16',     'modes/img/tiles16/ram_image.hex',         300, 'frame_0.ppm', 'tiles16.png',     ['sdram']),
    ('linedraw',    'modes/img/linedraw/ram_image.hex',        300, 'frame_0.ppm', 'linedraw.png',    ['sdram']),
    ('sprites2',    'modes/img/sprites2/ram_image.hex',        300, 'frame_0.ppm', 'sprites2.png',    ['sdram']),
    ('cpu_vram',    'modes/img/cpu_vram/ram_image.hex',        300, 'frame_0.ppm', 'cpu_vram.png',    ['sdram']),
]

def load_ppm(path):
    t = open(path).read().split()
    w, h = int(t[1]), int(t[2])
    return np.array(list(map(int, t[4:4 + w * h * 3])), dtype=np.uint8).reshape(h, w, 3)

def last(pattern, text):
    m = re.findall(pattern, text)
    return m[-1] if m else None

def check_sdram(log):
    m = last(r'SDRAM model: .*?violations=(\d+)(?:\s+I/O violations=(\d+))?', log)
    if m is None:
        return None, 'no SDRAM model report'
    v, io = int(m[0]), int(m[1] or 0)
    return (v == 0 and io == 0), f'SDRAM violations={v} I/O={io}'

def check_dma(log):
    m = last(r'DMACHK: (\d+) DMA reads checked against the expected sample, (\d+) wrong', log)
    if m is None:
        return False, 'no DMACHK line'
    n, w = int(m[0]), int(m[1])
    return (n > 0 and w == 0), f'audio DMA {n} reads, {w} wrong'

def check_lc(log):
    m = last(r'LCCHK: (\d+) line copper list reads checked, (\d+) wrong', log)
    if m is None:
        return False, 'no LCCHK line'
    n, w = int(m[0]), int(m[1])
    return (n > 0 and w == 0), f'line copper {n} reads, {w} wrong'

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', default=os.path.join(os.path.dirname(__file__), '..'))
    ap.add_argument('--build', default=None)
    ap.add_argument('--cfg', default='real')
    ap.add_argument('--only', default='')
    ap.add_argument('--no-run', action='store_true', help='only evaluate the results of the last run')
    a = ap.parse_args()
    root = os.path.abspath(a.root); build = os.path.abspath(a.build or os.path.join(root, 'build'))
    only = [x for x in a.only.split(',') if x]
    exe = os.path.join(build, a.cfg, 'Vtb_boot')
    if not a.no_run and not os.path.exists(exe):
        sys.exit(f'{exe} not found: run scripts/sim.sh build {a.cfg}')
    results = []
    for name, img, ms, frame, golden, checks in TESTS:
        if only and name not in only:
            continue
        out = os.path.join(build, 'runs', a.cfg, name)
        if not a.no_run:
            subprocess.run([os.path.join(root, 'scripts', 'sim.sh'), 'run', a.cfg, os.path.join(root, img), out, str(ms)], check=True)
        details, ok = [], True
        log = open(os.path.join(out, 'run.log'), errors='replace').read() if os.path.exists(os.path.join(out, 'run.log')) else ''
        if frame:
            fp = os.path.join(out, frame)
            if not os.path.exists(fp):
                ok = False; details.append('no frame')
            else:
                g = np.array(Image.open(os.path.join(root, 'golden', golden)).convert('RGB'))
                f = load_ppm(fp)
                d = int((f != g).any(axis=2).sum()) if f.shape == g.shape else -1
                ok &= (d == 0); details.append('frame identical' if d == 0 else f'frame differs in {d} px')
        for c in checks:
            r, txt = {'sdram': check_sdram, 'dmachk': check_dma, 'lcchk': check_lc}[c](log)
            if r is None:                      # the reference configuration has no SDRAM model
                continue
            ok &= bool(r); details.append(txt)
        results.append((name, ok, '; '.join(details)))
        print(f'{"PASS" if ok else "FAIL"}  {name:12s} {"; ".join(details)}', flush=True)
    bad = [n for n, ok, _ in results if not ok]
    print(f'\n{len(results) - len(bad)}/{len(results)} passed' + (f', FAILED: {", ".join(bad)}' if bad else ''))
    sys.exit(1 if bad else 0)

if __name__ == '__main__':
    main()
