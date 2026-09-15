#!/usr/bin/env bash
# Race reports on the applications: N runs per configuration with reporting ON, union of distinct races
# compared with stock ThreadSanitizer at L1 (kind + both frames function@file:line + location), L2
# (functions) and L3 (location + writer).
#
# Usage: scripts/31-preservation-apps.sh <sqlite|memcached|redis|ffmpeg|mysql> [N] [--configs a,b,c]
#   --configs takes a COMMA-separated list (run_preservation.py's own convention; perf uses spaces).
#   ART_SMOKE=1 -> N=1 and the harness's own "smoke" workload scale
#
# THE COMPARISON IS AGAINST STOCK, SO STOCK IS NOT OPTIONAL. Every claim here is of the form "the analysis
# did not lose a race stock reports", which a run that reports nothing satisfies for free -- a broken
# workload, a server that never started, a symbolizer that produced no frames. The `tsan` row is what makes
# the other rows mean anything, so it is forced into the configuration list whatever the caller asks for.
set -euo pipefail
. "$(dirname "$0")/_lib.sh"
need_harness tools/preservation; need_compiler

app="${1:?usage: 31-preservation-apps.sh <app> [N] [--configs a,b,c]}"; shift
n="$ART_RUNS"; configs="tsan,tsan-sound,tsan-dom_peeling-ea-lo-st-swmr"
while [ $# -gt 0 ]; do
  case "$1" in
    --configs) configs="${2:?--configs needs a comma-separated list}"; shift 2;;
    [0-9]*)    n="$1"; shift;;
    *) echo "unknown argument: $1" >&2; exit 2;;
  esac
done
case ",$configs," in *,tsan,*) ;; *) configs="tsan,$configs";; esac

scale=paper
[ "$ART_SMOKE" = 1 ] && { n=1; scale=smoke; }
budget "preservation on $app, N=$n, configurations $configs" "3 h" "1.5 h" "5 GB"
smoke_banner

out="$ART_RESULTS/preservation-$app-$(stamp)"
# --llvm-root defaults to OUR lab worktree (/home/alexey/dev/llvm-project-focs-lab/llvm/build), which does
# not exist here and must never be measured from anyway -- it is a working build that is relinked without
# notice. Pass the artifact's compiler explicitly; every run's manifest then records what it was built with.
exec python3 "$harness/tools/preservation/run_preservation.py" \
  --app "$app" --configs "$configs" --runs "$n" --scale "$scale" \
  --llvm-root "$TSAN_LLVM_ROOT" \
  --build-root "$ART_BUILD/preservation" \
  --workdir "${TMPDIR:-/tmp}/preservation-$app" \
  --no-ninja-check \
  --out "$out"
