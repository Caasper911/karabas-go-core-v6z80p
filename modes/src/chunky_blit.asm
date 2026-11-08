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
		ld hl,0
		ld (0x240),hl
		xor a
		ld (0x242),a
		ld a,0x80
		ld (0x201),a			; chunky bitmap mode
		ld a,0x40
		out (0x00),a			; video RAM paged in at $2000
		ld e,0
fp0:		ld a,e
		ld (0x206),a			; vidpage
		ld hl,0x2000
		ld c,32
fp2:		ld b,0
fp1:		ld a,l
		add a,e
		add a,h
		ld (hl),a
		inc hl
		djnz fp1
		dec c
		jr nz,fp2
		inc e
		ld a,e
		cp 7
		jr nz,fp0
		ld a,8
		ld (0x206),a			; VRAM $10000: the object
		ld hl,0x9400
		ld de,0x2000
		ld bc,896
		ldir
		xor a
		out (0x00),a
		ld de,0x1010
		ld c,0
		ld b,0x40
		call blit
		ld de,0x2830
		ld c,0
		ld b,0xC0
		call blit
		ld de,0x5020
		ld c,0
		ld b,0x40
		call blit
idle:		jr idle
blit:		ld hl,0
		ld (0x210),hl
		ld a,1
		ld (0x219),a
		xor a
		ld (0x214),a
		ld (0x212),de
		ld a,c
		ld (0x21a),a
		ld a,224
		ld (0x215),a
		ld a,b
		ld (0x218),a
		ld a,27
		ld (0x216),a
		ld a,31
		ld (0x217),a
		nop
		nop
bw:		in a,(7)
		bit 4,a
		jr nz,bw
		ret
