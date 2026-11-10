# Simulation (see sim/scripts/sim.sh) and the ISE flow (ise/Makefile)
.PHONY: build ref unit regress regress-quick ise clean
build:          ; sim/scripts/sim.sh build real
ref:            ; sim/scripts/sim.sh build ref
unit:           ; sim/scripts/sim.sh unit
regress:        ; sim/scripts/sim.sh regress
regress-quick:  ; sim/scripts/sim.sh regress --only planar4,tiles16,linedraw,sprites2,cpu_vram
ise:            ; $(MAKE) -C ise
clean:          ; rm -rf sim/build
