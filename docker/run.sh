#!/usr/bin/env bash
# Runs a script (or a shell) inside the artifact image with results written back to ./results.
# Usage: docker/run.sh scripts/10-minimal-example.sh [args]      or      docker/run.sh
#
# --security-opt seccomp=unconfined is required, not optional: the ThreadSanitizer runtime re-executes
# itself with ASLR disabled via personality(ADDR_NO_RANDOMIZE), and Docker's default seccomp profile
# refuses that call, so every instrumented program dies with SIGSEGV after
# "CHECK failed: tsan_platform_linux.cpp ... personality". See docs/troubleshooting.md.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$here/results" "$here/build"
# Evaluated here, on the host: env.sh derives ART_JOBS from the memory the daemon's cgroup actually
# has, which no process inside the container can see. The value and its reason go in with the run.
. "$here/env.sh"
echo "docker/run.sh: ART_JOBS=$ART_JOBS ($ART_JOBS_WHY); set ART_JOBS to override" >&2
cpus_flag=()
[ -n "${ART_CPUSET:-}" ] && cpus_flag=(--cpuset-cpus "$ART_CPUSET")
tty_flag=()
[ -t 0 ] && [ -t 1 ] && tty_flag=(-it)
# --user: the container runs as the caller, not as root. As root, everything it wrote into results/ and
# build/ was root-owned on the host (an evaluator could not delete a failed run without sudo, and a
# second attempt could not clear the first's tree), and memcached refuses to start as root at all, so
# its benchmark measured a client talking to nothing. HOME=/tmp because that uid has no home in the image.
# --shm-size: Docker's default /dev/shm is 64 MB. The FFmpeg workload writes each codec's output there,
# and two of the four outputs exceed 64 MB (measured on the 100 s clip: mjpeg 298 MB, stream copy 78 MB);
# without this the script drops those codecs, reports success, and the row measures a different quantity.
exec docker run --rm "${tty_flag[@]}" "${cpus_flag[@]}" \
  --security-opt seccomp=unconfined \
  --user "$(id -u):$(id -g)" -e HOME=/tmp \
  --shm-size=1g \
  -e ART_RUNS -e ART_WARMUP -e ART_SMOKE -e ART_CPUSET -e ART_JOBS -e ART_JOBS_WHY \
  -e ART_FFMPEG_CLIP_URL -e ART_FFMPEG_SOURCE \
  -e MC_THREADS -e MYSQL_THREADS -e FF_THREADS \
  -v "$here/results:/artifact/results" \
  -v "$here/build:/artifact/build" \
  -v "$here/data:/artifact/data:ro" \
  -v "$here/scripts:/artifact/scripts:ro" \
  -v "$here/env.sh:/artifact/env.sh:ro" \
  -v "$here/CLAIMS.md:/artifact/CLAIMS.md:ro" \
  -v "$here/harness:/artifact/harness:ro" \
  -w /artifact \
  "${ART_IMAGE:-tsan-atc26}" "${@:-/bin/bash}"
