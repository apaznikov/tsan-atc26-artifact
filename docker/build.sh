#!/usr/bin/env bash
# Builds the artifact image from the recipe. Use `docker pull` of the published image instead if
# you do not want to build LLVM (about 1-2 hours on 8 cores, needs ~16 GB RAM and ~40 GB disk).
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
jobs="${ART_JOBS:-$(nproc)}"
exec docker build --build-arg JOBS="$jobs" -t tsan-atc26 -f "$here/docker/Dockerfile" "$here"
