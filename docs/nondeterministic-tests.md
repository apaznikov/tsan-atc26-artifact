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

One further test, `getline_nohang.cpp`, is not a report-level variation but a test that should not run
here. It checks that ThreadSanitizer does not deadlock on a stdio stream lock at exit while a detached
thread blocks in `getline()` (google/sanitizers issues 454 and 1733), and upstream marks it
`UNSUPPORTED: glibc-2.38`, which lit reads as "2.38 and later"; the image's Ubuntu 24.04 carries glibc 2.39.
The vendored lit configuration detected the glibc version through `distutils.version.LooseVersion`, which
Python 3.12 no longer has, inside a bare `except`, so no `glibc-*` feature was added. The artifact's one
modification of the vendored suite, in `tests/lit.common.cfg.py`, compares versions as tuples of integers
instead. Exactly three tests in the suite are gated on glibc, and the fix moves exactly those three: 90
unsupported and 293 executed, with 0 failures and 0 timeouts in 60 repeats on both hosts
(`data/suite/preservation-suite-20260921T052239Z`). The earlier run shipped beside it
(`data/suite/preservation-suite-20260917T075005Z`, 91 unsupported, 292 executed) predates the fix, and there
`getline_nohang.cpp` waited out its per-test timeout in 48 of 60 repeats: timeouts, never failures, so never
a candidate lost race.

Everything else in the suite is deterministic: it reports the same race with the same stacks
(function, file, line) under every configuration, or reports nothing under every configuration.
