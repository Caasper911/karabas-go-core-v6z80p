; Audio DMA under load: 4 channels with short periods at different places of one buffer, the CPU busy with system RAM.
; Audio DMA above $20000: 4 channels looping a 512 byte sample buffer at $28000 (word $14000 = location $4000 + aud_loc_hi 1),
; the area of the samples of a big MOD file.  Same pattern as lc_audio (checked by DMACHK with +dmalo=28000 +dmahi=28200).
		org 0x5000
start:		di
		ld sp,0x4FF0
		xor a
		out (0x0b),a
		ld a,5
		out (0x00),a			; page $28000 at $8000
		ld hl,0x8000			; sample data: 256 bytes ramp*5, 256 bytes pattern
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
		xor a
		out (0x00),a
		ld a,1				; aud_loc_hi of the four channels = 1 (word address bit 16)
		out (0x24),a
		out (0x25),a
		out (0x26),a
		out (0x27),a
		; channel setup: location, length (words), period, volume
		ld b,0x40			; ch0 loc = $4000 (+ $10000)
		ld c,0x10
		ld a,0x00
		out (c),a
		ld b,0x00			; len = $0040 words
		ld c,0x11
		ld a,0x40
		out (c),a
		ld b,0x00			; period $0080
		ld c,0x12
		ld a,0x80
		out (c),a
		ld a,0x40
		out (0x13),a
		ld b,0x40			; ch1 loc = $4040
		ld c,0x14
		ld a,0x40
		out (c),a
		ld b,0x00
		ld c,0x15
		ld a,0x40
		out (c),a
		ld b,0x00
		ld c,0x16
		ld a,0x90
		out (c),a
		ld a,0x40
		out (0x17),a
		ld b,0x40			; ch2 loc = $4080
		ld c,0x18
		ld a,0x80
		out (c),a
		ld b,0x00
		ld c,0x19
		ld a,0x40
		out (c),a
		ld b,0x00
		ld c,0x1a
		ld a,0xA0
		out (c),a
		ld a,0x40
		out (0x1b),a
		ld b,0x40			; ch3 loc = $40C0
		ld c,0x1c
		ld a,0xC0
		out (c),a
		ld b,0x00
		ld c,0x1d
		ld a,0x40
		out (c),a
		ld b,0x00
		ld c,0x1e
		ld a,0xB0
		out (c),a
		ld a,0x40
		out (0x1f),a
		ld a,0x0F
		out (0x08),a			; enable the four channels

idle:		ld hl,0x9000
		ld de,0xA000
		ld bc,0x0800
		ldir
		jr idle
