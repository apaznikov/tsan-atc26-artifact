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

## Regression-suite tests that are non-deterministic under stock ThreadSanitizer

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

One further test, `getline_nohang.cpp`, is not a report-level variation but a test that should not have
been running. It checks that ThreadSanitizer does not deadlock on a stdio stream lock at exit while a
detached thread blocks in `getline()` (its own comment; google/sanitizers issues 454 and 1733), and upstream
marks it `UNSUPPORTED: glibc-2.38`, which lit reads as "2.38 and later"; the image's Ubuntu 24.04 carries
glibc 2.39. Until 21 Sep 2026 it ran anyway, because the vendored lit configuration detected the glibc
version through `distutils.version.LooseVersion`, which Python 3.12 no longer has, inside a bare `except`
that swallowed the import error: no `glibc-*` feature was ever added, so this test ran, and two tests that
`REQUIRES: glibc-2.30` (`pthread_mutex_clocklock.cpp`, `Linux/clockwait_double_lock.c`) were skipped. The
fix is one comparison in `tests/lit.common.cfg.py` (a tuple of integers in place of `LooseVersion`, marked in
the file as the artifact's only modification of the vendored suite); exactly three tests in the suite are
gated on glibc, so the fix moves exactly those three: 91 unsupported and 292 executed before it, 90 and 293
after, measured on 21 Sep 2026 (`data/suite/`), with 0 failures and 0 timeouts in 60 repeats on both hosts.

What the defect had cost, so that the earlier figures in this repository's history read correctly: a run in
which the deadlock occurred waited out the per-test timeout (120 s), and since `lit` runs tests in name order
the stalled repeat outlived the rest of its configuration's run and the machine sat idle for up to two minutes
per stalled repeat. The shipped-compiler run of 17 Sep (`data/suite/preservation-suite-20260917T075005Z`)
stalled in 48 of 60 repeats; a run on 8 processors on 19 Sep in 40 of 60, most of its two hours; a run on 112
unpinned processors on 20 Sep in 1 of 60. Earlier text here called the test flaky and its stall rate
load-dependent; both are withdrawn: the stall was a test running on a glibc it is unsupported on, and the
runs whose rates were compared differed in four recorded ways, so no dependence on load was established.
Under the counting rule the stalls were timeouts, never failures, and could not have become a candidate
lost race. Nothing else in the suite failed across any of these runs.

Everything else in the suite is deterministic: it reports the same race with the same stacks
(function, file, line) under every configuration, or reports nothing under every configuration.
