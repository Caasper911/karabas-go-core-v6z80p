; Karabas Go replacement for the OSCA boot ROM tail: no PIC / EEPROM, the MCU loader has already put FLOS
; into system RAM at $1000.  Hardware set-up is what bootcode_618 does before it starts the OS.
		org 0x69
start2:	xor a
		out (0Bh),a			; writes to $200-$7FF go to the video registers / palette / sprites
		ld hl,0200h			; clear palette + sprite + video registers $200-$5FF (video enabled: vidctrl = 0)
		ld bc,0400h
clr1:		ld (hl),0
		inc hl
		dec bc
		ld a,b
		or c
		jr nz,clr1
		ld hl,0230h			; as bootcode: clear $230-$27F
		ld b,50h
clr2:		ld (hl),0
		inc hl
		djnz clr2
		ld hl,0202h
		ld (hl),59h			; y window (192 lines)
		ld a,4
		ld (0204h),a			; select the x window register
		ld (hl),8Ch			; x window (320 pixels)
		ld a,1
		out (02h),a			; clear the keyboard irq flag (as bootcode start_os)
		xor a
		out (00h),a			; default upper page 0
		out (0Bh),a			; video registers paged in
		ld bc,0				; drives present: none
		ld hl,0618h			; bootcode version passed to the OS
		ld a,1				; A=1: valid version in HL
		jp 1010h			; FLOS entry = OS_location + 10h
