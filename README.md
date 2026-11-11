# OSCA (V6Z80P+) for Karabas Go, Mini and Mini G

A port of **OSCA**, the FPGA architecture of Phil Ruston's [V6Z80P+](https://github.com/minexew/v6z80p) Z80 computer
(V6Z80P+ v1.1, OSCA 676), to the Spartan-6 boards of the Karabas Go family. The core boots **FLOS 6.14**, the
disk operating system of the V6Z80P, and runs its programs, demos and tests.

One core file, `src/v6z80p.kg`, holds the bitstreams for all three boards:

| Board | Video | Audio |
|---|---|---|
| Karabas Go | VGA | PCM5102 DAC |
| Karabas Mini | HDMI (DVI on request of the MCU) | HDMI + sigma-delta line out |
| Karabas Mini G | HDMI (DVI on request of the MCU) | HDMI + PCM5102 DAC |

Status: work in progress, but in daily use on all three boards (see [What works](#what-works)).

## What the core contains
- **Z80 at 16 MHz**: T80pa (the T80 soft core with the bus phases of a real Z80), with the bus arbiter of OSCA (CPU / DMA).
- **OSCA video**: bitmap modes (chunky and planar), tile modes, hardware sprites, blitter, line draw, the line copper,
  palette; OSCA's VGA timing (60 or 50 Hz).
- **OSCA sound**: four DMA channels from system RAM.
- **Memory**: the 512 KB of system RAM in the SDRAM (96 MHz controller with read-ahead for the line copper and `WAIT` for the CPU);
  video RAM and sprite RAM share the 10 ns SRAM (three accesses per 16 MHz cycle).
- **Keyboard**: a PS/2 keyboard device fed with the scan codes of the board's MCU.
- **SD card**: the board's SD card, or a **virtual SD card** on a disk image chosen in the OSD (sector cache, fast MCU transfers).
- **OSD** of the board's MCU: reset, SD card / image selection.

The logic of OSCA itself is not rewritten: it is converted from the original ISE schematics to Verilog by scripts in this
repository (`src/scripts/sch2v/`), with a small set of documented patches for the shared memories.

## Using it
1. Copy `src/v6z80p.kg` to the SD card of the board, next to the other cores, and choose **V6Z80 OSCA** in the core menu.
2. FLOS 6.14 is in the core and starts at once. For files, use an SD card formatted FAT16 (as on the V6Z80P),
   or a disk image (`.img`, `.vhd`, `.hdf`) in the OSD.
3. A ready SD card image with the V6Z80P programs (collected from [minexew/v6z80p](https://github.com/minexew/v6z80p)) is attached to the
   [releases](https://github.com/Caasper911/karabas-go-core-v6z80p/releases/latest) (`osca_sd.zip`, 2 GB `osca_sd.img` inside):
   write it to an SD card, or put the `.img` on the board's SD card and select it in the OSD (SD card: Image, SD image).
   The release also has `v6z80p.kg`.

OSD:

| Item | Key | |
|---|---|---|
| Reset | F12 | resets the core (the board's reset button does the same) |
| SD card: Card / Image | Menu+S | the physical SD card, or the image below |
| SD image | Menu+F5 | the disk image of the virtual SD card |

Programs for the V6Z80P are in the [v6z80p repository](https://github.com/minexew/v6z80p)
(`FLOS_based_programs/`, demos, tests).

## What works
Checked on the hardware (Go, Mini, Mini G):
- FLOS 6.14, the keyboard, the OSD and the reset;
- the SD card and the virtual SD card on an image;
- video and sound of FLOS programs, the *parity* demo (line copper), MOD playback, the interrupt test.

Checked in simulation against the same core with ideal memories (frames bit-identical): chunky bitmap with the blitter,
4 bitplanes, 16x16 tiles, line draw, sprites with flipping and heights, CPU reads of video RAM, sound DMA, the line copper.

Not done: joysticks, PS/2 mouse, RTC, the second SD card, the config PIC / EEPROM of the V6Z80P
(the core boots from a replacement boot ROM). Not tested: 640x256 and interlaced modes, 8x8 tiles, dual playfield,
hardware scrolling. Open items: [`src/docs/OPEN_TASKS.md`](src/docs/OPEN_TASKS.md).

## Building
Needed: Xilinx ISE 14.7, a `make` / `bash` / `python3` environment (MSYS2 on Windows), and:
- [karabas-go-modules](https://github.com/andykarpov/karabas-go-modules): a git submodule in `modules/`. Clone with
  `git clone --recursive`, or run `git submodule update --init` in an existing clone;
- [karabas-go-tools](https://github.com/andykarpov/karabas-go-tools) cloned next to this repository (for `make_core.py`).

From `src/`:
```
make                 # all boards: karabas_go.bin, karabas_mini.bin, karabas_minig.bin -> v6z80p.kg
make go|mini|minig   # one board
make <board>-report  # resources and the timing result of the last build
make clean           # intermediate files of ISE
```
The build follows the Makefiles of Andy Karpov's cores (karabas-go-core-tsconf). If `map` stops in "Global Placement" without an
output file, run `make` again.

### Simulation
Verilator and Icarus Verilog testbenches are in `src/sim/` (`make regress`, `make unit`, `make sd-unit`): the whole system boots FLOS
and the test programs of `src/tests/`, and the frames are compared with a reference build that has ideal memories.
Design notes and measurements: [`src/docs/SIMULATION.md`](src/docs/SIMULATION.md), [`src/docs/MEASUREMENTS.md`](src/docs/MEASUREMENTS.md),
[`src/docs/SDRAM_TIMING.md`](src/docs/SDRAM_TIMING.md).

## Repository layout
```
src/
  rtl/                 karabas_{go,mini,minig}_osca_top.v (one per board: pins, video and audio outputs)
    soc/               kg_osca_system.v (shared: PLL, MCU link, reset, OSD, virtual SD), the OSCA core from the schematics
    cpu/ memory/ video/ sound/ io/ debug/ prims/
  karabas_<board>.prj/.xst/.ucf/.ut, core.json, Makefile
  roms/                FLOS, the replacement boot ROM (rom_tail.asm)
  tests/               Z80 test programs
  scripts/             schematic to Verilog conversion, test core packing
  sim/                 testbenches, memory models, reference frames
  docs/
modules/               karabas-go-modules (git submodule)
```

## Credits
- OSCA, FLOS and the V6Z80P: Phil Ruston; sources from [minexew/v6z80p](https://github.com/minexew/v6z80p).
- Karabas Go boards, MCU firmware, shared modules and the build scripts this port follows: Andy Karpov
  ([karabas-go-modules](https://github.com/andykarpov/karabas-go-modules), karabas-go-core-* repositories).
- T80 Z80 core: Daniel Wallner and contributors. HDMI transmitter (zhdmi) from karabas-go-modules.
- The SDRAM controller is based on `fastram_sdram.v` of karabas-go-core-nanomig; the SD card logic of the virtual SD on
  `nextor_sd.v` of karabas-go-core-msx.
