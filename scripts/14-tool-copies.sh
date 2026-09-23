#!/bin/bash
# The artifact ships two copies of the aggregation tools: harness/tools/perf, which the measurement path
# runs, and data/tools/perf, which 90-tables.sh runs because aggregate.py derives the harness root from
# its own location and must therefore sit inside a data tree. Two copies of load-bearing code diverge, and
# a stale data copy would make the documented table check run an older aggregator than the one that produced
# the measurements and still say the tables matched. This refuses that state: any file present in both
# directories must be byte-identical.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -eq 0 ] || { echo "$(basename "$0") takes no arguments (got: $*)"; exit 2; }
# EVERY file that exists in both trees, not only the tools: aggregate.py loads the per-application
# parsers from data/nosql, data/sql and data/projects, which are copies of the harness ones, and a check
# that looked only at data/tools would say "identical" while a parser drifted.
a="$here/harness"; b="$here/data"
[ -d "$a" ] && [ -d "$b" ] || { echo "one of $a, $b is absent; nothing to compare" >&2; exit 2; }
diverged=0; compared=0
while IFS= read -r f; do
  rel="${f#$b/}"
  cand="$a/$rel"
  if [ ! -f "$cand" ]; then
    # data/tools/perf/x.py corresponds to harness/tools/perf/x.py; the rest correspond by identical path.
    cand="$a/$(echo "$rel" | sed 's|^tools/|tools/|')"
    [ -f "$cand" ] || continue
  fi
  compared=$((compared+1))
  cmp -s "$f" "$cand" || { echo "  DIVERGED  data/$rel  vs  harness/$rel"; diverged=$((diverged+1)); }
done < <(cd "$b" && find . -name '*.py' | sed 's|^\./||' | sort | sed "s|^|$b/|")
if [ "$compared" -lt 6 ]; then
  echo "only $compared file(s) exist in both trees; this artifact ships the harness twice and should have more." >&2
  echo "Either the layout changed or one tree is incomplete; neither is a state this check can pass." >&2
  exit 1
fi
if [ "$diverged" -ne 0 ]; then
  echo "$diverged of $compared shared tool(s) differ between harness/tools and data/tools." >&2
  echo "The measurement path and the table-regeneration path would run different code." >&2
  exit 1
fi
echo "the $compared files shipped in both harness/ and data/ are identical"
