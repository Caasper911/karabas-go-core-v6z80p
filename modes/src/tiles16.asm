		org 0x8000
start:		di
		ld sp,0xFFF0
		xor a
		out (0x0b),a
		xor a
		ld (0x204),a
		ld a,0x3d
		ld (0x202),a
		ld a,4
		ld (0x204),a
		ld a,0x7e
		ld (0x202),a
		ld hl,0x9000
		ld de,0x0000
		ld bc,512
		ldir
		ld a,1
		ld (0x20c),a			; extended tile mode
		ld a,1
		ld (0x201),a			; 16x16 tile mode, single playfield
		xor a
		ld (0x200),a
		ld (0x203),a
		ld a,0x40
		out (0x00),a
		ld a,0x38
		ld (0x206),a
		call clr8k
		ld a,0x39
		ld (0x206),a
		call clr8k
		xor a
		ld (0x206),a
		ld hl,0x9800
		ld de,0x2000
		ld bc,0x1000
		ldir
		ld a,0x38
		ld (0x206),a
		ld hl,0x2000
		ld e,0
		ld c,16
lp2:		ld b,24
lp1:		ld (hl),e
		set 3,h
		ld (hl),0
		res 3,h
		inc hl
		inc e
		ld a,e
		and 15
		ld e,a
		djnz lp1
		ld a,l
		add a,8
		ld l,a
		jr nc,hi_ok
		inc h
hi_ok:		dec c
		jr nz,lp2
		xor a
		out (0x00),a
idle:		jr idle
clr8k:		ld hl,0x2000
		ld bc,0x2000
c8:		xor a
		ld (hl),a
		inc hl
		dec bc
		ld a,b
		or c
		jr nz,c8
		ret
