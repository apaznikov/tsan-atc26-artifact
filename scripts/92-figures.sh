#!/usr/bin/env bash
# The paper's presentation: one bar chart per application, speedup against stock ThreadSanitizer, with the
# 95 % interval on every bar. Bars are our campaign; a results tree given as an argument is drawn beside them
# as points, so an evaluator sees their own run against ours in the form the paper uses.
#
# Usage: scripts/92-figures.sh [results/perf-<app>-<stamp> ...]
#        with no argument it draws the shipped campaign alone.
set -euo pipefail
. "$(dirname "$0")/_lib.sh"
need_harness tools/perf   # figures.py reads the tables through the comparator's own parser, which lives in the harness
[ "${1:-}" = "--help" ] && { sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }
out="$ART_RESULTS/figures"
mkdir -p "$out"
echo "Drawing the speedup figures into $out:"
python3 "$harness/tools/perf/figures.py" --out "$out" "$@"
echo
echo "SVG, one file per application; open them in any browser. The numbers are read from the same"
echo "perf_<app>.md tables the comparator reads, so a bar cannot disagree with the table it comes from."
