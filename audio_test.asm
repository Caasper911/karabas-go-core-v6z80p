; OSCA audio DMA test: 4 channels looping a 512 byte sample buffer in system RAM at $6000 (word offset $3000)
		org 0x8000
start:		di
		ld sp,0xFFF0
		xor a
		out (0x0b),a
		ld hl,0x6000			; sample data: 256 bytes ramp*5, 256 bytes pattern
		ld b,0
		ld c,0
f1:		ld a,c
		add a,a
		add a,a
		add a,c
		ld (hl),a
		inc hl
		inc c
		djnz f1
		ld b,0
f2:		ld a,c
		xor 0x5A
		ld (hl),a
		inc hl
		inc c
		djnz f2
		; channel setup: location, length (words), period, volume
		ld b,0x30			; ch0 loc = $3000
		ld c,0x10
		xor a
		out (c),a
		ld b,0x01			; len = $0100 words
		ld c,0x11
		xor a
		out (c),a
		ld b,0x02			; period $0258 = 600
		ld c,0x12
		ld a,0x58
		out (c),a
		ld a,0x40
		out (0x13),a
		ld b,0x30			; ch1
		ld c,0x14
		xor a
		out (c),a
		ld b,0x01
		ld c,0x15
		xor a
		out (c),a
		ld b,0x02			; 650 = $028A
		ld c,0x16
		ld a,0x8A
		out (c),a
		ld a,0x40
		out (0x17),a
		ld b,0x30			; ch2
		ld c,0x18
		xor a
		out (c),a
		ld b,0x01
		ld c,0x19
		xor a
		out (c),a
		ld b,0x02			; 700 = $02BC
		ld c,0x1a
		ld a,0xBC
		out (c),a
		ld a,0x40
		out (0x1b),a
		ld b,0x30			; ch3
		ld c,0x1c
		xor a
		out (c),a
		ld b,0x01
		ld c,0x1d
		xor a
		out (c),a
		ld b,0x02			; 550 = $0226
		ld c,0x1e
		ld a,0x26
		out (c),a
		ld a,0x40
		out (0x1f),a
		ld a,0x0F
		out (0x08),a			; enable the four channels
idle:		jr idle
