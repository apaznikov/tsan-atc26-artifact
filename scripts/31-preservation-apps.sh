#!/usr/bin/env bash
# Race reports on the applications: N runs per configuration with reporting ON, union of distinct races
# compared with stock ThreadSanitizer at L1 (kind + both frames function@file:line + location), L2
# (functions) and L3 (location + writer).
#
# Usage: scripts/31-preservation-apps.sh <sqlite|memcached|redis|ffmpeg|mysql> [N] [--configs a,b,c]
#   --configs takes a COMMA-separated list (run_preservation.py's own convention; perf uses spaces).
#   ART_SMOKE=1 -> N=1 and the harness's own "smoke" workload scale
#
# Exits non-zero ONLY if a site is LOST (stock reports it in every run, the configuration in none).
# UNDETERMINED sites -- ones stock itself reports only sometimes -- are printed with their per-run
# frequencies and do not fail the run; raise N to narrow them.
#
# THE COMPARISON IS AGAINST STOCK, SO STOCK IS NOT OPTIONAL. Every claim here is of the form "the analysis
# did not lose a race stock reports", which a run that reports nothing satisfies for free -- a broken
# workload, a server that never started, a symbolizer that produced no frames. The `tsan` row is what makes
# the other rows mean anything, so it is forced into the configuration list whatever the caller asks for.
set -euo pipefail
. "$(dirname "$0")/_lib.sh"
# arguments before environment, for the reason given in 40-perf.sh
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
case "$app" in sqlite|memcached|redis|ffmpeg|mysql) ;; *) echo "unknown app $app" >&2; exit 2;; esac

need_harness tools/preservation; need_compiler
# The rule that decides LOST/KEPT/UNDETERMINED, checked against synthetic cases before it is trusted on
# real ones, and checked HERE rather than after the runs: a control that fires after three hours of
# measurement tells you the rule was broken and that the afternoon is gone. It costs under a second.
python3 "$harness/tools/preservation/preservation_verdict.py" --self-test || {
  echo "the preservation verdict rule failed its own self-test; not running the suite" >&2; exit 1; }

scale=paper
[ "$ART_SMOKE" = 1 ] && { n=1; scale=smoke; }
budget "preservation on $app, N=$n, configurations $configs" "3 h" "1.5 h" "5 GB"
smoke_banner

out="$ART_RESULTS/preservation-$app-$(stamp)"

# The binaries come from the same builds 40-perf.sh makes, in the same places (run_preservation.py looks in
# the application trees under the harness working copy). Build them first, idempotently: tsan-sound is not
# in the performance subset, so the build cannot be assumed to have happened as a side effect of 40-perf.sh.
# The rehearsal of 17 Sep found this script pointing --build-root at a directory nothing ever wrote to, so
# every invocation failed in one second with "missing binaries"; that flag was for A/B builds against
# another compiler and is gone.
"$here/scripts/40-perf.sh" "$app" --build-only --configs "$(printf '%s' "$configs" | tr ',' ' ')" || exit $?
# --llvm-root defaults to OUR lab worktree (/home/alexey/dev/llvm-project-focs-lab/llvm/build), which does
# not exist here and must never be measured from anyway -- it is a working build that is relinked without
# notice. Pass the artifact's compiler explicitly; every run's manifest then records what it was built with.
python3 "$harness/tools/preservation/run_preservation.py" \
  --app "$app" --configs "$configs" --runs "$n" --scale "$scale" \
  --llvm-root "$TSAN_LLVM_ROOT" \
  --workdir "${TMPDIR:-/tmp}/preservation-$app" \
  --no-ninja-check \
  --out "$out" || exit $?

# THE VERDICT IS COMPUTED ON YOUR OWN RUNS, NOT AGAINST OUR SITE LIST. Race detection is stochastic: a site
# stock finds in 7 of our 10 runs may appear in 4 of yours, or none, with nothing wrong. So the criterion is
# comparative -- a site is LOST only if stock reports it in EVERY run and the configuration in NONE, which
# is the one shape detection noise cannot produce. A site stock itself reports intermittently is
# UNDETERMINED at this N and never fails the run: a criterion that fails on noise fails on a good compiler
# too, and the exit code cannot tell those apart. Our five sites are an observation in CLAIMS.md, not the test.
echo
python3 "$harness/tools/preservation/preservation_verdict.py" \
  --results-dir "$out/logs" --app "$app" --baseline tsan
rc=$?
# Two questions share this script and must not share one exit code. At the paper scale the question is
# whether the baseline demonstrated detection and every configuration kept it, and the positive control
# above (a run in which stock found nothing certifies nothing) decides the exit code. In smoke mode the
# question is only whether the pipeline ran end to end: one short run cannot show a site that stock itself
# reports in two or three of ten paper-scale runs (CLAIMS.md), so the verdict script's refusal is expected,
# is printed above as information, and is not the step's result. The rehearsal of 17 Sep 2026 found the
# smoke exiting 1 for every evaluator on exactly this refusal, the fourth case that day of an absent check
# and a failed one sharing a channel.
if [ "$ART_SMOKE" = 1 ]; then
  echo
  echo "VERDICT NOT ATTEMPTED: smoke scale, N=1. The pipeline ran end to end (builds, $n run per configuration,"
  echo "the verdict script); a preservation verdict needs the paper scale and N=10 and is not a smoke question."
  echo "-> $out"
  exit 0
fi
echo "-> $out"
exit $rc
