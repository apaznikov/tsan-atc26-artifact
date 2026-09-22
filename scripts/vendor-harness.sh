#!/usr/bin/env bash
# vendor-harness.sh — copy the measurement harness into harness/, by RULE rather than by hand, and record
# what was copied so divergence from the live harness is visible on the next run and in git.
#
# Usage: scripts/vendor-harness.sh [--check]        HARNESS_SRC=<path>   (default ~/tsan-experiments)
#   --check  compare the live harness against harness/MANIFEST.tsv and report differences; copy nothing.
#
# WHY A SCRIPT AND A MANIFEST RATHER THAN A COPY. A vendored tree silently rots: the lab harness gains a
# fix, the artifact keeps the old file, and nobody finds out until a reviewer runs it. The manifest records
# every vendored file's sha256 against its source path, so `--check` answers "has the harness moved under
# us" in one command, and a re-run shows the drift as a diff in git rather than as a surprise.
#
# EXCLUSIONS ARE RULES, NOT A LIST OF NAMES. Anything derived -- logs, result trees, scratch, installs,
# archived builds, caches, generated IR and summaries -- is excluded by pattern. A hand-maintained list of
# what to leave out is wrong the first time something new is generated.
set -euo pipefail
cd "$(dirname "$0")/.."
ART=$PWD
SRC="${HARNESS_SRC:-$HOME/tsan-experiments}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DST="$ART/harness"
MAN="$DST/MANIFEST.tsv"
MODE=copy; FORCE=0
for a in "$@"; do case "$a" in
  --check) MODE=check;;
  --force) FORCE=1;;
  *) echo "unknown argument: $a (usage: vendor-harness.sh [--check] [--force])" >&2; exit 2;;
esac; done

[ -d "$SRC" ] || { echo "no harness source at $SRC (set HARNESS_SRC)" >&2; exit 2; }

# What comes over. Directories are copied with the exclusion rules below; the application entries take
# only scripts and documentation, never the sources, tarballs or build trees that live beside them.
INCLUDE_DIRS=(
  tools/perf
  tools/preservation
  tools/eviction-stress
)
INCLUDE_FILES=(
  config_definitions.sh
  tools/tsan_compiler.sh
  tools/write_build_info.sh
  tools/static_count_tsan_instrumentation.py
  tools/fetch_archive.sh
  tools/verify_archive.sh
  tools/source_archives.sha256
)
# sql/mysql/benchmysql IS THE MYSQL WORKLOAD: bench_one.sh runs `$APPDIR/benchmysql/run-one.sh`, which drives
# server-run, bench-init, bench-run, bench-cleanup and server-shutdown from that directory. Until 22 Sep 2026 the
# list stopped at sql/mysql and -maxdepth 1 never descended, so every MySQL cell of the shipped artifact died on
# `cd` after a 35-minute build of four servers: the MySQL RUN path had never been exercised in the container
# (the rehearsals built MySQL and measured nothing; found by the flag leg of 22 Sep). The directory's result
# files (benchmark_*.txt, *.stderr.log, old/, results/) are not scripts and the globs leave them behind.
APP_DIRS=(nosql/memcached nosql/redis sql/sqlite sql/mysql sql/mysql/benchmysql projects/ffmpeg)
# NOT ONLY SCRIPTS. An application directory holds inputs its scripts need, and a glob list of
# executables ships the caller without the thing it reads. Two were missing: sql/sqlite/threadtest3.c, the
# SQLite WORKLOAD ITSELF -- build_sqlite_test.sh:132 compiles ./threadtest3.c from the application
# directory, and download_and_compile_sqlite.sh copies it over the unpacked tree's version, which it
# differs from -- and nosql/redis/Makefile.patch, whose consumer make-redis-tsan-new.sh ships and begins
# with `patch -p0 <Makefile.patch`. The find below is -maxdepth 1, so these globs cannot descend into an
# unpacked source tree. (Rehearsal of 2026-09-17: the fourth vendoring omission, after fetch_archive.sh.)
APP_GLOBS=('*.sh' '*.py' '*.md' '*.conf' '*.c' '*.patch')

# LAB-ONLY ONE-OFF DRIVERS. Vendoring tools/perf wholesale swept in a dozen scripts that drove single
# investigations on this machine: they hardcode /home/alexey and /extra/alexey, name compilers that are not
# shipped, and one of them (cleanup_archive.sh) ends in `rm -rf /extra/alexey/...`. None is reachable from
# the artifact's eight scripts — checked, not assumed — and shipping them means a reviewer reads them as
# part of the artifact and may run one. Excluded by name, with the reason, rather than by a pattern that
# would also catch something needed.
LAB_ONLY=(
  chromium_bench_after.sh chromium_stock_first.sh cleanup_archive.sh sqlite_baseline_probe.sh
  mysql_ea_builds.sh mysql_ea_bench_chain.sh smoke_memcached.sh pilot_interference.sh
  sqlite_cpuscale_probe.sh mysql_ea_bench2.sh report.py
  launch_paper_march6.sh launch_final_p2.sh launch_hash_tagged.sh queue_wp_memcached.sh
  bench_ffmpeg_all-ap.sh   # does not parse (bash -n: syntax error near `done', line 268); unreferenced
  export_campaign.sh       # copies OUR campaign results into the artifact; an evaluator has no such tree
  cmake-export-main-vars.sh  # dead code naming a /dev/shm build root; build_mysql.sh builds under BUILD_SCRATCH on disk
  de_build.sh de_build2.sh   # one-off eviction drivers naming a frozen lab compiler; referenced by nothing
  # sql/mysql/benchmysql: run-one.sh's closure over code lines is nine files (run-one, server-datadir-init, server-run,
  # server-shutdown, server-check-connection, bench-init, bench-run, bench-cleanup, callmysql-export-main-vars);
  # the rest of the directory is the lab's launcher and its result analysis (computed 22 Sep 2026).
  benchmarks-launch.sh benchmarks-launch-progress.sh benchmarks-launch.md server-run-ap.sh server-cli.sh
  analyze_mysql_results.py test_analyze_mysql_results.py bench-post-logs2csv.sh
  # The campaign drivers of 13-17 Sep 2026: they hard-code one compiler hash and the lab's directory layout,
  # reach files that are not in the artifact (pilot_interference.sh, ../../chromium, tools/notes/), and are
  # reachable from nothing under scripts/. The packaging guide is explicit that an artifact "must not include
  # obsolete or unrelated code nor data", and a reviewer reading them would be reading our campaign's
  # scaffolding rather than the artifact (audit against the guide, 22 Sep 2026).
  stageA_pipeline.sh stageA_apps.sh stageA_after_apps.sh stageA_baseline_after.sh stageA_close.sh
  stageA_cpuscale_after.sh stageA_finish.sh stageA_last.sh stageA_layout_after.sh stageA_reruns.sh
  stageB_launch.sh stageB_sweep.sh stageB_rest.sh stageB_topup.sh stageB_yield.sh stageB_thread_pilot.sh
  stageB_accept_hash2.sh
  # The three remaining unverified downloads: each wgets an application archive with no sha256 check, and each
  # was superseded by tools/fetch_archive.sh, which verifies. Reachable from nothing; dropped so that the tree
  # contains no download path that skips verification.
  download-and-extract-mysql.sh download-and-unpack.sh redis-for-trace-analyzer.sh
)
# PATH-SPECIFIC exclusions, for files whose BASENAME is too common to put in LAB_ONLY (which matches by
# basename and would have taken every README.md in the harness, including the two that document the
# preservation and eviction tools).
LAB_ONLY_PATHS=(
  tools/perf/README.md   # the lab's method notebook; its content ships as data/notes/perf-method.md
)
EXCLUDES=(
  --exclude='results/' --exclude='old-builds/' --exclude='.scratch/' --exclude='installs/'
  --exclude='__pycache__/' --exclude='*.pyc'
  --exclude='*.log' --exclude='*.ll' --exclude='*_summary.txt' --exclude='summaries-*/'
  --exclude='*.tar.gz' --exclude='*.tgz' --exclude='*.zip'
  --exclude='build/' --exclude='bin/' --exclude='bin-*/'
  --exclude='.git/' --exclude='.gitignore'
)
for f in "${LAB_ONLY[@]}"; do EXCLUDES+=(--exclude="$f"); done

# manifest_matches_source <src> <manifest>: 0 if every vendored path still hashes the same in the source.
# Used by --check and by copy mode's guard, so the two can never disagree about what "differs" means.
manifest_matches_source() {
  local src=$1 man=$2 tmp rc=0
  tmp=$(mktemp -d)
  awk -F'\t' 'NR>2 {print $3"\t"$1}' "$man" | sort > "$tmp/vendored"
  ( cd "$src" && awk -F'\t' 'NR>2 {print $3}' "$man" | sort | while IFS= read -r f; do
      if [ -f "$f" ]; then printf '%s\t%s\n' "$f" "$(sha256sum -- "$f" | cut -d' ' -f1)"
      else printf '%s\tMISSING-IN-SOURCE\n' "$f"; fi
    done ) > "$tmp/live"
  diff -u "$tmp/vendored" "$tmp/live" > "$tmp/d" || rc=1
  [ "$rc" = 0 ] || sed -n '4,$p' "$tmp/d"
  rm -rf "$tmp"
  return $rc
}

hashes() {  # print "sha256<TAB>relpath" for every regular file under $1, sorted by path
  ( cd "$1" && find . -type f ! -name MANIFEST.tsv -printf '%P\n' | sort | while IFS= read -r f; do
      printf '%s\t%s\n' "$(sha256sum -- "$f" | cut -d' ' -f1)" "$f"; done )
}

if [ "$MODE" = check ]; then
  [ -f "$MAN" ] || { echo "no manifest at $MAN — run without --check first" >&2; exit 2; }
  # --check NEVER copies. It reads the manifest, re-hashes those same paths in the SOURCE, and diffs.
  # (An earlier draft re-invoked this script here to "re-derive with the same rules"; with no arguments
  # that is copy mode, which begins with `rm -rf "$DST"` -- a check that destroys what it is checking.)
  echo "compare: $SRC  ->  $MAN"
  # DRIFT HAS TWO DIRECTIONS AND THIS CHECKED ONE. Re-hashing the manifest's paths in the SOURCE answers
  # "has the live harness moved under us?" and is silent about "has the VENDORED tree been edited since it
  # was vendored?" -- which is what happened on 19 Sep 2026: three files were fixed in place under harness/,
  # the manifest still matched the source, --check printed "matches", and the next copy pass would have
  # erased all three without a word. Reported apart because the remedies are opposite: source drift is
  # taken with --force; in-place edits must be carried back to the source first or they are lost.
  vendored_rc=0
  while IFS="$(printf '\t')" read -r want path; do
    [ -n "${path:-}" ] || continue
    if [ ! -f "$DST/$path" ]; then echo "  MISSING FROM harness/: $path"; vendored_rc=1; continue; fi
    if [ "$(sha256sum "$DST/$path" | cut -d' ' -f1)" != "$want" ]; then
      echo "  EDITED IN PLACE since vendoring: $path"; vendored_rc=1
    fi
  done < <(awk -F'\t' 'NR>2 {print $1"\t"$3}' "$MAN")
  if [ "$vendored_rc" != 0 ]; then
    echo
    echo "harness/ has been edited in place. Those edits exist ONLY there: carry them back into $SRC first,"
    echo "or the next copy pass will overwrite them. --force would erase them now."
    exit 1
  fi
  if manifest_matches_source "$SRC" "$MAN"; then
    echo "harness/ matches the live harness at $SRC ($(( $(wc -l < "$MAN") - 2 )) files), and no vendored file has been edited in place"
  else
    echo
    echo "re-run scripts/vendor-harness.sh --force to take the live version, and commit the diff."
    exit 1
  fi
  exit 0
fi

command -v rsync >/dev/null || { echo "rsync is required" >&2; exit 2; }

# --- guards on the destructive step -------------------------------------------------------------------
# A reviewer runs this on a tree they cannot rebuild, so the rm -rf below has to be impossible to aim
# anywhere else and impossible to fire over unsaved work.
#
# First: the target is not a variable a caller can steer. ART_ROOT is derived from this script's own
# location, and DST must be exactly its harness/ subdirectory -- not a symlink to somewhere else, not a
# path that a stray HARNESS_SRC or a cd could have moved.
expected="$ART/harness"
[ "$DST" = "$expected" ] || { echo "refusing to delete $DST: the only permitted target is $expected" >&2; exit 2; }
case "$DST" in "$ART"/*) ;; *) echo "refusing to delete $DST: outside the artifact root $ART" >&2; exit 2;; esac
[ -L "$DST" ] && { echo "refusing to delete $DST: it is a symlink, and rm -rf would follow it out of the tree" >&2; exit 2; }

# Second: if a harness is already vendored and it does NOT match the live source, deleting it discards a
# difference somebody may not have seen. Say what differs and require --force. A matching tree is
# re-copied without ceremony, because then the delete destroys nothing that is not about to be rewritten.
if [ -d "$DST" ] && [ -f "$MAN" ] && [ "$FORCE" = 0 ]; then
  if ! manifest_matches_source "$SRC" "$MAN" > /tmp/.vendor-drift.$$ 2>&1; then
    echo "harness/ is already vendored and differs from $SRC:"; sed -n '1,40p' /tmp/.vendor-drift.$$
    rm -f /tmp/.vendor-drift.$$
    echo
    echo "Re-vendoring would delete that state. Run scripts/vendor-harness.sh --check to read it in full,"
    echo "then re-run with --force to take the live version."
    exit 1
  fi
  rm -f /tmp/.vendor-drift.$$
fi

rm -rf "$DST"; mkdir -p "$DST"
for d in "${INCLUDE_DIRS[@]}"; do
  [ -d "$SRC/$d" ] || { echo "missing in source: $d" >&2; exit 2; }
  mkdir -p "$DST/$d"; rsync -a "${EXCLUDES[@]}" "$SRC/$d/" "$DST/$d/"
done
for f in "${INCLUDE_FILES[@]}"; do
  [ -f "$SRC/$f" ] || { echo "missing in source: $f" >&2; exit 2; }
  mkdir -p "$DST/$(dirname "$f")"; cp -p "$SRC/$f" "$DST/$f"
done
for d in "${APP_DIRS[@]}"; do
  [ -d "$SRC/$d" ] || { echo "missing in source: $d" >&2; exit 2; }
  mkdir -p "$DST/$d"
  # LAB_ONLY has to be applied HERE too. The application directories are copied by this find/cp loop, not
  # by the rsync above, so the --exclude flags do not reach them — which is how an unparseable lab script
  # in projects/ffmpeg survived an exclusion that named it. The gate below caught it; this is the fix.
  for g in "${APP_GLOBS[@]}"; do
    while IFS= read -r f; do
      skip=0
      for lo in "${LAB_ONLY[@]}"; do [ "$(basename "$f")" = "$lo" ] && skip=1 && break; done
      for lp in "${LAB_ONLY_PATHS[@]}"; do [ "${f#$SRC/}" = "$lp" ] && skip=1 && break; done
      [ "$skip" = 1 ] || cp -p "$f" "$DST/$d/"
    done < <(find "$SRC/$d" -maxdepth 1 -type f -name "$g" ! -name '*.log')
  done
done

# The path-specific exclusions, applied after both copy paths rather than as rsync patterns: the rsync runs
# once per source directory, so a pattern would have to know which root it is relative to, and a wrong
# pattern fails silently by copying the file. Removing the file by its full path cannot fail that way.
for lp in "${LAB_ONLY_PATHS[@]}"; do rm -f "$DST/$lp"; done

{
  printf '# vendored from %s on %s\n' "$SRC" "$(date -Iseconds)"
  printf 'sha256\tbytes\tpath\n'
  ( cd "$DST" && find . -type f ! -name MANIFEST.tsv -printf '%P\n' | sort | while IFS= read -r f; do
      printf '%s\t%s\t%s\n' "$(sha256sum -- "$f" | cut -d' ' -f1)" "$(stat -c%s -- "$f")" "$f"; done )
} > "$MAN"

# A VENDORED FILE MUST NOT HARDCODE A LAB PATH. Three defects today were one machine's values written as
# though they were everyone's; this is the rule that catches the next one at vendor time rather than when a
# reviewer runs it. A path inside a ${VAR:-default} is fine — that is a default, not a fact.
bare=$(grep -rn '/home/alexey\|/extra/alexey' "$DST" --include='*.sh' --include='*.py' 2>/dev/null \
       | grep -vE '\$\{[A-Za-z0-9_]+:?-[^}]*(/home/alexey|/extra/alexey)' \
       | grep -vE 'environ\.get\([^)]*(/home/alexey|/extra/alexey)' \
       | grep -vE ':[0-9]+: *#' \
       | grep -vE '#[^\"]*(/home/alexey|/extra/alexey)' || true)
if [ -n "$bare" ]; then
  echo "REFUSING: vendored files hardcode lab paths outside a \${VAR:-default}:" >&2
  echo "$bare" | sed 's|^'"$DST"'/|  |' | head -20 >&2
  echo "Make each one overridable, or add it to LAB_ONLY if it is a lab driver that should not ship." >&2
  exit 1
fi

# EVERY SHIPPED SHELL SCRIPT MUST PARSE. A script that cannot be parsed is a defect whether or not
# anything calls it: a reviewer reads it as part of the artifact, and "nothing references it" is an
# argument for not shipping it rather than for shipping it broken.
unparsed=""
while IFS= read -r f; do bash -n "$f" 2>/dev/null || unparsed="$unparsed  $f"$'\n'; done < <(find "$DST" -name '*.sh')
if [ -n "$unparsed" ]; then
  echo "REFUSING: vendored shell scripts do not parse:" >&2
  printf '%s' "$unparsed" | sed 's|^  '"$DST"'/|  |' >&2
  echo "Fix them, or add them to LAB_ONLY if they should not ship." >&2
  exit 1
fi

n=$(( $(wc -l < "$MAN") - 2 ))
b=$(awk -F'\t' 'NR>2 {s+=$2} END {print s+0}' "$MAN")
echo "vendored $n files, $(numfmt --to=iec "$b" 2>/dev/null || echo "$b bytes") -> $DST"
# data/tools/perf holds a second copy of the aggregation tools, because aggregate.py derives the harness
# root from its own location and 90-tables.sh must therefore run it from inside a data tree. Two copies of
# load-bearing code diverge, and on 19 Sep 2026 they had: the data copy predated both the --runs option and
# the fix that stops the stability column claiming "all subtests within 5%" when nothing was measured, so
# the documented table check ran an aggregator older than the one that produced the measurements. The
# vendoring keeps them identical, and 01-functional refuses if they ever differ again.
synced=0
while IFS= read -r rel; do
  [ -f "$DST/$rel" ] || continue
  cmp -s "$DST/$rel" "$ROOT_DIR/data/$rel" || { cp -a "$DST/$rel" "$ROOT_DIR/data/$rel"; synced=$((synced+1)); }
done < <(cd "$ROOT_DIR/data" && find . -name '*.py' | sed 's|^\./||' | sort)
[ "$synced" = 0 ] || echo "synced $synced tool(s) into data/tools/perf (they must not diverge from harness/tools/perf)"

echo "manifest: $MAN"
echo
echo "NOT vendored, and each needs its own decision:"
echo "  - the five application SOURCES (tarballs and checkouts): see third-party/SOURCES.md"
echo "  - projects/ffmpeg/input/TearsOfSteel-1366x768-100s.mkv (77.8 MB): the FFmpeg runs need it and it is"
echo "    too large for git; it belongs beside the sources with its sha256, not in this tree."
