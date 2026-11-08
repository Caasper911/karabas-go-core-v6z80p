; CPU reads of the video RAM: write 512 bytes through the $2000 window, read them back (compare + LDIR), show the result in colour 0:
; green = no errors, otherwise red with the number of errors (clipped to 15) in the blue nibble
		org 0x8000
start:		di
		ld sp,0xFFF0
		xor a
		out (0x0b),a
		ld a,0x40
		out (0x00),a			; video RAM at $2000
		xor a
		ld (0x206),a			; vidpage 0
		ld hl,0x2000
		ld c,2
wo:		ld b,0
		ld a,1
wi:		ld (hl),a
		inc hl
		add a,3
		djnz wi
		dec c
		jr nz,wo
		ld hl,0x2000			; compare read-back
		ld c,2
		ld d,0
ro:		ld b,0
		ld a,1
ri:		cp (hl)
		jr z,rok
		inc d
rok:		inc hl
		add a,3
		djnz ri
		dec c
		jr nz,ro
		ld a,d
		ld (0x9F00),a			; keep the direct-compare error count (LDIR uses DE)
		ld hl,0x2000			; LDIR copy to RAM, then compare there
		ld de,0x9C00
		ld bc,512
		ldir
		ld hl,0x9C00
		ld c,2
		ld e,0
ro2:		ld b,0
		ld a,1
ri2:		cp (hl)
		jr z,rok2
		inc e
rok2:		inc hl
		add a,3
		djnz ri2
		dec c
		jr nz,ro2
		xor a
		out (0x00),a
		ld a,(0x9F00)
		ld d,a
		ld a,d					; D = errors of the direct compare, E = errors of the LDIR copy (each clipped to 15)
		cp 16
		jr c,s1
		ld d,15
s1:		ld a,e
		cp 16
		jr c,s2
		ld e,15
s2:		ld a,d
		rlca
		rlca
		rlca
		rlca
		or e
		ld (0x0000),a			; low byte: G = errors (direct), B = errors (LDIR)
		ld a,d
		or e
		ld a,0
		jr z,s3
		ld a,0x0F
s3:		ld (0x0001),a			; R = F if any error
		ld a,0xFF
		ld (0x0002),a
		ld a,0x0F
		ld (0x0003),a			; colour 1 = white: the program reached its end
done:		jr done
