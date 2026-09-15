#!/usr/bin/env bash
# The performance table for one application: builds every configuration (or the ones you name), runs one
# warm-up plus ART_RUNS measured runs per configuration in run-major order, and aggregates with the same
# aggregate.py that produced the paper's tables.
#
# Usage: scripts/40-perf.sh <sqlite|redis|memcached|ffmpeg|mysql> [--build-only] [--configs "c1 c2"]
#   --configs takes a SPACE-separated list (tools/perf's own convention; preservation uses commas).
#   ART_SMOKE=1  -> one run, short workloads, output marked NOT A MEASUREMENT
#   ART_CPUSET   -> taskset pinning (we used 4-27,60-83); leave empty to use every CPU the container has
set -euo pipefail
. "$(dirname "$0")/_lib.sh"

# ARGUMENTS FIRST, ENVIRONMENT SECOND. A reviewer who mistypes a flag on a checkout with no vendored
# harness should be told about the flag, not about the harness: diagnosing the setup first sends them off
# to fix something unrelated, after which they hit the typo again. Usage errors are cheaper to report and
# are the reader's own doing; environment errors are ours.
app="${1:?usage: 40-perf.sh <app> [--build-only] [--configs \"c1 c2\"]}"; shift
build_only=0; configs=""
while [ $# -gt 0 ]; do
  case "$1" in
    --build-only) build_only=1; shift;;
    --configs)    configs="${2:?--configs needs a quoted list}"; shift 2;;
    *) echo "unknown argument: $1" >&2; exit 2;;
  esac
done
case "$app" in sqlite|memcached|redis|ffmpeg|mysql) ;; *) echo "unknown app $app" >&2; exit 2;; esac

need_harness tools/perf; need_compiler

# THE COMPILER'S OWN STAMP, NOT THE DIRECTORY NAME. The harness identifies a compiler by the 40-hex commit
# it reports, and `basename /opt/tsan-llvm` is "tsan-llvm", which stamps nothing. Every binary the harness
# builds records `compiler_head`, and the runner refuses a binary whose stamp is not the hash of the run --
# so getting this wrong does not produce wrong numbers, it produces a run that cannot start. Read it from
# the file the image writes, and fall back to asking clang, which is where that file came from.
if [ -r "$TSAN_LLVM_ROOT/TSAN_AUDIT_HASH" ]; then
  hash=$(grep -oE '[0-9a-f]{40}' "$TSAN_LLVM_ROOT/TSAN_AUDIT_HASH" | head -1)
else
  hash=$("$TSAN_LLVM_ROOT/bin/clang" --version 2>/dev/null | grep -oE '[0-9a-f]{40}' | head -1)
fi
[ -n "${hash:-}" ] || { echo "cannot determine the compiler's commit: $TSAN_LLVM_ROOT has no TSAN_AUDIT_HASH and clang --version prints no 40-hex string" >&2; exit 2; }
hash=${hash:0:12}

case "$app" in
  sqlite)    t8="1 day"; t32="6 h";;   memcached) t8="18 h"; t32="5 h";;
  ffmpeg)    t8="5 h";   t32="2 h";;   redis)     t8="3 h";  t32="1 h";;
  mysql)     t8="see docs/mysql.md"; t32="~12 h";;
esac
runs="$ART_RUNS"; warmup="$ART_WARMUP"
if [ "$ART_SMOKE" = 1 ]; then
  runs=1; warmup=0
  # Smoke mode shortens the WORKLOAD as well as the repetition count. A single full-length run is still
  # hours on some applications, and a reader checking that the plumbing works should not pay for that.
  export MYSQL_SECONDS=20 MC_REQUESTS=2000 SQLITE_TESTS=walthread1 FF_THREADS="${FF_THREADS:-4}"
fi
budget "performance for $app, $warmup warm-up + $runs runs per configuration" "$t8" "$t32" "20-100 GB"
smoke_banner
[ "$ART_SMOKE" = 1 ] || refuse_if_building

out="$ART_RESULTS/perf-$app-$(stamp)"; mkdir -p "$out"
# Everything the harness would otherwise take from our lab's filesystem. Each of these has a lab default
# compiled into tools/perf/lib.sh; the artifact overrides all of them so nothing reaches outside ART_ROOT.
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

python3 "$harness/tools/perf/aggregate.py" "$out" --app "$app"
echo "-> $out/perf_$app.md"
smoke_banner
