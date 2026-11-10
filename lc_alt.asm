; Line copper in the legacy addressing mode (list in the top 64 KB of the system RAM, $70000) written through the alternative write page,
; as the 'parity' demo does, and rewritten by the CPU every frame (the colour of every line moves with the frame counter).
; 100 lines from $30, each: wait, select palette entry 0, write its two bytes.  Compare the frames with the ideal-memory reference.
		org 0x5000
start:		di
		ld sp,0xFFF0
		xor a
		out (0x0b),a
		ld e,0				; frame counter
		call build			; first list
		ld hl,0x0001
		ld (0x020D),hl			; linecop: address $0000 of the top 64 KB (legacy), bit 0 = enable
frame:		ld a,(0x0700)			; wait for the vertical retrace (bit 0 of vreg_read), then for its end
		and 1
		jr z,frame
fr2:		ld a,(0x0700)
		and 1
		jr nz,fr2
		inc e
		call build
		jr frame

; write the list into page 14 (= $70000, the line copper's legacy area) through the alternative write page
build:		ld a,0x12			; alternative write page on (bit 4), source bank 2
		out (0x00),a
		ld a,14
		out (0x0b),a
		ld hl,0x8000
		ld d,0x30			; line
		ld b,100
bl:		ld (hl),d			; wait for line d
		inc hl
		ld (hl),0xC0
		inc hl
		ld (hl),0x00			; select register $000 (palette entry 0)
		inc hl
		ld (hl),0x80
		inc hl
		ld a,d				; colour low byte (GB): line + frame
		add a,e
		ld (hl),a
		inc hl
		ld (hl),0x40			; write + increment
		inc hl
		ld a,e				; colour high byte (R): frame
		and 0x0F
		ld (hl),a
		inc hl
		ld (hl),0x00			; write
		inc hl
		inc d
		djnz bl
		ld (hl),0xFF			; wait for line $1FF: end of the list
		inc hl
		ld (hl),0xC1
		xor a
		out (0x00),a
		out (0x0b),a			; back: bank 0, video registers paged in
		ret
