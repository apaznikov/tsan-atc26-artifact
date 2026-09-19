#!/usr/bin/env bash
# Reports what is missing for each part of the artifact. Changes nothing.
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../env.sh
. "$here/env.sh"

[ $# -eq 0 ] || { echo "$(basename "$0") takes no arguments (got: $*)"; exit 2; }

ok=0; miss=0; docker_blocked=0
need() { # need <what> <command> [tier]
  if command -v "$2" >/dev/null 2>&1; then printf '  ok       %-22s %s\n' "$1" "$(command -v "$2")"; ok=$((ok+1))
  else printf '  MISSING  %-22s (%s)\n' "$1" "${3:-required}"; miss=$((miss+1)); fi
}

echo "Host: $(uname -srm); CPUs: $(nproc); RAM: $(awk '/MemTotal/{printf "%d GB", $2/1024/1024}' /proc/meminfo); free disk here: $(df -h "$here" | awk 'NR==2{print $4}')"
echo
echo "Container and compiler (Tier 0 and up):"
need docker docker "to build the image; skip if you run inside it"
# Having the docker command is not having Docker: the daemon must accept this user. On 18 Sep 2026 a run on
# a second server passed this check and then failed the image build with "permission denied while trying to
# connect to the docker API at unix:///var/run/docker.sock", because the user was not in the docker group.
if command -v docker >/dev/null 2>&1 && [ ! -x "${TSAN_LLVM_ROOT:-/opt/tsan-llvm}/bin/clang" ]; then
  if docker info >/dev/null 2>&1; then
    printf '  ok       %-22s %s\n' "docker daemon" "reachable as $(id -un)"
  else
    printf '  MISSING  %-22s (%s)\n' "docker daemon access" "the daemon refuses this user: add yourself to the docker group (sudo usermod -aG docker $(id -un), then log in again or run: newgrp docker), or run the scripts with sudo"
    miss=$((miss+1)); docker_blocked=1
  fi
fi
if [ -x "$TSAN_LLVM_ROOT/bin/clang" ]; then
  echo "  ok       TSan clang            $TSAN_LLVM_ROOT/bin/clang ($("$TSAN_LLVM_ROOT/bin/clang" --version | head -1))"
  if ldd "$TSAN_LLVM_ROOT/bin/clang" | grep -q 'libLLVM' && ldd "$TSAN_LLVM_ROOT/bin/clang" | grep 'libLLVM' | grep -qv "$TSAN_LLVM_ROOT"; then
    echo "  WARNING  clang resolves an LLVM library outside $TSAN_LLVM_ROOT; the install is not self-contained"; miss=$((miss+1))
  fi
else
  echo "  MISSING  TSan clang            expected at $TSAN_LLVM_ROOT/bin/clang (set TSAN_LLVM_ROOT or run inside the container)"; miss=$((miss+1))
fi
# ThreadSanitizer re-executes every program with ASLR off through personality(ADDR_NO_RANDOMIZE).
# Docker's default seccomp profile refuses it and the program dies with SIGSEGV; docker/run.sh passes
# --security-opt seccomp=unconfined. setarch makes the same call, so it is the probe.
if command -v setarch >/dev/null 2>&1; then
  if setarch "$(uname -m)" -R true 2>/dev/null; then echo "  ok       ASLR-off re-exec       personality(ADDR_NO_RANDOMIZE) allowed"
  else echo "  MISSING  ASLR-off re-exec       refused: TSan programs will crash; start the container with --security-opt seccomp=unconfined (docker/run.sh does)"; miss=$((miss+1)); fi
fi
echo
echo "Deterministic core (Tier 1):"
for c in cmake ninja python3 git objdump; do need "$c" "$c"; done
# llvm-lit is a Python launcher: an executable bit proves nothing, only starting it does.
if "$TSAN_LLVM_ROOT/bin/llvm-lit" --version >/dev/null 2>&1; then printf '  ok       %-22s %s\n' "llvm-lit" "$("$TSAN_LLVM_ROOT/bin/llvm-lit" --version 2>/dev/null | head -1)"; ok=$((ok+1))
elif [ ! -e "$TSAN_LLVM_ROOT/bin/llvm-lit" ]; then
  echo "  MISSING  llvm-lit               not at $TSAN_LLVM_ROOT/bin/llvm-lit; it ships with the compiler, so this is expected on a host without one -- run inside the container"; miss=$((miss+1))
else
  echo "  MISSING  llvm-lit               present but does not start: the 'lit' Python package must be importable (the image installs it; on a host, PYTHONPATH=<llvm-project>/llvm/utils/lit)"; miss=$((miss+1)); fi
echo
echo "Performance (Tier 2):"
need taskset taskset
need memtier_benchmark memtier_benchmark "built by scripts/40-perf.sh if absent"
need sysbench sysbench "MySQL only; optional"
need ffmpeg-dev-libs pkg-config "libx264/libx265 dev packages must be installed for FFmpeg"
echo
# The verdict an evaluator needs is about THEIR next step, not a count. On a host, the compiler, llvm-lit,
# memtier and sysbench are expected to be missing: they live inside the container, which docker/build.sh
# builds, and nothing is to be installed for them. The first external run (18 Sep 2026) read "4 item(s)
# missing" as a failure and asked what to install besides Docker; the answer is nothing.
# Exit status: 0 when the next step can be taken here. On a host that is Docker present (the compiler,
# llvm-lit and the benchmark clients are expected to be absent, they live inside the container); inside
# the container it is every item present. 1 otherwise.
if [ "$miss" -eq 0 ]; then
  echo "All prerequisites present."
elif [ ! -f /.dockerenv ] && [ ! -r "${TSAN_LLVM_ROOT:-/opt/tsan-llvm}/TSAN_AUDIT_HASH" ]; then
  if command -v docker >/dev/null 2>&1 && [ "${docker_blocked:-0}" != 1 ]; then
    echo "On this host: nothing to install beyond Docker. The $miss item(s) marked MISSING above are the compiler,"
    echo "llvm-lit and the benchmark clients, which live inside the container and are built by ./docker/build.sh"
    echo "(memtier and sysbench by the scripts that need them). Next step: ./docker/build.sh, then run every"
    echo "script through ./docker/run.sh, and this check passes inside the container."
    exit 0
  fi
  if [ "${docker_blocked:-0}" = 1 ]; then
    echo "On this host: Docker is installed but this user cannot use it (see the line above); fix that and run this again."
  else
    echo "On this host: Docker is missing, and it is the one thing the host needs; install it and run this again."
  fi
  exit 1
else
  echo "$miss item(s) missing inside the container; each line above says which script needs it."
  exit 1
fi
[ "$miss" -eq 0 ]
