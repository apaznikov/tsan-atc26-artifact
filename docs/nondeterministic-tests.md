# Running the preservation suite so that a pass means something

## Do not run it on one core

Two kinds of test live in the suite, and they behave differently when the machine is small.
A test that passes by *detecting* a race gets harder on fewer cores, so a pass is safe. A test
that passes by *not reporting* a race gets easier: with one runnable processor the interleaving
it exists to exercise may never occur, and it passes for a reason the measurement cannot see.

What survives that, and what does not:

| Quantity | Invariant under pinning? | Why |
|---|---|---|
| tests discovered, and tests unsupported on this platform | yes | decided by `lit` feature gates before anything runs |
| tests executed and passed | **no** | a no-report test can pass vacuously when the schedule never interleaves |

So give the suite real parallelism: at least 8 processors, unpinned, and do not run it inside a
container limited to one CPU. The counts of discovered and unsupported tests are comparable with
ours on any machine; a pass count taken on one core is not, and we do not quote one.

## The applications: a race set is an observation, not a guarantee

`31-preservation-apps.sh` runs each application with reporting on, N times per configuration, and
compares the sites reported. Detection there is schedule-dependent, so the set of sites we saw (five
on SQLite over 10 runs) is what our schedule produced, and a reviewer's run can legitimately see
fewer or more. The script therefore never compares against a fixed set. It prints, for stock and for
each configuration, how many of the N runs reported each site, and classifies each site by the
configuration's count first. KEPT: the configuration reported it in at least one run, so it can find
it, whatever stock's frequency. LOST: the configuration never reported it and stock did in every run.
UNDETERMINED at this N: the configuration never reported it and stock did only sometimes, so an
unlucky schedule cannot be told from a loss without more runs. ONLY-OPTIMIZED: the configuration
reported a site stock never did; not a loss, and labelled rather than dropped, because the
shadow-eviction effect can produce exactly this. Only LOST fails the script. This is the same
rule the regression suite uses, applied where the schedule is the workload's own.

# Regression-suite tests that are non-deterministic under stock ThreadSanitizer

The report-level comparison (every test's race report under each configuration against the report
under stock, keyed by `tsan_reports.py`) was made in the K = 5 replay recorded under
`data/suite/replay-aa8a6dd8a2e8/` (`CLAIMS.md`, section 1); `30-preservation-suite.sh` itself compares
pass and fail per test. Three tests vary run to run under stock itself, verified at K = 20 on an earlier
compiler; they are named here so that a reader of the replay does not take them for differences.

| Test | What varies | Under stock, K = 20 | Under every configuration |
|---|---|---|---|
| `race_on_barrier2.c` | which thread the race is reported from (the same race, seen from whichever access came second) | 18/20 one way, 2/20 the other | same pair, same proportions |
| `fd_location_closed.cpp` | the wording of the location descriptor line, not the race or its stacks | one L2 key 20/20 | one L2 key 20/20 |
| `fork_atexit.cpp` | whether the report appears at all in a given run | about one run in five | about one run in five |

One further test is not a report-level variation but a stall. `getline_nohang.cpp` exists to check that
ThreadSanitizer does not deadlock on a stdio stream lock at exit while a detached thread blocks in
`getline()` (its own comment; google/sanitizers issues 454 and 1733). Upstream marks it unsupported from
glibc 2.38 on, where that deadlock came back, and the image's Ubuntu 24.04 carries glibc 2.39: the test
should be skipped there and is not, because the vendored lit configuration detects the glibc version through
`distutils`, which Python 3.12 no longer has, and swallows the failure (`tests/lit.common.cfg.py`, the bare
`except` around `add_glibc_versions`), so no `glibc-*` feature is ever added; two tests that require glibc
2.30 are skipped for the same reason. Found 20 Sep 2026; the one-line fix, a tuple comparison in place of
`LooseVersion`, changes which tests run and goes in after the submission together with a re-run of the
suite (the executed count and the zero failures are unaffected either way: the test never produced a
failure, and the two newly running tests are not race tests). Until then a run in which the deadlock occurs
waits out the per-test timeout. So a stall is the
deadlock the test looks for, under stock ThreadSanitizer as under every configuration: the test either
passes in seconds or times out, under stock, EA and STC alike, it is flaky and not configuration-specific,
and under the counting rule it can never become a candidate lost race because it does not pass under stock
every time. The wall-time cost is real: `lit` runs the tests in name order, so a stalled repeat usually
outlives the rest of its configuration's run and the machine sits idle for up to two minutes per stalled
repeat, which an evaluator watching the load sees as idle periods; on a host where the stall is frequent
that is a large share of the suite's time: on our 8-processor run of 19 Sep it stalled 40 of 60 repeats,
up to 80 of the suite's 117 minutes (`ART_LIT_TIMEOUT=60` halves it, at the price of a shorter limit
for every test). Its stall rate rises with machine load, which is why we give
two figures rather than one: on an otherwise idle machine it stalled 3 times in 21 repeats of the full
383-test suite, roughly one repeat in six or seven; in the shipped-compiler run of 17 Sep,
60 repeats at 64 lit jobs beside a concurrent build on the other processors, it stalled 48 times in 60,
under all twelve configurations including stock. That run differed from the idle one in four recorded
ways (per-test timeout 120 s against 600 s, 64 lit jobs against 96, a 64-processor cpuset against none,
and the concurrent load), so we attribute the higher rate to load only loosely; what the two figures
establish together is that an evaluator on a busy or small machine should expect it frequently and
should read a two-minute pause as this test, not as a hang. What we cannot say
is whether a longer limit would let a stalled run finish: those runs were cut at the timeout, not
observed to complete. The cost is the timeout itself: at 600 s a single stall turned a 25-minute suite
into a two-hour one, so the per-test timeout is 120 s (`ART_LIT_TIMEOUT` to change it). Nothing else in
the suite failed across these runs.

Everything else in the suite is deterministic: it reports the same race with the same stacks
(function, file, line) under every configuration, or reports nothing under every configuration.
