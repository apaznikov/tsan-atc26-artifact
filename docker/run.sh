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
if [ -n "${ART_CPUSET:-}" ]; then
  cpus_flag=(--cpuset-cpus "$ART_CPUSET")
  # A requested set is silently intersected with the processors the Docker daemon itself may use, and
  # a daemon confined by systemd (AllowedCPUs on docker.slice) may not have them all: on our host a
  # request for 0-7 yields 4-7, and the correctness set then refuses with "4 usable processors" and no
  # hint why. Ask the container what it actually got, and say so when it is less than asked.
  # Membership, not size: a granted set of the same size but different members is a different pinning
  # (4-27,62-85 against 4-27,60-83), and a size check would pass it silently. Normalise both to a list.
  expand() { printf '%s' "$1" | tr ',' '\n' | awk -F- '{ if ($2 == "") print $1; else for (i = $1; i <= $2; i++) print i }' | sort -n | tr '\n' ' '; }
  want_list=$(expand "$ART_CPUSET")
  got_raw=$(docker run --rm --cpuset-cpus "$ART_CPUSET" "${ART_IMAGE:-tsan-atc26}" bash -c 'grep Cpus_allowed_list /proc/self/status | cut -f2' 2>/dev/null || true)
  got_list=$(expand "${got_raw:-$ART_CPUSET}")
  if [ "$got_list" != "$want_list" ]; then
    echo "docker/run.sh: ART_CPUSET=$ART_CPUSET, but the container gets ${got_raw:-an unknown set}: the daemon's own allowed set" >&2
    echo "  does not contain every processor asked for. Choose a set inside it; the daemon's set is what an unpinned" >&2
    echo "  container reports ($(docker run --rm "${ART_IMAGE:-tsan-atc26}" bash -c 'grep Cpus_allowed_list /proc/self/status | cut -f2' 2>/dev/null)). Every cell records the set it ran on." >&2
  fi
fi
# ART_MEMORY caps the container's memory (docker --memory, e.g. 16g): how we run the artifact at the
# README's minimum, 8 processors and 16 GB, to know the minimum is true rather than assumed.
[ -n "${ART_MEMORY:-}" ] && cpus_flag+=(--memory "$ART_MEMORY")
# The open-files limit, pinned. The sanitizer runtime starts its symbolizer with a fork that closes every
# descriptor from sysconf(_SC_OPEN_MAX) down to 3, one close() each (compiler-rt, sanitizer_posix_libcdep.cpp,
# StartSubprocess), so the first race report of every process costs time in proportion to the soft limit:
# measured on the minimal example's report, 0.19 s at 1024, 0.27 s at 1048576, and a limit of 1073741816
# (what a container inherits from a daemon with LimitNOFILE=infinity on a host whose fs.nr_open is that) means
# a test binary spinning for minutes in close() = EBADF.
# Docker's own default moved between versions (28: the daemon's 1048576; 29: 1024 soft), so the value is
# fixed here rather than inherited: 1048576, the soft limit our campaign ran under, capped by the kernel's
# nr_open so that the container can always start.
nofile=1048576
nr=$(cat /proc/sys/fs/nr_open 2>/dev/null || echo 0)
[ "$nr" -gt 0 ] 2>/dev/null && [ "$nr" -lt "$nofile" ] && nofile=$nr
tty_flag=()
[ -t 0 ] && [ -t 1 ] && tty_flag=(-it)
# --user: the container runs as the caller, not as root. As root, everything it wrote into results/ and
# build/ was root-owned on the host (an evaluator could not delete a failed run without sudo, and a
# second attempt could not clear the first's tree), and memcached refuses to start as root at all, so
# its benchmark measured a client talking to nothing. HOME=/tmp because that uid has no home in the image.
# tests/ is mounted from the checkout (read-only; lit writes under results/), so the suite that runs is the
# checkout's and a fix to a test or a lit configuration needs no image rebuild; the image carries its own
# copy for scripts/13-verify-image.sh, which starts containers without these mounts.
# --shm-size: Docker's default /dev/shm is 64 MB. The FFmpeg workload writes each codec's output there,
# and two of the four outputs exceed 64 MB (measured on the 100 s clip: mjpeg 298 MB, stream copy 78 MB);
# without this the script drops those codecs, reports success, and the row measures a different quantity.
exec docker run --rm "${tty_flag[@]}" "${cpus_flag[@]}" \
  --security-opt seccomp=unconfined \
  --user "$(id -u):$(id -g)" -e HOME=/tmp \
  --shm-size=1g --ulimit "nofile=$nofile:$nofile" \
  -e ART_RUNS -e ART_WARMUP -e ART_SMOKE -e ART_CPUSET -e ART_JOBS -e ART_JOBS_WHY \
  -e ART_FFMPEG_CLIP_URL -e ART_FFMPEG_SOURCE \
  -e MC_THREADS -e MYSQL_THREADS -e FF_THREADS \
  -e ART_LIT_TIMEOUT -e ART_ALLOW_FEW_CPUS -e ART_LIT_FORCE -e ART_LIT_PACKAGE -e ART_LIT_SHOW_UNSUPPORTED \
  -e CT_REPS -e P5_IGNORE_CPUS -e ART_MEMCACHED_PORT \
  -v "$here/results:/artifact/results" \
  -v "$here/build:/artifact/build" \
  -v "$here/data:/artifact/data:ro" \
  -v "$here/scripts:/artifact/scripts:ro" \
  -v "$here/env.sh:/artifact/env.sh:ro" \
  -v "$here/CLAIMS.md:/artifact/CLAIMS.md:ro" \
  -v "$here/harness:/artifact/harness:ro" \
  -v "$here/third-party:/artifact/third-party:ro" \
  -v "$here/tests:/artifact/tests:ro" \
  -w /artifact \
  "${ART_IMAGE:-tsan-atc26}" "${@:-/bin/bash}"
