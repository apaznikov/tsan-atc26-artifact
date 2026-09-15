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

## "Instrumentation counts differ from CLAIMS.md by a few calls"

The counts are of `__tsan_read*`/`__tsan_write*` calls in the whole binary and include libc glue
that depends on the exact glibc headers; inside the container they match exactly. Outside it, a
difference of a handful of calls on the stock side with the same *removed* column is expected.

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
