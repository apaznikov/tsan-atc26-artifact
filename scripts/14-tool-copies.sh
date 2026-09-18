#!/bin/bash
# The artifact ships two copies of the aggregation tools: harness/tools/perf, which the measurement path
# runs, and data/tools/perf, which 90-tables.sh runs because aggregate.py derives the harness root from
# its own location and must therefore sit inside a data tree. Two copies of load-bearing code diverge. On
# 19 Sep 2026 they had: the data copy predated both the --runs option and the fix that stops the stability
# column claiming "all subtests within 5%" when nothing was measured, so the documented table check ran an
# older aggregator than the one that produced the measurements, and said the tables matched. This refuses
# that state: any file present in both directories must be byte-identical.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -eq 0 ] || { echo "$(basename "$0") takes no arguments (got: $*)"; exit 2; }
a="$here/harness/tools"; b="$here/data/tools"
[ -d "$a" ] && [ -d "$b" ] || { echo "one of $a, $b is absent; nothing to compare" >&2; exit 2; }
diverged=0; compared=0
while IFS= read -r f; do
  rel="${f#$b/}"
  for cand in "$a/$rel" "$a/perf/$(basename "$f")" "$a/preservation/$(basename "$f")" "$a/$(basename "$f")"; do
    [ -f "$cand" ] || continue
    compared=$((compared+1))
    if cmp -s "$f" "$cand"; then :; else
      echo "  DIVERGED  ${f#$here/}  vs  ${cand#$here/}"; diverged=$((diverged+1))
    fi
    break
  done
done < <(find "$b" -name '*.py' | sort)
if [ "$compared" -eq 0 ]; then
  echo "no file exists in both trees, which is not the expected shape of this artifact" >&2; exit 2
fi
if [ "$diverged" -ne 0 ]; then
  echo "$diverged of $compared shared tool(s) differ between harness/tools and data/tools." >&2
  echo "The measurement path and the table-regeneration path would run different code." >&2
  exit 1
fi
echo "the $compared tools shipped in both harness/tools and data/tools are identical"
