#!/bin/bash
# evaluate.sh -- the artifact in one command per badge. Name the tier:
#
#   ./evaluate.sh check          Does it all run here? Prerequisites, the image (built the first time, 15-25 min),
#                                the image's identity, the minimal example, the correctness set without the
#                                regression suite, the tables. About 2 minutes once the image exists. Not a badge:
#                                the kick-the-tires check.
#   ./evaluate.sh functional     The Functional badge: everything in check, plus the regression suite in 12
#                                configurations. Under an hour on any x86-64 Linux host with Docker (23 min on
#                                64 processors, 48 min on 8).
#   ./evaluate.sh reproduced     The Reproduced badge: the whole functional tier first, then the performance
#                                subset, Redis, memcached, FFmpeg and SQLite at the defaults (four configurations,
#                                two runs), compared with the intervals CLAIMS.md ships. About 3 hours (2 h 38 min
#                                measured on our host). Runs on any processor count; the comparison with our
#                                intervals needs the campaign's shape pinned, 24 physical cores with both SMT
#                                threads (48 logical processors, chosen here when the machine has them), and a
#                                machine that is otherwise idle.
#   ./evaluate.sh everything     reproduced at all fourteen configurations, plus MySQL. About 14 hours.
#
# Each tier contains the one before it, so one command per badge is the whole job. Without a tier name this
# script prints this text and runs nothing.
#
# Options: --plan (print the tier's steps and expected times, run nothing), --yes (accepted and ignored: nothing
# asks a question, a tier starts when named), --rebuild (build the image again from nothing,
# without Docker's layer cache, which is the only build that re-runs the reconstructed-tree assertion; 15-25 min),
# --performance-only (reproduced or everything without repeating the functional tier, for a checkout on which
# ./evaluate.sh functional already ended in PASS; about 2 h 30 min for reproduced). --quick is the old name of check.
#
# Why tiers and not one command for all of it: the correctness set runs anywhere in under an hour; the performance
# set runs only on a quiet, large machine and takes hours (about 2.5 for the subset, 14 for everything), which is
# a decision a person makes; the badges are awarded separately; and a fourteen-hour command that fails in its
# ninth hour is worse than steps that can be repeated one at a time. Every step is one of the scripts the
# README documents, called in the documented order; this file adds nothing else.
# Environment: ART_CPUSET (pin the performance runs; our runs used 48 processors; unset, the script pins 48 of
# the processors the Docker daemon grants when there are that many), ART_RUNS (2 by default, 5 for intervals),
# ART_FFMPEG_CLIP_URL (the reference clip; without it FFmpeg's rows are timed but not compared), ART_JOBS
# (derived by env.sh); see env.sh for the rest.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
cd "$here" || exit 2

tier=""; quick=0; plan=0; yes=0; rebuild=0; perf_only=0
usage() { awk 'NR == 1 { next } /^set -uo pipefail/ { exit } { sub(/^# ?/, ""); print }' "$here/evaluate.sh"; }
for a in "$@"; do
  case "$a" in
    check|functional|reproduced|everything) tier="$a" ;;
    --quick)   quick=1 ;;   # the old name of check
    --plan)    plan=1 ;;
    --yes)     yes=1 ;;
    --rebuild) rebuild=1 ;;
    --performance-only) perf_only=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "evaluate.sh: unknown argument '$a' (tiers: check, functional, reproduced, everything; options: --plan --yes --rebuild --performance-only)" >&2; exit 2 ;;
  esac
done
if [ "$quick" = 1 ]; then
  case "$tier" in ""|check|functional) tier=check ;; *) echo "evaluate.sh: --quick is the old name of the check tier and does not combine with $tier" >&2; exit 2 ;; esac
fi
if [ -z "$tier" ]; then
  # No silent default: a bare ./evaluate.sh runs nothing, so the command always names what it runs.
  usage; echo; echo "evaluate.sh: name the tier: check | functional | reproduced | everything. Nothing was run." >&2; exit 2
fi
perf_tier=0; case "$tier" in reproduced|everything) perf_tier=1 ;; esac
[ "$perf_only" = 1 ] && [ "$perf_tier" != 1 ] && { echo "evaluate.sh: --performance-only applies to the reproduced and everything tiers" >&2; exit 2; }

# The plan: <label>|<expected time>|<command>. Times are this artifact's own measurements (README).
steps=()
add() { steps+=("$1|$2|$3"); }
add "prerequisites on the host"           "1 min"     "./scripts/00-prereqs.sh"
add "container image (compiler inside)"   "15-25 min" "IMAGE"
if [ "$perf_only" != 1 ]; then
  # On the host, since it starts its own container: the image's clang is our commit, self-contained, and the
  # patch series reproduced our source tree (read from the build log that docker/build.sh keeps).
  add "image verification (host)"         "1 min"     "./scripts/13-verify-image.sh --static"
fi
if [ "$perf_only" != 1 ]; then
  add "minimal example"                   "under a minute" "./docker/run.sh scripts/10-minimal-example.sh"
  if [ "$tier" = check ]; then
    add "correctness set, quick"          "2-5 min"   "./docker/run.sh scripts/01-functional.sh --quick"
  else
    add "correctness set, full"           "23 min on 64 processors, 48 min on 8" "./docker/run.sh scripts/01-functional.sh"
  fi
  add "tables from the shipped runs"      "1 min"     "./docker/run.sh scripts/90-tables.sh"
fi
if [ "$perf_tier" = 1 ]; then
  all=""; [ "$tier" = everything ] && all=" --all-configs"
  add "performance: Redis"     "15 min${all:+ (all configurations: 1 h)}"        "./docker/run.sh scripts/40-perf.sh redis$all"
  add "performance: memcached" "30 min${all:+ (all configurations: 2 h)}"        "./docker/run.sh scripts/40-perf.sh memcached$all"
  add "performance: FFmpeg"    "about 25 min for five configurations, plus the clip's first download${all:+ (all configurations: 1.2 h)}" "./docker/run.sh scripts/40-perf.sh ffmpeg$all"
  add "performance: SQLite"    "1 h${all:+ (all configurations: 3.4 h)}"          "./docker/run.sh scripts/40-perf.sh sqlite$all"
  [ "$tier" = everything ] && add "performance: MySQL" "3.5 h plus a 10-minute build per configuration" "./docker/run.sh scripts/40-perf.sh mysql"
fi

total=$(case "$tier:$perf_only" in
  check:*)      echo "about 2 minutes, plus the image build the first time (15-25 min)";;
  functional:*) echo "under an hour (23 min on 64 processors, 48 min on 8), plus the image build the first time";;
  reproduced:1) echo "about 2 h 30 min, plus the image build the first time";;
  reproduced:*) echo "about 3 hours, plus the image build the first time";;
  everything:1) echo "about 12 hours, plus the image build the first time";;
  everything:*) echo "about 14 hours, plus the image build the first time";; esac)
describe=$(case "$tier" in
  check)      echo "check (not a badge): does it all run here";;
  functional) echo "the Functional tier: the correctness set";;
  reproduced) echo "the Reproduced tier = the whole Functional tier, then the performance subset";;
  everything) echo "everything = the Reproduced tier at all fourteen configurations, plus MySQL";; esac)
echo "evaluate.sh: $describe$( [ "$perf_only" = 1 ] && echo ' (--performance-only: the Functional tier not repeated)'); $total"
i=0; for s in "${steps[@]}"; do i=$((i+1)); IFS='|' read -r label t cmd <<< "$s"; printf '  %2d. %-38s %-44s %s\n' "$i" "$label" "($t)" "${cmd/IMAGE/./docker\/build.sh (skipped if the image exists)}"; done
[ "$plan" = 1 ] && exit 0

autopin=0
if [ "$perf_tier" = 1 ]; then
  echo
  echo "Four things to know about the performance tier (it starts right after them; --plan lists the steps without starting):"
  echo "  1. Machine. Any processor count runs. The comparison with our intervals is made on the campaign's shape,"
  echo "     24 physical cores with both SMT threads of each pinned (48 logical processors; memcached's thread count"
  echo "     follows the logical count; with fewer, its rows are reported, not judged), and on a machine on which"
  echo "     nothing else runs: the disturbance gate retires every cell measured under foreign load (docs/confounds.md)."
  # Our intervals describe 24 physical cores with both SMT siblings (48 logical, 4-27 and 60-83 on our host,
  # siblings n and n+56), and the workload's thread counts follow from the logical count
  # (docs/campaign-parameters.md). So, unless the caller chose a set, pin that shape when the machine has it:
  # the first 24 complete sibling pairs among the processors the Docker daemon actually grants to containers
  # (asked of the image once it exists, because a daemon confined by systemd grants fewer than the host has,
  # and a request outside the grant is clipped). The first 48 granted would be 4-51 on our host: 48 distinct
  # cores with no SMT contention, twice the campaign's compute under the same logical count. Without 24 such
  # pairs, the first 48 granted, labelled as a different shape.
  # A smaller machine runs unpinned, not gate-checked, memcached's rows reported rather than compared.
  if [ -z "${ART_CPUSET:-}" ]; then
    ncpu_here=$(nproc 2>/dev/null || echo 0)
    if [ "$ncpu_here" -ge 48 ]; then
      autopin=1
      echo "     ART_CPUSET not set: once the image exists, the run pins the campaign's shape from the processors the"
      echo "     Docker daemon grants to containers, the first 24 complete SMT sibling pairs (48 logical), and prints"
      echo "     the set; on a machine without 24 such pairs, the first 48 granted, printed as a different shape."
      echo "     Set ART_CPUSET to choose the set yourself."
    else
      echo "     ART_CPUSET not set and $ncpu_here processors here (fewer than 48): the run uses every processor the"
      echo "     container sees and is not gate-checked. Its processor-set shape differs from the campaign's (24 cores"
      echo "     with both SMT threads), so every row is reported with its ratio against stock and the reason, and none"
      echo "     is judged: the tier then ends 'COMPARISON NOT APPLICABLE ON THIS MACHINE', which is not a failure."
    fi
  else
    echo "     ART_CPUSET=$ART_CPUSET (our runs used 48 processors, 4-27 and 60-83 on our host)."
  fi
  echo "  2. Names. The tables use the harness's configuration names: orig = native, no ThreadSanitizer; tsan ="
  echo "     stock ThreadSanitizer; tsan-dom_peeling-ea-lo-st-swmr = AllOpt with peeling, the paper's AllOpt;"
  echo "     tsan-stmt = DynSTC. Each configuration row is a ratio against tsan: above 1.0 is faster than stock."
  if [ -n "${ART_FFMPEG_CLIP_URL:-}" ]; then
    echo "  3. FFmpeg. The reference clip is fetched from the artifact's GitHub release (78 MB) and verified by sha256,"
    echo "     so its rows are compared. Export ART_FFMPEG_CLIP_URL= (empty) to regenerate it from the Blender source"
    echo "     (557 MB) instead; those rows are then 'not comparable' by design (docs/ffmpeg-input.md)."
  else
    echo "  3. FFmpeg. ART_FFMPEG_CLIP_URL is empty: the run regenerates the input from the Blender source (557 MB), its"
    echo "     timings are valid, and its three rows print 'not comparable' by design (docs/ffmpeg-input.md)."
  fi
  echo "  4. The end. The tier ends with one line per configuration row of this run against the interval CLAIMS.md"
  echo "     ships for it (IN; OUT with the distance; not judged; not comparable) and 'N rows judged'. What an OUT"
  echo "     row can mean, and the five-run re-check for it, is CLAIMS.md section 5, 'Match criterion'."
  # No question: a reader who named a tier meant it, --plan exists for looking first, and a prompt breaks
  # every run under nohup, tmux scripts and CI. --yes is accepted and ignored.
  : "$yes"
fi

# The campaign's shape from the processors the daemon grants to containers: the first 24 complete SMT
# sibling pairs (48 logical); failing that, the first 48 granted, labelled. Prints "<set><TAB><shape>";
# nothing when fewer than 48 are granted. Sibling pairs come from the host's sysfs, which the container
# shares.
expand_cpus() { tr ',' '\n' | awk -F- '{ if ($2 == "") print $1; else for (i = $1; i <= $2; i++) print i }' | sort -n; }
compress_cpus() {  # sorted list on stdin -> range list
  awk 'NR == 1 { s = $1; p = $1; next }
       $1 == p + 1 { p = $1; next }
       { out = out (out == "" ? "" : ",") (s == p ? s : s "-" p); s = $1; p = $1 }
       END { if (NR) print out (out == "" ? "" : ",") (s == p ? s : s "-" p) }'
}
resolve_autopin() {
  local granted list c sib a b n=0 used=" " pairs="" chosen shape cores
  granted=$(docker run --rm "${ART_IMAGE:-tsan-atc26}" bash -c 'grep Cpus_allowed_list /proc/self/status | cut -f2' 2>/dev/null || true)
  [ -n "$granted" ] || granted="0-$(( $(nproc 2>/dev/null || echo 1) - 1 ))"
  list=$(printf '%s' "$granted" | expand_cpus)
  [ "$(printf '%s\n' "$list" | wc -l)" -ge 48 ] || return 0
  for c in $list; do
    case "$used" in *" $c "*) continue ;; esac
    sib=$(cat "/sys/devices/system/cpu/cpu$c/topology/thread_siblings_list" 2>/dev/null | expand_cpus | tr '\n' ' ')
    set -- $sib
    [ $# -eq 2 ] || continue
    a=$1; b=$2
    { printf '%s\n' "$list" | grep -qx "$a" && printf '%s\n' "$list" | grep -qx "$b"; } || continue
    pairs="$pairs $a $b"; used="$used $a $b "; n=$((n+1))
    [ "$n" -eq 24 ] && break
  done
  if [ "$n" -eq 24 ]; then
    chosen=$(printf '%s\n' $pairs | sort -n | compress_cpus)
    shape="24 physical cores with both SMT threads of each (48 logical processors), the campaign's shape"
  else
    chosen=$(printf '%s\n' "$list" | head -48 | compress_cpus)
    cores=$(for c in $(printf '%s\n' "$list" | head -48); do echo "$(cat /sys/devices/system/cpu/cpu$c/topology/physical_package_id 2>/dev/null):$(cat /sys/devices/system/cpu/cpu$c/topology/core_id 2>/dev/null)"; done | sort -u | wc -l)
    shape="48 logical processors on $cores physical cores: NOT the campaign's shape (24 cores with both SMT threads), so the rows are labelled with it and the memcached rows are not compared"
  fi
  printf '%s\t%s' "$chosen" "$shape"
}

mkdir -p results
log="results/evaluate-$tier-$(date -u +%Y%m%d-%H%M%S).log"
echo "log: $log  (the stamp is UTC, like the results directories written inside the container)"; echo
start_all=$(date +%s); verdict=PASS; failed=""; compared=""
i=0
for s in "${steps[@]}"; do
  i=$((i+1)); IFS='|' read -r label t cmd <<< "$s"
  if [ "$cmd" = IMAGE ]; then
    if [ "$rebuild" != 1 ] && docker image inspect tsan-atc26 >/dev/null 2>&1; then
      printf '%2d. %-38s skipped: image tsan-atc26 exists (use --rebuild to build it again)\n' "$i" "$label"; continue
    fi
    cmd="./docker/build.sh"; [ "$rebuild" = 1 ] && cmd="./docker/build.sh --no-cache"
  fi
  if [ "$autopin" = 1 ] && [ -z "${ART_CPUSET:-}" ] && [[ "$cmd" == *40-perf.sh* ]]; then
    IFS=$'\t' read -r set48 shape48 <<< "$(resolve_autopin)"
    if [ -n "$set48" ]; then
      export ART_CPUSET="$set48"
      echo "    pinning ART_CPUSET=$set48: $shape48" | tee -a "$log"
    else
      autopin=0
      echo "    the Docker daemon grants fewer than 48 processors to containers: running unpinned, not gate-checked"
    fi
  fi
  printf '%2d. %-38s started %s, expected %s\n' "$i" "$label" "$(date +%H:%M:%S)" "$t"
  t0=$(date +%s)
  step_out="$log.step"
  case "$t" in "1 min"|"under a minute"|"2-5 min") ;; *)
    echo "    follow it: tail -f $step_out   (the console shows the step's output when it ends)" ;;
  esac
  # LIVE PROGRESS. The step's full output goes to the step file and the log; the lines that say what is
  # happening (a sub-step's verdict, a build starting or failing, a measured cell, an image layer, a fetch)
  # are echoed to the console as they appear, prefixed with a bar, so a reader watching a two-hour step sees
  # it move and sees what it is doing. Everything else
  # stays in the log.
  : > "$step_out"
  { echo "=== $label: $cmd"; bash -c "$cmd"; } > "$step_out" 2>&1 & steppid=$!
  # The reader follows the step's own process (tail --pid) and ends by itself when the step ends; killing
  # a subshell around the pipeline would leave tail, grep and sed alive on a deleted file and hold the
  # console open for whoever was piping this script.
  tail -n +1 -F --pid="$steppid" "$step_out" 2>/dev/null \
      | grep --line-buffered -E '^(PASS|FAIL|SKIP)  |^== |^Expected:|^ *configurations RUN|^  [A-Za-z+-]+ +always-fail=|^\[[0-9-]+ [0-9:]+\] .*( run[0-9]+ rc=| build |BUILD FAILED|builds of |done: |ERROR|-> )|^#[0-9]+ (\[|DONE)|^fetch_archive:|^ensure_input_clip:|^  (ok|FAIL|MISSING|WARNING|later) |^(analysis|STC|SWMR|LO|EA|DE) |^  race-|^app  |^[a-z]+  +(AllOpt|DynSTC|DE|EA|LO|STC|SWMR|four|stock)|rows judged|replayed |Regenerating|identical to the shipped' \
      | sed -u 's/^/      | /' & readerpid=$!
  wait "$steppid"; rc=$?
  wait "$readerpid" 2>/dev/null || true
  cat "$step_out" >> "$log"
  dt=$(( $(date +%s) - t0 ))
  printf '    %-38s rc=%d  finished %s, %dm%02ds elapsed\n' "$label" "$rc" "$(date +%H:%M:%S)" $((dt/60)) $((dt%60))
  # A skipped check is neither a pass nor a failure, and it must not be reported as a pass: 01-functional
  # prints "the correctness set is INCOMPLETE" when a step's prerequisite is absent and exits 0, because
  # nothing failed. Testing the text only on a non-zero exit would report PASS over an INCOMPLETE set.
  # The test is on THIS step's output.
  if /usr/bin/grep -q 'correctness set is INCOMPLETE' "$step_out"; then
    [ "$verdict" = FAIL ] || verdict=INCOMPLETE
    echo "    INCOMPLETE: a check could not be made here and was skipped (its prerequisite is absent); see $log"
  fi
  # The tree assertion is printed only by an uncached image build, so an image built before this checkout
  # kept build logs (or with a warm layer cache) leaves that check unmade: neither a pass nor a failure.
  if /usr/bin/grep -q 'SKIP  patch series reproduced tree' "$step_out"; then
    [ "$verdict" = FAIL ] || verdict=INCOMPLETE
    echo "    INCOMPLETE: the image tsan-atc26 on this machine was built from an earlier checkout, before the build"
    echo "    stamped its source-tree hash into the image, so that check cannot be made from it. Every other step"
    echo "    runs. ./evaluate.sh $tier --rebuild builds the image again from nothing (15-25 min) and stamps it."
  fi
  if [ "$rc" -ne 0 ]; then
    verdict=FAIL; failed="$label"; echo "    FAILED; the last lines of its output:"; tail -15 "$step_out" | sed 's/^/      /'; rm -f "$step_out"; break
  fi
  # A clipped or refused processor set is the one warning a reviewer must see at once, not after hours.
  /usr/bin/grep -h 'docker/run.sh: ART_CPUSET' "$step_out" | sed 's/^/    /' || true
  # What the step said, on the console as well as in the log: a short output in full (the minimal
  # example's table, the correctness set's per-step verdicts); a long one was followed live above, and its
  # closing lines are repeated here so the verdict sentences are not lost among the progress lines.
  n=$(wc -l < "$step_out")
  if [ "$n" -le 30 ]; then sed 's/^/      /' "$step_out"
  else echo "      ... last 6 of $n lines (all of them in the log):"; tail -6 "$step_out" | sed 's/^/      /'; fi
  rm -f "$step_out"
done
# The performance tiers end with the comparison an evaluator came for: every row this run produced
# against the interval CLAIMS.md ships for it. The script reads the intervals out of CLAIMS.md's own
# tables and the expected thread counts out of the shipped campaign runs, so nothing is hardcoded; its
# silence is never a pass, six of its nine output states are refusals, and its "rows judged" line is
# the one to read first. A judged row outside its interval is reported as such, not as a failure of
# the artifact's plumbing, and the exit status carries it.
if [ "$perf_tier" = 1 ] && [ "$verdict" != FAIL ]; then
  # results/ literally, with a trailing slash: docker/run.sh always mounts ./results (ART_RESULTS does not cross
  # the container boundary), and a symlinked results/ pointing at a larger disk is followed only with the slash.
  trees=$(find results/ -maxdepth 1 -name 'perf-*' -newermt "@$start_all" 2>/dev/null | sort | tr '\n' ' ')
  if [ -z "$trees" ]; then
    # The comparison is why this tier exists. If the run produced no performance tree to compare, that
    # is a failure of the tier and not a silent skip: without this the whole tier could report PASS
    # having compared nothing at all.
    echo
    echo "No performance results were produced by this run, so nothing could be compared with CLAIMS.md."
    echo "Looked for directories named perf-* under results/ created after the run began."
    verdict=FAIL; failed="the performance tier produced no results to compare"
  fi
  if [ -n "$trees" ]; then
    echo
    echo "Comparison with the intervals in CLAIMS.md (section 5):"
    ./docker/run.sh python3 harness/tools/perf/compare_with_claims.py CLAIMS.md $trees 2>&1 | tee -a "$log"
    cmp_rc=${PIPESTATUS[0]}
    # 0: every judged row inside. 2: nothing could be compared for a machine reason (the processor-set shape,
    # a thread count, the input) and nothing was outside: the run is valid and unjudged, which is not a failure
    # and not a pass. Anything else: a judged row outside, no table / no shipped data to compare with, or 64, the
    # comparator's usage error (cannot happen here: it is called only with trees), read as not clean on purpose.
    case "$cmp_rc" in 0) ;; 2) compared=NOTAPPLICABLE;; *) compared=OUTSIDE;; esac
  fi
fi
dt=$(( $(date +%s) - start_all ))
echo
{
if [ "$dt" -ge 3600 ]; then took="$((dt/3600))h$(( (dt%3600)/60 ))m"; else took="$((dt/60))m$(printf %02d $((dt%60)))s"; fi
where="(tier $tier, $took; full log in $log)"
if [ "$verdict" = PASS ] && [ "${compared:-}" = NOTAPPLICABLE ]; then
  echo "evaluate.sh: PASS on every step; COMPARISON NOT APPLICABLE ON THIS MACHINE  $where"
  echo "Every step ran and passed. No performance row could be compared with our intervals, for the reason each row"
  echo "prints (this machine's processor-set shape, thread count or input is not the campaign's); the run is a valid"
  echo "measurement and its ratios stand beside the intervals above, unjudged. To be judged, pin 24 physical cores with"
  echo "both SMT threads (48 logical processors) with ART_CPUSET, as CLAIMS.md section 5 describes. Exit status 3."
elif [ "$verdict" = PASS ] && [ -n "${compared:-}" ]; then
  # Not "PASS, rows outside": every step ran, and the comparison is the tier's question, so the line
  # must say the comparison did not come back clean. The exit status says the same.
  echo "evaluate.sh: PASS on every step, COMPARISON NOT CLEAN  $where"
  echo "Every step ran and passed, and the comparison above did not come back clean: a judged row lies outside"
  echo "its shipped interval, or no row could be judged at all. Its own output says which. CLAIMS.md section 5"
  echo "('Match criterion') says what an outside row can mean and gives the five-run re-check for it."
else
  vline="$verdict"
  # Both facts when both hold: a skipped check and a comparison that did not come back clean are two answers,
  # and the last line must not drop the second.
  [ "$verdict" = INCOMPLETE ] && [ "${compared:-}" = OUTSIDE ] && vline="INCOMPLETE, and COMPARISON NOT CLEAN"
  [ "$verdict" = INCOMPLETE ] && [ "${compared:-}" = NOTAPPLICABLE ] && vline="INCOMPLETE; COMPARISON NOT APPLICABLE ON THIS MACHINE"
  echo "evaluate.sh: $vline  $where"
  case "$verdict" in
    PASS) case "$tier" in
      check)
        echo "Every step ran and passed: the image is our compiler built from the patch series, each analysis removes what it"
        echo "claims and the race is still reported, and the shipped tables follow from the shipped runs. This is the check,"
        echo "not the Functional badge: the regression suite (no configuration loses a race) runs in ./evaluate.sh functional." ;;
      functional)
        echo "Every step ran and passed: the image is our compiler built from the patch series, the analyses, the regression suite and the shipped tables (what"
        echo "each step established is CLAIMS.md sections 1 to 4). This tier says nothing about speed." ;;
      *)
        echo "Every step ran and passed, and every judged performance row lies inside its shipped interval (the table above)." ;;
    esac ;;
    INCOMPLETE) echo "Nothing failed, but a check could not be made here (its prerequisite is absent); the log names it. A skipped check is neither a pass nor a failure."
                [ "${compared:-}" = OUTSIDE ] && echo "And the comparison above did not come back clean: a judged row lies outside its shipped interval, or no row could be judged; CLAIMS.md section 5 ('Match criterion') says what that can mean."
                [ "${compared:-}" = NOTAPPLICABLE ] && echo "And no performance row could be compared on this machine (each row prints why); the ratios stand unjudged." ;;
    FAIL) echo "Stopped at: $failed. docs/troubleshooting.md lists the failures we know; the log has the rest." ;;
  esac
fi
} | tee -a "$log"    # the verdict goes into the log too: a log that ends without it answers a different question
# Exit status: 0 PASS with a clean comparison (or no comparison in this tier); 3 PASS on every step with the comparison
# not applicable on this machine; 1 otherwise.
if [ "$verdict" = PASS ] && [ -z "${compared:-}" ]; then exit 0; fi
if [ "$verdict" = PASS ] && [ "${compared:-}" = NOTAPPLICABLE ]; then exit 3; fi
exit 1
