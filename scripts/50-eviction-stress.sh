#!/usr/bin/env bash
# The two synthetic bounded-shadow experiments: (a) one fully occupied granule, a planted race, a burst of
# elidable accesses before the evicting access; (b) two races on one granule exercising both DE effects.
# 1000 runs per build and burst type (ART_SMOKE=1: 20).  Usage: scripts/50-eviction-stress.sh
#
# The planted race is the control and it is built in: the `tsan` build must report it. A configuration that
# reports nothing is indistinguishable from an elision that lost it, so a run in which stock itself reports
# nothing is a broken harness and not a result -- this script says so rather than printing a table of zeros.
set -euo pipefail
. "$(dirname "$0")/_lib.sh"
need_harness tools/eviction-stress; need_compiler
runs=1000; [ "$ART_SMOKE" = 1 ] && runs=20
budget "eviction stress, $runs runs per cell" "1 h" "15 min" "100 MB"
smoke_banner

out="$ART_RESULTS/eviction-stress-$(stamp)"; mkdir -p "$out/bin"
( cd "$harness/tools/eviction-stress" \
  && LLVM_TSAN_ROOT="$TSAN_LLVM_ROOT" ./build.sh "$out/bin" \
  && EVS_OUT="$out" JOBS="$ART_JOBS" art_cpus ./run.sh "$out/bin" "$runs" )

# The control, checked rather than assumed. `report.md` counts reports per configuration; if the stock row
# is zero the whole table is vacuous, whatever the other rows say.
rep="$out/report.md"
if [ -f "$rep" ]; then
  if grep -qiE '^\|?\s*tsan\s*\|' "$rep" && ! grep -EiA0 '^\|?\s*tsan\s*\|[^|]*\|\s*0\s*\|' "$rep" >/dev/null; then
    echo "control ok: the stock build reported the planted race."
  else
    echo "CONTROL FAILED: the stock (tsan) build reported no race in $rep." >&2
    echo "Every elision result in this table is vacuous until that is fixed -- a build that reports" >&2
    echo "nothing looks exactly like an elision that lost the race." >&2
    exit 4
  fi
fi
echo "-> $out (report.md per experiment); compare with data/eviction-stress/"
smoke_banner
