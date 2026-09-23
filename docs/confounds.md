# What makes the performance numbers vary, and by how much

Read this before comparing your run with the campaign's tables (`data/perf/campaign-f3deebfbab60/`). Every item below was measured, not assumed.

## Speedup ratios travel; absolute overheads do not

Every speedup in the paper is a ratio against stock ThreadSanitizer built by the same compiler tree
and run in the same window. Ratios are stable across trees because both sides share the runtime;
absolute "x times native" figures are not comparable across compiler trees, and one of ours was
inflated by a runtime eviction counter that the shipped runtime does not compile in. Compare your ratios with ours;
compare your absolute overheads only with each other.

## The shared denominator

Every configuration of an application divides by the same stock-TSan runs. One unusual baseline
run therefore moves every ratio of that application in the same direction, and a per-configuration
confidence interval cannot show it because the error is correlated across rows. Two consequences
we measured:

- **First execution.** Without a warm-up run, the first run of a binary deviates: measured on an
  earlier campaign that had none, the median shift of a speedup from dropping run 1 was 0.70
  points and the maximum 3.77, in a direction set by the baseline's own first run (memcached up,
  Redis down). The artifact's scripts run one discarded warm-up per configuration. With the warm-up
  in place, run 1 is above the median of runs 2 to 5 in 9 of 14 Redis configurations (median
  difference +0.63%) and 6 of 14 memcached configurations (median difference -1.47%), a coin toss
  around zero, and the point estimate over runs 2 to 5 lies inside the all-five interval on every row.
- **Between sessions.** Byte-identical Redis binaries measured six days apart on the same host
  gave stock ThreadSanitizer 14% less throughput on the later date and an uninstrumented build 5%
  less, so eight of thirteen Redis rows changed verdict between the two sessions. The cause was not
  established (load, reboot, governor, huge pages, NUMA, swap, thermal throttling and a contended
  core were each eliminated). Every leg we ship records its machine conditions in `session.json`;
  do the same, and treat a disagreement with our Redis rows of a few points as within this effect.

## Concurrency

The sweep in `data/perf/contention-d3bf9f8c39fe`, taken with an earlier compiler, shows the speedup flat
from 2 to 112 threads on SQLite's walthread1 and from 50 to 512 clients on Redis, and rising on FFmpeg's
AllOpt with peeling from 1.007 at 2 threads to 1.055 at 16 (libx265's ceiling). The curves on the shipped
compiler are in `data/perf/ffmpeg-threadsweep-f3deebfbab60/` and `data/perf/campaign-f3deebfbab60/sweep-*`: FFmpeg's thread sweep (AllOpt with peeling 1.005 and 1.010 at 2 and 4
threads, 1.063 and 1.065 at 8 and 16; DynSTC about 1.11 at every count) and, measured after the campaign,
memcached's server threads, Redis's clients and SQLite's walthread1 threads. FFmpeg's rows are compared at
16 threads by default and at the paper's 4 with `FF_THREADS=4`; the other applications at the campaign's
concurrency.

## Application-specific noise

- **memcached**: on the earlier campaign its wall time was bimodal (two modes about 20% apart, sticky
  for tens of minutes); on the shipped campaign the per-configuration variation is 1 to 3% at N = 5,
  and the speedup intervals of its twelve instrumented configurations are still 11.9 to 15.7 points
  wide (a ratio's bootstrap over five runs). Rows inside that interval are nulls, not zeros. The two modes
  returned on another host with a different processor-set shape (32 cores, 16 of them with both SMT threads)
  and vanished on that host's sibling-paired set: the bimodality follows the set's shape
  (`docs/campaign-parameters.md`, "The shape of the processor set").
- **MySQL**: intervals 7 to 8 points wide on the campaign (AllOpt with peeling 1.042 [0.985, 1.062], with
  DynSTC 1.018 [0.967, 1.037]). Same reading. Its EA-bearing configurations took about 2.2 hours each to
  build with the previous compiler and take about 8 minutes (459 s at 56 jobs) with the shipped one.
- **SQLite**: the seven subtests are heterogeneous; two of them carry about 15 per cent run-to-run
  variation, and the uninstrumented build varies by 37.9 % run to run. The resolvable-subtest column exists
  for this.
- **FFmpeg**: `-threads` is an input to the encoder, not a count of contending threads; libx265
  sizes its own worker pool and refuses more than 16 frame threads, above which the h265 codec
  silently disappears from the results. Check that all four codecs produced output.

## Pinning is a pin for the workload, not an exclusion for everything else

The benchmark is confined to its processor set; nothing stops other processes being scheduled there,
and in our campaign interactive sessions and `sshd` were.

How much they consumed, computed per run from each run's own accounting as measured busy time on the
pinned processors minus the workload's own CPU time, over 211 of the campaign's measured runs:

| | share of the 48 pinned processors |
|---|---|
| median | 0.28% |
| 90th percentile | 0.47% |
| maximum | 1.13% |
| runs whose estimate is negative | a third of them |

A third of the estimates come out below zero, which is the measure of this method's precision: the
foreign share sits at the limit of what the accounting resolves, about one per cent. So the statement
is a bound and not a value: **foreign consumption on the pinned processors is under roughly one per
cent of their capacity, and this accounting cannot resolve it more finely.**

Whether it is correlated with configuration was tested by comparing the spread between configuration
means with the scatter between runs of one configuration:

| | between configurations | within a configuration | reading |
|---|---|---|---|
| Redis | 0.063 pp | 0.164 pp | configuration explains little |
| SQLite | 0.036 pp | 0.086 pp | configuration explains little |
| memcached | 0.165 pp | 0.189 pp | inconclusive |

On memcached the estimator is dominated by accounting error: its estimates are negative for every
configuration, because the server runs outside the timed region and its ticks are added back by
hand. The question cannot be answered on that application, and it does not arise there: the quantity
bounded above is under one point, while the narrowest speedup interval among memcached's twelve
instrumented configurations is 11.9 points. Where the question can be answered, foreign activity adds
to run-to-run variation rather than shifting configurations relative to one another, and that variation
is already contained in the reported intervals. One weak coupling is known: foreign share correlates
with run duration at r = 0.18 over the same 211 runs, and configurations differ slightly in duration.

**The intruder fields record presence, not consumption.** Each run's `meta.json` carries
`cpuset_intruders` (how many foreign processes were seen on the pinned CPUs) and
`cpuset_intruder_peak_pcpu`; the per-sample list of process names behind them is written during a run
but not shipped. The counts come from `ps -eo psr,pcpu,comm`, sampled every two seconds, where `pcpu` is a process's average CPU
over its whole lifetime and `psr` is merely the processor it was last seen on. A peak reading 2586
therefore means "a process whose lifetime average is about 26 cores was, at one sampling instant, last
seen on one of our processors"; it says nothing about what that process took during the run. Use the
fields to answer "was anything else on these cores", and the table above to answer "how much"; the
disturbance gate that retires cells reads busy time, not these fields.

## Builds and benchmarks on one machine

A full LLVM build correctly pinned away from the benchmark CPUs still puts them four to five times
over the foreign-activity gate and invalidates every run in flight. Do not build anything while
`40-perf.sh` runs; the script refuses to start if it detects a compiler build and records foreign
CPU share per run so a disturbed run is dropped, not averaged in.

## Other people's load retires cells, and the output says so

The gate does not distinguish your builds from anyone else's. On a shared machine, a colleague's
compilation, an IDE's background build, or a scheduled job on the processors outside your `ART_CPUSET`
raises `outside_busy_share` above the 0.10 threshold, and every cell measured under it is marked
DISTURBED in the run log, re-run once at the end of the leg, retired again if the load persists, and
dropped; the aggregate then reports the configuration with fewer runs than requested or with no data,
never with a number taken under the load. A leg with retired cells is not a result to interpret: read
`outside_busy_share` in each cell's `meta.json`, find what was running on the other processors, and re-run
the leg on a quiet machine.

With 48 processors pinned on a 112-thread host, 64 processors are watched, and 0.10 of them is about six
cores of anything at all. Pinning fewer processors does not help; it enlarges the watched set. The
campaign's cells record `n_outside: 56` because `harness/tools/perf/ignore_cpus` then excluded eight
processors from the watched set; the shipped file excludes nothing, so an evaluator's gate watches every
processor outside the set. The threshold is the campaign's (`P5_FOREIGN_MAX`, 0.10), and every session
records the value in force as `foreign_max` in `session.json`; a run at a looser threshold is possible,
and the record then says so beside every cell.

## The container sees the processors the daemon allows

Inside the container `nproc` reports the processors the Docker daemon's own cgroup allows, which can be
fewer than the host has (104 of 112 on our machine). With `ART_CPUSET` empty that number is what the
thread rule and `ART_JOBS` derive from, and it is recorded in each session as `ncpu`; it is a property of
the host's Docker configuration, not of the artifact.

## An unpinned run is not gate-checked

The disturbance gate reads busy time on the CPUs outside `ART_CPUSET`. With `ART_CPUSET` empty there are
no CPUs outside the set and nothing to measure; the harness records `outside_busy_share` as null with
`gate_checked: false` beside it and prints "not gate-checked" rather than a zero that would read as a
quiet machine. The absence is recorded as a false flag beside the cell, not as a missing field. Pin 48
CPUs of the campaign's shape (which also fixes memcached's thread count) and leave the rest idle if you
want a run that can be compared with ours.

## Lower N is not a smaller interval

At N = 3 the percentile bootstrap interval is 6-14% *narrower* than at N = 5 while the point
estimate moves by about 4 points depending on which three runs are kept. `ART_SMOKE=1` mode (N = 1)
therefore prints its numbers with an explicit "not a measurement" marker. A result from two to four runs
is read as a point against the campaign's interval, never as an interval of its own.

## Foreign load inside the pinned set is invisible from inside the container

The disturbance gate measures the processors outside the pinned set, so a foreign process whose affinity
covers the whole machine and that the scheduler places inside the set is not seen by it: the cell reads
clean and is slower. The per-cell intruder record (`cpuset_intruders`, `cpuset_intruder_peak_pcpu`) exists
for that case, but the artifact's runs execute inside a container with its own pid namespace, where `ps`
lists the container's processes only, so from the evaluator path the record can name nothing on the host;
we have seen a foreign job run inside the set while every cell recorded zero intruders. Keep the whole host
quiet during a timed leg, and read an outside row first against the leg's own `inside_busy_share`
distribution.
