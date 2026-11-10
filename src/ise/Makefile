# ISE 14.7 command line flow for karabas_go_osca_top (xc6slx25-ftg256-2).  NOT RUN YET: written from the flow of the NanoMig / Next cores
# (../../modules is a clone of karabas-go-modules, see ../../CLAUDE.md).
#   make                 xst, ngdbuild, map, par, trce, bitgen   -> work/osca676p.bit (.bin)
#   make xst | impl      synthesis only | up to par + trce
#   make report          resources and the timing result of the last build
#   make UCF_EXTRA=sdram_offsets_wip.ucf    adds the SDRAM interface constraints (branch wip/sdram-iob-timing)
#   make clean
ISE_SETTINGS ?= /opt/Xilinx/14.7/ISE_DS/settings64.sh
PART    = xc6slx25-ftg256-2
TOP     = osca676p
UCF_EXTRA ?=
MAP_OPT = -logic_opt off -ol high -xe n -xt 0 -register_duplication off -r 4 -global_opt off -mt 2 -detail -ir off -pr b -lc off -power off
PAR_OPT = -ol high -xe n -mt 4
MAP_T  ?= 2
SHELL = /bin/bash
.SHELLFLAGS = -e -o pipefail -c
XIL = set --; source $(ISE_SETTINGS) > /dev/null;
SRC = $(shell sed -n 's/^[a-z]* work "\(.*\)"/\1/p' $(TOP).prj)

.PHONY: all xst impl report clean
all: work/$(TOP).bin
xst: work/$(TOP).ngc
impl: work/$(TOP).twr

work/$(TOP).ngc: $(TOP).prj $(TOP).xst $(SRC)
	mkdir -p work/xst/projnav.tmp
	$(XIL) xst -intstyle ise -ifn $(TOP).xst -ofn work/$(TOP).syr
work/$(TOP).ucf: ../karabas_go_osca_top.ucf $(UCF_EXTRA)
	cat ../karabas_go_osca_top.ucf $(UCF_EXTRA) > $@
work/$(TOP).ngd: work/$(TOP).ngc work/$(TOP).ucf
	cd work && $(XIL) ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc $(TOP).ucf -p $(PART) $(TOP).ngc $(TOP).ngd
work/$(TOP).twr: work/$(TOP).ngd
	cd work && $(XIL) map -intstyle ise -p $(PART) -w $(MAP_OPT) -t $(MAP_T) -o $(TOP)_map.ncd $(TOP).ngd $(TOP).pcf
	cd work && $(XIL) par -w -intstyle ise $(PAR_OPT) $(TOP)_map.ncd $(TOP).ncd $(TOP).pcf
	cd work && $(XIL) trce -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml $(TOP).twx $(TOP).ncd -o $(TOP).twr $(TOP).pcf -ucf $(TOP).ucf
work/$(TOP).bin: work/$(TOP).twr $(TOP).ut
	cd work && $(XIL) bitgen -intstyle ise -f ../$(TOP).ut $(TOP).ncd
report:
	@grep -E "Number of (Slice LUTs|occupied Slices|RAMB16BWERs|RAMB8BWERs):" work/$(TOP)_map.mrp
	@grep -E "constraints? (was|were) met|constraints? not met|Timing Score" work/$(TOP).par | sort -u
	@echo "SDR_CLK / SDRAM pins (clock to pad, setup / hold of the inputs):"; grep -nE "SDR_(CLK|DQ|A|BA|DQM|RAS_N|CAS_N|WE_N)" work/$(TOP).twr | head -40
clean:
	rm -rf work
