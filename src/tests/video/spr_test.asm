; OSCA sprite stress test: 3 overlapping rows of 16 sprites (48 sprites on the busiest lines), two definitions
		org 0x8000
start:		di
		ld sp,0xFFF0
		xor a
		out (0x0b),a			; video registers / palette paged in for writes
		; palette: 1 = yellow (0FF0), 2 = green (00F0), 3 = blue (000F); word, low byte (GB) first
		ld hl,0x0002
		ld (hl),0xF0
		inc hl
		ld (hl),0x0F
		ld hl,0x0004
		ld (hl),0xF0
		inc hl
		ld (hl),0x00
		ld hl,0x0006
		ld (hl),0x0F
		inc hl
		ld (hl),0x00
		; sprite definitions in sprite RAM bank 0
		ld a,0x80
		ld (0x0206),a			; vidpage register, bit 7 set = sprite page 0
		ld a,0x80
		out (0x00),a			; page sprite RAM in at $1000-$1FFF
		ld hl,0x1000
		ld b,0
		ld a,1
d0:		ld (hl),a			; definition 0: all colour 1
		inc hl
		djnz d0
		ld b,0
		ld c,2
d1:		ld (hl),c			; definition 1: colours 2 / 3 alternating
		inc hl
		ld a,c
		xor 1
		ld c,a
		djnz d1
		xor a
		out (0x00),a			; page sprite RAM out again
		; sprite registers at $400, 4 bytes each: x low, misc, y low, definition
		ld hl,0x0400
		ld d,3				; rows
		ld e,0				; y offset
rowlp:		ld b,0				; column
collp:		ld a,b
		add a,a
		add a,a
		add a,a
		add a,a				; b*16
		add a,128			; carry = bit 8 of x
		ld (hl),a
		inc hl
		ld a,0x10			; height 1
		adc a,0
		ld (hl),a
		inc hl
		ld a,e
		add a,49
		ld (hl),a
		inc hl
		ld a,b
		and 1
		ld (hl),a
		inc hl
		inc b
		ld a,b
		cp 16
		jr nz,collp
		ld a,e
		add a,6
		ld e,a
		dec d
		jr nz,rowlp
		ld a,1
		ld (0x0207),a			; sprites on
idle:		jr idle
