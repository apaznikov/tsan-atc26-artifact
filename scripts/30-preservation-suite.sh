#!/usr/bin/env bash
# Does an analysis lose a race the stock detector finds? Runs the TSan test suite under
# every configuration, K times each, and reports a test as a candidate loss only when it
# reports under stock in every repeat and fails under that configuration in every repeat.
# Usage: scripts/30-preservation-suite.sh [--self-test] [K] [config-name ...]   K defaults to $ART_RUNS
#   --self-test  runs stock against a deliberately blinded detector and requires this
#                harness to REPORT the loss. A suite that reports nothing is what both a
#                preserved race and a broken harness look like; this tells them apart.
set -euo pipefail
. "$(dirname "$0")/_lib.sh"
need_compiler

selftest=0
if [ "${1:-}" = "--self-test" ]; then selftest=1; shift; fi
k="${ART_RUNS}"
case "${1:-}" in
  ''|*[!0-9]*) ;;                       # first argument is a config name, not a count
  *) k="$1"; shift ;;
esac
[ "$ART_SMOKE" = 1 ] && k=1
want=("$@")

matrix="$ART_DATA/preservation/lit-configurations.txt"
if [ $selftest -eq 1 ]; then
  matrix="$(mktemp)"
  # -tsan-instrument-memory-accesses=0 leaves the runtime and the test unchanged and simply
  # stops instrumenting loads and stores, so the races in the suite become invisible.
  printf 'stock|\nBLINDED|-tsan-instrument-memory-accesses=0\n' > "$matrix"
  want=()
fi
suite="$here/tests/tsan"
[ -f "$matrix" ] || { echo "missing $matrix"; exit 2; }
[ -d "$suite" ]  || { echo "no vendored TSan tests at $suite"; exit 2; }

ncfg=$(grep -vc '^#' "$matrix")
budget "the TSan suite, $ncfg configurations x K=$k repeats" "3 h" "45 min" "2 GB"
smoke_banner
refuse_if_lit_running
need_lit

name="preservation-suite-$(stamp)"
outdir="$ART_RESULTS/$name"; mkdir -p "$outdir"
cp "$matrix" "$outdir/configurations.txt"

echo "compiler : $("$TSAN_LLVM_ROOT/bin/clang" --version | head -1)"
echo "tests    : $(find "$suite" -name '*.c' -o -name '*.cpp' | wc -l) source files"
echo "repeats  : K=$k"
echo

# Every run gets its own exec root. lit puts temporaries in Output/ under the exec root,
# so two runs sharing one directory overwrite each other's binaries: that produced 45
# failures out of 462 here once, none of them the compiler's doing. with_lit_lock keeps
# our own runs serial on top of that.
: > "$outdir/failures.tsv"
: > "$outdir/ran.txt"
while IFS='|' read -r cname cflags; do
  case "$cname" in ''|\#*) continue ;; esac
  if [ ${#want[@]} -gt 0 ]; then
    case " ${want[*]} " in *" $cname "*) ;; *) continue ;; esac
  fi
  echo "$cname" >> "$outdir/ran.txt"
  printf "  %-20s" "$cname"
  for rep in $(seq 1 "$k"); do
    er="$outdir/exec/$cname/$rep"; rm -rf "$er"; mkdir -p "$er"
    log="$outdir/lit-$cname-$rep.log"
    set +e
    with_lit_lock env TSAN_MLLVM_FLAGS="$cflags" ART_LIT_EXEC_ROOT="$er" \
      "$TSAN_LLVM_ROOT/bin/llvm-lit" -q --timeout 600 -j"${ART_JOBS}" "$suite" > "$log" 2>&1
    set -e
    nf=$(grep -c '^  ThreadSanitizer' "$log" || true)
    grep '^  ThreadSanitizer' "$log" | sed "s|^  ThreadSanitizer[^:]*:: *|$cname\t$rep\t|" >> "$outdir/failures.tsv" || true
    printf " %s" "$nf"
    rm -rf "$er"
  done
  echo ""
done < "$matrix"
echo "  (numbers above are failing tests per repeat; 0 everywhere is the expected result)"
echo

set +e
python3 - "$outdir/failures.tsv" "$k" "$outdir/ran.txt" <<'PY' | tee "$outdir/report.txt"
import collections, sys
fails = collections.defaultdict(set)          # (config, repeat) -> {test}
seen_cfg = []
for ln in open(sys.argv[1]):
    if not ln.strip(): continue
    c, r, t = ln.rstrip("\n").split("\t")
    fails[(c, int(r))].add(t.strip())
k = int(sys.argv[2])
# Only configurations that ACTUALLY RAN. Reading the matrix file instead would print
# "clean" for every configuration this invocation skipped -- no failure rows recorded
# looks exactly like no failures.
for ln in open(sys.argv[3]):
    c = ln.strip()
    if c: seen_cfg.append(c)
def always(c):  return set.intersection(*[fails[(c, r)] for r in range(1, k+1)]) if k else set()
def ever(c):    return set.union(*[fails[(c, r)] for r in range(1, k+1)]) if k else set()
stock_always = always("stock") if "stock" in seen_cfg else set()
stock_ever   = ever("stock")   if "stock" in seen_cfg else set()
print(f"  configurations RUN : {len(seen_cfg)}   repeats: K={k}")
print(f"  {' '.join(seen_cfg)}")
if "stock" not in seen_cfg:
    print("  WARNING: stock was not run, so there is no baseline. Every comparison below is")
    print("           against an empty set and cannot show a loss.")
print(f"  stock: fails always={len(stock_always)}  fails at least once={len(stock_ever)}")
print()
rc = 0
for c in seen_cfg:
    if c == "stock": continue
    a, e = always(c), ever(c)
    # A candidate loss: fails under this configuration every time, and stock never failed it.
    lost = sorted(a - stock_ever)
    flaky = sorted((e - a) - stock_ever)
    tag = "clean" if not lost else f"{len(lost)} CANDIDATE LOSS"
    print(f"  {c:22s} always-fail={len(a):3d} ever-fail={len(e):3d}  {tag}")
    for t in lost[:8]:
        print(f"        LOST: {t}")
    for t in flaky[:4]:
        print(f"        flaky (not every repeat, not a loss): {t}")
    if lost: rc = 1
print()
if k < 3:
    print("NOTE: K<3. These tests deflake internally, but a single repeat cannot separate a")
    print("      lost race from a flaky one. Do not quote this as a preservation result.")
if rc == 0:
    print("RESULT: no configuration consistently failed a test that stock consistently passed.")
else:
    print("RESULT: at least one candidate lost race. Read the per-test logs before concluding:")
    print("        a thread-leak report and a missed race both show up as a failing test.")
sys.exit(rc)
PY
rc=${PIPESTATUS[0]}
set -e
if [ $selftest -eq 1 ]; then
  rm -f "$matrix"
  echo
  if [ $rc -ne 0 ] && grep -q "LOST:" "$outdir/report.txt"; then
    echo "SELF-TEST PASSED: the harness reported the blinded detector's losses."
    echo "  A clean result from the real matrix is therefore worth something."
    exit 0
  fi
  echo "SELF-TEST FAILED: a detector with load/store instrumentation switched OFF was not"
  echo "  reported as losing races. This harness cannot detect a lost race; every clean"
  echo "  result it has produced is worthless until this is fixed."
  exit 1
fi
echo "-> $outdir"
exit $rc
