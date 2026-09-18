#!/usr/bin/env bash
# Compile-time cost of the analyses over an uninstrumented build, per application.
# Usage: scripts/21-compile-time.sh <app> [config ...]        (configs are SPACE-separated)
#   configs default: orig tsan tsan-ea AllOpt+peel   ART_SMOKE=1 -> one repetition instead of three
#
# Each repetition rebuilds from nothing: an incremental build measures what the previous build left behind,
# not the compiler. `orig` and `tsan` are forced into every run as controls -- the output is a ratio, and a
# ratio is only about the compiler if the machine held still, which only a configuration using no escape
# analysis can show. See the header of compile_time.sh for the session where that mattered.
set -euo pipefail
. "$(dirname "$0")/_lib.sh"
# arguments before environment, for the reason given in 40-perf.sh
app="${1:?usage: 21-compile-time.sh <app> [config ...]}"; shift || true
case "$app" in sqlite|memcached|redis|ffmpeg|mysql) ;; *) echo "unknown app $app" >&2; exit 2;; esac

need_harness tools/perf; need_compiler

if [ -r "$TSAN_LLVM_ROOT/TSAN_AUDIT_HASH" ]; then
  hash=$(grep -oE '[0-9a-f]{40}' "$TSAN_LLVM_ROOT/TSAN_AUDIT_HASH" | head -1 || true)
else
  hash=$("$TSAN_LLVM_ROOT/bin/clang" --version 2>/dev/null | grep -oE '[0-9a-f]{40}' | head -1 || true)
fi
[ -n "${hash:-}" ] || { echo "cannot determine the compiler's commit from $TSAN_LLVM_ROOT" >&2; exit 2; }
hash=${hash:0:12}

budget "compile-time cost for $app, 3 clean builds per configuration" "1-3 h (MySQL: ~10 h)" "20-60 min (MySQL: ~5 h)" "10-100 GB"
smoke_banner
[ "$ART_SMOKE" = 1 ] || refuse_if_building

out="$ART_RESULTS/compile-time-$app-$(stamp)"; mkdir -p "$out"
export LLVM_TSAN_ROOT="$TSAN_LLVM_ROOT" P5_OUT="$out"
export P5_INSTALL_ROOT="$ART_BUILD/installs" P5_SCRATCH="$ART_BUILD/scratch"
export P5_LOCK="${TMPDIR:-/tmp}/artifact-perf.lock" P5_MACHINE_LOCK="$ART_MACHINE_LOCK"
export NPROC_MYSQL="$ART_JOBS" NPROC_FFMPEG="$ART_JOBS" NPROC_SQLITE="$ART_JOBS" \
       NPROC_MEMCACHED="$ART_JOBS" NPROC_REDIS="$ART_JOBS"
mkdir -p "$P5_INSTALL_ROOT" "$P5_SCRATCH"
CT_REPS="${CT_REPS:-3}" ART_SMOKE="$ART_SMOKE" exec "$harness/tools/perf/compile_time.sh" "$app" "$hash" "$@"
