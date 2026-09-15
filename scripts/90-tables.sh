#!/usr/bin/env bash
# Regenerates every table from recorded runs: the per-application performance tables (aggregate.py),
# the results ledger (results_ledger.py), and the preservation and eviction tables. Works on the
# data we shipped (default) or on a results tree you produced with 40-perf.sh.
#
#   scripts/90-tables.sh                     # from data/perf/stageB-d3bf9f8c39fe and the ledger trees
#   scripts/90-tables.sh results/perf-XXXX   # from your own run
#
# Nothing is written into data/: the trees are copied to results/tables/<name>/ and regenerated there,
# so the shipped files stay as evidence of what we saw and your regeneration can be diffed against them.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../env.sh
. "$here/env.sh"
for a in "$@"; do
  case "$a" in
    -*) echo "$(basename "$0") takes results trees, not flags (got: $a). With no argument it regenerates from the shipped data."; exit 2 ;;
    *) [ -d "$a" ] || { echo "not a results tree: $a"; exit 2; } ;;
  esac
done
tools="$ART_DATA/tools/perf"
out="$ART_RESULTS/tables"; mkdir -p "$out"

regen_perf() { # regen_perf <results tree>
  local tree="$1" name; name="$(basename "$tree")"
  local copy="$out/$name"; rm -rf "$copy"; cp -r "$tree" "$copy"
  rm -f "$copy"/perf_*.md "$copy"/perf_*.csv "$copy"/perf_*.json
  python3 "$tools/aggregate.py" "$copy" >"$copy/aggregate.log" 2>&1 || { tail -5 "$copy/aggregate.log"; return 1; }
  echo "  $name: $(grep -cE '^[a-z]+: [0-9]+ configs' "$copy/aggregate.log") applications -> $copy/perf_summary.md"
  if ls "$tree"/perf_*.json >/dev/null 2>&1; then
    local same=1
    for f in "$tree"/perf_*.json; do cmp -s "$f" "$copy/$(basename "$f")" || same=0; done
    [ "$same" = 1 ] && echo "    identical to the shipped tables" || echo "    DIFFERS from the shipped tables (see $copy)"
  fi
}

if [ $# -eq 0 ]; then
  echo "Regenerating the performance tables from the shipped runs:"
  regen_perf "$ART_DATA/perf/stageB-d3bf9f8c39fe"
  regen_perf "$ART_DATA/perf/redis-stageB-repeat-2026-09-14"
  echo
  echo "Regenerating the results ledger (what each configuration is worth):"
  python3 "$tools/results_ledger.py" --print >"$out/results-ledger-tables.md"
  echo "  $out/results-ledger-tables.md ($(wc -l <"$out/results-ledger-tables.md") lines)"
  echo
  echo "Preservation tables (race reports per configuration): shipped as data/preservation/*/preservation_<app>.md;"
  echo "regenerate one with: python3 $ART_DATA/tools/preservation/tsan_reports.py <tree>  (see its --help)"
else
  for t in "$@"; do regen_perf "$t"; done
fi
echo "Done."
