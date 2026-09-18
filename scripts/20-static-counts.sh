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
failed=0
out="$ART_RESULTS/static-counts-$(stamp).csv"; mkdir -p "$ART_RESULTS"
budget "static counts" "5 min" "2 min" "none"
echo "app,config,binary,sites,tsan_calls" > "$out"
find "$root" -type f -perm -u+x -name '*' | while read -r bin; do
  file "$bin" | grep -q ELF || continue
  app="$(basename "$(dirname "$(dirname "$bin")")")"; cfg="$(basename "$(dirname "$bin")")"
  # The counter has no --csv option and never had one: asking for it made argparse exit 2 with nothing on
  # stdout, the substitution yielded "", the row was skipped, and this script wrote a header and no data on
  # every run while reporting success (found 19 Sep 2026). Parse its actual output, as the harness does.
  read -r sites total <<< "$(python3 "$ART_DATA/tools/static_count_tsan_instrumentation.py" "$bin" 2>/dev/null \
      | awk '/Memory accesses/ {s=$NF} /GRAND TOTAL/ {t=$NF} END {print (s==""?"":s), (t==""?"":t)}')"
  if [ -n "$sites" ] && [ -n "$total" ]; then
    echo "$app,$cfg,$(basename "$bin"),$sites,$total" >> "$out"
  else
    echo "  counting failed for $bin (no site total in the counter's output)" >&2; failed=$((failed+1))
  fi
done
rows=$(( $(wc -l < "$out") - 1 ))
echo "-> $out ($rows binaries counted${failed:+, $failed failed})"
[ "$rows" -gt 0 ] || { echo "no binary could be counted: the table is empty, which is not a result" >&2; exit 1; }
echo "Compare with data/perf/campaign-f3deebfbab60/*/static-counts.csv (same compiler => identical sites)."
