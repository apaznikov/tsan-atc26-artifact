#!/usr/bin/env bash
# Runs a script (or a shell) inside the artifact image with results written back to ./results.
# Usage: docker/run.sh scripts/10-minimal-example.sh [args]      or      docker/run.sh
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$here/results"
cpus_flag=()
[ -n "${ART_CPUSET:-}" ] && cpus_flag=(--cpuset-cpus "$ART_CPUSET")
exec docker run --rm -it "${cpus_flag[@]}" \
  -e ART_RUNS -e ART_WARMUP -e ART_SMOKE -e ART_CPUSET \
  -v "$here/results:/artifact/results" \
  -v "$here/data:/artifact/data:ro" \
  tsan-atc26 "${@:-/bin/bash}"
