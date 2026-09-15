#!/usr/bin/env bash
# The two synthetic bounded-shadow experiments: (a) one fully occupied granule, a planted race, a burst of
# elidable accesses before the evicting access; (b) two races on one granule exercising both DE effects.
# 1000 runs per build and burst type (ART_SMOKE=1: 20). Usage: scripts/50-eviction-stress.sh [--de]
set -euo pipefail
. "$(dirname "$0")/_lib.sh"
need_harness tools/eviction-stress; need_compiler
runs=1000; [ "$ART_SMOKE" = 1 ] && runs=20
budget "eviction stress, $runs runs per cell" "1 h" "15 min" "100 MB"
smoke_banner
out="$ART_RESULTS/eviction-stress-$(stamp)"; mkdir -p "$out/bin"
cd "$harness/tools/eviction-stress"
LLVM_TSAN_ROOT="$TSAN_LLVM_ROOT" ./build.sh "$out/bin"
JOBS="${ART_JOBS}" ./run.sh "$out/bin" "$runs"
echo "-> $out (report.md per experiment); compare with data/eviction-stress/"
