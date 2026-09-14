#!/usr/bin/env bash
# Reports what is missing for each part of the artifact. Changes nothing.
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../env.sh
. "$here/env.sh"

ok=0; miss=0
need() { # need <what> <command> [tier]
  if command -v "$2" >/dev/null 2>&1; then printf '  ok       %-22s %s\n' "$1" "$(command -v "$2")"; ok=$((ok+1))
  else printf '  MISSING  %-22s (%s)\n' "$1" "${3:-required}"; miss=$((miss+1)); fi
}

echo "Host: $(uname -srm); CPUs: $(nproc); RAM: $(awk '/MemTotal/{printf "%d GB", $2/1024/1024}' /proc/meminfo); free disk here: $(df -h "$here" | awk 'NR==2{print $4}')"
echo
echo "Container and compiler (Tier 0 and up):"
need docker docker "to build or pull the image; skip if you run inside it"
if [ -x "$TSAN_LLVM_ROOT/bin/clang" ]; then
  echo "  ok       TSan clang            $TSAN_LLVM_ROOT/bin/clang ($("$TSAN_LLVM_ROOT/bin/clang" --version | head -1))"
  if ldd "$TSAN_LLVM_ROOT/bin/clang" | grep -q 'libLLVM' && ldd "$TSAN_LLVM_ROOT/bin/clang" | grep 'libLLVM' | grep -qv "$TSAN_LLVM_ROOT"; then
    echo "  WARNING  clang resolves an LLVM library outside $TSAN_LLVM_ROOT; the install is not self-contained"; miss=$((miss+1))
  fi
else
  echo "  MISSING  TSan clang            expected at $TSAN_LLVM_ROOT/bin/clang (set TSAN_LLVM_ROOT or run inside the container)"; miss=$((miss+1))
fi
echo
echo "Deterministic core (Tier 1):"
for c in cmake ninja python3 git objdump; do need "$c" "$c"; done
need "llvm-lit" "$TSAN_LLVM_ROOT/bin/llvm-lit" "ships with the compiler build"
echo
echo "Performance (Tier 2):"
need taskset taskset
need memtier_benchmark memtier_benchmark "built by scripts/40-perf.sh if absent"
need sysbench sysbench "MySQL only; optional"
need ffmpeg-dev-libs pkg-config "libx264/libx265 dev packages must be installed for FFmpeg"
echo
if [ "$miss" -eq 0 ]; then echo "All prerequisites present."; else echo "$miss item(s) missing. Each script above says which tier needs them."; fi
[ "$miss" -eq 0 ]
