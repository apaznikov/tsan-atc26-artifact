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
# Leave empty to use every CPU the container was given (evaluate.sh's performance tiers then pin 48 of the
# processors the Docker daemon grants to containers, when there are that many).
# Empty means "every CPU" and also means "not gate-checked": the disturbance gate measures busy time on
# the CPUs OUTSIDE the set, and with no set there is nothing to measure. Unpinned runs record
# outside_busy_share = null with gate_checked = false in session.json and print "not gate-checked"; do not
# compare them with the pinned numbers in
# CLAIMS.md as if the conditions matched.
export ART_CPUSET="${ART_CPUSET:-}"
# Memory cap for the container (docker --memory), empty for none; e.g. ART_MEMORY=16g for the README's minimum.
export ART_MEMORY="${ART_MEMORY:-}"
# The image docker/run.sh starts; docker/build.sh builds it under this name.
export ART_IMAGE="${ART_IMAGE:-tsan-atc26}"

# Number of measured runs per configuration and whether a discarded warm-up run precedes them.
# Three modes, and the tables say which one produced them:
#   ART_RUNS=2  (default)  a point estimate per row, no confidence interval; the reviewer's mode.
#                          Match criterion: the point falls inside the interval shipped in CLAIMS.md.
#   ART_RUNS=5             our campaign; a 95% bootstrap interval per row; criterion: intervals overlap.
#   ART_SMOKE=1            one run, reduced workloads; printed as "not a measurement".
# No interval is ever printed for fewer than five runs.
export ART_RUNS="${ART_RUNS:-2}"
export ART_WARMUP="${ART_WARMUP:-1}"

# Smoke mode: one run, short workloads, reduced test lists. Prints "not a measurement".
export ART_SMOKE="${ART_SMOKE:-0}"

# The FFmpeg input clip, by the first of three paths that applies (docs/ffmpeg-input.md): a prepared copy of
# the reference clip at ART_FFMPEG_CLIP_URL (checked against the pinned sha256), a local copy of the Blender
# source in ART_FFMPEG_SOURCE (cut here with the recorded command), or, with both empty, the Blender source
# downloaded and cut. The default is the asset of this repository's GitHub release `inputs-v1` (78 MB, CC BY 3.0
# with attribution in the release notes; the artifact's Zenodo record carries the same file). The `${VAR-default}`
# form, not `${VAR:-default}`: an evaluator who exports the EMPTY string opts out and regenerates the clip from
# the Blender source, whose rows are then reported and not compared. docker/run.sh forwards both variables into
# the container; until 17 Sep 2026 it forwarded neither, so a setting made by an evaluator was silently dropped
# at the container boundary (defect 11 of the rehearsal).
export ART_FFMPEG_CLIP_URL="${ART_FFMPEG_CLIP_URL-https://github.com/apaznikov/tsan-atc26-artifact/releases/download/inputs-v1/TearsOfSteel-1366x768-100s.mkv}"
export ART_FFMPEG_SOURCE="${ART_FFMPEG_SOURCE:-}"

# Workload thread counts. Empty means the campaign's rule (docs/campaign-parameters.md): one memcached server
# thread per processor of the pinned set, three quarters of that for sysbench, FFmpeg at an absolute 4. Set
# one to measure a different point; every cell records the value it ran with (threads_setting) and whether
# it was overridden (threads_from_env). docker/run.sh forwards all three; until 18 Sep 2026 it forwarded none,
# so the documented override could not reach the container (the same defect as the clip variables).
export MC_THREADS="${MC_THREADS:-}"
export MYSQL_THREADS="${MYSQL_THREADS:-}"
export FF_THREADS="${FF_THREADS:-}"

# The port memcached's benchmark uses; change it if 7777 is taken on your host. Redis's port is not a
# knob: its benchmark reaches the server through redis.conf and the default 6379, and threading a port
# through that path is a change to the workload script rather than a substitution, so the variable is
# not offered rather than offered and ignored (19 Sep 2026; it had been declared here and read nowhere).
export ART_MEMCACHED_PORT="${ART_MEMCACHED_PORT:-7777}"

# Parallelism for builds and test suites. The default is derived from what the machine can carry, not
# from how many processors it has: 80% of the processors this run may use (the ART_CPUSET count when it
# is set, else nproc), bounded by memory at about 2.5 GiB per job, where memory is the smallest of
# MemAvailable, this cgroup's memory.max when it is finite (a container started with --memory), and
# docker.slice's MemoryMax when systemd reports one. docker/run.sh evaluates this on the host and passes
# the result into the container, because the daemon's cap is invisible from inside. One job per
# processor on a shared or memory-capped machine does not fail, it thrashes: 112 jobs under a 64 GiB
# cap wedged our Docker daemon on 17 Sep 2026. ART_JOBS overrides; ART_JOBS_WHY says where it came from.
art_default_jobs() {  # prints "<jobs><TAB><reason>"
  local cpus mem_kib lim src by_mem
  cpus=""
  if [ -n "${ART_CPUSET:-}" ]; then
    cpus=$(printf '%s' "$ART_CPUSET" | tr ',' '\n' | awk -F- '{ n += ($2 == "" ? 1 : $2 - $1 + 1) } END { print n + 0 }')
  fi
  [ "${cpus:-0}" -gt 0 ] 2>/dev/null || cpus=$(nproc 2>/dev/null || echo 8)
  cpus=$((cpus * 4 / 5)); [ "$cpus" -lt 1 ] && cpus=1
  mem_kib=$(awk '/MemAvailable/ {print $2}' /proc/meminfo 2>/dev/null || echo 0); src="MemAvailable"
  for lim in "cgroup memory.max:$(cat /sys/fs/cgroup/memory.max 2>/dev/null)" \
             "docker.slice MemoryMax:$(systemctl show docker.slice -p MemoryMax --value 2>/dev/null)"; do
    case "${lim#*:}" in ''|max|infinity) ;;
      *) if [ "${lim#*:}" -gt 0 ] 2>/dev/null && [ $(( ${lim#*:} / 1024 )) -lt "$mem_kib" ]; then
           mem_kib=$(( ${lim#*:} / 1024 )); src="${lim%%:*}"; fi ;;
    esac
  done
  if [ "$mem_kib" -gt 0 ]; then
    by_mem=$((mem_kib / 2621440)); [ "$by_mem" -lt 1 ] && by_mem=1
    if [ "$by_mem" -lt "$cpus" ]; then printf '%s\t%s\n' "$by_mem" "$src $((mem_kib / 1048576)) GiB at 2.5 GiB per job"; return; fi
  fi
  printf '%s\t%s\n' "$cpus" "80% of the processors"
}
if [ -z "${ART_JOBS:-}" ]; then
  _art_j=$(art_default_jobs); ART_JOBS="${_art_j%%	*}"; ART_JOBS_WHY="${_art_j#*	}"; unset _art_j
else
  ART_JOBS_WHY="${ART_JOBS_WHY:-set by the caller}"
fi
export ART_JOBS ART_JOBS_WHY

# The machine lock and the "bench" reservation of our lab are not needed anywhere else.
# These shims are no-ops unless you point them at your own tools.
export ART_MACHINE_LOCK="${ART_MACHINE_LOCK:-true}"

art_cpus() {  # wraps a command in taskset if ART_CPUSET is set
  if [ -n "$ART_CPUSET" ]; then taskset -c "$ART_CPUSET" "$@"; else "$@"; fi
}
