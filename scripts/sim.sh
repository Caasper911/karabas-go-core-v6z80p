#!/usr/bin/env bash
# Simulation driver (Verilator for the whole SoC, iverilog for the SDRAM controller unit test).
#   scripts/sim.sh build [real|ref]          build build/<cfg>/Vtb_boot   (real = the design, ref = ideal memories + original blitter / sprite pipeline)
#   scripts/sim.sh run <cfg> <image.hex> <outdir> [ms]   run one image (frames and run.log go to <outdir>)
#   scripts/sim.sh regress [--cfg real] [--only a,b]     run the regression and compare with golden/*.png (scripts/regress.py)
#   scripts/sim.sh unit                       SDRAM controller against the timing-checking SDRAM model (iverilog)
# Environment: BUILD (default <repo>/build), IMG_BYTES (default 49152), SIM_MS (default 1000, build-time default; +simms=N overrides at run time).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="${BUILD:-$ROOT/build}"
IMG_BYTES="${IMG_BYTES:-49152}"
SIM_MS="${SIM_MS:-1000}"
JOBS="${JOBS:-$(nproc)}"
VFLAGS=(--binary --timing -Wno-fatal -Wno-lint -Wno-style -Wno-WIDTH -Wno-MULTIDRIVEN -Wno-UNOPTFLAT
        -DKG_CPU_TV80 -DTV80_REFRESH ${KG_EXTRA_DEFS:-} --top-module tb_boot -O1 -j "$JOBS" -GSIM_MS="$SIM_MS" -GIMG_BYTES="$IMG_BYTES")

design_files() {   # the design and the testbench models, relative to the directory given as $1
  ( cd "$1" && ls *.v | grep -vE '^(osca_pal\.v|karabas_go_osca_top\.v)$|^tb_' ; ls tv80/*.v; echo tb_sdram_model.v )
}

build() {
  local cfg="${1:-real}" src="$ROOT" extra=()
  if [ "$cfg" = ref ]; then
    src="$BUILD/ref-src"; rm -rf "$src"; mkdir -p "$src"
    cp "$ROOT"/*.v "$ROOT"/tb_boot.sv "$src"/; cp -r "$ROOT/tv80" "$src"/
    cp "$ROOT"/ref_overrides/*.v "$src"/            # kg_osca_mem (ideal), sprite_system513 (original), osca_core (original blitter capture)
    extra=(-DKG_SYSRAM_MODEL)
  fi
  rm -rf "$BUILD/$cfg"; mkdir -p "$BUILD"
  ( cd "$src" && verilator "${VFLAGS[@]}" "${extra[@]}" --Mdir "$BUILD/$cfg" tb_boot.sv $(design_files "$src") ) > "$BUILD/$cfg.build.log" 2>&1 \
    || { tail -20 "$BUILD/$cfg.build.log"; echo "build failed, see $BUILD/$cfg.build.log"; exit 1; }
  echo "built $BUILD/$cfg/Vtb_boot"
}

run() {
  local cfg="$1" img="$2" out="$3" ms="${4:-}"
  mkdir -p "$out"; rm -f "$out"/frame_*.ppm
  cp "$img" "$out/ram_image.hex"
  ( cd "$out" && "$BUILD/$cfg/Vtb_boot" ${ms:+"+simms=$ms"} > run.log 2>&1 )
}

case "${1:-}" in
  build)   build "${2:-real}" ;;
  run)     shift; run "$@" ;;
  regress) shift; exec python3 "$ROOT/scripts/regress.py" --root "$ROOT" --build "$BUILD" "$@" ;;
  unit)    mkdir -p "$BUILD"
           ( cd "$ROOT" && iverilog -g2005 -o "$BUILD/sd.vvp" tb_kg_osca_sdram.v kg_osca_sdram.v tb_sdram_model.v && vvp "$BUILD/sd.vvp" ) \
             | grep -vE "TBW|CMD t|MODEL WRITE|OP t|ring:" ;;
  *)       sed -n 2,9p "$0"; exit 1 ;;
esac
