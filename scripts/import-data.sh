#!/usr/bin/env bash
# Author-side script: copies the recorded results and the aggregation scripts from the working
# harness (~/tsan-experiments) into data/, excluding the bulk (perf.data, test.db) and the trees
# that are misleading rather than large (listed below with the reason). Evaluators never run this;
# it is here so the provenance of data/ is reproducible from the lab's repository.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
src="${TSAN_EXPERIMENTS:-$HOME/tsan-experiments}"
dst="$here/data"
[ -d "$src/tools/perf/results" ] || { echo "no harness at $src"; exit 2; }
mkdir -p "$dst/perf" "$dst/preservation" "$dst/eviction-stress" "$dst/eviction-counters" "$dst/tools/perf" "$dst/tools/preservation"

# Stage A trees, the probes and the reach trees are not shipped: nothing in the ledger cites them.
# The eight trees results_ledger.py reads, plus the sweep and the two Redis re-measurements.
PERF_TREES=(campaign-f3deebfbab60 ffmpeg-threadsweep-f3deebfbab60 compile-time-memcached-f3deebfbab60 stageB-d3bf9f8c39fe nofe-d3bf9f8c39fe merge-timing-afe47a2a75a5 yield-d98873cda906 profile-2026-09-09 profile-2026-09-09-counters combo-counters merge-counters contention-d3bf9f8c39fe redis-recheck-2026-09-14 redis-stageB-repeat-2026-09-14)
EXCL=(--exclude 'perf.data*' --exclude 'test.db*' --exclude 'clock-samples.csv' --exclude '__pycache__' --exclude GO --exclude RESUME --exclude GAPDONE --exclude 'foreign-build-window.txt')
# THIS IMPORT ADDS; IT DOES NOT REWRITE. Until 23 Sep 2026 the copy was `rsync -a --delete` from the live
# harness, which makes data/ a MIRROR of that harness rather than a record of what was measured, and the
# difference bit three times in one pass on the morning of the submission: fifty preservation files that had
# been de-symlinked into real content here went back to being symlinks (the harness holds symlinks and
# `rsync -a` preserves them); two `shape.json` files and a preservation tree exported by hand from the second
# host were DELETED, because the harness has no such files; and a dozen cells of the contention tree were
# overwritten by a later re-run of the same cells, silently changing a shipped tree's contents. None of it
# would have been visible in a table.
#
# So: no --delete, --ignore-existing, and -L where the source holds symlinks. A tree that genuinely has to be
# replaced is removed by hand first, which is a deliberate act and leaves a diff. (23 Sep 2026.)
# WHAT A CAMPAIGN ROOT HOLDS IN THE LAB IS NOT WHAT THE ARTIFACT SHIPS. The live root also carries the
# build directory and its logs, the per-leg logs, and four sub-roots that are deliberately not shipped:
# `oldclip-not-shipped` (the retired FFmpeg clip's control, whose name says it), `compile-time-memcached`
# and `redis-recheck` (shipped as roots of their own, under their own names), and `sound-rows`. Before
# 23 Sep 2026 they were absent from the copy only because no import had run since they appeared, which is
# not a reason. Named here, so that what ships is a decision and not an accident of timing.
NOT_SHIPPED=(--exclude 'build' --exclude 'build-*.log' --exclude 'leg-*.log'
             --exclude 'compile-time-memcached' --exclude 'oldclip-not-shipped'
             --exclude 'redis-recheck' --exclude 'sound-rows')
# The sub-roots below come from the legs clone and the night clone, by the explicit copies further down,
# not from the live harness; excluding them here keeps each one's provenance to a single line.
FROM_CLONES=(--exclude 'ffmpeg-t16' --exclude 'flag-*' --exclude 'threads-8-dynstc'
             --exclude 'sweep-*' --exclude 'wp-dynstc-*')
# AN EXISTING TREE IS LEFT ALONE ENTIRELY, not merely not-deleted. --ignore-existing still ADDS files to a
# tree that is already shipped, and on 23 Sep 2026 it added retired cells and per-cell command logs to two
# frozen roots -- harmless-looking additions to evidence that claims rest on, made hours before a tag and
# reviewed by nobody. A tree that must be refreshed is deleted here first; that is one command, it leaves a
# diff, and it is a decision.
for t in "${PERF_TREES[@]}"; do
  [ -d "$dst/perf/$t" ] && { echo "  $t: already here, left untouched"; continue; }
  [ -d "$src/tools/perf/results/$t" ] && rsync -aL "${NOT_SHIPPED[@]}" "${FROM_CLONES[@]}" "${EXCL[@]}" "$src/tools/perf/results/$t/" "$dst/perf/$t/"
done
# The legs of 21-22 Sep 2026 (FFmpeg at 16 and 8 threads with DynSTC; the upstream flag on stock and on ours),
# run from a fresh clone at /extra/alexey/legs-20260921 on the campaign's set: one results tree each.
LEGS_SRC=${LEGS_SRC:-/extra/alexey/legs-20260921/tsan-atc26-artifact/results}
legs_copy() { [ -d "$dst/perf/$2" ] && return 0; [ -d "$LEGS_SRC/$1" ] && rsync -aL "${EXCL[@]}" "$LEGS_SRC/$1/" "$dst/perf/$2/"; }
legs_copy perf-ffmpeg-20260921-135106 campaign-f3deebfbab60/ffmpeg-t16
legs_copy perf-ffmpeg-20260921-144526 ffmpeg-threadsweep-f3deebfbab60/threads-8-dynstc
legs_copy perf-redis-20260921-152206 campaign-f3deebfbab60/flag-redis
legs_copy perf-memcached-20260921-162538 campaign-f3deebfbab60/flag-memcached
legs_copy perf-sqlite-20260921-173333 campaign-f3deebfbab60/flag-sqlite

# The legs of 22-23 Sep 2026, run from a fresh clone at /extra/alexey/night-20260922 on the campaign's set
# after the artifact was complete: the one combination of our own transforms never measured (whole-program
# summaries together with DynSTC, three applications) and the concurrency arms the campaign took at one
# point only. They answer questions asked after the data existed, so they ship whole, with the arm's knob
# value in its directory name, and CLAIMS.md reports them as measured after the fact (see its section 5).
NIGHT_SRC=${NIGHT_SRC:-/extra/alexey/night-20260922/tsan-atc26-artifact/results}
LEGS_LOG_SRC=${LEGS_LOG_SRC:-/extra/alexey/night-20260922/night-legs.log}
LEGS_RUN_SRC=${LEGS_RUN_SRC:-/extra/alexey/night-20260922/night-legs.sh}
night_copy() { [ -d "$dst/perf/$2" ] && return 0; [ -d "$NIGHT_SRC/$1" ] && rsync -aL "${EXCL[@]}" "$NIGHT_SRC/$1/" "$dst/perf/$2/"; }
night_copy perf-redis-20260922-104910     campaign-f3deebfbab60/wp-dynstc-redis
night_copy perf-sqlite-20260922-113303    campaign-f3deebfbab60/wp-dynstc-sqlite
night_copy perf-memcached-20260922-142601 campaign-f3deebfbab60/wp-dynstc-memcached
night_copy perf-memcached-20260922-153509 campaign-f3deebfbab60/sweep-memcached-t96
night_copy perf-memcached-20260922-171336 campaign-f3deebfbab60/sweep-memcached-t112
night_copy perf-memcached-20260922-185704 campaign-f3deebfbab60/sweep-memcached-t24
night_copy perf-redis-20260922-200553     campaign-f3deebfbab60/sweep-redis-c256
night_copy perf-redis-20260922-213644     campaign-f3deebfbab60/sweep-redis-c512
# SQLITE_SWEEP_ARMS: the six walthread1 arms of the morning of 23 Sep, filled in when they retired.
night_copy perf-sqlite-20260923-001218        campaign-f3deebfbab60/sweep-sqlite-w1t8
night_copy perf-sqlite-20260923-002529        campaign-f3deebfbab60/sweep-sqlite-w1t16
night_copy perf-sqlite-20260923-003840        campaign-f3deebfbab60/sweep-sqlite-w1t32
night_copy perf-sqlite-20260923-005159        campaign-f3deebfbab60/sweep-sqlite-w1t48
night_copy perf-sqlite-20260923-010523        campaign-f3deebfbab60/sweep-sqlite-w1t96
night_copy perf-sqlite-20260923-011900        campaign-f3deebfbab60/sweep-sqlite-w1t112
# THE ARM'S KNOB IS NOT IN ITS CELLS. A cell records the thread count for memcached and MySQL and nothing
# for Redis's clients or SQLite's walthread1 threads (the harness writes the workload knob only from 23 Sep
# 2026, after these legs ran), so the directory name above is the only statement of which arm is which. The
# driver and its log ship beside the arms for exactly that reason: the log names every arm with its knob
# value and its start and end, so the mapping is evidence rather than our word for it.
cp "$LEGS_LOG_SRC" "$dst/perf/campaign-f3deebfbab60/sweep-legs.log" 2>/dev/null || true
cp "$LEGS_RUN_SRC" "$dst/perf/campaign-f3deebfbab60/sweep-legs.sh" 2>/dev/null || true

# The same two curves on the second host (apollo, AMD EPYC 9115, 64 threads, 32 of them pinned as
# 0-23,32-55), which is NOT the shape the performance comparison is judged on -- that is why they live in
# their own root and not beside ours. A reader comparing the two roots is comparing two machines, which is
# the point of them. Staged to this host with rsync before the import, so that this script needs no network.
APOLLO_SRC=${APOLLO_SRC:-/extra/alexey/apollo-sweep-20260922}
# mkdir first: rsync creates the last path component, not two of them, and this root is new.
mkdir -p "$dst/perf/sweep-apollo-f3deebfbab60"
apollo_copy() { [ -d "$dst/perf/sweep-apollo-f3deebfbab60/$2" ] && return 0; [ -d "$APOLLO_SRC/$1" ] && rsync -aL "${EXCL[@]}" "$APOLLO_SRC/$1/" "$dst/perf/sweep-apollo-f3deebfbab60/$2/"; }
apollo_copy perf-memcached-20260922-090654 memcached-t48
apollo_copy perf-memcached-20260922-103501 memcached-t96
apollo_copy perf-memcached-20260922-123345 memcached-t112
apollo_copy perf-memcached-20260922-143926 memcached-t24
apollo_copy perf-redis-20260922-205023     redis-c50
apollo_copy perf-redis-20260922-195955     redis-c112
apollo_copy perf-redis-20260922-161531     redis-c256
apollo_copy perf-redis-20260922-173707     redis-c512
cp "$APOLLO_SRC/legs.log" "$dst/perf/sweep-apollo-f3deebfbab60/legs.log" 2>/dev/null || true
cp "$APOLLO_SRC/legs.sh" "$dst/perf/sweep-apollo-f3deebfbab60/legs.sh" 2>/dev/null || true
rsync -aL --ignore-existing "${EXCL[@]}" --exclude 'memcached-10k' --exclude '*apollo*' "$src/tools/preservation/results/" "$dst/preservation/"
rsync -aL --ignore-existing "${EXCL[@]}" --exclude '*.mod4-artefact' "$src/tools/eviction-stress/results/" "$dst/eviction-stress/"
rsync -aL --ignore-existing "${EXCL[@]}" "$src/tools/eviction-counters/results/" "$dst/eviction-counters/"
# The scripts that turn recorded runs into the paper's tables, unchanged from the harness.
# aggregate.py computes ROOT as ../.. from its own directory, so it must sit at data/tools/perf/ and the
# per-application parsers at data/{nosql,sql,projects}/..., mirroring the harness layout.
for f in aggregate.py report.py results_ledger.py meta_tool.py; do
  [ -f "$src/tools/perf/$f" ] && cp "$src/tools/perf/$f" "$dst/tools/perf/"
done
cp "$src/tools/preservation/tsan_reports.py" "$dst/tools/preservation/" 2>/dev/null || true
cp "$src/tools/static_count_tsan_instrumentation.py" "$dst/tools/" 2>/dev/null || true
# aggregate.py resolves the per-application parsers relative to its own location (ROOT = data/).
mkdir -p "$dst/nosql/redis" "$dst/sql/sqlite" "$dst/projects/ffmpeg"
cp "$src/nosql/redis/analyze_results_redis.py" "$dst/nosql/redis/"
cp "$src/sql/sqlite/parse_results.py" "$dst/sql/sqlite/"
cp "$src/projects/ffmpeg/ffmpeg_contention_report.py" "$dst/projects/ffmpeg/"
# Method notes that the read-me cites.
mkdir -p "$dst/notes"
# -n, for the same reason the rsyncs are --ignore-existing: these notes carry artifact-side annotations
# (which of the scripts they quote are lab-only and not shipped, above all), and a plain cp reverted them on
# every import without a word. A note that must be refreshed is deleted here first.
for n in paper-setup-campaign-2026-09-13.md preregistration-2026-09-13.md run1-cold-start-2026-09-13.md march-provenance-2026-09-13.md preservation-l1-l2-l3.md; do
  [ -f "$src/tools/notes/$n" ] && [ ! -f "$dst/notes/$n" ] && cp "$src/tools/notes/$n" "$dst/notes/"
done
[ -f "$src/tools/perf/README.md" ] && [ ! -f "$dst/notes/perf-method.md" ] && cp "$src/tools/perf/README.md" "$dst/notes/perf-method.md"
# results_ledger.py rewrites the tables inside RESULTS.md next to itself and reads results/<tree> from there.
[ -f "$src/tools/perf/RESULTS.md" ] && cp "$src/tools/perf/RESULTS.md" "$dst/tools/perf/RESULTS.md"
ln -sfn ../../perf "$dst/tools/perf/results"
echo "imported $(du -sh "$dst" | cut -f1) into $dst"
