		org 0x8000
start:		di
		ld sp,0xFFF0
		xor a
		out (0x0b),a
		xor a
		ld (0x204),a
		ld a,0x5a
		ld (0x202),a
		ld a,4
		ld (0x204),a
		ld a,0x8c
		ld (0x202),a
		ld hl,0x9000
		ld de,0x0000
		ld bc,512
		ldir
		ld a,0x80
		out (0x00),a			; sprite RAM at $1000
		ld a,0x80
		ld (0x0206),a
		ld hl,0xA800
		ld de,0x1000
		ld bc,3072
		ldir
		xor a
		out (0x00),a
		ld a,1
		ld (0x0207),a			; sprites on
frame:		in a,(7)
		bit 0,a
		jr nz,frame
w1:		in a,(7)
		bit 0,a
		jr z,w1
		ld ix,0xB400
		ld b,24
mv:		inc (ix+0)
		ld de,4
		add ix,de
		djnz mv
		ld hl,0xB400
		ld de,0x0400
		ld bc,96
		ldir
		jr frame
