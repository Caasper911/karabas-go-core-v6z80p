; System RAM test over $08000-$7FFFF: pages 1..15 (32 KB each, at $8000 through sys_mem_select) get a signature byte at 8 offsets
; ($8000, $9000 ... $F000: every SDRAM row bit inside the page); page $00000-$07FFF holds the program.
; Then everything is read back.  Result in palette entry 0 (the whole screen):
;   green = no error;  red = errors, the blue nibble = the first bad page, the green nibble = the first bad offset ($x000 >> 12, 8..F).
		org 0x5000
start:		di
		ld sp,0x4FF0
		xor a
		out (0x0b),a
		ld hl,0x0000			; palette entry 0: grey while the test runs
		ld (hl),0x88
		inc hl
		ld (hl),0x08
		; ---- write
		ld c,1				; page (values 0 and 1 both select $08000: start at 1)
wp:		ld a,c
		out (0x00),a			; page c at $8000
		ld h,0x80
wo:		ld l,0
		ld a,c				; signature: page * 16 + offset nibble, xor $5A
		add a,a
		add a,a
		add a,a
		add a,a
		add a,h
		xor 0x5A
		ld (hl),a
		inc l
		cpl
		ld (hl),a			; and its complement in the next byte
		ld a,h
		add a,0x10
		ld h,a
		jr nc,wo			; $8000 .. $F000
		inc c
		ld a,c
		cp 16
		jr nz,wp
		; ---- read back
		ld c,1
rp:		ld a,c
		out (0x00),a
		ld h,0x80
ro:		ld l,0
		ld a,c
		add a,a
		add a,a
		add a,a
		add a,a
		add a,h
		xor 0x5A
		cp (hl)
		jr nz,bad
		inc l
		cpl
		cp (hl)
		jr nz,bad
		ld a,h
		add a,0x10
		ld h,a
		jr nc,ro
		inc c
		ld a,c
		cp 16
		jr nz,rp
		xor a
		out (0x00),a
		ld hl,0x0000			; green
		ld (hl),0xF0
		inc hl
		ld (hl),0x00
		jr idle
bad:		xor a
		out (0x00),a
		ld a,h				; green nibble = offset nibble (8..F), blue nibble = page
		and 0xF0
		or c
		ld hl,0x0000
		ld (hl),a
		inc hl
		ld (hl),0x0F			; red
idle:		jr idle
