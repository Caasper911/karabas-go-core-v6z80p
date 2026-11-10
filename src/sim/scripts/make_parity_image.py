#!/usr/bin/env python3
"""Build a simulation RAM image of the 'parity' demo (v6z80p FLOS_based_programs/demos/parity) without FLOS and without an SD card.

The demo's own code runs unchanged; only what FLOS gives it is replaced:
  * the FLOS jump table at $1000 (the entries the demo calls) jumps to small stubs (set/get/inc bank, memfill, wait VRT, version ...);
  * load_from_bulk_file copies the file from a 'shelf' in the system RAM (put there by the image) to the requested bank / address;
    bgndspr.bin is shelved at its destination ($10000) and is not copied;
  * $1010 (where the boot ROM jumps) starts the demo with SP = $4FF0.
Output: a flat image (file offset = system RAM address) for tb_boot.sv (build with IMG_BYTES >= the printed size).

usage: make_parity_image.py <v6z80p checkout> <out.hex> [--sjasm path]
"""
import argparse, os, re, subprocess, sys

ap = argparse.ArgumentParser()
ap.add_argument('v6z80p')
ap.add_argument('out')
ap.add_argument('--sjasm', default='/c/hobby/tools/sjasmplus/sjasmplus')
ap.add_argument('--work', default='build/parity_sim')
ap.add_argument('--fast', action='store_true', help='skip the slow intro of the demo (see below)')
a = ap.parse_args()

root = a.v6z80p
src = os.path.join(root, 'FLOS_based_programs/demos/parity/source')
os.makedirs(a.work, exist_ok=True)

# files: name used by the demo -> (bulk file, shelf address)
files = [('BGNDSPR.BIN', 'bgndspr.bin', 0x10000),      # = its destination (bank 1, $8000): no copy
         ('LOGOSPR.BIN', 'logospr.bin', 0x40000),
         ('FONTSPR.BIN', 'fontspr.bin', 0x41000),
         ('12BITPAL.BIN', '12bitpal.bin', 0x45000),
         ('SAMPLES.BIN', 'tune.sam', 0x4D000)]
blobs = {}
for name, fn, shelf in files:
    d = open(os.path.join(src, 'bulk_files', fn), 'rb').read()
    blobs[name] = (shelf, d)
for i, (n1, _, s1) in enumerate(files):
    e1 = s1 + ((len(blobs[n1][1]) + 255) & ~255)
    for n2, _, s2 in files[i + 1:]:
        assert e1 <= s2, (n1, n2)

# ---- stubs (org $1000)
tab = []
for name, fn, shelf in files:
    n = (len(blobs[name][1]) + 255) // 256
    tab.append('\tdw fn_%s, $%04x, %d' % (re.sub(r'\W', '_', name), shelf >> 8, n))
names = '\n'.join('fn_%s\tdb "%s",0' % (re.sub(r'\W', '_', nm), nm) for nm, _, _ in files)
stubs = r'''
	org $1000
	ds $10
	jp boot			; $1010: the boot ROM jumps here
	jp s_ret		; $1013 kjt_print_string
	ds $101f-$
	jp s_wait_vrt		; $101f
	ds $1064-$
	jp s_set_bank		; $1064
	jp s_get_bank		; $1067
	ds $106d-$
	jp s_inc_bank		; $106d
	ds $1076-$
	jp s_memfill		; $1076 kjt_bchl_memfill
	ds $1091-$
	jp s_get_version	; $1091
	ds $10c4-$
	jp s_ret		; $10c4 kjt_flos_display
	ds $1100-$
	jp s_load		; $1100 load_from_bulk_file
	jp s_ret		; $1103 bfl_change_to_programs_dirvol
	jp s_ret		; $1106 bfl_restore_original_dirvol

boot	di
	ld sp,$4ff0
	xor a
	out ($00),a
	out ($0b),a
	ld (cur_bank),a
	call $5000
	ld a,$5a
	ld ($4ff8),a		; the demo returned (ESC)
	jr $

s_ret	xor a
	ret

s_wait_vrt			; wait for the start of the vertical retrace (bit 0 of vreg_read: 0 -> 1)
	push af
wv1	ld a,($0700)
	and 1
	jr nz,wv1
wv2	ld a,($0700)
	and 1
	jr z,wv2
	pop af
	ret

s_get_bank
	ld a,(cur_bank)
	cp a			; Z
	ret
s_inc_bank
	ld a,(cur_bank)
	inc a
s_set_bank			; FLOS bank b -> page b+1 at $8000 (bits 3:0 of sys_mem_select), the other bits kept
	push bc
	ld (cur_bank),a
	inc a
	and $0f
	ld b,a
	in a,($00)
	and $f0
	or b
	out ($00),a
	pop bc
	xor a
	ret

s_memfill			; fill BC bytes at HL with A
	push bc
	push de
	push hl
	ld d,a
mf1	ld (hl),d
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,mf1
	pop hl
	pop de
	pop bc
	xor a
	ret

s_get_version
	ld hl,$0614		; FLOS
	ld de,$0676		; OSCA
	xor a
	ret

; load_from_bulk_file: HL = file name, DE = address ($8000-aligned 256), B = FLOS bank.  Copies the shelved file in 256 byte chunks.
s_load	push bc
	push de
	push hl
	push ix
	in a,($00)
	ld (ld_mem),a
	ld a,b			; destination chunk index = ((b+1) << 7) + (D - $80)
	inc a
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld a,d
	sub $80
	add a,l
	ld l,a
	ld (dci),hl
	ld ix,ftab
	ld hl,2			; the name pointer (HL, pushed third; IX is on top): fetch it from the stack
	add hl,sp
	ld e,(hl)
	inc hl
	ld d,(hl)		; de = the demo's file name
fl	ld l,(ix+0)
	ld h,(ix+1)
	ld a,h
	or l
	jr z,ld_err
	push de
fcmp	ld a,(de)
	cp (hl)
	jr nz,fnext
	or a
	jr z,ffound
	inc hl
	inc de
	jr fcmp
fnext	pop de
	ld bc,6
	add ix,bc
	jr fl
ffound	pop de
	ld l,(ix+2)
	ld h,(ix+3)
	ld (sci),hl
	ld e,(ix+4)
	ld d,(ix+5)
	ld (cnt),de
	ld de,(dci)
	or a
	sbc hl,de
	jr z,ld_ok		; shelved at its destination
cploop	ld hl,(sci)
	call ci2pa
	out ($00),a
	ld de,buf
	ld bc,256
	ldir
	ld hl,(dci)
	call ci2pa
	out ($00),a
	ex de,hl
	ld hl,buf
	ld bc,256
	ldir
	ld hl,(sci)
	inc hl
	ld (sci),hl
	ld hl,(dci)
	inc hl
	ld (dci),hl
	ld hl,(cnt)
	dec hl
	ld (cnt),hl
	ld a,h
	or l
	jr nz,cploop
ld_ok	ld a,(ld_mem)
	out ($00),a
	pop ix
	pop hl
	pop de
	pop bc
	xor a
	ret
ld_err	ld a,$ee
	ld ($4ff9),a
	pop ix
	pop hl
	pop de
	pop bc
	ld a,1
	or a			; NZ = error
	ret

ci2pa	ld a,l			; HL = chunk index (address >> 8) -> A = page (address >> 15), HL = $8000 + (address & $7f00)
	rla
	ld a,h
	rla
	push af
	ld a,l
	or $80
	ld h,a
	ld l,0
	pop af
	ret

cur_bank db 0
ld_mem	db 0
sci	dw 0
dci	dw 0
cnt	dw 0
ftab
''' + '\n'.join(tab) + '\n\tdw 0\n' + names + '\n\tds $1f00-$\nbuf\tds 256\n'
assert '$1f00' in stubs
open(os.path.join(a.work, 'stubs.asm'), 'w').write(stubs)

# ---- the demo: includes made absolute, the bulk file loader replaced by the stub entries
m = open(os.path.join(src, 'main.asm'), encoding='latin-1').read()
def fix_inc(mo):
    kw, p = mo.group(1), mo.group(2).replace('\\', '/')
    if 'bulk_file_loader' in p:
        return ('load_from_bulk_file equ $1100\nbfl_change_to_programs_dirvol equ $1103\nbfl_restore_original_dirvol equ $1106\n')
    if p.lower().startswith('equates/'):
        p = 'Equates/' + p[8:]
    if p.lower().startswith('flos_based_programs/'):
        p = 'FLOS_based_programs/' + p[20:]
    if kw.strip().lower() == 'include': kw = '\tinclude'                 # (sjasmplus: a keyword in column 0 is a label)
    return '%s "%s"' % (kw, os.path.join(root, p).replace('\\', '/'))
if a.fast:
    # start at the 4096 colour picture's arrival (stage 0) with the backdrop and the logo already in place, short waits:
    # the zoom starts ~90 frames after the main loop instead of ~10 s
    for old, new in [('stage               db $e0', 'stage               db $00'),
                     ('bdspr_sin           db 0', 'bdspr_sin           db 64'),
                     ('logo_max            dw 236', 'logo_max            dw 0'),
                     ('          ld de,215', '          ld de,10'),
                     ('          ld hl,100\n', '          ld hl,10\n')]:
        assert m.count(old) == 1, old
        m = m.replace(old, new)
m2, n = re.subn(r'(?im)^(\s*include|\s*[A-Za-z_]\w*\s+incbin|\s*incbin)\s+"([^"]+)"', fix_inc, m)
open(os.path.join(a.work, 'main_sim.asm'), 'w', encoding='latin-1').write(m2)
print('includes rewritten:', n)

def asm(name):
    out = os.path.join(a.work, name.replace('.asm', '.bin'))
    r = subprocess.run([a.sjasm, '--nologo', '--raw=' + out, os.path.join(a.work, name)], capture_output=True, text=True)
    if r.returncode != 0 or not os.path.exists(out):
        print(r.stdout, r.stderr); sys.exit(1)
    return open(out, 'rb').read()

sb = asm('stubs.asm')
mb = asm('main_sim.asm')
assert len(sb) == 0x1000, hex(len(sb))
size = max(s + len(d) for s, d in blobs.values())
size = (size + 0xFFF) & ~0xFFF
img = bytearray(size)
img[0x1000:0x1000 + len(sb)] = sb
img[0x5000:0x5000 + len(mb)] = mb
assert 0x5000 + len(mb) <= 0x10000, hex(0x5000 + len(mb))
for s, d in blobs.values():
    img[s:s + len(d)] = d
open(a.out, 'w').write(''.join('%02x\n' % b for b in img))
print('parity: code $5000-$%04x, image %d bytes (IMG_BYTES >= %d)' % (0x5000 + len(mb) - 1, size, size))
