#!/bin/bash
# Build the image, including the compiler. The one argument that matters is the number of compile jobs,
# and it is NOT one per processor: building clang with assertions takes about 2.5 GiB per job, and the
# build runs inside the Docker daemon's own memory cgroup (docker.slice on a systemd host, often capped
# far below the machine's RAM; ours: 64 GiB of 250). Too many jobs under that cap does not fail cleanly:
# with no swap the cgroup thrashes on page-cache reclaim, the compiles stall, and the daemon stops
# answering, which only root can undo.
# env.sh derives the default (80% of the processors, bounded by memory at 2.5 GiB per job, the daemon's
# cap included) and ART_JOBS overrides it. Twenty-four jobs build the compiler in about fifteen minutes.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/env.sh"
mkdir -p "$here/results"
log="$here/results/image-build-$(date -u +%Y%m%d-%H%M%S).log"
echo "docker/build.sh: ${ART_JOBS} compile jobs (${ART_JOBS_WHY}); set ART_JOBS to override; log: results/$(basename "$log")"
# Anything on the command line goes to docker build unchanged, e.g. ./docker/build.sh --no-cache
# The log is kept because scripts/13-verify-image.sh reads the reconstructed-tree assertion out of it (an
# uncached build prints it once; a cached rebuild prints nothing), and results/ is outside the build context.
docker build "$@" --build-arg JOBS="$ART_JOBS" -t tsan-atc26 -f "$here/docker/Dockerfile" "$here" 2>&1 | tee "$log"
exit "${PIPESTATUS[0]}"
