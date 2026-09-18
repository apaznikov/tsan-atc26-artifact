#!/bin/bash
# evaluate.sh -- the artifact in one command, one tier per badge.
#
#   ./evaluate.sh                      Functional: prerequisites, the image, the minimal example, the full
#                                      correctness set, the tables. About 2 hours on any x86-64 Linux host
#                                      with Docker (15 minutes of it the image build the first time).
#   ./evaluate.sh --quick              The same in about 20 minutes, without the regression suite.
#   ./evaluate.sh reproduced           Functional, then the performance subset: Redis, memcached, FFmpeg and
#                                      SQLite at the defaults (four configurations, two runs). About 4 hours.
#                                      Needs 32 or more processors and a machine that is otherwise idle.
#   ./evaluate.sh everything           Reproduced, plus MySQL and all fourteen configurations. About 14 hours.
#   ./evaluate.sh <tier> --plan        Print the steps and the expected time, run nothing.
#
# Why three tiers and not one command for all of it: the correctness set runs anywhere in two hours; the
# performance set runs only on a quiet, large machine and takes four to fourteen hours, which is a decision
# a person makes; the badges are awarded separately; and a fourteen-hour command that fails in its ninth
# hour is worse than steps that can be repeated one at a time. Every step below is one of the scripts the
# README documents, called in the documented order; this file adds nothing else.
#
# Options: --quick (Functional without the regression suite), --plan (print and exit), --yes (no
# confirmation before the multi-hour tiers), --rebuild (build the image even if one exists).
# Environment: ART_CPUSET (pin the performance runs; our runs used 48 processors), ART_RUNS (2 by default,
# 5 for intervals), ART_JOBS (derived by env.sh); see env.sh for the rest.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
cd "$here" || exit 2

tier=functional; quick=0; plan=0; yes=0; rebuild=0
for a in "$@"; do
  case "$a" in
    functional|reproduced|everything) tier="$a" ;;
    --quick)   quick=1 ;;
    --plan)    plan=1 ;;
    --yes)     yes=1 ;;
    --rebuild) rebuild=1 ;;
    -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "evaluate.sh: unknown argument '$a' (tiers: functional, reproduced, everything; options: --quick --plan --yes --rebuild)" >&2; exit 2 ;;
  esac
done
[ "$quick" = 1 ] && [ "$tier" != functional ] && { echo "evaluate.sh: --quick applies to the functional tier only" >&2; exit 2; }

# The plan: <label>|<expected time>|<command>. Times are this artifact's own measurements (README).
steps=()
add() { steps+=("$1|$2|$3"); }
add "prerequisites on the host"           "1 min"     "./scripts/00-prereqs.sh"
add "container image (compiler inside)"   "15-25 min" "IMAGE"
add "minimal example"                     "1 min"     "./docker/run.sh scripts/10-minimal-example.sh"
if [ "$quick" = 1 ]; then
  add "correctness set, quick"            "5 min"     "./docker/run.sh scripts/01-functional.sh --quick"
else
  add "correctness set, full"             "31 min on 64 processors, 1 h 45 min on 32, longer on 8" "./docker/run.sh scripts/01-functional.sh"
fi
add "tables from the shipped runs"        "1 min"     "./docker/run.sh scripts/90-tables.sh"
if [ "$tier" != functional ]; then
  all=""; [ "$tier" = everything ] && all=" --all-configs"
  add "performance: Redis"     "15 min${all:+ (all configurations: 1 h)}"        "./docker/run.sh scripts/40-perf.sh redis$all"
  add "performance: memcached" "30 min${all:+ (all configurations: 2 h)}"        "./docker/run.sh scripts/40-perf.sh memcached$all"
  add "performance: FFmpeg"    "25 min plus the clip's first download${all:+ (all configurations: 1.2 h)}" "./docker/run.sh scripts/40-perf.sh ffmpeg$all"
  add "performance: SQLite"    "1 h${all:+ (all configurations: 3.4 h)}"          "./docker/run.sh scripts/40-perf.sh sqlite$all"
  [ "$tier" = everything ] && add "performance: MySQL" "3.5 h plus a 10-minute build per configuration" "./docker/run.sh scripts/40-perf.sh mysql"
fi

total=$(case "$tier:$quick" in functional:1) echo "about 20 minutes, plus the image build the first time";;
  functional:0) echo "about 2 hours, plus the image build the first time";;
  reproduced:*) echo "about 4 hours, plus the image build";;
  everything:*) echo "about 14 hours, plus the image build";; esac)
echo "evaluate.sh: tier '$tier'$( [ "$quick" = 1 ] && echo ' (--quick)'), $total"
i=0; for s in "${steps[@]}"; do i=$((i+1)); IFS='|' read -r label t cmd <<< "$s"; printf '  %2d. %-38s %-44s %s\n' "$i" "$label" "($t)" "${cmd/IMAGE/./docker\/build.sh (skipped if the image exists)}"; done
[ "$plan" = 1 ] && exit 0

if [ "$tier" != functional ]; then
  echo
  echo "The performance tier needs 32 or more processors and a machine on which nothing else runs: the"
  echo "disturbance gate retires every cell measured under foreign load (docs/confounds.md)."
  # Our intervals describe a 48-processor pinned set, and the workload's thread counts follow from the
  # set's size (docs/campaign-parameters.md). So, unless the caller chose a set, pin the first 48
  # processors when the machine has them: the run is then gate-checked and its thread counts equal ours.
  # A smaller machine runs unpinned, not gate-checked, and its rows are reported with their thread
  # counts rather than compared. Topology (which 48, hyperthread siblings) is the caller's to refine.
  if [ -z "${ART_CPUSET:-}" ]; then
    ncpu_here=$(nproc 2>/dev/null || echo 0)
    if [ "$ncpu_here" -ge 48 ]; then
      export ART_CPUSET="0-47"
      echo "ART_CPUSET not set: pinning the first 48 of $ncpu_here processors (ART_CPUSET=0-47) so the run is"
      echo "gate-checked and its thread counts match ours; set ART_CPUSET yourself to choose which 48."
    else
      echo "ART_CPUSET not set and only $ncpu_here processors: the run uses every processor the container sees,"
      echo "is not gate-checked, and its rows carry their own thread counts (not comparable with our 48-set intervals)."
    fi
  else
    echo "ART_CPUSET=$ART_CPUSET (our runs used 48 processors)."
  fi
  if [ "$yes" != 1 ]; then
    printf 'Start now? [y/N] '; read -r ans; case "$ans" in y|Y|yes) ;; *) echo "not started"; exit 0;; esac
  fi
fi

mkdir -p results
log="results/evaluate-$tier-$(date +%Y%m%d-%H%M%S).log"
echo "log: $log"; echo
start_all=$(date +%s); verdict=PASS; failed=""; compared=""
i=0
for s in "${steps[@]}"; do
  i=$((i+1)); IFS='|' read -r label t cmd <<< "$s"
  if [ "$cmd" = IMAGE ]; then
    if [ "$rebuild" != 1 ] && docker image inspect tsan-atc26 >/dev/null 2>&1; then
      printf '%2d. %-38s skipped: image tsan-atc26 exists (use --rebuild to build it again)\n' "$i" "$label"; continue
    fi
    cmd="./docker/build.sh"
  fi
  printf '%2d. %-38s started %s, expected %s\n' "$i" "$label" "$(date +%H:%M:%S)" "$t"
  t0=$(date +%s)
  step_out="$log.step"
  { echo "=== $label: $cmd"; bash -c "$cmd"; } > "$step_out" 2>&1; rc=$?
  cat "$step_out" >> "$log"
  dt=$(( $(date +%s) - t0 ))
  printf '    %-38s rc=%d  %dm%02ds\n' "$label" "$rc" $((dt/60)) $((dt%60))
  # A skipped check is neither a pass nor a failure, and it must not be reported as a pass: 01-functional
  # prints "the correctness set is INCOMPLETE" when a step's prerequisite is absent and exits 0, because
  # nothing failed. The first version of this script tested the text only on a non-zero exit and reported
  # PASS over an INCOMPLETE set (found on a second server, 18 Sep 2026). The test is on THIS step's output.
  if /usr/bin/grep -q 'correctness set is INCOMPLETE' "$step_out"; then
    [ "$verdict" = FAIL ] || verdict=INCOMPLETE
    echo "    INCOMPLETE: a check could not be made here and was skipped (its prerequisite is absent); see $log"
  fi
  if [ "$rc" -ne 0 ] && ! /usr/bin/grep -q 'correctness set is INCOMPLETE' "$step_out"; then
    verdict=FAIL; failed="$label"; echo "    FAILED; the last lines of its output:"; tail -15 "$step_out" | sed 's/^/      /'; rm -f "$step_out"; break
  fi
  rm -f "$step_out"
done
# The performance tiers end with the comparison an evaluator came for: every row this run produced
# against the interval CLAIMS.md ships for it. The script reads the intervals out of CLAIMS.md's own
# tables and the expected thread counts out of the shipped campaign runs, so nothing is hardcoded; its
# silence is never a pass, six of its nine output states are refusals, and its "rows judged" line is
# the one to read first. A judged row outside its interval is reported as such, not as a failure of
# the artifact's plumbing, and the exit status carries it.
if [ "$tier" != functional ] && [ "$verdict" != FAIL ]; then
  trees=$(find results -maxdepth 1 -name 'perf-*' -newermt "@$start_all" | sort | tr '\n' ' ')
  if [ -n "$trees" ]; then
    echo
    echo "Comparison with the intervals in CLAIMS.md (section 5):"
    ./docker/run.sh python3 harness/tools/perf/compare_with_claims.py CLAIMS.md $trees 2>&1 | tee -a "$log"
    cmp_rc=${PIPESTATUS[0]}
    [ "$cmp_rc" -eq 0 ] || compared=OUTSIDE
  fi
fi
dt=$(( $(date +%s) - start_all ))
echo
{
echo "evaluate.sh: $verdict${compared:+, rows $compared their intervals}  (tier $tier, $((dt/3600))h$(( (dt%3600)/60 ))m; full log in $log)"
case "$verdict" in
  PASS) echo "Every step ran and passed. For what each step established, read CLAIMS.md; the performance rows compare against its intervals." ;;
  INCOMPLETE) echo "Nothing failed, but a check could not be made here (its prerequisite is absent); the log names it. A skipped check is neither a pass nor a failure." ;;
  FAIL) echo "Stopped at: $failed. docs/troubleshooting.md lists the failures we know; the log has the rest." ;;
esac
[ -n "${compared:-}" ] && echo "At least one judged performance row lies outside the shipped interval; CLAIMS.md section 5 says what such a row can and cannot mean."
} | tee -a "$log"    # the verdict goes into the log too: a log that ends without it answers a different question
[ "$verdict" = PASS ] && [ -z "${compared:-}" ]
