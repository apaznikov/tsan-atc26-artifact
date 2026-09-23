#!/usr/bin/env bash
# Tier 0, under a minute once the image exists (measured 7 to 11 s): one small program per analysis, compiled with stock ThreadSanitizer and
# with that analysis enabled, showing how many memory-access instrumentation calls each analysis
# removes and why; then a program with a real race, run under every configuration, showing the race
# is still reported. Needs only the compiler; no benchmark applications.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../env.sh
. "$here/env.sh"
CC="$TSAN_LLVM_ROOT/bin/clang"; OBJDUMP="$TSAN_LLVM_ROOT/bin/llvm-objdump"
[ $# -eq 0 ] || { echo "$(basename "$0") takes no arguments (got: $*)"; exit 2; }
[ -x "$CC" ] || { echo "no TSan clang at $CC (set TSAN_LLVM_ROOT or run inside the container)"; exit 2; }
# The counter below greps llvm-objdump's output, so a missing or broken objdump yields 0 for every
# column and a table in which every analysis appears to have removed nothing, while the script still
# exits 0 on the race check alone. Refuse instead.
[ -x "$OBJDUMP" ] || { echo "no llvm-objdump at $OBJDUMP; the instrumentation counts below would all read 0"; exit 2; }
out="$ART_RESULTS/minimal-example-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$out"
src="$here/scripts/minimal"

# name  source  paper-section  flags
CASES=(
  "STC   stc.c  §4.1 -mllvm -tsan-use-single-threaded"
  "SWMR  swmr.c §4.2 -mllvm -tsan-use-swmr"
  "LO    lo.c   §4.3 -mllvm -tsan-use-lock-ownership"
  "EA    ea.c   §4.4 -mllvm -tsan-use-escape-analysis-global"
  "DE    de.c   §5   -mllvm -tsan-use-dominance-analysis"
)
ALLOPT="-mllvm -tsan-use-single-threaded -mllvm -tsan-use-swmr -mllvm -tsan-use-lock-ownership -mllvm -tsan-use-escape-analysis-global -mllvm -tsan-use-dominance-analysis"

count_instr() { "$OBJDUMP" -d "$1" | grep -cE 'call.*<__tsan_(read|write|unaligned_read|unaligned_write)[0-9]+' || true; }

echo "Compiler: $("$CC" --version | head -1)"
echo "Results:  $out"
echo
printf '%-5s %-8s %-8s %8s %8s %8s\n' analysis program section stock enabled removed
for c in "${CASES[@]}"; do
  read -r name file sec flags <<<"$c"
  "$CC" -O2 -g -fsanitize=thread "$src/$file" -o "$out/$name-stock" -lpthread
  # shellcheck disable=SC2086
  "$CC" -O2 -g -fsanitize=thread $flags "$src/$file" -o "$out/$name-on" -lpthread
  s=$(count_instr "$out/$name-stock"); e=$(count_instr "$out/$name-on")
  printf '%-5s %-8s %-8s %8s %8s %8s\n' "$name" "$file" "$sec" "$s" "$e" "$((s-e))"
  # The table is the step's headline claim, so it is asserted and not merely printed. A stock build
  # with no instrumentation at all means the counter is not counting; an analysis that removed nothing
  # means the claim this row makes is not true here. Either is a failure of this step.
  [ "$s" -gt 0 ] || { echo "  $name: the stock build shows no instrumentation at all, so the counter is not counting" >&2; bad=1; }
  [ "$((s-e))" -gt 0 ] || { echo "  $name: this analysis removed nothing, which is what this row claims it does" >&2; bad=1; }
done
[ "${bad:-0}" = 0 ] || { echo "the instrumentation table above does not support what this step claims" >&2; exit 1; }
echo
echo "Each row counts calls to __tsan_read*/__tsan_write* in the whole binary (the program's own"
echo "accesses plus libc glue); 'removed' is what that analysis eliminated. Read the comment at the"
echo "top of each source file for why those accesses cannot race."
echo
echo "Now the race. It must be reported under every configuration:"
"$CC" -O2 -g -fsanitize=thread "$src/race.c" -o "$out/race-stock" -lpthread
# shellcheck disable=SC2086
"$CC" -O2 -g -fsanitize=thread $ALLOPT "$src/race.c" -o "$out/race-allopt" -lpthread
for b in race-stock race-allopt; do
  if TSAN_OPTIONS="exitcode=0" "$out/$b" 2>"$out/$b.log" >/dev/null && grep -q 'WARNING: ThreadSanitizer: data race' "$out/$b.log"; then
    printf '  %-12s data race reported (%s)\n' "$b" "$(grep -m1 -oE 'Write of size [0-9]+ at 0x[0-9a-f]+ by (main )?thread( T[0-9]+)?' "$out/$b.log" | head -1)"
  else
    printf '  %-12s NO REPORT -- this is a failure\n' "$b"; exit 1
  fi
done
echo
echo "Full reports are in $out/*.log. Done."
