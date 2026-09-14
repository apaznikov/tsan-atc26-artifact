# run1 and the shared denominator — what the effect actually is

Found 2026-09-13 from a question by the tsan-dev lane, checked against the 500 clean runs of Stage B, and then
**substantially revised the same evening** when the discriminating check was run. The revision matters more
than the original finding, so it is first.

**The harness has no warm-up run.** `bench_one.sh` executes the workload once and records it, so run 1 of every
configuration is the first execution of that binary on that data. That much is unchanged.

## What was first claimed, and why it was too strong

Dropping run 1 and recomputing every Stage B speedup on runs 2-5 shifts the result by a median of 0.70 pp and
up to 3.77 pp, with a sign that is consistent *within* each application and differs *between* them:

| application | configurations | shift > 0 | shift < 0 | median shift |
|---|---|---|---|---|
| memcached | 14 | 13 | 1 | +1.92 pp |
| redis | 12 | 0 | 12 | −0.79 pp |
| sqlite | 12 | 10 | 2 | +0.44 pp |
| ffmpeg | 10 | 1 | 9 | −0.12 pp |
| mysql | 10 | 5 | 5 | −0.05 pp |

I read that consistent sign as evidence of an **arm-dependent** effect — run 1 penalising heavily instrumented
binaries more than light ones, which equal N per arm cannot protect against. That reading was wrong.

## What the discriminator shows

Three candidate mechanisms were named: position in the run-major block, cold start scaling with instrumentation
weight, and workload state that is not idempotent across runs. All three are testable on data already on disk.

| application | n | mean run-1 deviation | spread | r(execution order) | r(static sites) |
|---|---|---|---|---|---|
| memcached | 16 | +0.35 % | 2.84 % | +0.15 | +0.04 |
| redis | 14 | −0.89 % | 1.91 % | +0.32 | +0.32 |
| sqlite | 14 | +1.27 % | 5.36 % | −0.03 | +0.19 |
| ffmpeg | 12 | −0.20 % | 0.47 % | −0.43 | −0.42 |
| mysql | 12 | +5.26 % | 5.25 % | −0.81 | −0.04 |

**Instrumentation weight explains nothing** — the correlations are +0.04, +0.32, +0.19, −0.42, −0.04, with no
consistent sign. **Execution order explains nothing except possibly on MySQL** (−0.81, n = 12). And application
identity accounts for only **24 %** of the variance in cell deviations, so it is not a clean per-application
offset either.

## The actual mechanism: one outlying baseline run, counted many times

Every speedup in an application shares one denominator — that application's stock-TSan runs. So a deviation in
**stock TSan's own run 1** moves every ratio in that application in the same direction, whatever the
configuration. The sign of stock TSan's run-1 deviation predicts the sign of the median shift in four of five
applications:

| application | stock TSan's run-1 deviation | median shift in speedup |
|---|---|---|
| memcached | +2.64 % | +1.92 pp |
| redis | **−5.04 %** | −0.79 pp |
| sqlite | +3.75 % | +0.44 pp |
| ffmpeg | −0.33 % | −0.12 pp |
| mysql | +10.64 % | −0.05 pp (the exception) |

Redis's baseline run 1 sits 2.2 standard deviations from that application's mean cell deviation; the others are
within one. **This is a shared-denominator sensitivity, not an arm-dependent bias.** The distinction is the
whole point: nothing here says instrumentation makes run 1 worse.

### Sign convention, and two cells anyone can check by inspection

**A deviation is sign-normalised into the metric's own better-is-higher direction, so a POSITIVE deviation
means run 1 was BETTER — faster, or higher throughput — not worse.** Stating that in prose was not enough: a
reader re-deriving the relationship from "stock TSan run-1 deviation +2.64 %" naturally reads it as "run 1 was
slow" and then gets the opposite sign in every row, correctly. So here are two cells with the raw numbers,
one of each sign, and the direction is checkable without trusting any convention.

```
memcached / tsan-sound / ops_sec        (higher is better)
  run:              1          2          3          4          5
  stock:      1674959    1601519    1671694    1592589    1662254     <- run 1 is the HIGHEST: fast
  config:     1583803    1579009    1608277    1625155    1621008
  stock median   all five 1662254   runs 2-5 1631887      (falls when run 1 is dropped)
  speedup        all five   0.9675   runs 2-5   0.9894    shift +2.19 pp

redis / tsan-dom / GET                  (higher is better)
  run:              1          2          3          4          5
  stock:       428225     467936     449688     496008     471465     <- run 1 is the LOWEST: slow
  config:      487310     480523     467499     469253     471021
  stock median   all five  467936   runs 2-5  469701       (rises when run 1 is dropped)
  speedup        all five   1.0066   runs 2-5   1.0009     shift -0.57 pp
```

Dropping a **fast** baseline run lowers the denominator and the speedup rises; dropping a **slow** one raises
the denominator and the speedup falls. That is the whole relationship, and it is arithmetic rather than a
mechanism — which is exactly why it transmits into every row of the application at once.

## Consequences, including for the statistics I quoted

- **The sign test was counting one fact many times.** Configurations inside an application are not independent
  trials — they share the denominator, the machine and the block — so "13 of 14 memcached configurations shift
  positive" is close to a single observation about memcached's baseline run 1, restated fourteen times. The
  p-values (0.0018, 0.0005, 0.0386, 0.0215) are **descriptive only** and must not be reported as inferential.
  The effect size is the argument; 1.92 pp is the argument.
- **No Stage B number is withdrawn.** All-five is the pre-registered aggregation and stays the headline. This
  is a disclosed sensitivity.
- **The prescription survives but its justification changes.** A discarded warm-up still helps, because it
  removes the first-execution run from every arm including the denominator. But the deeper exposure is that a
  five-run median in a *shared* denominator transmits one odd run into every ratio of that application at once,
  which a per-configuration interval does not show, because it is correlated error across rows rather than
  noise within one.
- **A choice that must be made deliberately, not inherited.** If part of the effect is workload state —
  SQLite's `walthread1` builds its database in run 1 and finds it in page cache afterwards, FFmpeg's input is
  on disk for run 1 and cached later — then discarding a warm-up means reporting **steady-state** rather than
  first-execution performance. That is defensible for a database benchmark, and so is the opposite (resetting
  state before every run, making all five runs like run 1). It should be chosen and written down, not acquired
  as a side effect of a harness change made for another reason.

## What would settle the remaining question

A single leg run **config-major** rather than run-major separates block position from the rest, and a leg with
the workload's state reset between runs separates workload state from cold start. Neither has been run; until
then the mechanism is narrowed to "not instrumentation weight, and not mainly application identity", which is
less than an answer.

## Addendum 2026-09-14: the Redis levels moved between dates, and the machine was not the same

Separate from the run-1 effect above, and found while sweeping: **the same byte-identical Redis binaries give
different throughput on different dates.** Verified sha256-equal on all fourteen arms across four result trees.
Relative to Stage B (8 September):

| config | 08 Sep | 13 Sep | 14 Sep recheck |
|---|---|---|---|
| native | 1.000 | 0.949 | 0.944 |
| stock TSan | 1.000 | **0.862** | **0.863** |
| DynSTC | 1.000 | 0.950 | 0.948 |
| AllOpt+peel | 1.000 | **0.873** | **0.860** |

The 13th and 14th agree to within 0.3 %, so it is a step rather than a disturbed run, and it is arm-dependent:
about 14 % on the heavily instrumented arms and 5 % on native and DynSTC. **Stage B's Redis DynSTC row changes
sign as a result** — 0.969 [0.950, 0.990], a conclusive loss, against 1.065-1.068 today, a conclusive gain.

**Eliminated:** machine load (the recheck ran at load 1.86 against Stage B's 1.10), reboot (same boot,
7 September), governor, THP (`thp_fault_fallback` zero since boot, all `compact_*` zero, 22 654 free
top-order blocks, `AnonHugePages` 0 kB), KSM (never run), NUMA (one node), swap (none), `/dev/shm`,
fragmentation, position in the run order, block length, binary identity, dynamic linkage (the TSan runtime is
statically linked — no `NEEDED` sanitizer entry, no RPATH or RUNPATH), and thermal throttling
(package throttling is live but 2 ms in 59 s, 0.0034 % of wall, against the ~14 % that would be needed).

**Two machine conditions that did differ between the dates, both documented rather than blamed:**

1. A JetBrains remote-development stack came up on **8 September at 13:52**, six hours after Stage B's Redis
   leg ran at 07:29-08:55, and has run unpinned (`affinity 0-111`) ever since. The timing is the best fit
   anyone found for a step. Its *present* cost is not: measured from `/proc/<pid>/stat` deltas rather than
   `ps pcpu` — which reports a **lifetime** average and had this at 62 % — the actual current figure is 7.4 %,
   and total non-benchmark load is 148 % of a core, **1.32 % of machine capacity**. Cycle theft at that level
   does not explain 14 %. Cache and memory-bandwidth pollution remains available and is not measurable from
   `/proc`; it would need LLC-miss and offcore counters on the bench CPUs with and without the stack.
2. A stuck `rev` process burned a full core from **13 September 18:37** until it was killed at
   **14 September 12:21** — through the whole concurrency sweep and the recheck, but not during Stage B. One
   core of 112, and the arms are not equally exposed to it.

**Consequence for how the trees are read.** If the machine changed on 8 September and stayed changed, then
Stage B is the outlier and every measurement since is the machine as it now is. The concurrency sweep's
internal comparisons are all within one window, so its trend conclusions stand; any cross-date comparison with
Stage B is suspect in both directions, including the Redis DynSTC sign change above.
