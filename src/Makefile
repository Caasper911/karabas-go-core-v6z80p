# Command line build of the OSCA (V6Z80P+) core for Karabas Go and Mini with ISE 14.7, the way the cores of Andy Karpov are built
# (karabas-go-core-tsconf/src/Makefile): sources -> karabas_<board>.bin -> v6z80p.kg (make_core.py of karabas-go-tools).
# Mini G: not yet.
#
#   make                 all the boards (v6z80p.kg)
#   make go|mini         one board: synthesis, implementation, bitstream, its part of v6z80p.kg
#   make mini-xst        one step: <board>-xst (.ngc), <board>-impl (.bin), <board>-core (.kg)
#   make mini-report     LUTs, slices, block RAMs and the timing result of the last build
#   make clean           the intermediate files of ISE (not the .bin / .kg)
#   make tests           the core files of the Z80 test programs: tests/out/<name>.kg (scripts/make_test_cores.py)
#
#   make unit            simulation: the SDRAM controller against the timing-checking SDRAM model (iverilog)
#   make sim-build       simulation: sim/build/real/Vtb_boot (Verilator); sim-ref: the reference build (ideal memories)
#   make regress         simulation: the regression, frames compared with sim/golden; regress-quick: the modes only
#   make sim-clean       the simulation builds
#
# Inputs per board: karabas_<board>.prj (the source list: "rtl/...", the shared modules "../modules/rtl/..."), .xst, .ucf, .ut, core.json, roms/.
# A step runs again when one of its inputs is newer than its output.
#
# Windows: run make from the MSYS2 shell (make, bash and python3 of MSYS2); ISE is called with the environment its
# settings64.bat would set (XILINX, PATH).  Linux: settings64.sh is sourced, as in the tsconf Makefile.
# map sometimes stops silently in "Global Placement" (no .ncd): run make again.

PART = xc6slx25-ftg256-2
BOARDS = go mini

SHELL = /bin/bash
.SHELLFLAGS = -e -o pipefail -c
.NOTPARALLEL:

ifeq ($(OS),Windows_NT)
ISE_DIR ?= C:/Xilinx/14.7/ISE_DS
ISE_DIR_U := /$(subst :,,$(ISE_DIR))
XIL = export XILINX="$(ISE_DIR)/ISE" XILINX_DSP="$(ISE_DIR)/ISE" \
	PATH="$(ISE_DIR_U)/ISE/bin/nt64:$(ISE_DIR_U)/ISE/lib/nt64:$(ISE_DIR_U)/common/bin/nt64:$(ISE_DIR_U)/common/lib/nt64:$$PATH";
else
ISE_SETTINGS ?= /opt/Xilinx/14.7/ISE_DS/settings64.sh
# settings64.sh takes the arguments of the shell that sources it: none here
XIL = source $(ISE_SETTINGS) > /dev/null;
endif

# make_core.py of https://github.com/andykarpov/karabas-go-tools (cloned next to this repo)
MAKE_CORE ?= ../../karabas-go-tools/make_core/make_core.py
PYTHON ?= python3
# the assembler of the test programs (make tests)
ifeq ($(OS),Windows_NT)
SJASM ?= C:/hobby/tools/sjasmplus/sjasmplus.exe
else
SJASM ?= sjasmplus
endif

KG = v6z80p.kg
JSON = core.json
# the "build" of core.json is set to the date and hour of the build (YYMMDDHH) when the core file is made
BUILD_DATE := $(shell date +%y%m%d%H)

# map / par options: the cost table (map -t, the placement seed) 2 meets all the constraints (the one-tick paths into the
# SRAM / SDRAM IOB registers are close: see docs/OPEN_TASKS.md)
MAP_T_go = 3
MAP_T_mini = 2
MAP_OPT = -logic_opt on -ol high -xe n -register_duplication on -r 4 -global_opt off -mt 2 -detail -ir off -pr b -lc off -power off
PAR_OPT = -ol high -xe n -mt 4

# read by the sources, not in the prj
INCLUDES = $(wildcard ../modules/rtl/mcu/*.vh)

.PHONY: all clean $(BOARDS) $(BOARDS:=-xst) $(BOARDS:=-impl) $(BOARDS:=-core) $(BOARDS:=-report) \
	unit sim-build sim-ref regress regress-quick sim-clean sd-unit

all: $(BOARDS)

define board
SRC_$(1) := $$(shell sed -n 's/^[a-z]* work "\(.*\)"/\1/p' karabas_$(1).prj)

karabas_$(1).ngc: karabas_$(1).prj karabas_$(1).xst $$(SRC_$(1)) $(INCLUDES)
	mkdir -p xst/projnav.tmp
	$(XIL) xst -intstyle ise -ifn karabas_$(1).xst -ofn karabas_$(1).syr

karabas_$(1).bin: karabas_$(1).ngc karabas_$(1).ucf karabas_$(1).ut
	$(XIL) ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc karabas_$(1).ucf -p $(PART) karabas_$(1).ngc karabas_$(1).ngd
	rm -f karabas_$(1)_map.ncd
	$(XIL) map -intstyle ise -p $(PART) -w $(MAP_OPT) -t $(MAP_T_$(1)) -o karabas_$(1)_map.ncd karabas_$(1).ngd karabas_$(1).pcf
	@test -f karabas_$(1)_map.ncd || { echo "map stopped without karabas_$(1)_map.ncd (it does that in Global Placement now and then): run make again"; exit 1; }
	$(XIL) par -w -intstyle ise $(PAR_OPT) karabas_$(1)_map.ncd karabas_$(1).ncd karabas_$(1).pcf
	$(XIL) trce -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml karabas_$(1).twx karabas_$(1).ncd -o karabas_$(1).twr karabas_$(1).pcf -ucf karabas_$(1).ucf
	$(XIL) bitgen -intstyle ise -f karabas_$(1).ut karabas_$(1).ncd
	@grep -q "All constraints were met" karabas_$(1).par || echo "*** karabas_$(1): TIMING NOT MET (see karabas_$(1).twr)"

kg_$(1).stamp: karabas_$(1).bin $(JSON) $$(wildcard roms/*)
	sed -i -E 's/("build": *")[0-9]+"/\1$(BUILD_DATE)"/' $(JSON)
	$(PYTHON) $(MAKE_CORE) $(JSON) $(KG) --boards $(1)
	touch $$@

$(1): kg_$(1).stamp
$(1)-xst: karabas_$(1).ngc
$(1)-impl: karabas_$(1).bin
$(1)-core: kg_$(1).stamp
$(1)-report:
	@grep -E "Number of (Slice LUTs|occupied Slices|RAMB16BWERs|RAMB8BWERs):" karabas_$(1)_map.mrp
	@grep -E "constraints? (was|were) met|constraints? not met|Timing Score" karabas_$(1).par | sort -u
endef

$(foreach b,$(BOARDS),$(eval $(call board,$(b))))

clean:
	rm -f kg_*.stamp
	rm -rf xst _ngo _xmsgs xlnx_auto_0_xdb iseconfig
	rm -f karabas_*_osca_top.lso
	rm -f $(foreach b,$(BOARDS),$(addprefix karabas_$(b),.ngc .ngd .ngr .syr .lso .bld .pcf .ncd _map.ncd _map.ngm \
		_map.map _map.mrp _map.xrpt .par .pad _pad.csv _pad.txt .twr .twx .unroutes .xpi .ptwx .bgn .bit .drc \
		_bitgen.xwbt _summary.xml _usage.xml _xst.xrpt _ngdbuild.xrpt _par.xrpt _guide.ncd))

# ---- the core files of the test programs (the bitstream of the last build, each test image as the ROM)
.PHONY: tests
tests: karabas_go.bin
	$(PYTHON) scripts/make_test_cores.py --make-core $(MAKE_CORE) --sjasm $(SJASM) --python $(PYTHON)

# ---- simulation (sim/scripts/sim.sh; see CLAUDE.md)
unit:          ; sim/scripts/sim.sh unit
sim-build:     ; sim/scripts/sim.sh build real
sim-ref:       ; sim/scripts/sim.sh build ref
regress:       ; sim/scripts/sim.sh regress
regress-quick: ; sim/scripts/sim.sh regress --only planar4,tiles16,linedraw,sprites2,cpu_vram
sim-clean:     ; rm -rf sim/build
# the emulated SD card (kg_sd_emu) against an SPI master like OSCA's and the command sequence of the FLOS driver
sd-unit:
	mkdir -p sim/build
	iverilog -g2012 -o sim/build/sdemu.vvp sim/tb_kg_sd_emu.v rtl/io/kg_sd_emu.v ../modules/rtl/mem/kg_tdpram.v
	vvp sim/build/sdemu.vvp | grep -E "MISMATCH|SD EMU|TIMEOUT"
