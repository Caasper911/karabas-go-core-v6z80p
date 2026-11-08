# OSCA (V6Z80P+ v1.1, osca676p) -> Karabas Go   (status: work in progress)

All results are from simulation (iverilog / Verilator / yosys). Nothing was built with ISE or run on hardware.

## Verified in simulation (bit-exact against the same core with ideal zero-delay asynchronous memories)
- Schematic-entry project -> Verilog (`sch2v.py`, `gen_prims.py`, `patch_osca_top.py`): no tri-states, no driver conflicts, reversed
  buses `x(0:7)` handled, boot ROM contents from the UCF carried over.
- Soft Z80 (T80s VHDL, or tv80s for iverilog) + shared-bus arbiter (`kg_osca_cpu.v`). A real Z80 changes its outputs tens of ns after the
  clock edge and OSCA relies on it, so the CPU outputs are staged through falling-edge registers (half a cycle late) and MREQ#/IORQ# are held
  another half cycle after WR#/RD# (sprite register RAM, sound registers and the ports clocked by `delayed_cpu_wr` depend on that).
  FLOS and the sprite test are bit-identical to the reference with this staging.
- Boot without the config PIC/EEPROM: replacement boot ROM (`rom_tail.asm`, `OSCA_ROM_BIN=boot_rom_mcu.bin sch2v.py ...`) jumps to FLOS
  at $1010; FLOS is written into system RAM by the MCU ROM loader while the core is in reset.
- **Video RAM + sprite RAM on the single 10 ns SRAM through `kg_osca_mem.v` (v2)**:
  * FLOS banner frame (`frame_two_phase_wrapper.png`) is identical to the reference.
  * Sprite stress test (`spr_test.asm`: 48 sprites on the busiest lines, two definitions; `frame_sprites_real_wrapper.png`) is identical to
    the reference frame.
- PS/2 keyboard device from MCU scan codes (`kg_osca_ps2dev.v`, tested against OSCA's own receiver), audio, VGA mapping, board top
  level + UCF (lint only).

## How the memory problem was solved (all measured)
OSCA's video and sprite RAMs are two-phase buses: addresses change on both clk16 edges (display fetch on the rising edge; blitter, CPU,
line draw and the sprite engine on the FALLING edge), strobes are half-cycle pulses, data is captured on the rising edge. The core
tolerates only ~2-3 ticks (96 MHz) of read latency. The wrapper schedules three accesses per 16 MHz cycle (2 ticks each):
A tick 1 display read, B tick 3 sprite RAM, C tick 5 video write / second-phase read. Core changes (`patch_osca_top.py`):
- second-phase video data on its own bus `vram_rdata2`; the blitter data register captures half a cycle later (inverted clock,
  registered enable); CPU video reads use `vram_rdata2`;
- sprite data arrives one cycle later than with the original SRAM (its address changes on the falling edge, the wrapper reads it a half
  cycle too early); the whole write side of the sprite line buffer (address, write enable, line parity, two data-qualifier bits,
  14 flip-flops in `sprite_system513`) is delayed by one cycle to match.

## Audio DMA latency tolerance (measured)
`audio_test.asm` (4 channels looping 512 bytes at $6000; image `audio_ram_image.hex`, build with `-GIMG_BYTES=32911`), metric = checksum of the core's
1-bit audio output over 20..120 ms (`AUDHASH`); with real samples the output density varies per window, with zero samples (`audio_zero.asm`) it is a constant 50%.
`kg_sysram_model.v` delays the read data at run time: `+sysdy=N` for CPU cycles, `+dmady=N` for FPGA-owned (DMA) cycles, N in 96 MHz ticks (10.4 ns).
- **Audio DMA: correct up to 11 ticks (~115 ns), wrong from 12 ticks (125 ns).** A DMA read lasts two clk16 cycles.
- **CPU without WAIT_n: fails from 10 ticks (~104 ns)**, i.e. it tolerates 9 ticks (94 ns) (with the half-cycle output staging of `kg_osca_cpu.v`).
- The SDRAM (75 ns) fits both limits with 19-40 ns of margin, but a refresh that lands in front of an access adds several ticks: for the CPU `WAIT_n`
  covers it, the DMA cannot be stalled, so refreshes must be scheduled outside the DMA windows (once per scan line).
- NOT measured: the line copper (format of its list unknown), DMA of more than 4 channels' worst case, row-miss timing of a real controller.
- Correction: earlier notes claimed the half-cycle staging of the CPU outputs was needed for the sound registers; the identical audio checksum before and
  after the change shows the audio setup worked without it. The staging is kept (FLOS and sprites are still bit-identical) but its necessity is not proven.

## System RAM on the SDRAM (done in simulation)
`kg_osca_sdram.v` (96 MHz, based on the access sequence of NanoMig's `fastram_sdram.v`, clocks re-counted for 10.4 ns): ACTIVE / READ|WRITE with auto-precharge,
CAS 2, 7 clocks (73 ns) per access. Reads are speculative on every change of the word address, writes are captured once per strobe and executed when free (the read
word is kept coherent), refresh debt is paid when idle and never while the FPGA requests or owns the bus (audio / line copper DMA cannot be stalled); the CPU gets
`WAIT_n` while it reads a word that is not there yet (`sdram_wait_n` in `kg_osca_soc.v`). Pins/clock in `karabas_go_osca_top.v` (SDR_*, ODDR2 clock), UCF updated.
Results (`tb_kg_osca_sdram.v` against `tb_sdram_model.v`, which checks tRCD / tRC / tRFC / closed rows / refresh gap; `tb_boot.sv` on the whole SoC):
- 0 timing violations, 0 data mismatches (4443 unit-test reads); max gap between refreshes 9.4-17.8 us.
- FLOS frame and sprite frame on the SDRAM are bit-identical to the ideal-memory references.
- Audio DMA: 18393 DMA reads checked against the expected sample, 0 wrong; max read latency 9 ticks (limit 11).
- The CPU gets WAIT in 0.098% of the cycles.
- The MCU loader must not start before `init_done` (the top holds the MCU in reset until then; the testbench waits too).
Unverified: physical timing (the chip's data valid window at 96 MHz with a plain clock copy is ~0.5 ns of margin: a phase-shifted SDR_CLK is probably needed),
ISE build, worst cases with many simultaneous DMA channels.
`kg_sysram_model.v` (zero-latency stand-in with `+sysdy` / `+dmady` delays) is still there, selected with `-DKG_SYSRAM_MODEL`.

## Line copper (measured and fixed)
Format (from `FLOS_based_programs/Simple_examples/LineCop/linecop.asm`): 16-bit words `wr $0000 / wril $2000 / wrir $4000 / wrilir $6000 / sr $8000 / wl $c000`; list start in
$20F (bit 7 set, bits 18:16) / $20E / $20D (bit 0 = enable). `lc_only.asm` / `lc_audio.asm` (list of 417 words at $6400: 108 colour bands of palette entry 0, `lc_images/`; the second also runs
4 audio channels) give 50 distinct colour bands per frame.
- Tolerance (ideal-memory build, `+dmady=N`): the line copper works with a read delay of up to **6 ticks (62 ns)**, from 7 ticks the whole frame is wrong. A plain SDRAM read (7-8 ticks) was
  therefore too slow: the first read of each burst returned stale data (visible in the frame although the byte check at the end of the access was clean - a checker must sample where the consumer does).
- The line copper reads its list in the last 16 cycles of each scan line, high byte first, and its PC (`lsrw_pc`, exported as `linecop_pc_o`) is stable between the bursts.
  Fix: the SDRAM controller keeps two read-ahead words (the word of the PC and the next one, `hint_addr = linecop_pc_o`); both are already loaded when the copper asks (latency 0-1 tick),
  the next word is fetched in the background. `tb_kg_osca_sdram.v` HINT-STREAM: 600 sequential reads, 0 mismatches, 0 reads slower than 1 tick.
- On the whole SoC (SDRAM): line copper frame (with and without audio DMA) identical to the ideal-memory frame, 1626 list reads checked, 0 wrong; audio DMA 0 wrong; FLOS and sprite frames
  still identical; CPU WAIT in < 0.1% of the cycles.
- Caveat: the read-ahead is specific to the line copper (a sequential, predictable DMA); the 512 KB system RAM accesses of the CPU and the audio DMA are served without it.

## Other OSCA modes (measured, `modes/`)
Programs (`modes/src/*.asm`, images with their data tables in `modes/img/*/ram_image.hex`, `-GIMG_BYTES=49152`), register use taken from `FLOS_based_programs/Simple_examples` and `tests/Misc`:
`chunky_blit` (8 bit chunky bitmap 256x200, CPU-filled pages, three blits of a 32x28 object: opaque, with the transparency bit set, opaque), `planar4` (4 bitplanes, 320x200),
`tiles16` (extended tile mode, 16x16 tiles, single playfield, map at VRAM $70000), `linedraw` (8 lines in all octants, register protocol of `ext_line_draw.asm`, constants computed offline),
`sprites2` (24 sprites, heights 16-64, x flip, moving every frame), `cpu_vram` (CPU writes 512 bytes of video RAM, reads them back directly and with LDIR).
Reference = same core with ideal asynchronous memories (`ref_overrides/`: `kg_osca_mem.v` = `alt/kg_osca_mem_ideal2.v`, the original sprite pipeline `sprite_system513.v`, and `osca_core.v` with the
ORIGINAL blitter data capture and CPU video read path), `-DKG_SYSRAM_MODEL`. Real = SDRAM controller + two-phase SRAM wrapper + patched core.
- All five frames are bit-identical to the reference (non-black pixels: 101284 / 109942 / 168584 / 2460 / 25936, 0 differing pixels); `cpu_vram`: 0 read errors (direct and LDIR), identical frames.
- Two false alarms on the way, both in my test set-up, not in the design: (1) the first reference had the patched blitter capture with an ideal memory that changes data with the address, so its
  blit never copied the object (the real system drew the object exactly as the table says) - the reference core must keep the original capture; (2) my read test used DE as an error counter and LDIR overwrote it.
- Not covered: 640x256 and interlaced modes, 8x8 tiles, dual playfield, hardware scrolling (xhws / yhws / modulo), more than 4 bitplanes, blitter descending mode / modulo bits / the real meaning
  of the transparency bit (0xC0 was a guess: the blit is deterministic either way), sprite priority / matte modes, line draw with window widths other than 256, simultaneous blit + line draw + DMA.

## Not done / open
- Physical SDRAM timing and the ISE build are unverified (see above).
- **CPU reads of the video RAM** come from `vram_rdata2` (valid at tick 8): probably need one extra wait cycle - untested.
- Verified: FLOS text (bitmap plane + blitter), sprites (static). Not verified: tile mode, line draw, other bitmap modes, sprite flipping /
  heights / priorities, moving sprites, audio DMA, line copper.
- Hardware timing (pad delays ~10 ns for out+in at 96 MHz) unverified; OFFSET constraints in the .ucf are placeholders.
- Joystick serial protocol, PS/2 mouse, RTC, second SD not done.

## Running the tests (Verilator, flags `-DKG_CPU_TV80 -DTV80_REFRESH`; real boards use T80s, `t80/*.vhd`)
- FLOS boot: `tb_boot.sv` + `ram_image.hex` (FLOS at $1000); screenshots go to frame_*.ppm.
- Sprite test: copy `spr_ram_image.hex` to `ram_image.hex`, build with `-GIMG_BYTES=32888 -GSIM_MS=300`.
- Ideal-memory reference: `alt/kg_osca_mem_ideal2.v` instead of `kg_osca_mem.v` (with `-DIDEAL_MEM`). Note: the reference must use the
  UNPATCHED sprite pipeline (it returns data in the same cycle); `alt/` also holds older variants and old tests.
