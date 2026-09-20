#!/usr/bin/env bash
# Reports what is missing for each part of the artifact. Changes nothing.
#
# On the host it checks the host's part only: Docker, its daemon, the ASLR-off re-exec, disk. The compiler,
# llvm-lit and the benchmark clients live inside the container image and are checked there
# (./docker/run.sh scripts/00-prereqs.sh). Until 20 Sep 2026 the host run listed those as MISSING with a note
# that this was expected on a host, and every reader took the word MISSING for a failure, on the first
# screen of the first command, in the tail evaluate.sh shows when a step fails.
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../env.sh
. "$here/env.sh"

[ $# -eq 0 ] || { echo "$(basename "$0") takes no arguments (got: $*)"; exit 2; }

ok=0; miss=0
need() { # need <what> <command> [what to do]
  if command -v "$2" >/dev/null 2>&1; then printf '  ok       %-22s %s\n' "$1" "$(command -v "$2")"; ok=$((ok+1))
  else printf '  MISSING  %-22s (%s)\n' "$1" "${3:-required}"; miss=$((miss+1)); fi
}
# ThreadSanitizer re-executes every program with ASLR off through personality(ADDR_NO_RANDOMIZE).
# Docker's default seccomp profile refuses it and the program dies with SIGSEGV; docker/run.sh passes
# --security-opt seccomp=unconfined. setarch makes the same call, so it is the probe.
aslr_probe() {
  command -v setarch >/dev/null 2>&1 || return 0
  if setarch "$(uname -m)" -R true 2>/dev/null; then echo "  ok       ASLR-off re-exec       personality(ADDR_NO_RANDOMIZE) allowed"
  else echo "  MISSING  ASLR-off re-exec       refused: TSan programs will crash; start the container with --security-opt seccomp=unconfined (docker/run.sh does)"; miss=$((miss+1)); fi
}
in_container=0
{ [ -f /.dockerenv ] || [ -r "$TSAN_LLVM_ROOT/TSAN_AUDIT_HASH" ]; } && in_container=1

echo "Host: $(uname -srm); CPUs: $(nproc); RAM: $(awk '/MemTotal/{printf "%d GB", $2/1024/1024}' /proc/meminfo); free disk here: $(df -h "$here" | awk 'NR==2{print $4}')"

if [ "$in_container" = 0 ]; then
  echo
  echo "On the host the artifact needs Docker and nothing else:"
  need docker docker "install Docker Engine; everything else runs inside the image it builds"
  # Having the docker command is not having Docker: the daemon must be running and must accept this user.
  # Two different failures, two different remedies, told apart by what docker itself says: a user outside
  # the docker group gets "permission denied while trying to connect" (18 Sep 2026, a second server); a
  # daemon that is installed but not started gets "Is the docker daemon running?" (20 Sep 2026, a student
  # after a reboot, whom the first version of this line told to fix his group membership).
  if command -v docker >/dev/null 2>&1; then
    err=$(docker info 2>&1 >/dev/null); drc=$?
    if [ "$drc" -eq 0 ]; then
      printf '  ok       %-22s %s\n' "docker daemon" "running, reachable as $(id -un)"; ok=$((ok+1))
    else
      case "$err" in
        *ermission\ denied*)
          why="running, but it refuses this user: add yourself to the docker group (sudo usermod -aG docker $(id -un), then log in again or run: newgrp docker), or run the scripts with sudo" ;;
        *"Is the docker daemon running"*|*"Cannot connect"*|*"connection refused"*|*"No such file"*)
          why="not running: start it (sudo systemctl start docker; sudo systemctl enable docker keeps it across reboots) and run this again" ;;
        *)
          why="docker info failed: $(printf '%s' "$err" | grep -v '^$' | head -1)" ;;
      esac
      printf '  MISSING  %-22s (%s)\n' "docker daemon" "$why"; miss=$((miss+1))
    fi
  fi
  aslr_probe
  free_gb=$(df -BG "$here" 2>/dev/null | awk 'NR==2{print $4}' | tr -d G)
  if [ -n "${free_gb:-}" ] && [ "$free_gb" -lt 20 ] 2>/dev/null; then
    echo "  WARNING  disk                   ${free_gb} GB free here; the image build and the correctness set need about 20 GB, the performance set up to 100 GB with MySQL"
  fi
  echo
  echo "The compiler, llvm-lit and the benchmark clients are inside the container image, which ./docker/build.sh"
  echo "builds (evaluate.sh does that the first time); ./docker/run.sh scripts/00-prereqs.sh checks them there."
  if [ "$miss" -eq 0 ]; then
    echo "On this host: nothing to install beyond Docker. Next step: ./evaluate.sh check"
    exit 0
  fi
  echo "On this host: fix the MISSING line above and run this again."
  exit 1
fi

# Inside the container: everything must be present.
echo
echo "Compiler:"
if [ -x "$TSAN_LLVM_ROOT/bin/clang" ]; then
  echo "  ok       TSan clang            $TSAN_LLVM_ROOT/bin/clang ($("$TSAN_LLVM_ROOT/bin/clang" --version | head -1))"; ok=$((ok+1))
  if ldd "$TSAN_LLVM_ROOT/bin/clang" | grep -q 'libLLVM' && ldd "$TSAN_LLVM_ROOT/bin/clang" | grep 'libLLVM' | grep -qv "$TSAN_LLVM_ROOT"; then
    echo "  WARNING  clang resolves an LLVM library outside $TSAN_LLVM_ROOT; the install is not self-contained"; miss=$((miss+1))
  fi
else
  echo "  MISSING  TSan clang            expected at $TSAN_LLVM_ROOT/bin/clang (set TSAN_LLVM_ROOT)"; miss=$((miss+1))
fi
aslr_probe
echo
echo "Deterministic core:"
for c in cmake ninja python3 git objdump; do need "$c" "$c"; done
# llvm-lit is a Python launcher: an executable bit proves nothing, only starting it does.
if "$TSAN_LLVM_ROOT/bin/llvm-lit" --version >/dev/null 2>&1; then printf '  ok       %-22s %s\n' "llvm-lit" "$("$TSAN_LLVM_ROOT/bin/llvm-lit" --version 2>/dev/null | head -1)"; ok=$((ok+1))
elif [ ! -e "$TSAN_LLVM_ROOT/bin/llvm-lit" ]; then
  echo "  MISSING  llvm-lit               not at $TSAN_LLVM_ROOT/bin/llvm-lit; it ships with the compiler"; miss=$((miss+1))
else
  echo "  MISSING  llvm-lit               present but does not start: the 'lit' Python package must be importable (the image installs it; on a host, PYTHONPATH=<llvm-project>/llvm/utils/lit)"; miss=$((miss+1)); fi
echo
echo "Performance:"
need taskset taskset
# memtier is not a prerequisite: 40-perf.sh memcached builds it from the pinned tarball when it is absent, so it is
# reported and not counted (counted, it made this check exit 1 inside every image, and README said it passes there).
if command -v memtier_benchmark >/dev/null 2>&1; then printf '  ok       %-22s %s\n' memtier_benchmark "$(command -v memtier_benchmark)"; ok=$((ok+1))
else printf '  later    %-22s %s\n' memtier_benchmark "built by scripts/40-perf.sh memcached when first needed"; fi
need sysbench sysbench "MySQL only; optional"
need ffmpeg-dev-libs pkg-config "libx264/libx265 dev packages must be installed for FFmpeg"
echo
if [ "$miss" -eq 0 ]; then
  echo "All prerequisites present."
  exit 0
fi
echo "$miss item(s) missing inside the container; each line above says which script needs it."
exit 1
