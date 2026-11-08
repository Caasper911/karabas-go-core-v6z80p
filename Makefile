# Simulation (see scripts/sim.sh) and the ISE flow (ise/Makefile)
.PHONY: build ref unit regress regress-quick ise clean
build:          ; scripts/sim.sh build real
ref:            ; scripts/sim.sh build ref
unit:           ; scripts/sim.sh unit
regress:        ; scripts/sim.sh regress
regress-quick:  ; scripts/sim.sh regress --only planar4,tiles16,linedraw,sprites2,cpu_vram
ise:            ; $(MAKE) -C ise
clean:          ; rm -rf build
