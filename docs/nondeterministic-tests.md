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

`30-preservation-suite.sh` compares every test's race report under each configuration with the
report under stock ThreadSanitizer. Three tests vary run to run under stock itself, verified at
K = 20; the script names them in its output and excludes them from the "identical" count rather
than letting them appear as differences.

| Test | What varies | Under stock, K = 20 | Under every configuration |
|---|---|---|---|
| `race_on_barrier2.c` | which thread the race is reported from (the same race, seen from whichever access came second) | 18/20 one way, 2/20 the other | same pair, same proportions |
| `fd_location_closed.cpp` | the wording of the location descriptor line, not the race or its stacks | one L2 key 20/20 | one L2 key 20/20 |
| `fork_atexit.cpp` | whether the report appears at all in a given run | about one run in five | about one run in five |

One further test is not a report-level variation but a stall. `getline_nohang.cpp` either passes in
seconds or waits out the per-test timeout, under stock, EA and STC alike, so it is flaky and not
configuration-specific, and under the counting rule it can never become a candidate lost race because
it does not pass under stock every time. Its stall rate rises with machine load, which is why we give
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
