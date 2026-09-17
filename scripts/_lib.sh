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

# --- lit: exclusivity and private output roots -------------------------------
# Two lit runs over the SAME test directory share its Output/ subdirectory and
# overwrite each other's temporaries. Four concurrent runs once produced 45 failures
# out of 462 here that had nothing to do with the compiler. Both halves below exist
# because of that: a private exec root per run, and a lock so our own scripts serialise.
#
# The running-lit detector matches on comm, never on the full command line. A
# `pgrep -f lit` would match the pgrep process itself -- its own argv contains the
# pattern -- so the guard would always fire. comm for the pgrep we run is "pgrep", so
# there is nothing to self-match.
#
# comm for llvm-lit is "llvm-lit": MEASURED, not deduced. comm is not reliably a script's
# own name -- it is the name of whatever the kernel actually exec'd, so a script with
# `#!/usr/bin/env bash` reports "bash", and comm is capped at 15 characters besides. This
# guard is therefore correct for the llvm-lit we ship and would NOT catch a differently
# wrapped lit. Re-measure before trusting it against another driver.
refuse_if_lit_running() {
  local pids; pids=$(pgrep -x llvm-lit 2>/dev/null || true)
  [ -z "$pids" ] && return 0
  echo "another llvm-lit is running (pids: $(echo $pids | tr '\n' ' '))." >&2
  echo "Concurrent lit runs share Output/ and produce failures that are not the compiler's." >&2
  echo "Wait for it to finish, or set ART_LIT_FORCE=1 if you are certain it uses a different tree." >&2
  [ "${ART_LIT_FORCE:-0}" = 1 ] || exit 3
}
# lit_exec_root <name>: a private, empty exec root under results/, echoed on stdout.
lit_exec_root() { local d="$ART_RESULTS/$1/lit-exec"; rm -rf "$d"; mkdir -p "$d"; echo "$d"; }
# with_lit_lock <cmd...>: serialise against our other lit-running scripts.
with_lit_lock() {
  local lock="${TMPDIR:-/tmp}/tsan-artifact-lit.lock"
  if command -v flock >/dev/null 2>&1; then flock "$lock" -c "$(printf '%q ' "$@")"; else "$@"; fi
}
# The lit driver: llvm-lit plus the vendored lit python package it imports.
lit_run() {
  need_compiler
  [ -x "$TSAN_LLVM_ROOT/bin/llvm-lit" ] || { echo "no llvm-lit at $TSAN_LLVM_ROOT/bin/llvm-lit"; exit 2; }
  "$TSAN_LLVM_ROOT/bin/llvm-lit" "$@"
}

# need_lit: llvm-lit is a Python script that imports the `lit` package. Installing the
# driver without the package ships something that cannot start -- both the artifact image
# and the frozen copies under /extra/alexey/builds did exactly that. Testing the
# executable bit does not catch it; only starting it does. If the package is findable
# nearby, point PYTHONPATH at it rather than failing.
need_lit() {
  local lit="$TSAN_LLVM_ROOT/bin/llvm-lit"
  [ -x "$lit" ] || { echo "no llvm-lit at $lit"; exit 2; }
  "$lit" --version >/dev/null 2>&1 && return 0
  local cand
  for cand in "$TSAN_LLVM_ROOT/lib/python-lit" \
              "$TSAN_LLVM_ROOT/../llvm-project/llvm/utils/lit" \
              "${ART_LIT_PACKAGE:-}"; do
    [ -n "$cand" ] && [ -d "$cand/lit" ] || continue
    if PYTHONPATH="$cand${PYTHONPATH:+:$PYTHONPATH}" "$lit" --version >/dev/null 2>&1; then
      export PYTHONPATH="$cand${PYTHONPATH:+:$PYTHONPATH}"
      echo "note: llvm-lit could not import lit; using the package at $cand"
      return 0
    fi
  done
  echo "llvm-lit is present but cannot start:" >&2
  "$lit" --version 2>&1 | tail -3 | sed 's/^/  /' >&2
  echo "The lit Python package is missing from this compiler. Set ART_LIT_PACKAGE to a" >&2
  echo "directory containing lit/ (for a source checkout: llvm/utils/lit), or use a" >&2
  echo "compiler prefix that ships it -- the artifact image has it at lib/python-lit." >&2
  exit 2
}

# lit_timeout_flag: `--timeout` makes lit exit 2 outright when the psutil module is
# missing, which reads as a suite failure and is not one. Use the flag when it works and
# say so plainly when it does not, rather than losing the run to a missing dependency.
lit_timeout_flag() {
  if python3 -c 'import psutil' >/dev/null 2>&1; then printf -- '--timeout %s' "$1"
  else echo "note: python3-psutil not installed; running without a per-test timeout" >&2; fi
}
