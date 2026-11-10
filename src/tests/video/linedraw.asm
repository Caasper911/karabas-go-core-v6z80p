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
		ld a,0xbb
		ld (0x202),a
		ld hl,0x9000
		ld de,0x0000
		ld bc,512
		ldir
		ld hl,0x1E00
		ld (0x240),hl
		ld a,7
		ld (0x242),a			; datafetch start $71E00
		ld a,0x80
		ld (0x201),a
		ld hl,0xB600
		ld de,0x0230
		ld bc,16
		ldir				; line draw constants
		ld ix,0xB500
		ld b,8
nl:		in a,(7)
		bit 4,a
		jr nz,nl
		ld l,(ix+0)
		ld h,(ix+1)
		ld (0x224),hl
		ld l,(ix+2)
		ld h,(ix+3)
		ld (0x220),hl
		ld l,(ix+4)
		ld h,(ix+5)
		ld (0x222),hl
		ld a,(ix+6)
		ld (0x20b),a
		ld l,(ix+8)
		ld h,(ix+9)
		ld (0x226),hl
		ld de,10
		add ix,de
		djnz nl
idle:		jr idle
