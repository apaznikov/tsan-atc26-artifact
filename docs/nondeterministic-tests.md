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

Everything else in the suite is deterministic: it reports the same race with the same stacks
(function, file, line) under every configuration, or reports nothing under every configuration.
