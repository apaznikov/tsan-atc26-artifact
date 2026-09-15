#!/usr/bin/env bash
# Compile-time overhead of the analyses over an uninstrumented build, per application.
# Usage: scripts/21-compile-time.sh <app> [config ...]      configs default: native tsan tsan-sound AllOpt+peel
# Times the application's build under each configuration (three builds each, median), through the vendored
# harness's build.sh with /usr/bin/time, and writes results/compile-time-<stamp>.csv.
set -euo pipefail
. "$(dirname "$0")/_lib.sh"
need_harness tools/perf; need_compiler
app="${1:?usage: 21-compile-time.sh <app> [config ...]}"; shift || true
budget "compile-time overhead for $app" "1-3 h (MySQL: ~10 h)" "20-60 min (MySQL: ~5 h)" "10-100 GB"
smoke_banner
exec "$harness/tools/perf/compile_time.sh" "$app" "$@"
