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

- **First execution.** Without a warm-up run, the first run of a binary deviates: measured on an
  earlier campaign that had none, the median shift of a speedup from dropping run 1 was 0.70
  points and the maximum 3.77, in a direction set by the baseline's own first run (memcached up,
  Redis down). The artifact's scripts run one discarded warm-up per configuration and report
  steady state, and the campaign shows that this works rather than assuming it: with the warm-up
  in place, run 1 is above the median of runs 2 to 5 in 9 of 14 Redis configurations (median
  difference +0.63%) and 6 of 14 memcached configurations (median difference -1.47%), which is a
  coin toss around zero. The tables computed over all five runs and over runs 2 to 5 agree
  everywhere within intervals, for the same reason.
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
  its coefficient of variation is 10-12% at N = 5 and the speedup intervals of its twelve
  instrumented configurations are 11.9 to 15.7 points wide, measured on the campaign. Rows
  inside that interval are nulls, not zeros.
- **MySQL**: intervals of the same order, about 14 points wide on the earlier campaign; the current figures replace this line when its leg completes. Same reading. Its EA-bearing configurations take about
  2.2 hours each to build with this compiler.
The provenance rule
cannot be used that way, and it buys a statement a reviewer can check instead of an argument: no
cell in the dataset overlapped a known foreign-work window.

What the provenance rule is not: an outlier filter. The retired cell turned out to be an ordinary
measurement. SQLite's run-to-run spread within one configuration is 17.2% of the median (maximum
37.9%, on the uninstrumented build), so the 14% gap that drew attention to that cell is below the
workload's normal spread, and the value-dependent rule would have kept it. Provenance removed an
unremarkable cell and does not claim it was bad; the price is one cell in seventy, refilled inside
the same leg.
- **FFmpeg**: `-threads` is an input to the encoder, not a count of contending threads; libx265
  sizes its own worker pool and refuses more than 16 frame threads, above which the h265 codec
  silently disappears from the results. Check that all four codecs produced output.
- **Redis**: throughput declines monotonically with client count from the tool's default of 50;
  there is no saturation knee.

## Pinning is a pin for the workload, not an exclusion for everything else

The benchmark is confined to its processor set; nothing stops other processes being scheduled there,
and in our campaign our own interactive sessions, a remote-development backend and `sshd` all were.

How much they consumed, computed per run from each run's own accounting as measured busy time on the
pinned processors minus the workload's own CPU time, over the 211 measured runs of the completed
legs:

| | share of the 48 pinned processors |
|---|---|
| median | 0.28% |
| 90th percentile | 0.47% |
| maximum | 1.13% |
| runs whose estimate is negative | a third of them |

A third of the estimates come out below zero, which is the honest measure of this method's
precision: the foreign share sits at the limit of what the accounting resolves, about one per cent.
So the defensible statement is a bound and not a value: **foreign consumption on the pinned
processors is under roughly one per cent of their capacity, and this accounting cannot resolve it
more finely.**

Whether it is correlated with configuration was tested rather than assumed, by comparing the spread
between configuration means with the scatter between runs of one configuration:

| | between configurations | within a configuration | reading |
|---|---|---|---|
| Redis | 0.063 pp | 0.164 pp | configuration explains little |
| SQLite | 0.036 pp | 0.086 pp | configuration explains little |
| memcached | 0.165 pp | 0.189 pp | inconclusive |

On memcached the estimator is dominated by accounting error: its estimates are negative for every
configuration, because the server runs outside the timed region and its ticks are added back by
hand. The comparable spreads there are more likely that error tracking configuration than foreign
load doing so, and the question cannot be answered on that application. It also does not arise
there: the quantity bounded above is under one point, while the narrowest speedup interval among
memcached's twelve instrumented configurations is 11.9 points, more than ten times wider.

Where the question can be answered, foreign activity adds to run-to-run variation rather than
shifting configurations relative to one another, and that variation is already contained in the
reported intervals. One mechanism by which it could couple to configuration is known and weak:
foreign share correlates with run duration at r = 0.18 over the 211 runs, and configurations differ
slightly in duration.

**The per-process file records presence, not consumption.** Each run ships
`cpuset-intruders.txt` and the `cpuset_intruders` fields of `meta.json`, listing the processes seen
on the pinned CPUs. They come from `ps -eo psr,pcpu,comm`, where `pcpu` is a process's average CPU
over its whole lifetime and `psr` is merely the processor it was last seen on. A row reading 1002%
therefore means "a process whose lifetime average is ten cores was, at one sampling instant, last
seen on one of our processors" -- it says nothing about what that process took during the run. Use
the file to answer "was anything else on these cores", and the table above to answer "how much".

## Builds and benchmarks on one machine

A full LLVM build correctly pinned away from the benchmark CPUs still puts them four to five times
over our foreign-activity gate and invalidates every run in flight. Do not build anything while
`40-perf.sh` runs; the script refuses to start if it detects a compiler build and records foreign
CPU share per run so a disturbed run is dropped, not averaged in.

## An unpinned run is not gate-checked

The disturbance gate reads busy time on the CPUs outside `ART_CPUSET`. With `ART_CPUSET` empty, the
artifact's default on a machine that is not ours, there are no CPUs outside the set and nothing to
measure; the harness records `outside_busy_share` as null with `gate_checked: false` beside it and prints
"not gate-checked" rather than a zero that would read as a quiet machine. Pin a set of at least 32 CPUs and leave the rest idle if
you want a run that can be compared with ours.

## Lower N is not a smaller interval

At N = 3 the percentile bootstrap interval is 6-14% *narrower* than at N = 5 while the point
estimate moves by about 4 points depending on which three runs are kept. `--smoke` mode (N = 1)
therefore prints its numbers with an explicit "not a measurement" marker, and no result from fewer
than five runs should be compared with `CLAIMS.md`.
