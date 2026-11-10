; Interrupt test (IM 1, OSCA ROM vector $0038 -> JP $0A00).  Sources: timer (period 256 -> one IRQ per 65536 ticks of 16 MHz),
; audio channel 0 looping a 128 byte sample at period 512 (also one IRQ per 65536 ticks), video raster IRQ at line 100 (one per frame).
; Load while it runs: the line copper writes 8 palette entries on every second line, the CPU copies memory (8 byte LDIR) between polls of the VRT
; flag (the VRT line lasts 64 us: the poll gap, with up to three interrupts served in it, stays well below that).
; One pass = NFR frames, then the counts are checked:
;   video = NFR exactly;  timer and audio within 2 of each other and between 3*NFR and 6*NFR;  no interrupt without a flag set.
; Result: horizontal bands of colour 0 set by the line copper; passes repeat forever and errors stay:
;   top / bottom: pass indicator, white and grey alternating every pass (all black before the first pass ends);
;   then 5 bands, green = never failed, red = failed at least once:  1 fewer video IRQs than frames,  2 more video IRQs than frames,
;   3 timer count,  4 audio vs timer,  5 an interrupt with no flag.
; The counts of the last pass: system RAM $4F00 (and video RAM $00000, for the simulation): video, timer, audio, keyboard, none (words),
; pass number, error bits (bytes).
	IFNDEF NFR
NFR	equ 50
	ENDIF
cnt_v	equ 0x4F00
cnt_t	equ 0x4F02
cnt_a	equ 0x4F04
cnt_k	equ 0x4F06
cnt_n	equ 0x4F08
iter	equ 0x4F0A
fail	equ 0x4F0B
nfr	equ 0x4F0C
vprev	equ 0x4F0D
bandtab	equ 0x4F20			; 7 addresses of the colour 0 writes in the line copper list (lines $30, $50 ... $F0)

	org 0x5000			; the image puts JP $5003 at $0A00 (the ROM's IRQ vector target)
	jp start
	jp irq_h
start:	di
	ld sp,0x4FF0
	im 1
	xor a
	out (0x0b),a
	out (0x00),a
	out (0x01),a			; no interrupt sources
	out (0x08),a			; audio off
	ld hl,0x0000			; colour 0: grey while the first pass runs
	ld (hl),0x88
	inc hl
	ld (hl),0x08
	xor a
	ld (iter),a
	ld (fail),a
	; ---- sample: 128 bytes at $6000 (word address $3000)
	ld hl,0x6000
	ld b,128
	xor a
smp:	ld (hl),a
	add a,2
	inc hl
	djnz smp
	xor a
	out (0x24),a			; loc_hi
	ld b,0x30			; loc = $3000
	ld c,0x10
	xor a
	out (c),a
	ld b,0x00			; len = 64 words
	ld c,0x11
	ld a,0x40
	out (c),a
	ld b,0x02			; period = 512
	ld c,0x12
	xor a
	out (c),a
	ld a,0x20
	out (0x13),a
	ld a,0x01
	out (0x08),a			; channel 0 on
	; ---- line copper list in the legacy area ($70000 = page 14 at $8000)
	ld a,14
	out (0x00),a
	ld hl,0x8000
	ld d,0x30			; line
	ld b,100
	ld ix,bandtab
lcl:	ld (hl),d			; wait for line d
	inc hl
	ld (hl),0xC0
	inc hl
	ld a,d				; band boundary (line $30, $50 ... $F0): colour 0 = the band's colour (patched by the CPU)
	and 0x1F
	cp 0x10
	jr nz,lcnb
	ld a,d
	cp 0xF8
	jr nc,lcnb
	ld (hl),0x00			; select register $000 (palette entry 0)
	inc hl
	ld (hl),0x80
	inc hl
	ld (ix+0),l			; address of the low data byte
	ld (ix+1),h
	inc ix
	inc ix
	ld (hl),0x00			; colour low (G B), write + increment
	inc hl
	ld (hl),0x40
	inc hl
	ld (hl),0x00			; colour high (R), write
	inc hl
	ld (hl),0x00
	inc hl
lcnb:	ld (hl),0x20			; select register $020 (palette entry 16)
	inc hl
	ld (hl),0x80
	inc hl
	ld c,16				; 16 bytes = 8 entries, write + increment
lcw:	ld a,d
	add a,c
	ld (hl),a
	inc hl
	ld (hl),0x40
	inc hl
	dec c
	jr nz,lcw
	inc d
	inc d
	djnz lcl
	ld (hl),0xFF			; wait for line $1FF: end of the list
	inc hl
	ld (hl),0xC1
	xor a
	out (0x00),a
	ld hl,0x0001
	ld (0x020D),hl			; line copper: legacy address $0000 of the top 64 KB, enabled
	; ---- raster IRQ at line 100
	xor a
	ld (0x0204),a
	ld a,100
	ld (0x0205),a

pass:	call vrt_start
	di
	ld hl,0
	ld (cnt_v),hl
	ld (cnt_t),hl
	ld (cnt_a),hl
	ld (cnt_k),hl
	ld (cnt_n),hl
	xor a
	out (0x07),a			; timer: period 256, prescaler cleared
	ld a,0xF7
	out (0x02),a			; clear keyboard, mouse, timer, audio flags
	ld a,0x80
	ld (0x0204),a			; clear the video flag
	ld a,0x1C
	out (0x01),a			; enable timer, video, audio
	ld a,NFR
	ld (nfr),a
	ld a,1
	ld (vprev),a
	ei
fr:	ld hl,0x6400			; load: 32 byte copy, then look at the VRT flag
	ld de,0x6800
	ld bc,8
	ldir
	ld a,(0x0700)
	and 1
	ld b,a
	ld a,(vprev)
	cp b
	jr z,fr
	ld a,b
	ld (vprev),a
	or a
	jr z,fr				; end of the VRT line: not counted
	ld a,(nfr)
	dec a
	ld (nfr),a
	jr nz,fr
	di
	xor a
	out (0x01),a
	; ---- check (error bits of this pass in E; only HL / BC used for the arithmetic)
	ld e,0
	ld hl,(cnt_v)			; video = NFR
	ld bc,NFR
	or a
	sbc hl,bc
	jr z,ck1
	set 0,e				; fewer video IRQs than frames (carry)
	jr c,ck1
	res 0,e
	set 1,e				; more video IRQs than frames
ck1:	ld hl,(cnt_t)			; timer between 3*NFR and 6*NFR
	ld bc,3*NFR
	or a
	sbc hl,bc
	jr c,ck2b
	ld hl,(cnt_t)
	ld bc,6*NFR+1
	or a
	sbc hl,bc
	jr c,ck2
ck2b:	set 2,e
ck2:	ld hl,(cnt_t)			; timer - audio + 2 must be 0..4
	ld bc,(cnt_a)
	or a
	sbc hl,bc
	inc hl
	inc hl
	ld a,h
	or a
	jr nz,ck3b
	ld a,l
	cp 5
	jr c,ck4
ck3b:	set 3,e
ck4:	ld hl,(cnt_n)			; no interrupt without a flag
	ld a,h
	or l
	jr z,ck5
	set 4,e
ck5:	ld a,(fail)
	or e
	ld (fail),a
	ld a,(iter)
	inc a
	ld (iter),a
	; ---- show: the line copper's colour 0 writes.  Band 0 (lines $30..$4F) and the last one ($D0..): pass indicator (white / grey);
	;      bands 1..4 ($50, $70, $90, $B0): error bits 0..3 (green = never, red = happened at least once)
	ld a,14
	out (0x00),a
	ld a,(iter)
	and 1
	ld bc,0x0FFF			; B = high (R), C = low (G B)
	jr z,sh1
	ld bc,0x0444
sh1:	ld hl,(bandtab)
	call putcol
	ld hl,(bandtab+12)
	call putcol
	ld a,(fail)
	ld e,a
	ld ix,bandtab+2
	ld d,5
shb:	ld bc,0x00F0			; green
	srl e
	jr nc,shb1
	ld bc,0x0F00			; red
shb1:	ld l,(ix+0)
	ld h,(ix+1)
	call putcol
	inc ix
	inc ix
	dec d
	jr nz,shb
	xor a
	out (0x00),a
	; ---- copy the counts to video RAM $00000 (for the simulation)
	ld a,0x40
	out (0x00),a			; video RAM at $2000
	xor a
	ld (0x0206),a			; video page 0
	ld hl,cnt_v
	ld de,0x2000
	ld bc,12
	ldir
	xor a
	out (0x00),a
	jp pass

putcol:	ld (hl),c			; HL = address of the low data byte of a colour write in the list
	inc hl
	inc hl
	ld (hl),b
	ret

vrt_start:				; wait for the start of the VRT line (bit 0 of vreg_read: 0 -> 1)
	ld a,(0x0700)
	and 1
	jr nz,vrt_start
vs2:	ld a,(0x0700)
	and 1
	jr z,vs2
	ret

irq_h:	push af
	push bc
	push hl
	ld c,0				; sources served
	in a,(0x01)
	ld b,a
	bit 2,b
	jr z,ih1
	ld hl,(cnt_t)
	inc hl
	ld (cnt_t),hl
	ld a,0x04
	out (0x02),a
	inc c
ih1:	bit 3,b
	jr z,ih2
	ld hl,(cnt_v)
	inc hl
	ld (cnt_v),hl
	ld a,0x80
	ld (0x0204),a
	inc c
ih2:	bit 0,b
	jr z,ih3
	in a,(0x02)
	ld hl,(cnt_k)
	inc hl
	ld (cnt_k),hl
	ld a,0x01
	out (0x02),a
	inc c
ih3:	in a,(0x08)
	and 0xF0
	jr z,ih4
	out (0x02),a			; clear the loop flags that are set
	ld hl,(cnt_a)
	inc hl
	ld (cnt_a),hl
	inc c
ih4:	ld a,c
	or a
	jr nz,ih5
	ld hl,(cnt_n)
	inc hl
	ld (cnt_n),hl
ih5:	pop hl
	pop bc
	pop af
	ei
	reti
