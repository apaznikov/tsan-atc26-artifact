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
for t in "${PERF_TREES[@]}"; do
  # The sub-roots measured on 21-22 Sep 2026 from the legs clone (best/, flag-*/, threads-8-dynstc/) live under
  # the campaign and sweep roots but come from another source tree, so --delete must leave them alone.
  [ -d "$src/tools/perf/results/$t" ] && rsync -a --delete --exclude best --exclude 'flag-*' --exclude threads-8-dynstc "${EXCL[@]}" "$src/tools/perf/results/$t/" "$dst/perf/$t/"
done
# The legs of 21-22 Sep 2026 (FFmpeg at 16 and 8 threads with DynSTC; the upstream flag on stock and on ours),
# run from a fresh clone at /extra/alexey/legs-20260921 on the campaign's set: one results tree each.
LEGS_SRC=${LEGS_SRC:-/extra/alexey/legs-20260921/tsan-atc26-artifact/results}
legs_copy() { [ -d "$LEGS_SRC/$1" ] && rsync -a --delete "${EXCL[@]}" "$LEGS_SRC/$1/" "$dst/perf/$2/"; }
legs_copy perf-ffmpeg-20260921-135106 campaign-f3deebfbab60/best
legs_copy perf-ffmpeg-20260921-144526 ffmpeg-threadsweep-f3deebfbab60/threads-8-dynstc
legs_copy perf-redis-20260921-152206 campaign-f3deebfbab60/flag-redis
rsync -a --delete "${EXCL[@]}" --exclude 'memcached-10k' "$src/tools/preservation/results/" "$dst/preservation/"
rsync -a --delete "${EXCL[@]}" --exclude '*.mod4-artefact' "$src/tools/eviction-stress/results/" "$dst/eviction-stress/"
rsync -a --delete "${EXCL[@]}" "$src/tools/eviction-counters/results/" "$dst/eviction-counters/"
# The scripts that turn recorded runs into the paper's tables, unchanged from the harness.
# aggregate.py computes ROOT as ../.. from its own directory, so it must sit at data/tools/perf/ and the
# per-application parsers at data/{nosql,sql,projects}/..., mirroring the harness layout.
for f in aggregate.py report.py results_ledger.py write_readme_results.py meta_tool.py; do
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
for n in paper-setup-campaign-2026-09-13.md preregistration-2026-09-13.md run1-cold-start-2026-09-13.md march-provenance-2026-09-13.md preservation-l1-l2-l3.md; do
  [ -f "$src/tools/notes/$n" ] && cp "$src/tools/notes/$n" "$dst/notes/"
done
[ -f "$src/tools/perf/README.md" ] && cp "$src/tools/perf/README.md" "$dst/notes/perf-method.md"
# results_ledger.py rewrites the tables inside RESULTS.md next to itself and reads results/<tree> from there.
[ -f "$src/tools/perf/RESULTS.md" ] && cp "$src/tools/perf/RESULTS.md" "$dst/tools/perf/RESULTS.md"
ln -sfn ../../perf "$dst/tools/perf/results"
echo "imported $(du -sh "$dst" | cut -f1) into $dst"
