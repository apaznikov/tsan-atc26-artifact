#!/usr/bin/env bash
# W1 on apollo: the concurrency curves our host has no time for. Fresh clone, campaign shape 0-23,32-55.
# memcached: the application that has never been swept. Redis: 50/112 exist here only at N=2, 256/512 nowhere.
set -u
root=/extra/alexey/sweep-20260922 2>/dev/null || root=$HOME/sweep-20260922
root=$HOME/sweep-20260922
[ -d "$root/tsan-atc26-artifact" ] && { echo "clone exists at $root"; exit 1; }
mkdir -p "$root" && cd "$root" && git clone -q https://github.com/apaznikov/tsan-atc26-artifact.git && cd tsan-atc26-artifact && git checkout -q master || exit 1
echo "== APOLLO SWEEP START $(date +%H:%M:%S) at $(git rev-parse --short HEAD)"
C="orig tsan tsan-dom_peeling-ea-lo-st-swmr tsan-stmt tsan-dom_peeling-ea-lo-st-swmr-stmt"
export ART_CPUSET=0-23,32-55 ART_RUNS=5 ART_WARMUP=1
for t in 48 96 112 24; do
  echo "== memcached t=$t START $(date +%H:%M:%S)"
  MC_THREADS=$t ./docker/run.sh scripts/40-perf.sh memcached --configs "$C"
  echo "== memcached t=$t END $(date +%H:%M:%S) rc=$?"
done
for c in 256 512 112 50; do
  echo "== redis c=$c START $(date +%H:%M:%S)"
  ./docker/run.sh bash -c "REDIS_BENCH_CLIENTS=$c scripts/40-perf.sh redis --configs \"$C\""
  echo "== redis c=$c END $(date +%H:%M:%S) rc=$?"
done
echo "== APOLLO SWEEP DONE $(date +%H:%M:%S)"
