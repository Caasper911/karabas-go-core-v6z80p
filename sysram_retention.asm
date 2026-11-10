; System RAM retention test: pages 1..15 ($08000-$7FFFF, 480 KB) are filled with a pattern (every byte), left alone for WAITFR frames
; (the program and its stack stay in $00000-$07FFF, nothing else touches the SDRAM rows of the pages), then read back.  Repeats forever,
; the pattern is inverted on every pass.  A loss of data in rows that are not read (refresh) shows here, a fast write / read test cannot see it.
; Result in palette entry 0 (the whole screen):
;   grey while the first pass runs;  green bright / dim alternating every pass = no error so far;
;   red = an error happened (stays): the blue nibble = the page of the first error, the green nibble = bits 14..12 of its offset.
	IFNDEF WAITFR
WAITFR	equ 500				; 10 s at 50 Hz
	ENDIF
	IFNDEF NPAGES
NPAGES	equ 15				; pages 1..NPAGES (the simulation uses fewer)
	ENDIF
inv	equ 0x4F00
fail	equ 0x4F01
iter	equ 0x4F02
cnt	equ 0x4F04

	org 0x5000
start:	di
	ld sp,0x4FF0
	xor a
	out (0x0b),a
	out (0x00),a
	ld (inv),a
	ld (fail),a
	ld (iter),a
	ld hl,0x0000			; grey
	ld (hl),0x88
	inc hl
	ld (hl),0x08

pass:	; ---- fill: byte = L xor H xor (page*65 mod 256) xor inv
	ld c,1
fp:	ld a,c
	out (0x00),a
	add a,a				; page * $1D in B
	add a,a
	add a,a
	add a,a
	add a,c
	add a,a
	add a,a
	sub c
	sub c
	sub c
	ld b,a				; (= page * 65 mod 256)
	ld a,(inv)
	xor b
	ld b,a
	ld hl,0x8000
fl:	ld a,l
	xor h
	xor b
	ld (hl),a
	inc hl
	ld a,h
	or a
	jr nz,fl			; until HL wraps to $0000
	inc c
	ld a,c
	cp NPAGES+1
	jr nz,fp
	xor a
	out (0x00),a
	; ---- wait WAITFR frames (only the low 32 KB and the video registers are touched)
	ld hl,WAITFR
	ld (cnt),hl
wt:	ld a,(0x0700)
	and 1
	jr z,wt
wt2:	ld a,(0x0700)
	and 1
	jr nz,wt2
	ld hl,(cnt)
	dec hl
	ld (cnt),hl
	ld a,h
	or l
	jr nz,wt
	; ---- verify
	ld c,1
vp:	ld a,c
	out (0x00),a
	add a,a
	add a,a
	add a,a
	add a,a
	add a,c
	add a,a
	add a,a
	sub c
	sub c
	sub c
	ld b,a
	ld a,(inv)
	xor b
	ld b,a
	ld hl,0x8000
vl:	ld a,l
	xor h
	xor b
	cp (hl)
	jr nz,bad
vn:	inc hl
	ld a,h
	or a
	jr nz,vl
	inc c
	ld a,c
	cp NPAGES+1
	jr nz,vp
	xor a
	out (0x00),a
	jr show

bad:	xor a
	out (0x00),a
	ld a,(fail)
	or a
	jr nz,show			; keep the first error
	ld a,h				; green nibble = offset bits 14..12, blue nibble = page
	and 0x70
	or c
	ld (fail),a

show:	ld a,(fail)
	or a
	jr nz,shbad
	ld a,(iter)
	and 1
	ld a,0xF0
	jr z,sh1
	ld a,0x80
sh1:	ld (0x0000),a
	xor a
	ld (0x0001),a
	jr next
shbad:	ld (0x0000),a
	ld a,0x0F
	ld (0x0001),a
next:	ld a,(iter)
	inc a
	ld (iter),a
	ld a,(inv)
	cpl
	ld (inv),a
	jp pass
