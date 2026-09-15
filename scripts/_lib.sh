# Shared helpers for the numbered scripts. Sourced, not executed.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../env.sh
. "$here/env.sh"
harness="$here/harness"          # the measurement harness, vendored by tsan-exp (tools/perf, tools/preservation, ...)
need_harness() { [ -d "$harness/$1" ] || { echo "this script needs $harness/$1 (the vendored harness); not present in this checkout"; exit 2; }; }
need_compiler() { [ -x "$TSAN_LLVM_ROOT/bin/clang" ] || { echo "no TSan clang at $TSAN_LLVM_ROOT/bin/clang (set TSAN_LLVM_ROOT or run inside the container)"; exit 2; }; }
stamp() { date +%Y%m%d-%H%M%S; }
smoke_banner() { [ "$ART_SMOKE" = 1 ] && echo "SMOKE MODE: N=1, reduced workload. Output is NOT A MEASUREMENT and must not be compared with CLAIMS.md." || true; }
budget() { # budget <what> <8-core time> <32-core time> <disk>
  printf 'Expected: %s -- about %s on 8 cores, %s on 32 cores, %s of disk.\n' "$1" "$2" "$3" "$4"
}
refuse_if_building() { # a compiler build on the host invalidates timing runs
  if pgrep -x ninja >/dev/null 2>&1 || pgrep -f 'clang.*-cc1' >/dev/null 2>&1; then
    echo "a compiler build is running on this host; timing runs would be invalid. Wait for it to finish."; exit 3; fi
}
