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
APP_DIRS=(nosql/memcached nosql/redis sql/sqlite sql/mysql projects/ffmpeg)
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
  if manifest_matches_source "$SRC" "$MAN"; then
    echo "harness/ matches the live harness at $SRC ($(( $(wc -l < "$MAN") - 2 )) files)"
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
      [ "$skip" = 1 ] || cp -p "$f" "$DST/$d/"
    done < <(find "$SRC/$d" -maxdepth 1 -type f -name "$g" ! -name '*.log')
  done
done

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
for f in aggregate.py meta_tool.py results_ledger.py write_readme_results.py; do
  if [ -f "$DST/tools/perf/$f" ] && [ -f "$ROOT_DIR/data/tools/perf/$f" ]; then
    cmp -s "$DST/tools/perf/$f" "$ROOT_DIR/data/tools/perf/$f" || { cp -a "$DST/tools/perf/$f" "$ROOT_DIR/data/tools/perf/$f"; synced=$((synced+1)); }
  fi
done
[ "$synced" = 0 ] || echo "synced $synced tool(s) into data/tools/perf (they must not diverge from harness/tools/perf)"

echo "manifest: $MAN"
echo
echo "NOT vendored, and each needs its own decision:"
echo "  - the five application SOURCES (tarballs and checkouts): see third-party/SOURCES.md"
echo "  - projects/ffmpeg/input/TearsOfSteel-1366x768-100s.mkv (77.8 MB): the FFmpeg runs need it and it is"
echo "    too large for git; it belongs beside the sources with its sha256, not in this tree."
