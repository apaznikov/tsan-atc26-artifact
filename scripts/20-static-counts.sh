#!/usr/bin/env bash
# Static instrumentation sites per application and configuration (deterministic, machine-independent).
# Usage: scripts/20-static-counts.sh [build-root]     default: the binaries 40-perf.sh built under results/
# Counts __tsan_* call sites in each application binary with data/tools/static_count_tsan_instrumentation.py
# and writes results/static-counts-<stamp>.csv in the same layout as data/perf/*/static-counts.csv.
set -euo pipefail
. "$(dirname "$0")/_lib.sh"
case "${1:-}" in -*) echo "$(basename "$0") takes an optional build root, not a flag (got: $1)"; exit 2 ;; esac
[ $# -le 1 ] || { echo "$(basename "$0") takes at most one argument, a build root (got $#)"; exit 2; }
root="${1:-$ART_BUILD}"
[ -d "$root" ] || { echo "no build root at $root; run scripts/40-perf.sh --build-only first"; exit 2; }
out="$ART_RESULTS/static-counts-$(stamp).csv"; mkdir -p "$ART_RESULTS"
budget "static counts" "5 min" "2 min" "none"
echo "app,config,binary,sites,tsan_calls" > "$out"
find "$root" -type f -perm -u+x -name '*' | while read -r bin; do
  file "$bin" | grep -q ELF || continue
  app="$(basename "$(dirname "$(dirname "$bin")")")"; cfg="$(basename "$(dirname "$bin")")"
  n=$(python3 "$ART_DATA/tools/static_count_tsan_instrumentation.py" "$bin" --csv 2>/dev/null | tail -1 || echo "")
  [ -n "$n" ] && echo "$app,$cfg,$(basename "$bin"),$n" >> "$out"
done
echo "-> $out"; echo "Compare with data/perf/stageB-d3bf9f8c39fe/static-counts.csv (same compiler => identical sites)."
