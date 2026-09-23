#!/usr/bin/env bash
# Tonight on this host, in order: W2 (whole-program summaries with DynSTC), then the memcached and Redis
# arms apollo is not covering, then the cheap SQLite walthread1 curve. Fresh clone; nothing edits it while it runs.
set -u
root=/extra/alexey/night-20260922
pgrep -f 'm6b\.sh' >/dev/null && { echo "the MySQL leg is still running; refusing"; exit 1; }
[ -d "$root/tsan-atc26-artifact" ] && { echo "clone exists at $root"; exit 1; }
mkdir -p "$root" && cd "$root" && git clone -q https://github.com/apaznikov/tsan-atc26-artifact.git && cd tsan-atc26-artifact && git checkout -q master || exit 1
echo "== NIGHT START $(date +%H:%M:%S) at $(git rev-parse --short HEAD)"
export ART_CPUSET=4-27,60-83 ART_RUNS=5 ART_WARMUP=1
WP="orig tsan tsan-dom_peeling-ea-lo-st-swmr-wp tsan-dom_peeling-ea-lo-st-swmr-stmt tsan-dom_peeling-ea-lo-st-swmr-stmt-wp"
SW="orig tsan tsan-dom_peeling-ea-lo-st-swmr tsan-stmt tsan-dom_peeling-ea-lo-st-swmr-stmt"
for app in redis sqlite memcached; do
  echo "== W2 $app START $(date +%H:%M:%S)"
  ./docker/run.sh scripts/40-perf.sh "$app" --configs "$WP"
  echo "== W2 $app END $(date +%H:%M:%S) rc=$?"
done
for t in 96 112 24; do
  echo "== W1 memcached t=$t START $(date +%H:%M:%S)"
  MC_THREADS=$t ./docker/run.sh scripts/40-perf.sh memcached --configs "$SW"
  echo "== W1 memcached t=$t END $(date +%H:%M:%S) rc=$?"
done
for c in 256 512; do
  echo "== W1 redis c=$c START $(date +%H:%M:%S)"
  ./docker/run.sh bash -c "REDIS_BENCH_CLIENTS=$c scripts/40-perf.sh redis --configs \"$SW\""
  echo "== W1 redis c=$c END $(date +%H:%M:%S) rc=$?"
done
for t in 8 16 32 48 96 112; do
  echo "== W1 sqlite w1=$t START $(date +%H:%M:%S)"
  ./docker/run.sh bash -c "SQLITE_W1_THREADS=$t scripts/40-perf.sh sqlite --configs \"$SW\""
  echo "== W1 sqlite w1=$t END $(date +%H:%M:%S) rc=$?"
done
echo "== NIGHT DONE $(date +%H:%M:%S)"
