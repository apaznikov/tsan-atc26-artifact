#!/usr/bin/env bash
# Checks that every measured run in a results tree is attributable: that it records the compiler it
# was built by, the binary it ran, the input it read, the processor set and mode it ran under, the
# foreign-activity share the disturbance gate saw, and that each configuration has its full N.
#
# Usage: scripts/91-verify-provenance.sh [root ...]      default: every root under data/perf
#
# This answers "was this measured the way we say", and it reads only what the runs themselves
# recorded, so it cannot be satisfied by a script having been told the right thing. Two limits worth
# knowing: it does not check that a configuration's flags were the intended ones (that is the build
# guard, at build time, in build_info.txt), and it says nothing about whether a number is right. A
# tree can pass this and still be wrong; it cannot pass this and be unattributable.
set -euo pipefail
. "$(dirname "$0")/_lib.sh"
need_harness tools/perf

roots=("$@")
if [ ${#roots[@]} -eq 0 ]; then
  mapfile -t roots < <(find "$ART_DATA/perf" -mindepth 1 -maxdepth 1 -type d | sort)
fi
[ ${#roots[@]} -gt 0 ] || { echo "no results roots found under $ART_DATA/perf"; exit 2; }

budget "provenance of ${#roots[@]} results root(s)" "2 min" "1 min" "none"
rc=0
for r in "${roots[@]}"; do
  echo "== $r"
  python3 "$harness/tools/perf/verify_provenance.py" "$r" || rc=1
done
if [ "$rc" = 0 ]; then
  echo "All runs are attributable: compiler stamp, binary hash, input hash, processor set and mode,"
  echo "gate share and run count are present, singular per configuration, and consistent."
else
  echo "Provenance failed above. A table computed from that root carries conditions it cannot state." >&2
fi
exit "$rc"
