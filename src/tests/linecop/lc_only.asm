; OSCA audio DMA test: 4 channels looping a 512 byte sample buffer in system RAM at $6000 (word offset $3000)
		org 0x8000
start:		di
		ld sp,0xFFF0
		xor a
		out (0x0b),a

		ld a,0x80
		ld (0x020F),a			; linecop address bits 23:16, bit 7 set
		ld a,0x64
		ld (0x020E),a			; linecop address bits 15:8  -> list at $6400
		ld a,0x01
		ld (0x020D),a			; linecop address bits 7:0, bit 0 = enable
idle:		jr idle
