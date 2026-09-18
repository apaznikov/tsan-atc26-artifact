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
number from the host's memory: on our machine 78 jobs from 197 GiB available, against a 64 GiB
ceiling, which is exactly the thrash described above. The wrapper is where the right number can be
computed, not a convenience; if you bypass it, set `ART_JOBS` yourself from the daemon's cap. Measured with `--no-cache` on our host: 14m52s at
the derived default of 25 jobs, 24m38s at 8 jobs. We found this on our own machine, 112 threads
under a 64 GiB cap, when the script still defaulted to one job per thread.

## "Instrumentation counts differ from CLAIMS.md by a few calls"

The counts are of `__tsan_read*`/`__tsan_write*` calls in the whole binary and include code that
depends on the build environment's headers. Two builds in the same container match exactly; a build
in the container against our host-built campaign binaries shows a small constant offset, measured on
Redis at 19 sites fewer in every configuration, with the *removed* and *added* columns identical. The
cause is named: Redis auto-detects libsystemd at build time and the image has no `libsystemd-dev`, so
the container build compiles out `redisCommunicateSystemd` and the branches in its four callers, 19
memory-access sites; the same 19 will appear on every evaluator's image. The differences between
configurations are the claim; an offset on every row alike is the build environment, not the compiler.
Making both sides independent of the host (`USE_SYSTEMD=no` in the harness) is a post-submission
change, since it would also change the campaign's binaries.

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

`race_on_barrier2.c` reports its race from either thread (18/20 one way, 2/20 the other, under
stock and every configuration); `fd_location_closed.cpp` varies its location descriptor line;
`fork_atexit.cpp` reports in roughly one run in five under stock and every configuration alike. The
suite script's report diff excludes these three by name and says so in its output.

## "The container has fewer cores than a script assumes"

Every script prints its expected time for 8 and 32 cores and refuses to run the performance leg on
fewer than 8 unless `ART_SMOKE=1`. Smoke-mode output carries a "not a measurement" marker.

## A filtered, timed-out pipeline printing nothing

`timeout 5 ./prog | grep something` can print nothing because `grep` is killed before it flushes,
not because nothing matched. Redirect to a file and inspect it. This cost us an hour once.
