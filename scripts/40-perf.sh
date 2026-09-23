#!/usr/bin/env bash
# The performance table for one application: builds every configuration (or the ones you name), runs one
# warm-up plus ART_RUNS measured runs per configuration in run-major order, and aggregates with the same
# aggregate.py that produced the paper's tables.
#
# Usage: scripts/40-perf.sh <sqlite|redis|memcached|ffmpeg|mysql> [--build-only] [--all-configs] [--configs "c1 c2"]
#   default          the four-configuration subset: native, stock TSan, AllOpt+peel, DynSTC
#   --all-configs    all fourteen configurations of the paper's table
#   --configs        a SPACE-separated list (tools/perf's own convention; preservation uses commas)
#
# THE DEFAULT IS A SUBSET BECAUSE THE FULL TABLE IS NOT A REVIEWER-SIZED JOB. At ART_RUNS=2 plus a warm-up,
# measured on two hosts: Redis 13-15 min, memcached 28-36 min, FFmpeg 20-25 min, SQLite 65-68 min,
# MySQL about 3.4 h for the four; all fourteen at N=2 is about 11 h. The four carry the paper's claims --
# the overhead over native, AllOpt with peeling, and DynSTC.
#   ART_SMOKE=1  -> one run, no warm-up, output marked NOT A MEASUREMENT; the workload is shortened only
#                   for memcached and MySQL (SQLite runs its whole suite; Redis and FFmpeg run theirs once)
#   ART_CPUSET   -> taskset pinning (we used 4-27,60-83); leave empty to use every CPU the container has
set -euo pipefail
. "$(dirname "$0")/_lib.sh"

# ARGUMENTS FIRST, ENVIRONMENT SECOND. A reviewer who mistypes a flag on a checkout with no vendored
# harness should be told about the flag, not about the harness: diagnosing the setup first sends them off
# to fix something unrelated, after which they hit the typo again. Usage errors are cheaper to report and
# are the reader's own doing; environment errors are ours.
app="${1:?usage: 40-perf.sh <app> [--build-only] [--all-configs] [--configs \"c1 c2\"]}"; shift
build_only=0; configs=""; all_configs=0
SUBSET="orig tsan tsan-dom_peeling-ea-lo-st-swmr tsan-stmt"
# FFmpeg adds the combination, its headline row (AllOpt with peeling and DynSTC, 1.187 [1.171, 1.201] at the
# 16-thread default; CLAIMS.md, the first FFmpeg section). About a quarter more time than the four.
[ "$app" = ffmpeg ] && SUBSET="$SUBSET tsan-dom_peeling-ea-lo-st-swmr-stmt"
while [ $# -gt 0 ]; do
  case "$1" in
    --build-only)  build_only=1; shift;;
    --all-configs) all_configs=1; shift;;
    --configs)     configs="${2:?--configs needs a quoted list}"; shift 2;;
    *) echo "unknown argument: $1" >&2; exit 2;;
  esac
done
[ "$all_configs" = 1 ] && [ -n "$configs" ] && { echo "--all-configs and --configs are mutually exclusive" >&2; exit 2; }
# An explicit --configs wins; otherwise the subset, unless --all-configs asked for the fourteen. Passing
# nothing to the harness means ITS default set, which is not the same thing, so the subset is named here.
[ -n "$configs" ] || { [ "$all_configs" = 1 ] || configs="$SUBSET"; }
# --all-configs means the campaign's fourteen (twelve for FFmpeg, which has no whole-program rows; four for
# MySQL), named here. An EMPTY list would mean the harness's own default set, which is the six of its Stage A
# and has no DynSTC row at all, so `evaluate.sh everything` measured six configurations and never the one
# whose interval excludes 1.0.
ALL14="orig tsan tsan-st tsan-swmr tsan-lo tsan-ea tsan-dom tsan-dom_peeling tsan-dom-ea-lo-st-swmr tsan-dom_peeling-ea-lo-st-swmr tsan-dom_peeling-ea-lo-st-swmr-stmt tsan-stmt tsan-dom_peeling-ea-lo-st-swmr-wp tsan-sound-wp"
if [ "$all_configs" = 1 ]; then
  case "$app" in
    ffmpeg) configs=$(printf '%s\n' $ALL14 | grep -v -- '-wp$' | tr '\n' ' ');;
    mysql)  configs="orig tsan tsan-dom_peeling-ea-lo-st-swmr tsan-dom_peeling-ea-lo-st-swmr-stmt";;
    *)      configs="$ALL14";;
  esac
fi
case "$app" in sqlite|memcached|redis|ffmpeg|mysql) ;; *) echo "unknown app $app" >&2; exit 2;; esac

need_harness tools/perf; need_compiler

# THE COMPILER'S OWN STAMP, NOT THE DIRECTORY NAME. The harness identifies a compiler by the 40-hex commit
# it reports, and `basename /opt/tsan-llvm` is "tsan-llvm", which stamps nothing. Every binary the harness
# builds records `compiler_head`, and the runner refuses a binary whose stamp is not the hash of the run --
# so getting this wrong does not produce wrong numbers, it produces a run that cannot start. Read it from
# the file the image writes, and fall back to asking clang, which is where that file came from.
if [ -r "$TSAN_LLVM_ROOT/TSAN_AUDIT_HASH" ]; then
  hash=$(head -1 "$TSAN_LLVM_ROOT/TSAN_AUDIT_HASH" | grep -oE '[0-9a-f]{40}' || true)   # line 1 is the commit; line 2 is a tree hash
else
  hash=$("$TSAN_LLVM_ROOT/bin/clang" --version 2>/dev/null | grep -oE '[0-9a-f]{40}' | head -1 || true)
fi
[ -n "${hash:-}" ] || { echo "cannot determine the compiler's commit: $TSAN_LLVM_ROOT has no TSAN_AUDIT_HASH and clang --version prints no 40-hex string" >&2; exit 2; }
hash=${hash:0:12}

# Measured at the defaults (four configurations, N = 2) on 48 pinned processors, on two hosts;
# --all-configs multiplies by about 3.4 and ART_RUNS=5 by about 2 (one warm-up plus N runs; the campaign's per-cell costs).
case "$app" in
  sqlite)    t="1 h";;      memcached) t="30 min";;   ffmpeg) t="about 25 min for the five configurations, plus the clip's first download";;
  redis)     t="15 min";;   mysql)     t="3.5 h plus a build of about 10 min per configuration";;
esac
runs="$ART_RUNS"; warmup="$ART_WARMUP"
if [ "$ART_SMOKE" = 1 ]; then
  runs=1; warmup=0
  # Smoke mode drops to one unwarmed run. It shortens the WORKLOAD only for memcached (MC_REQUESTS) and
  # MySQL (MYSQL_SECONDS): SQLITE_TESTS takes effect only on run_sqlite_test.sh's --w1-threads path, so
  # SQLite runs its whole suite, and FF_THREADS=16 restates FFmpeg's default thread count.
  export MYSQL_SECONDS=20 MC_REQUESTS=2000 SQLITE_TESTS=walthread1 FF_THREADS="${FF_THREADS:-16}"
fi
printf 'Expected: performance for %s, %s warm-up + %s runs per configuration -- about %s at the defaults on 48 pinned processors (--all-configs about 3.4x, ART_RUNS=5 about 2x, smoke mode one run, with a shortened workload for memcached and MySQL only), 20-100 GB of disk.\n' "$app" "$warmup" "$runs" "$t"
smoke_banner
[ "$ART_SMOKE" = 1 ] || refuse_if_building

out="$ART_RESULTS/perf-$app-$(stamp)"; mkdir -p "$out"
# Everything the harness would otherwise take from its built-in defaults in tools/perf/lib.sh; the artifact
# overrides all of them so nothing reaches outside ART_ROOT.
export LLVM_TSAN_ROOT="$TSAN_LLVM_ROOT"
export P5_OUT="$out"
export P5_INSTALL_ROOT="$ART_BUILD/installs"
export P5_SCRATCH="$ART_BUILD/scratch"
export P5_LOCK="${TMPDIR:-/tmp}/artifact-perf.lock"
export P5_CPUSET_DEFAULT="$ART_CPUSET"
export P5_MACHINE_LOCK="$ART_MACHINE_LOCK"      # `true` by default: the lab's whole-machine lock is a no-op here
export NPROC_MYSQL="$ART_JOBS" NPROC_FFMPEG="$ART_JOBS" NPROC_SQLITE="$ART_JOBS" \
       NPROC_MEMCACHED="$ART_JOBS" NPROC_REDIS="$ART_JOBS"
mkdir -p "$P5_INSTALL_ROOT" "$P5_SCRATCH"

# shellcheck disable=SC2086   # $configs is a list on purpose; empty means "the script's default set"
"$harness/tools/perf/build.sh" "$app" "$hash" $configs
[ "$build_only" = 1 ] && { echo "built; configurations are under $P5_INSTALL_ROOT and the application trees"; exit 0; }

run_args=("$app" "$hash" "$runs")
[ "$warmup" -gt 0 ] && run_args+=(--warmup "$warmup")
[ -n "$configs" ] && run_args+=(--configs "$configs")
[ -n "$ART_CPUSET" ] && run_args+=(--cpuset "$ART_CPUSET")
"$harness/tools/perf/run.sh" "${run_args[@]}"

# --expect-n is ART_RUNS, so a two-run default renders as a point estimate rather than being branded
# NOT A MEASUREMENT; an interval still needs five runs, which no value of ART_RUNS below five can buy.
python3 "$harness/tools/perf/aggregate.py" "$out" --app "$app" --expect-n "$runs"
echo "-> $out/perf_$app.md"
smoke_banner
