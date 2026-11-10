#!/usr/bin/env python3
"""Build a simulation RAM image that plays a Protracker .MOD with the v6z80p OSCA player (code_library/Protracker_Player, osca_modplayer_v515)
the way FLOS MODPLAY does (module right after the code, word aligned), without FLOS: the two FLOS calls the player uses (kjt_read_sysram_flat,
kjt_write_sysram_flat) are stubs at their jump table entries.  Output: a flat image (file offset = system RAM address) for tb_boot.sv.

usage: make_mod_image.py <v6z80p checkout> <file.mod> <out.hex> [--sjasm path]
"""
import argparse, os, subprocess, sys

ap = argparse.ArgumentParser()
ap.add_argument('v6z80p')
ap.add_argument('mod')
ap.add_argument('out')
ap.add_argument('--sjasm', default='C:/hobby/tools/sjasmplus/sjasmplus.exe')
ap.add_argument('--work', default='build/mod_sim')
a = ap.parse_args()
root = a.v6z80p.replace('\\', '/')
os.makedirs(a.work, exist_ok=True)

src = r'''
	include "%(root)s/Equates/kernal_jump_table.asm"
	include "%(root)s/Equates/osca_hardware_equates.asm"
	include "%(root)s/Equates/system_equates.asm"

	org $1000
	ds $10
	jp $5000		; $1010: the boot ROM jumps here
s_rd	ld a,h			; page = E:HL >> 15
	rla
	ld a,e
	rla
	or a
	jr z,s_rdlo		; flat $00000-$07FFF: the low half of the Z80 space itself
	out (sys_mem_select),a
	ld a,h
	or $80
	ld h,a
	ld a,(hl)
	push af
	xor a
	out (sys_mem_select),a
	pop af
	ret
s_rdlo	ld a,(hl)
	ret
s_wr	push af
	ld a,h
	rla
	ld a,e
	rla
	or a
	jr z,s_wrlo
	out (sys_mem_select),a
	ld a,h
	or $80
	ld h,a
	pop af
	ld (hl),a
	push af
	xor a
	out (sys_mem_select),a
	pop af
	ret
s_wrlo	pop af
	ld (hl),a
	ret
	ds $10e2-$
	jp s_rd			; $10e2 kjt_read_sysram_flat:  A = byte at flat E:HL
	jp s_wr			; $10e5 kjt_write_sysram_flat: byte A to flat E:HL
	ds $1100-$

	org $5000
	di
	ld sp,$4ff0
	xor a
	out (sys_alt_write_page),a
	out (sys_mem_select),a
	call pt_init
	jr z,init_ok
	ld a,$ee
	ld ($4ff8),a		; incompatible module
	jr $
init_ok	ld a,$5a
	ld ($4ff8),a
wvrt	ld a,(vreg_read)	; wait for VRT, then play one tick (as MODPLAY does)
	and 1
	jr z,wvrt
wvrte	ld a,(vreg_read)
	and 1
	jr nz,wvrte
	call osca_play_tracker
	jr wvrt

	include "%(root)s/FLOS_based_programs/code_library/Protracker_Player/inc/osca_modplayer_v515.asm"

pt_module_loc_hi	equ 0
	org ($+1) & $FFFE
pt_module_loc_lo	db 0
''' % {'root': root}
# the library includes its generic part with a path relative to the v6z80p root and backslashes
lib = open(os.path.join(root, 'FLOS_based_programs/code_library/Protracker_Player/inc/osca_modplayer_v515.asm'), encoding='latin-1').read()
lib = lib.replace('include "FLOS_based_programs\\code_library\\Protracker_Player\\inc\\generic_z80_modplayer.asm"',
                  'include "%s/FLOS_based_programs/code_library/Protracker_Player/inc/generic_z80_modplayer.asm"' % root)
open(os.path.join(a.work, 'osca_modplayer_v515.asm'), 'w', encoding='latin-1').write(lib)
src = src.replace('%s/FLOS_based_programs/code_library/Protracker_Player/inc/osca_modplayer_v515.asm' % root,
                  os.path.abspath(os.path.join(a.work, 'osca_modplayer_v515.asm')).replace('\\', '/'))
open(os.path.join(a.work, 'modsim.asm'), 'w').write(src)

def asm(org, name):
    out = os.path.join(a.work, name)
    r = subprocess.run([a.sjasm, '--nologo', '--raw=' + out, '--sym=' + out + '.sym', os.path.join(a.work, 'modsim.asm')],
                       capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stdout, r.stderr); sys.exit(1)
    return open(out, 'rb').read()

raw = asm(0x1000, 'modsim.bin')
sym = {}
for l in open(os.path.join(a.work, 'modsim.bin.sym')):
    p = l.replace(':', '').split()
    if len(p) >= 3 and p[1].upper() == 'EQU':
        sym[p[0]] = int(p[2], 0)
mloc = sym['pt_module_loc_lo']
mod = open(a.mod, 'rb').read()
img = bytearray(max(0x10000, mloc + len(mod)))
# --raw concatenates the two org blocks: $1000-$10FF (stubs), then $5000.. (player)
if raw[0x100:0x104] != bytes([0xF3, 0x31, 0xF0, 0x4F]):
    sys.exit('unexpected raw output layout')
img[0x1000:0x1100] = raw[:0x100]
code = raw[0x100:]
img[0x5000:0x5000 + len(code)] = code
img[mloc:mloc + len(mod)] = mod
size = (len(img) + 0xFFF) & ~0xFFF
img += bytes(size - len(img))
open(a.out, 'w').write(''.join('%02x\n' % b for b in img))
print('player $5000-$%04x, module %s (%d bytes) at $%05x, image %d bytes (IMG_BYTES >= %d)' % (mloc - 1, os.path.basename(a.mod), len(mod), mloc, size, size))
