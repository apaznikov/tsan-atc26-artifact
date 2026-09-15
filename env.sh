# Every machine-specific knob in one place. Source this before running any script.
# Every value has a fallback that works inside the container on an ordinary machine.

# Where the TSan-enabled clang lives. Inside the container this is the install prefix.
export TSAN_LLVM_ROOT="${TSAN_LLVM_ROOT:-/opt/tsan-llvm}"

# Where the benchmark applications are built and where results are written.
export ART_ROOT="${ART_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export ART_BUILD="${ART_BUILD:-$ART_ROOT/build}"
export ART_RESULTS="${ART_RESULTS:-$ART_ROOT/results}"
export ART_DATA="${ART_DATA:-$ART_ROOT/data}"

# Processor set for performance runs. Our machine used 4-27,60-83 (48 logical CPUs).
# Leave empty to use every CPU the container was given.
# Empty means "every CPU" and also means "not gate-checked": the disturbance gate measures busy time on
# the CPUs OUTSIDE the set, and with no set there is nothing to measure. Unpinned runs record
# outside_busy_share = null and print "not gate-checked"; do not compare them with the pinned numbers in
# CLAIMS.md as if the conditions matched.
export ART_CPUSET="${ART_CPUSET:-}"

# Number of measured runs per configuration and whether a discarded warm-up run precedes them.
export ART_RUNS="${ART_RUNS:-5}"
export ART_WARMUP="${ART_WARMUP:-1}"

# Smoke mode: one run, short workloads, reduced test lists. Prints "not a measurement".
export ART_SMOKE="${ART_SMOKE:-0}"

# Ports used by the server benchmarks; change if they collide with something on your host.
export ART_MEMCACHED_PORT="${ART_MEMCACHED_PORT:-7777}"
export ART_REDIS_PORT="${ART_REDIS_PORT:-6379}"

# Parallelism for builds.
export ART_JOBS="${ART_JOBS:-$(nproc)}"

# The machine lock and the "bench" reservation of our lab are not needed anywhere else.
# These shims are no-ops unless you point them at your own tools.
export ART_MACHINE_LOCK="${ART_MACHINE_LOCK:-true}"

art_cpus() {  # wraps a command in taskset if ART_CPUSET is set
  if [ -n "$ART_CPUSET" ]; then taskset -c "$ART_CPUSET" "$@"; else "$@"; fi
}
