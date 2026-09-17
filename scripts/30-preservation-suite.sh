#!/usr/bin/env bash
# Does an analysis lose a race the stock detector finds? Runs the TSan test suite under
# every configuration, K times each, and reports a test as a candidate loss only when it
# reports under stock in every repeat and fails under that configuration in every repeat.
# Usage: scripts/30-preservation-suite.sh [--self-test] [K] [config-name ...]   K defaults to $ART_RUNS
#
# Per-test timeout is 120 s (override with ART_LIT_TIMEOUT). Measured 2026-09-17: one test,
# getline_nohang.cpp, stalls in roughly one repeat in six and then waits out the whole
# timeout -- under stock as often as under any analysis, so it can never count as a lost
# race here. At 600 s that single test was the difference between a 25-minute suite and a
# two-hour one. It either passes in seconds or hangs, so a long timeout buys nothing.
# IF THE SUITE APPEARS TO STOP FOR A COUPLE OF MINUTES, IT HAS NOT HUNG: one test is
# waiting out its timeout.
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

# A no-report test passes when no race is reported. On too few processors the schedule
# may never interleave the threads the test exists to exercise, so it passes without
# having tested anything -- and a suite of such passes is indistinguishable from a suite
# that genuinely preserved every race. The discovered and unsupported counts are decided
# by lit feature gates before anything runs and are unaffected; it is the PASS that
# becomes vacuous. Hence a hard refusal rather than a warning: a reviewer on a one-CPU
# virtual machine would otherwise file a clean result that means nothing.
cpus=$(nproc)          # respects cpuset and affinity, so this sees what we can really use
if [ "$cpus" -lt 8 ]; then
  echo "This host offers $cpus usable processors; this suite needs at least 8." >&2
  echo "Below that, tests that pass by NOT reporting a race can pass because the schedule" >&2
  echo "never interleaved, not because the race was preserved. The result would look clean" >&2
  echo "and mean nothing. Give the container more CPUs (docker run --cpus / --cpuset-cpus)." >&2
  echo "Worse than vacuous, measured 2026-09-16: pinned to a single core this suite does not" >&2
  echo "finish. compare_exchange.cpp livelocks at test 99 of 383 -- two runnable threads (R S R)" >&2
  echo "contending for one core, one spinning at 100% while the other is never scheduled. The" >&2
  echo "run hangs rather than failing, so a watchdog may kill it and blame something else." >&2
  echo "If you want the discovered/unsupported counts anyway, which ARE valid at any CPU count" >&2
  echo "because lit decides them before running a thing, set ART_ALLOW_FEW_CPUS=1 -- but do not" >&2
  echo "quote a pass count, and expect the run to hang partway." >&2
  [ "${ART_ALLOW_FEW_CPUS:-0}" = 1 ] || exit 3
  echo "ART_ALLOW_FEW_CPUS=1: continuing. Counts are valid; PASSES ARE NOT EVIDENCE." >&2
fi

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
      "$TSAN_LLVM_ROOT/bin/llvm-lit" -q $(lit_timeout_flag "${ART_LIT_TIMEOUT:-120}") -j"${ART_JOBS}" "$suite" > "$log" 2>&1
    set -e
    # lit prints "Failed Tests (N):", "Timed Out Tests (N):" and "Unresolved Tests (N):"
    # above IDENTICAL "  ThreadSanitizer ... :: name" lines, so a plain grep cannot tell a
    # compiler result from a clock. That distinction is the difference between reporting a
    # lost race and reporting that a machine was slow, so the block header is carried
    # through and a timeout can never reach the lost-race rule.
    awk -v c="$cname" -v r="$rep" '
      /^Failed Tests/      {blk="fail";       next}
      /^Timed Out Tests/   {blk="timeout";    next}
      /^Unresolved Tests/  {blk="unresolved"; next}
      /^Unexpectedly Passed/ {blk="xpass";    next}
      /^  ThreadSanitizer/ {
        if (blk != "") { t=$0; sub(/^  ThreadSanitizer[^:]*:: */,"",t); print c"\t"r"\t"blk"\t"t }
      }' "$log" >> "$outdir/failures.tsv"
    nf=$(awk -v c="$cname" -v r="$rep" -F'\t' '$1==c && $2==r {n++} END{print n+0}' "$outdir/failures.tsv")
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
stalls = collections.defaultdict(set)      # (config, repeat) -> {test}  timeouts/unresolved
for ln in open(sys.argv[1]):
    if not ln.strip(): continue
    c, r, kind, t = ln.rstrip("\n").split("\t")
    if kind == "fail":
        fails[(c, int(r))].add(t.strip())
    else:
        stalls[(c, int(r))].add(t.strip())
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
all_stalls = collections.Counter()
for (c, r), ts in stalls.items():
    for t in ts: all_stalls[t] += 1
if all_stalls:
    print()
    print("  TIMED OUT / UNRESOLVED -- neither a pass nor a lost race, excluded from the rule:")
    for t, n in all_stalls.most_common():
        cfgs = sorted({c for (c, _), ts in stalls.items() if t in ts})
        print(f"    {t}  {n} time(s), under: {' '.join(cfgs)}")
    print("    A timeout is the machine being slow or a test hanging, not the compiler")
    print("    declining to instrument. Raise ART_LIT_TIMEOUT if these are legitimate.")
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
