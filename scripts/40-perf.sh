#!/usr/bin/env bash
# The performance table for one application: builds every configuration (or the ones you name), runs
# one warm-up plus ART_RUNS measured runs per configuration in run-major order, and aggregates with the
# same aggregate.py that produced the paper's tables.
# Usage: scripts/40-perf.sh <sqlite|redis|memcached|ffmpeg|mysql> [--build-only] [--configs "c1 c2"]
#   ART_SMOKE=1  -> one run, short workloads, output marked NOT A MEASUREMENT
#   ART_CPUSET   -> taskset pinning (we used 4-27,60-83); leave empty to use every CPU
set -euo pipefail
. "$(dirname "$0")/_lib.sh"
need_harness tools/perf; need_compiler
app="${1:?usage: 40-perf.sh <app> [--build-only] [--configs \"c1 c2\"]}"; shift
case "$app" in sqlite) t8="1 day"; t32="6 h";; memcached) t8="18 h"; t32="5 h";; ffmpeg) t8="5 h"; t32="2 h";; redis) t8="3 h"; t32="1 h";; mysql) t8="see docs/mysql.md"; t32="~12 h";; *) echo "unknown app $app"; exit 2;; esac
budget "performance for $app, ${ART_WARMUP} warm-up + ${ART_RUNS} runs per configuration" "$t8" "$t32" "20-100 GB"
smoke_banner
[ "$ART_SMOKE" = 1 ] || refuse_if_building
out="$ART_RESULTS/perf-$app-$(stamp)"; mkdir -p "$out"
export P5_OUT="$out" P5_BUILDS="$(dirname "$TSAN_LLVM_ROOT")" P5_CPUSET_DEFAULT="$ART_CPUSET" P5_MACHINE_LOCK="$ART_MACHINE_LOCK"
hash="$(basename "$TSAN_LLVM_ROOT")"
"$harness/tools/perf/build.sh" "$app" "$hash" "$@"
[ "${1:-}" = "--build-only" ] && { echo "built into $out/build"; exit 0; }
"$harness/tools/perf/run.sh" "$app" "$hash" "$ART_RUNS" --warmup "$ART_WARMUP" "$@"
python3 "$ART_DATA/tools/perf/aggregate.py" "$out" --app "$app"
echo "-> $out/perf_$app.md"; smoke_banner
