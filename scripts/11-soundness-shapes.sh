#!/usr/bin/env bash
# The lost-race shapes: the IR tests that pin every access this compiler declines to
# instrument, run against the shipped compiler, plus the control that proves those tests
# can tell a removal from a compiler that never instrumented the access at all.
# Usage: scripts/11-soundness-shapes.sh [--quick]     --quick skips the vacuity control
set -euo pipefail
. "$(dirname "$0")/_lib.sh"
need_compiler

quick=0
case "${1:-}" in
  --quick) quick=1 ;;
  "") ;;
  *) echo "usage: scripts/11-soundness-shapes.sh [--quick]"; exit 2 ;;
esac

budget "the IR soundness suite" "2 min" "1 min" "none"
refuse_if_lit_running
need_lit

name="soundness-shapes-$(stamp)"
outdir="$ART_RESULTS/$name"; mkdir -p "$outdir"
exec_root="$(lit_exec_root "$name")"     # private: concurrent lit runs must not share Output/
suite="$here/tests/ir"
[ -d "$suite" ] || { echo "no vendored IR tests at $suite"; exit 2; }

echo "compiler : $TSAN_LLVM_ROOT"
echo "           $("$TSAN_LLVM_ROOT/bin/clang" --version | head -1)"
[ -f "$TSAN_LLVM_ROOT/TSAN_AUDIT_HASH" ] \
  && echo "stamp    : $(head -1 "$TSAN_LLVM_ROOT/TSAN_AUDIT_HASH")" \
  || echo "stamp    : (no TSAN_AUDIT_HASH; provenance unverified)"
echo "tests    : $(find "$suite" -name '*.ll' | wc -l) in $suite"
echo "exec root: $exec_root"
echo

echo "=== 1. every test passes against the shipped compiler ==="
set +e
with_lit_lock env ART_LIT_EXEC_ROOT="$exec_root" \
  "$TSAN_LLVM_ROOT/bin/llvm-lit" -q --timeout 300 -j"${ART_JOBS}" "$suite" \
  > "$outdir/lit.log" 2>&1
lit_rc=$?
set -e
if [ $lit_rc -eq 0 ]; then
  echo "  PASS: no failures"
else
  echo "  FAIL: lit exited $lit_rc"
  sed -n '/Failed Tests/,$p' "$outdir/lit.log" | head -40
fi

if [ $quick -eq 1 ]; then
  echo; echo "(--quick: vacuity control skipped. A passing suite alone is not evidence:"
  echo " a test that asserts an access was removed also passes against a compiler that"
  echo " never instrumented it. Run without --quick before quoting this result.)"
  echo "-> $outdir"; exit $lit_rc
fi

echo
echo "=== 2. control: can these tests tell a removal from an absence? ==="
echo "    Each test is re-run with its -tsan-* flags stripped. A test that asserts a"
echo "    removal must FAIL without the analysis; one that asserts instrumentation stays"
echo "    is expected to pass either way."
set +e
python3 "$ART_DATA/tools/ir_test_vacuity.py" "$TSAN_LLVM_ROOT" "$suite" \
  --json "$outdir/vacuity.json" | tee "$outdir/vacuity.log"
vac_rc=${PIPESTATUS[0]}
set -e

echo
if [ $lit_rc -eq 0 ] && [ $vac_rc -eq 0 ]; then
  echo "RESULT: the suite passes AND every removal it claims is one it can detect."
else
  echo "RESULT: NOT CLEAN -- lit rc=$lit_rc, vacuity rc=$vac_rc. Read the logs before quoting anything."
fi
echo "-> $outdir"
[ $lit_rc -eq 0 ] && [ $vac_rc -eq 0 ]
