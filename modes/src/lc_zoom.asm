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
		ld a,3
		ld (0x203),a			; 4 bitplanes
		xor a
		ld (0x201),a			; bitmap mode, not chunky
		ld hl,0
		ld (0x240),hl
		xor a
		ld (0x242),a
		ld hl,0x2000
		ld (0x244),hl
		xor a
		ld (0x246),a
		ld hl,0x4000
		ld (0x248),hl
		xor a
		ld (0x24a),a
		ld hl,0x6000
		ld (0x24c),hl
		xor a
		ld (0x24e),a
		ld a,0x40
		out (0x00),a
		ld e,0
pp0:		ld a,e
		ld (0x206),a
		ld hl,0x2000
		ld c,32
pp2:		ld b,0
pp1:		ld a,l
		xor h
		add a,e
		rrca
		add a,e
		add a,e
		ld (hl),a
		inc hl
		djnz pp1
		dec c
		jr nz,pp2
		inc e
		ld a,e
		cp 4
		jr nz,pp0
		xor a
		out (0x00),a
		ld a,0x80
		ld (0x020F),a			; linecop address bits 18:16 = 0, bit 7 set
		ld a,0xA0
		ld (0x020E),a			; list at $A000
		ld a,0x01
		ld (0x020D),a			; bit 0 = enable
idle:		jr idle
