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
mkdir -p "$dst/perf" "$dst/preservation" "$dst/eviction-stress" "$dst/eviction-counters" "$dst/tools"

# Performance trees that the paper's tables and CLAIMS.md rest on. Stage A trees and the one-off
# probes are not shipped: they were measured on an earlier compiler and are cited nowhere.
PERF_TREES=(stageB-d3bf9f8c39fe contention-d3bf9f8c39fe redis-recheck-2026-09-14 redis-stageB-repeat-2026-09-14 nofe-d3bf9f8c39fe)
EXCL=(--exclude 'perf.data*' --exclude 'test.db*' --exclude 'clock-samples.csv' --exclude '__pycache__')
for t in "${PERF_TREES[@]}"; do
  [ -d "$src/tools/perf/results/$t" ] && rsync -a --delete "${EXCL[@]}" "$src/tools/perf/results/$t/" "$dst/perf/$t/"
done
rsync -a --delete "${EXCL[@]}" --exclude 'memcached-10k' "$src/tools/preservation/results/" "$dst/preservation/"
rsync -a --delete "${EXCL[@]}" --exclude '*.mod4-artefact' "$src/tools/eviction-stress/results/" "$dst/eviction-stress/"
rsync -a --delete "${EXCL[@]}" "$src/tools/eviction-counters/results/" "$dst/eviction-counters/"
# The scripts that turn recorded runs into the paper's tables, unchanged from the harness.
for f in aggregate.py report.py results_ledger.py write_readme_results.py meta_tool.py; do
  [ -f "$src/tools/perf/$f" ] && cp "$src/tools/perf/$f" "$dst/tools/"
done
cp "$src/tools/preservation/tsan_reports.py" "$dst/tools/" 2>/dev/null || true
cp "$src/tools/static_count_tsan_instrumentation.py" "$dst/tools/" 2>/dev/null || true
# Method notes that the read-me cites.
mkdir -p "$dst/notes"
for n in paper-setup-campaign-2026-09-13.md preregistration-2026-09-13.md run1-cold-start-2026-09-13.md march-provenance-2026-09-13.md preservation-l1-l2-l3.md; do
  [ -f "$src/tools/notes/$n" ] && cp "$src/tools/notes/$n" "$dst/notes/"
done
[ -f "$src/tools/perf/README.md" ] && cp "$src/tools/perf/README.md" "$dst/notes/perf-method.md"
[ -f "$src/tools/perf/RESULTS.md" ] && cp "$src/tools/perf/RESULTS.md" "$dst/notes/results-ledger.md"
echo "imported $(du -sh "$dst" | cut -f1) into $dst"
