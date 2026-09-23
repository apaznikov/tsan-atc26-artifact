# Troubleshooting

Failures we have seen, including the ones that look like our bugs and are not.

## "The minimal example's race was not reported"

ThreadSanitizer reports a race only when the second of two conflicting accesses finds the first
one's record in shadow memory. For two writes that happen microseconds apart, whether that happens
depends on the schedule: in our tests such a race was reported in 12 of 20 runs under our stock
build and in 7 of 20 under an unmodified upstream clang-18, with identical instrumentation in every
configuration. The shipped example makes the worker sleep 100 ms before its write; with that it is
reported in 20 of 20 runs under stock, under AllOpt and under upstream. If you edit the example and
remove the sleep, expect intermittent reports; that is the runtime's detection, not an elision.

## "permission denied while trying to connect to the docker API at unix:///var/run/docker.sock"

Docker is installed but the daemon refuses your user. Add yourself to the `docker` group and start a new
login session (or `newgrp docker` in the current shell), then run the command again:

```
sudo usermod -aG docker "$USER"
newgrp docker
./evaluate.sh check
```

Running the scripts with `sudo` also works but leaves `results/` and `build/` owned by root.
`00-prereqs.sh` reports this as "docker daemon access" missing.

Two warnings from Docker itself are not failures: "DEPRECATED: The legacy builder is deprecated" means the
BuildKit plugin (`docker-buildx`) is not installed, and the image builds with the legacy builder all the
same; a "seccomp" notice comes from the `--security-opt seccomp=unconfined` that `docker/run.sh` passes on purpose.

## "Segmentation fault" for every instrumented program inside Docker

The log ends with `ThreadSanitizer: CHECK failed: tsan_platform_linux.cpp ... personality(old_personality
| ADDR_NO_RANDOMIZE)`. The runtime re-executes the program with address-space randomization off, and
Docker's default seccomp profile refuses `personality(ADDR_NO_RANDOMIZE)`. Start the container with
`--security-opt seccomp=unconfined`; `docker/run.sh` does, and `00-prereqs.sh` reports "ASLR-off
re-exec refused" when it is missing. The compiler and the analyses are unaffected: the instrumentation
counts are identical either way, only running the binaries needs the flag.

## `docker/build.sh` is slow, prints "Killed signal terminated program cc1plus", or Docker stops answering

The compiler builds inside the Docker daemon's own memory cgroup, and on a systemd host that is
`docker.slice`, which is often capped well below the machine's RAM. Building clang with assertions
needs about 2.5 GiB per job at its peak. Too many jobs under the cap does not fail cleanly: without
swap the cgroup thrashes on page-cache reclaim, every compile stalls, and the daemon stops answering
`docker` commands. Killing the build client does not stop the daemon-side compile; only root can,
with `systemctl kill -s KILL docker.slice` (this also stops any running container) or by killing the
`ninja` and `cc1plus` processes in that cgroup.

`env.sh` therefore derives `ART_JOBS` as `min(80% of the processors, memory / 2.5 GiB)`, where memory
is the smallest of `MemAvailable`, the cgroup's `memory.max` when finite, and the daemon cgroup's
`MemoryMax` when systemd reports one; `docker/build.sh` and `docker/run.sh` evaluate it on the host,
where the daemon's cap is visible, and print the number with its reason. The same value drives the
application builds and the test suites inside the container. `ART_JOBS=n` overrides it. A container
started by hand rather than through `docker/run.sh` cannot see the daemon's cap and derives a larger
number from the host's memory (on our machine 78 jobs from 197 GiB available, against a 64 GiB
ceiling, which is exactly the thrash described above); if you bypass the wrapper, set `ART_JOBS` yourself
from the daemon's cap. Measured with `--no-cache` on our host: 14m52s at the derived default of 25 jobs,
24m38s at 8 jobs.

## A performance leg ran to the end and then failed before printing its table

The runs and the table are separate: every cell is written to its own directory as it completes, and the
table is computed afterwards by `aggregate.py`. A failure at that last step (a full disk or an interrupted
container, for example) loses the table and not the runs. Regenerate it from the tree without re-running anything:

```
./docker/run.sh scripts/90-tables.sh results/perf-<app>-<stamp>
```

## "This host offers 4 usable processors; this suite needs at least 8" although you gave the container 8

The processor set you pass is intersected with the set the Docker daemon itself is allowed to use, and
a daemon confined by systemd (`AllowedCPUs=` on `docker.slice`) may not have every processor; on our
host a request for 0-7 gives the container 4-7. `docker/run.sh` asks the container what it got and
prints a warning naming the daemon's set when it is less than asked; choose `ART_CPUSET` inside that
set. The correctness set refuses below 8 processors for a reason stated in its message: below that,
tests that pass by reporting nothing can pass for want of an interleaving.

## `ART_SMOKE=1 scripts/40-perf.sh sqlite` is not short

It is not hung: SQLite is the one application whose smoke run is not shortened
(`docs/campaign-parameters.md`, "Smoke mode"): threadtest3 runs the whole seven-subtest suite on each build.
Expect roughly the time of a SQLite measurement rather than a few minutes: the first cell, the uninstrumented
`orig` build, takes 7 minutes 40 seconds on its own, and the instrumented configurations are slower. To check
that the pipeline works on your machine, smoke memcached, whose smoke cells take about twelve seconds each.

## "Instrumentation counts differ from CLAIMS.md by a few calls"

The counts are of `__tsan_read*`/`__tsan_write*` calls in the whole binary and include code that
depends on the build environment's headers. Two builds in the same container match exactly; a build
in the container against our host-built campaign binaries shows a small constant offset, measured on
Redis at 19 sites fewer in every configuration, with the *removed* and *added* columns identical. The
cause is named: Redis auto-detects libsystemd at build time and the image has no `libsystemd-dev`, so
the container build compiles out `redisCommunicateSystemd` and the branches in its four callers, 19
memory-access sites; the same 19 will appear on every evaluator's image. The differences between
configurations are the claim; an offset on every row alike is the build environment, not the compiler.

## "DE removed nothing from my own test program"

At `-O2` the optimizer deletes most redundant stores before any analysis runs; DE only sees what
survives. The shipped `de.c` keeps both stores alive with a call to a sync-free function in the
same file. Compile at `-O0` to see the analysis act on unoptimized code, but do not compare those
counts with the paper's, which are at `-O2`.

## "A benchmark configuration prints ThreadSanitizer warnings"

Expected: the applications have real races (SQLite's wal-index, memcached's `current_time`), and
the preservation scripts exist to collect them. The performance scripts run with `report_bugs=0` so
reporting cost does not enter the timing.

## Tests that are non-deterministic under stock ThreadSanitizer too

`race_on_barrier2.c`, `fd_location_closed.cpp` and `fork_atexit.cpp` vary under stock and every
configuration alike; `docs/nondeterministic-tests.md` says how. The suite script compares pass and fail per
test, so they do not affect its verdict.

## "The container has fewer cores than a script assumes"

The measurement scripts print their expected time before starting. The regression suite refuses fewer
than 8 processors (`ART_ALLOW_FEW_CPUS=1` overrides it; `docs/nondeterministic-tests.md` says why that is
unwise); the performance scripts run on any count and record it, and `evaluate.sh` says when the count is
too small for the comparison. Smoke-mode output carries a "not a measurement" marker.

## A filtered, timed-out pipeline printing nothing

`timeout 5 ./prog | grep something` can print nothing because `grep` is killed before it flushes,
not because nothing matched. Redirect to a file and inspect it.

## A test binary spins for minutes in `close()` returning EBADF

Seen under `strace` on a compiled test (`deep_stack2.cpp.tmp`): thousands of `close(1007432713) = -1 EBADF`,
descending. That is the sanitizer runtime starting its symbolizer: the forked child closes every descriptor
from `sysconf(_SC_OPEN_MAX)` down to 3 before exec (compiler-rt, `sanitizer_posix_libcdep.cpp`,
`StartSubprocess`), so the first race report of a process costs one `close()` per descriptor of the soft
open-files limit. At 1024 or 1048576 that is milliseconds; at 1073741816, the limit a container inherits from
a Docker daemon with `LimitNOFILE=infinity` on a host whose `fs.nr_open` is that, it is minutes, and the
test times out. `docker/run.sh` pins the limit to 1048576 (our campaign's), so the loop cannot be long
inside it; running a test binary by hand outside `docker/run.sh` with a huge `ulimit -n` is
where it can still be seen. Same under stock ThreadSanitizer; nothing of ours.

## "fetch_archive: download failed for https://..."

The application archives ship in `third-party/sources/` and are used from there, so this line can only
come from MySQL's archive (fetched by the `everything` tier, 421 MB from GitHub) or from a checkout whose
`third-party/sources/` is missing. Obtain the file by any means and place it at the path the message names;
it is verified against the pinned sha256 before use, so where it came from does not matter.

## The log's stamp and the results directories' stamps differ by hours

Both are UTC (`results/evaluate-<tier>-<stamp>.log` and the `perf-<app>-<stamp>` directories the
container writes); the "started HH:MM:SS" lines on the console are local time.

## "COMPARISON NOT APPLICABLE ON THIS MACHINE" at the end of a Reproduced run

Not a failure. Every step passed and the performance run is valid; no row was judged because this machine's
processor-set shape (physical cores and complete SMT sibling pairs, recorded per cell), thread count or FFmpeg
input is not the campaign's, and the comparator says which on each row. The intervals in `PERFORMANCE.md`
describe 24 physical cores with both SMT threads (48 logical processors); on such a machine `evaluate.sh` pins
that set itself, elsewhere set `ART_CPUSET` to a set of that shape if the machine has one. On any other shape
read the ratios beside the intervals by eye: FFmpeg's DynSTC gain appeared on both hosts we ran, while Redis's
DynSTC cost did not reproduce on the second one (`PERFORMANCE.md`, the Redis curves). Exit status 3 distinguishes this from a clean
comparison (0) and from a judged row outside its interval (1).

## The image build stops in an `apt-get install` layer with "did not complete successfully: exit code: 100"

The package download was interrupted. The two `apt-get` steps retry each fetch five times
(`Acquire::Retries`); if the build still fails there, run the same command again: Docker keeps the layers that
completed, so a second `./evaluate.sh <tier>` (or `./docker/build.sh`) resumes at the failed layer rather than
rebuilding the compiler. Nothing about the artifact's content depends on when the packages were fetched; the
compiler's identity is asserted by the source-tree hash and the stamp, not by the base image's package versions.

## The image you build is not bit-identical to the one we measured on

The base image is pinned by digest and the compiler's source tree is asserted against its hash, so the
compiler is the one this artifact describes. What is not pinned is the Ubuntu package set: `apt-get install`
resolves to whatever the archive holds on the day, so a build months from now links against a slightly
different libstdc++ or builds with a slightly different g++. That moves neither the instrumentation the
compiler emits, which `scripts/12-compiler-equivalence.sh` checks against the counts our measurements were
taken on, nor any claim in `CLAIMS.md`; it can move a wall-clock number by the amount `docs/confounds.md`
describes for a different machine.
