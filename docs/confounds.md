# What makes the performance numbers vary, and by how much

Read this before comparing your run with `CLAIMS.md`. Every item below was measured, not assumed.

## Speedup ratios travel; absolute overheads do not

Every speedup in the paper is a ratio against stock ThreadSanitizer built by the same compiler tree
and run in the same window. Ratios are stable across trees because both sides share the runtime;
absolute "x times native" figures are not comparable across compiler trees, and one of ours was
inflated by a runtime counter that has since been compiled out. Compare your ratios with ours;
compare your absolute overheads only with each other.

## The shared denominator

Every configuration of an application divides by the same stock-TSan runs. One unusual baseline
run therefore moves every ratio of that application in the same direction, and a per-configuration
confidence interval cannot show it because the error is correlated across rows. Two consequences
we measured:

- **First execution.** Without a warm-up run, the first run of a binary deviates; on our campaign
  the median shift of a speedup from dropping run 1 was 0.70 points, the maximum 3.77, in a
  direction set by the baseline's own first run (memcached up, Redis down). The artifact's scripts
  run one discarded warm-up per configuration and report steady state.
- **Between sessions.** Byte-identical Redis binaries measured six days apart on the same host
  gave stock ThreadSanitizer 14% less throughput on the later date and an uninstrumented build 5%
  less, so eight of thirteen Redis rows changed verdict between the two sessions. The cause was not
  established (load, reboot, governor, huge pages, NUMA, swap, thermal throttling and a contended
  core were each eliminated). Every leg we ship records its machine conditions in `session.json`;
  do the same, and treat a disagreement with our Redis rows of a few points as within this effect.

## Concurrency

The sweep in `data/perf/contention-d3bf9f8c39fe` shows the speedup flat from 2 to 112 threads on
SQLite's walthread1 and flat from 50 to 512 clients on Redis, and rising on FFmpeg's AllOpt+peel
from 1.007 at 2 threads to 1.055 at 16 (libx265's ceiling). The point plots use the paper's own
thread counts; the curves are shipped so no point is hidden.

## Application-specific noise

- **memcached**: wall time is bimodal (two modes about 20% apart, sticky for tens of minutes), so
  its coefficient of variation is 10-12% at N = 5 and its interval is about 12 points wide. Rows
  inside that interval are nulls, not zeros.
- **MySQL**: interval about 14 points wide; same reading. Its EA-bearing configurations take about
  2.2 hours each to build with this compiler.
- **SQLite**: seven subtests of unequal stability; `stress1` and `dynamic_triggers` carry 16-20%
  run-to-run variation, so every SQLite row is reported twice, over all seven and over the four
  resolvable subtests (walthread1, walthread2, checkpoint_starvation_1, checkpoint_starvation_2).
- **FFmpeg**: `-threads` is an input to the encoder, not a count of contending threads; libx265
  sizes its own worker pool and refuses more than 16 frame threads, above which the h265 codec
  silently disappears from the results. Check that all four codecs produced output.
- **Redis**: throughput declines monotonically with client count from the tool's default of 50;
  there is no saturation knee.

## Builds and benchmarks on one machine

A full LLVM build correctly pinned away from the benchmark CPUs still puts them four to five times
over our foreign-activity gate and invalidates every run in flight. Do not build anything while
`40-perf.sh` runs; the script refuses to start if it detects a compiler build and records foreign
CPU share per run so a disturbed run is dropped, not averaged in.

## An unpinned run is not gate-checked

The disturbance gate reads busy time on the CPUs outside `ART_CPUSET`. With `ART_CPUSET` empty, the
artifact's default on a machine that is not ours, there are no CPUs outside the set and nothing to
measure; the harness records `outside_busy_share` as null and prints "not gate-checked" rather than
a zero that would read as a quiet machine. Pin a set of at least 32 CPUs and leave the rest idle if
you want a run that can be compared with ours.

## Lower N is not a smaller interval

At N = 3 the percentile bootstrap interval is 6-14% *narrower* than at N = 5 while the point
estimate moves by about 4 points depending on which three runs are kept. `--smoke` mode (N = 1)
therefore prints its numbers with an explicit "not a measurement" marker, and no result from fewer
than five runs should be compared with `CLAIMS.md`.
