#!/usr/bin/env bash
# Simulation driver (Verilator for the whole SoC, iverilog for the SDRAM controller unit test).
#   (all in src/sim: the testbench, the simulation models, tv80, the reference overrides, golden frames, roms/*.hex, build/;
#    the design itself is the tree src/rtl)
#   scripts/sim.sh build [real|ref]          build build/<cfg>/Vtb_boot   (real = the design, ref = ideal memories + original blitter / sprite pipeline)
#   scripts/sim.sh run <cfg> <image.hex> <outdir> [ms]   run one image (frames and run.log go to <outdir>)
#   scripts/sim.sh regress [--cfg real] [--only a,b]     run the regression and compare with golden/*.png (scripts/regress.py)
#   scripts/sim.sh unit                       SDRAM controller against the timing-checking SDRAM model (iverilog)
# Environment: BUILD (default src/sim/build), IMG_BYTES (default 65536), SIM_MS (default 1000, build-time default; +simms=N overrides at run time),
#   KG_CPU (t80pa = the T80pa bus model, default; tv80 = tv80s), KG_EXTRA_DEFS (more Verilog defines).
set -euo pipefail
SIM="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"     # src/sim
SRC="$(cd "$SIM/.." && pwd)"                                  # src: the design
BUILD="${BUILD:-$SIM/build}"
IMG_BYTES="${IMG_BYTES:-65536}"
SIM_MS="${SIM_MS:-1000}"
JOBS="${JOBS:-$(nproc)}"
# CPU model: the T80pa bus model (kg_tv80pa.v, the phases of the board's T80pa) by default; KG_CPU=tv80 builds the old tv80s configuration
if [ "${KG_CPU:-t80pa}" = tv80 ]; then CPU_DEFS="-DKG_CPU_TV80"; else CPU_DEFS="-DKG_CPU_T80PA -DKG_CPU_TV80PA"; fi
VFLAGS=(--binary --timing -Wno-fatal -Wno-lint -Wno-style -Wno-WIDTH -Wno-MULTIDRIVEN -Wno-UNOPTFLAT
        $CPU_DEFS -DTV80_REFRESH ${KG_EXTRA_DEFS:-} --top-module tb_boot -O1 -j "$JOBS" -GSIM_MS="$SIM_MS" -GIMG_BYTES="$IMG_BYTES")

design_files() {   # the design (the rtl tree given as $1, all subfolders) and the simulation models (src/sim), full paths
  find "$1" -name '*.v' | grep -vE '/(osca_pal\.v|karabas_go_osca_top\.v)$' | sort
  ( cd "$SIM" && ls *.v | grep -v '^tb_' | sed "s|^|$SIM/|" ); ls "$SIM"/tv80/*.v; echo "$SIM/tb_sdram_model.v"
}

build() {
  local cfg="${1:-real}" src="$SRC/rtl" extra=()
  if [ "$cfg" = ref ]; then
    src="$BUILD/ref-src"; rm -rf "$src"; mkdir -p "$src"
    cp -r "$SRC"/rtl/. "$src"/
    # kg_osca_mem (ideal), sprite_system513 (original), osca_core (original blitter capture): each replaces the file of the same name in the tree
    for o in "$SIM"/ref_overrides/*.v; do
      t=$(find "$src" -name "$(basename "$o")"); [ -n "$t" ] || { echo "ref override $(basename "$o"): no such file in rtl"; exit 1; }
      cp "$o" "$t"
    done
    extra=(-DKG_SYSRAM_MODEL)
  fi
  rm -rf "$BUILD/$cfg"; mkdir -p "$BUILD"
  ( cd "$SIM" && verilator "${VFLAGS[@]}" "${extra[@]}" --Mdir "$BUILD/$cfg" "$SIM/tb_boot.sv" $(design_files "$src") ) > "$BUILD/$cfg.build.log" 2>&1 \
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
  regress) shift; exec python3 "$SIM/scripts/regress.py" --root "$SIM" --build "$BUILD" "$@" ;;
  unit)    mkdir -p "$BUILD"
           ( cd "$SIM" && iverilog -g2005 -o "$BUILD/sd.vvp" tb_kg_osca_sdram.v "$SRC/rtl/memory/kg_osca_sdram.v" tb_sdram_model.v && vvp "$BUILD/sd.vvp" ) \
             | grep -vE "TBW|CMD t|MODEL WRITE|OP t|ring:" ;;
  *)       sed -n 2,9p "$0"; exit 1 ;;
esac
