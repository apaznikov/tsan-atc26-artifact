#!/usr/bin/env bash
# The correctness set: everything that can be checked without measuring performance, in order, with
# one verdict at the end. This is the path for the Functional badge; nothing here depends on the
# machine, and the results are identical on any x86-64 Linux host.
#
#   scripts/01-functional.sh            all of it: 23 min on 64 processors, 30 min on 112, 48 min on 8 (measured)
#   scripts/01-functional.sh --quick    everything except the regression suite, about 2 to 5 minutes
#
# Run it inside the container: docker/run.sh scripts/01-functional.sh
# It stops at the first failure, because every later step assumes the compiler is the one it claims.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/scripts/_lib.sh"

quick=0
for a in "$@"; do case "$a" in
  --quick) quick=1 ;;
  *) echo "$(basename "$0") takes --quick or nothing (got: $a)"; exit 2 ;;
esac; done

steps=(
  "10-minimal-example.sh|each analysis removes the instrumentation it claims, and a real race is still reported"
  "11-soundness-shapes.sh|the 23 lost-race shapes stay instrumented, and every claimed removal is one the test can detect"
  "12-compiler-equivalence.sh|this compiler emits what the measured compiler emitted, on 112 corpus rows"
  "91-verify-provenance.sh|every shipped run records the conditions it was taken under"
  "14-tool-copies.sh|the table-regeneration path runs the same code as the measurement path"
  "15-verdict-rules.sh|the rule that decides a lost race can say LOST, and refrains one run short of it"
)
[ "$quick" = 1 ] || steps+=(
  "30-preservation-suite.sh --self-test|the preservation harness can detect a lost race at all"
  "30-preservation-suite.sh 5|no configuration loses a race that stock ThreadSanitizer reports"
)
steps+=( "90-tables.sh|every table in the paper follows from the shipped runs" )

if [ "$quick" = 1 ]; then budget "the quick correctness set (${#steps[@]} steps, no regression suite)" "2 min" "1 min" "2 GB"
else budget "the correctness set (${#steps[@]} steps)" "48 min" "25 min (23 min on 64)" "2 GB"; fi
printf '\n'
declare -a verdict; skipped=0
for spec in "${steps[@]}"; do
  s="${spec%%|*}"; what="${spec#*|}"
  printf '=== %s\n    %s\n' "$s" "$what"
  # shellcheck disable=SC2086
  bash "$here/scripts/"$s; rc=$?
  case "$rc" in
    0) verdict+=("PASS  $s") ;;
    # Every script in this artifact exits 2 when it cannot run here at all -- a missing compiler, a
    # harness that has not been vendored. That is not a failed check: it is a check not made, and it
    # is recorded as such rather than counted either way.
    2) verdict+=("SKIP  $s -- prerequisite absent, see its message above"); skipped=$((skipped+1)) ;;
    *) verdict+=("FAIL  $s (exit $rc)")
       printf '\n'; printf '%s\n' "${verdict[@]}"
       printf '\nSTOPPED at %s. Every later step assumes what this one checks.\n' "$s" >&2
       exit 1 ;;
  esac
  printf '\n'
done
printf '%s\n' "${verdict[@]}"
if [ "$skipped" -gt 0 ]; then
  printf '\nNothing failed, but %d step(s) could not run here, so the correctness set is INCOMPLETE.\n' "$skipped"
  printf 'A skipped step is a check not made. Satisfy its prerequisite and run this again.\n'
else
  if [ "$quick" = 1 ]; then printf '\nThe quick correctness set passed: every step above, without the regression suite (the Functional tier is the full set).\n'
  else printf '\nThe correctness set passed, in full.\n'; fi
fi
printf 'What it does NOT cover: performance (scripts/40-perf.sh and CLAIMS.md section 5), which compares\nwith our intervals only on 48 pinned processors and a quiet machine.\n'
