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
