# Results ledger — what each optimisation is actually worth

The standing record of every measured optimisation, so it is possible to see at a glance which ones pay. The
tables between the markers are **regenerated from the results trees** by `results_ledger.py`; nothing in them
is typed by hand, so a number here cannot drift from the run that produced it. The narrative around them is
written by hand.

**To update:** `python3 tools/perf/results_ledger.py` after any new measurement. To add a new experiment, add
one entry to `TREES` in that script; a tree that does not exist yet is listed as *pending* rather than omitted,
because an absent row and a null row must never look the same.

**Rules this ledger follows.** A speedup is quoted only against the same configuration without the lever, from
one compiler with one switch, never across compilers. "Not resolved" is a null, not a zero: it means the effect
is below that application's resolution (12.2 points on memcached, 14.1 on MySQL), not that there is no effect.
Bold marks an interval that excludes 1.0.

---

## ⚠ Redis rows are under review as of 2026-09-14

**Stage B's Redis table does not reproduce.** Re-measured today on byte-identical binaries, N = 5, same
cpuset: **eight of thirteen rows change verdict**, including both of Redis's conclusive ones. DE goes from a
conclusive gain (1.020) to a null (1.002); AllOpt+peel with summaries stays a gain but quadruples (1.027 →
1.130); DynSTC flips from a conclusive **loss** (0.969) to a conclusive **gain** (1.084). Native rises from
7.934× stock TSan to 8.914×, which is the same fact stated the other way: the denominator moved.

Cause not established. Eliminated: load, reboot, governor, THP, KSM, NUMA, swap, fragmentation, run-order
position, block length, binary identity, dynamic linkage, thermal throttling, and one contended core (tested
directly, median 1.012 over six arms). The best remaining candidate is cache and memory-bandwidth pollution
from an unpinned remote-development stack that started on 8 September at 13:52, six hours after Stage B's
Redis leg — an exact fit in time, but only 1.32 % of machine capacity in CPU, so it would have to act through
cache rather than cycles. Not asserted.

**Redis is the only application anyone has re-run.** memcached, SQLite, FFmpeg and MySQL were all measured on
the pre-8-September machine and none has been re-measured. They are **not known to be fine — they are
unexamined**, and every table below them should be read that way. The mechanism is not Redis-specific: the
*uninstrumented* arm moved too (7.934× → 8.914× stock, and −5.9 % in absolute throughput), which nothing about
shadow memory can explain.

**No Redis row from either tree should be quoted until this is resolved** —
`tools/notes/run1-cold-start-2026-09-13.md`, addendum 2026-09-14. Nothing here affects the concurrency sweep,
whose every comparison sits inside one window.

**The decision this presents is not "which dataset is right".** Both are internally consistent — each was one
leg on one machine — and they disagree because the machine differs, not because either is wrong. The question
is which machine the paper reports, and the only defensible answer is the one that exists now and that an
artifact reviewer can reproduce. That makes the work ahead "re-run everything once, on a machine whose state is
written down", not "re-run Redis".

## Standing summary

**The execution speedup in this project came from a flag that already existed, not from the analyses.**
Turning off shadow-stack maintenance (`-mllvm -tsan-instrument-func-entry-exit=false`) is worth 23 % on Redis,
14 % on MySQL and 4.4 % on SQLite. The best analysis-based result anywhere in the 58-row campaign is 1.027 on
Redis. The compiler work bought compile time and soundness fixes; it did not buy execution speed.

*Alexey's ruling, 2026-09-13: the flag does not appear in the paper at all — it is upstream LLVM and not this
project's contribution, so it belongs in neither the evaluation nor the camera-ready tables. It stays measured
here, because this ledger records what is true rather than what is ours.*

**What orders the shadow-stack lever is the share of instrumented cycles it occupies**, and that ordering holds
across all five applications with no inversions — though only three are individually resolved, so it is three
points ordered correctly rather than five. Its *magnitude* is unexplained: 17.8 % of instrumented cycles
predicted about 5 % on Redis and delivered 23 %.

**Why the analyses bought nothing** is settled and mechanical. Dominance elimination removes an access only
when no release lies between it and its cover; a thread's epoch advances only on a release; so the removed
access has a shadow word identical to its cover's, which is exactly what `ContainsSameAccess` tests — and that
check returns before the trace write and the race check. The analyses remove calls the runtime already answers
in about fifteen cycles. Making them more aggressive extends the same worthless class.

**That open question has now been answered, and the answer is that quantity was never the variable.** The
campaign's flat reach-versus-speedup curve had one escape: every point on it came from analyses that remove
fast-path *hits*, so perhaps a transform aimed at *misses* would behave differently. The granule merge was
built to tell those two readings apart. It does remove executed accesses — 6.3 % on SQLite on top of
AllOpt-peel, well clear of that cell's 2.7 % floor — and the timing does not move: 1.034 [0.970, 1.101] on
SQLite, 0.990 [0.949, 1.056] on MySQL. A measured 4–6 % cut in executed accesses bought no measurable time.
That is the strongest single piece of evidence that what these transforms remove is work the runtime was
already doing cheaply, and it closes the quantity reading rather than leaving it open
(`tools/notes/achievable-speedup-2026-09-09.md`).

<!-- LEDGER-START -->

### Scoreboard — what each lever is worth

Speedup against the same configuration without the lever, geometric mean over the application's tests, 95 % bootstrap interval, N = 5. **Bold** means the interval excludes 1.0. A blank cell is not measured; "not resolved" is a null, not a zero — the effect is below that application's resolution, which is 12.2 points on memcached and 14.1 on MySQL.

**func entry/exit off** · compiler `d3bf9f8c39fe` · `results/nofe-d3bf9f8c39fe`  
*flag already upstream; costs report calling context, not soundness*

| application | speedup | resolvable subtests | verdict |
|---|---|---|---|
| redis | **1.233 [1.183, 1.254]** | **1.235** [1.183, 1.258] (18/19) | gain +23.5 % |
| mysql | **1.136 [1.081, 1.188]** | — | gain +13.6 % |
| sqlite | 1.057 [0.962, 1.241] | **1.044** [1.025, 1.060] (4/7) | gain +4.4 % |
| ffmpeg | 1.028 [0.977, 1.069] | — | not resolved |
| memcached | 1.026 [0.928, 1.122] | — | not resolved |

**granule merge** · compiler `afe47a2a75a5` · `results/merge-timing-afe47a2a75a5`  
*conditional on the counters showing executed misses fall*

| application | speedup | resolvable subtests | verdict |
|---|---|---|---|
| sqlite | 1.034 [0.970, 1.101] | 1.026 [0.984, 1.053] (4/7) | not resolved |
| mysql | 0.990 [0.949, 1.056] | — | not resolved |

### Contribution of each specific improvement

Percentage change in speed that **this one change** adds on top of the configuration named in the note — not what its family is worth. Each pair differs by exactly one improvement, measured in the same tree with the same N. **Bold** means the interval excludes zero; a plain number is inside the noise; `·` means that configuration does not exist for that application. Where an application has a resolvable-subtest set, the figure uses it.

| improvement | note | memcached | redis | sqlite | ffmpeg | mysql |
|---|---|---|---|---|---|---|
| escape analysis | alone, vs stock | -4.3 | +0.7 | +0.2 | +0.2 | +3.4 |
| lock ownership | alone, vs stock | -3.3 | +0.6 | -0.5 | -0.7 | -1.4 |
| single-threaded (STC) | alone, vs stock | -0.8 | +1.4 | -0.1 | -0.4 | -1.7 |
| dynamic single-threaded (DynSTC) | alone, vs stock | -2.6 | **-3.0** | **-1.7** | **+11.3** | -1.7 |
| SWMR | alone, vs stock | -0.7 | +0.4 | +0.3 | -0.6 | +0.6 |
| dominance elimination (DE) | alone, vs stock | -0.0 | **+1.6** | +0.1 | +0.4 | +0.9 |
| loop peeling | added to DE | -3.9 | -0.1 | -0.1 | +0.4 | -1.0 |
| the four sound analyses together | EA+LO+STC+SWMR vs stock | -3.2 | -0.2 | +0.3 | -0.1 | +2.1 |
| DE added to the sound bundle | AllOpt-peel vs sound | +3.2 | +0.9 | +0.0 | +0.2 | +0.1 |
| loop peeling added to AllOpt |  | -2.6 | +0.2 | -0.1 | +0.4 | -0.9 |
| whole-program summaries | added to sound | +0.1 | +1.4 | -0.6 | · | · |
| thread-free names | added to sound; memcached only | +0.5 | · | · | · | · |
| summaries added to thread-free names | memcached only | -1.2 | · | · | · | · |
| yield branch, all seven changes | on the sound bundle | -0.0 | -0.5 | -0.1 | -0.0 | · |
| yield branch, on stock | isolates the interceptor table | -1.9 | +0.0 | -0.2 | +0.9 | · |
| yield branch, on DynSTC | isolates C1 | -0.5 | +0.5 | -0.3 | +0.8 | · |
| yield branch, on AllOpt+peel |  | -0.4 | -0.5 | +0.8 | -0.3 | · |
| shadow-stack maintenance off | added to sound; costs report calling context | +2.6 | **+23.5** | **+4.4** | +2.8 | **+13.6** |

### The bar: best analysis-based result in the campaign

Every configuration of the paper's set, five applications, 58 rows with a speedup (`results/stageB-d3bf9f8c39fe`). Only these separate from stock TSan.

| application | configuration | speedup |
|---|---|---|
| ffmpeg | `tsan-stmt` | 1.113 [1.097, 1.124] |
| redis | `AllOpt+peel (WP summaries)` | 1.027 [1.008, 1.051] |
| redis | `tsan-dom` | 1.020 [1.002, 1.045] |

### Where the instrumented cycles go

Share of instrumented cycles by callback class, sound configuration, one sampled run per cell. The shadow-stack column is the lever above. **sync / clocks** is `SlotLock`, `Release`, `MetaMap::GetSync`, `VectorClock` and the mutex interceptors — the release machinery, which no analysis in the campaign touches and which dominates two applications. These figures were wrong until 2026-09-10: perf demangles C++ frames, and the classifier matched only the `__tsan_` C prefix, so every `__tsan::` frame was binned as application — 58 % of memcached's cycles.

| application | cycles in TSan | access callbacks | shadow stack | sync / clocks | range | other |
|---|---|---|---|---|---|---|
| memcached | 75.9 % | 52.2 % | **1.2 %** | 39.3 % | 0.0 % | 7.4 % |
| redis | 69.0 % | 62.5 % | **14.9 %** | 3.5 % | 0.0 % | 19.1 % |
| sqlite | 69.6 % | 89.0 % | **4.2 %** | 1.5 % | 0.0 % | 5.3 % |
| ffmpeg | 67.3 % | 88.5 % | **2.9 %** | 4.9 % | 0.0 % | 3.6 % |
| mysql | 84.1 % | 29.3 % | **6.4 %** | 56.1 % | 0.0 % | 8.2 % |

### Dynamic reach — what each improvement removes from the executed accesses

The mechanism behind the speedups above, and a different quantity from them: the change in executed access callbacks, one run per cell, negative meaning fewer. Every pair is taken inside one compiler copy. SQLite is normalised per threadtest3 iteration because its subtests run for a fixed time and a faster build simply completes more of them; the other applications do a fixed amount of work, so their raw totals compare directly. MySQL's counter leg is sampled for a fixed number of seconds with no completed-transaction count, so it cannot be normalised and is left out rather than compared wrongly.

**Repeatability floor**, from the configurations measured twice inside the same compiler copy: memcached 0.02 %; sqlite 2.67 %. A cell smaller than its application's floor is not a measurement of that improvement and is shown in parentheses; an application with no repeat of its own borrows the largest floor measured, which is the conservative choice. A floor read off a single pair of runs is itself optimistic: it is the smallest spread two runs happened to show, not the spread of the cell.

| improvement | note | copy | memcached | redis | sqlite | ffmpeg |
|---|---|---|---|---|---|---|
| granule merge | on the sound bundle | `afe47a2a75a5` | **-0.34** | · | (-2.47) | · |
| granule merge | on AllOpt-peel | `afe47a2a75a5` | **-0.25** | · | **-6.26** | · |
| granule merge | on AllOpt+peel | `afe47a2a75a5` | **-0.26** | · | **-4.41** | · |
| loop peeling | on AllOpt, merge on | `afe47a2a75a5` | (-0.00) | · | (+1.34) | · |
| loop peeling | on AllOpt, merge off | `afe47a2a75a5` | (+0.01) | · | (-0.63) | · |
| whole-program summaries | on the sound bundle | `1391bf330765` | **-0.96** | **-2.77** | **+5.73** | · |
| dominance elimination (DE) | alone, vs stock | `1391bf330765` | **-2.96** | (+1.48) | (-1.46) | (-0.30) |
| the four sound analyses | EA+LO+STC+SWMR vs stock | `1391bf330765` | **-0.04** | (+0.18) | **-2.77** | (-0.59) |
| AllOpt+peel | the whole bundle vs stock | `1391bf330765` | **-3.04** | **-3.40** | (-1.38) | (-0.99) |

### Executed-access counters

Counts, not costs — a fast-path hit and a function entry are not the same number of cycles. A miss costs about 19.6 cycles and a hit 5.8 (tsan-dev lane, lower bound).

| application | executed accesses | fast-path hits | func entries / access | mean range bytes |
|---|---|---|---|---|
| memcached | 3,612,950,374 | 22.9 % | 0.217 | 77 |
| redis | 2,068,677,823 | 95.7 % | 0.249 | 25 |
| sqlite | 13,696,440,631 | 92.7 % | 0.075 | 69 |
| ffmpeg | 2,148,096,363 | 86.9 % | 0.039 | 89 |
| mysql | 6,885,418,180 | 55.6 % | 0.645 | 53 |


<!-- LEDGER-END -->

---

## Change log — what was measured, when, and what it bought

Newest first. Each entry names the compiler state, what changed in it, and the outcome.

### 2026-09-13 · shadow-stack preservation · `d3bf9f8c39fe` — **no race lost; the stacks collapse from 15 frames to 1.5**
The ledger's largest number rested on a claim that was reasoned, not measured. It is now measured. SQLite
`threadtest3`, three arms on one compiler copy, N = 10, run-major, pinned
(`tools/preservation/results/sqlite/2026-09-13-nofe-d3bf9f8c39fe`). Acceptance condition checked before launch:
`__tsan_func_entry` call sites go 1610 → 0 between the two sound arms.

| config | runs | reports/run | union L1 | union L2 | union L3 | frames per stack |
|---|---|---|---|---|---|---|
| `tsan` | 10 | 2.5 ± 1.4 | 7 | 2 | 5 | 15.5 (median 15) |
| `tsan-sound` | 10 | 2.5 ± 1.4 | 5 | 2 | 3 | 14.8 (median 15) |
| `tsan-sound-nofe` | 10 | 2.2 ± 1.4 | 5 | 2 | 3 | **2.9 (median 1.5, max 5)** |

**No race is lost.** Against `tsan-sound` — the pair that isolates the flag — the union sets are identical at
all three keys, and the per-race detection frequencies differ only within the stochastic band this workload
always shows (8/10 vs 6/10 vs 8/10 on the same race). Both sound arms lose the same two entries relative to
stock, each seen in **1 of 10** baseline runs, which at N = 10 is below what this harness can call a loss at
all — the rule in `CLAUDE.md` exists for exactly that case.

**The cost is stack depth, and it is severe.** A report goes from a fifteen-frame call chain to a median of
one and a half frames: the access site and little else. That is the real trade, and it is worse than the
earlier guess.

**The earlier guess was wrong in its specifics and is corrected here.** The 2026-09-10 entry predicted that
losing the calling context would move the L1 and L2 report keys while leaving L3 alone. It does not: those keys
are built from the top two frames, which come from the access PC rather than from the shadow stack, so they
survive intact. What the shadow stack supplies is everything *below* the top frames.

### 2026-09-13 · combination counters · `tsan-merge-afe47a2a75a5-astats` — **loop peeling isolated, and it is a null**
Six configurations on SQLite and memcached inside one compiler copy, with the merge switch flipped in each, so
loop peeling is separated from the bundle it has always been measured inside. Both arms sit below the
repeatability floor on both applications: SQLite +1.34 % with the merge on and −0.63 % with it off, memcached
±0.01 %. Opposite signs below the floor is a null, not a small effect.

**Both peeling figures that have circulated are withdrawn.** Neither "peeling adds sites faster than DE removes
them" nor any dynamic reduction attributed to it survives isolation; the earlier numbers were bundle
comparisons in which peeling was never the only thing that changed.

The same leg makes whole-program summaries readable: −2.77 % executed accesses on Redis, −0.96 % on memcached,
and **+5.73 % on SQLite**, which is above the floor and in the wrong direction. No mechanism is offered; it sits
on the one copy with no repeat of its own, so it is recorded as an open discrepancy rather than a finding.

### 2026-09-11 · granule merge · `tsan-merge-afe47a2a75a5` — **delivered, no effect on execution time**
Merges adjacent same-granule accesses in one basic block into one wider access; a second mechanism handles
under-aligned pairs through `__tsan_unaligned_write8`. Static reach: SQLite −8.01 %, memcached −3.12 %,
shell.c −2.21 %, Redis −1.34 %, MySQL −1.34 %.

**Timing, paired inside the one copy, N = 5:** SQLite 1.034 [0.970, 1.101], MySQL 0.990 [0.949, 1.056]. Neither
interval excludes 1.0 and MySQL's centre is on the wrong side of it. The cost model fixed before the run
predicted 1.054–1.067, so this is an over-prediction of about two-fold and the fifth dead predictor in a row;
it is recorded as such rather than as a success.

**The dynamic side is what makes this informative.** The merge really does remove executed accesses where DE is
present — SQLite −6.26 % on AllOpt-peel and −4.41 % on AllOpt+peel, both clear of that cell's 2.67 % floor, and
memcached −0.25 % to −0.34 % against a 0.02 % floor. So this is not a transform that failed to fire. It fired,
removed several percent of executed accesses, and moved no time. See the standing summary.

**Missed its pre-registered bar** on the static side as well: the rule fixed before building was 2 % of
instrumented sites on memcached, and the transform as the rule described it (aligned pairs only) delivers
1.84 %. The 3.12 % figure includes a mechanism invented after the rule was fixed, so it is recorded as two
figures and not as a pass.

Open discrepancy, still with no mechanism offered: the transform reaches furthest where misses are rarest
(SQLite, 92.7 % hits) and least where they are commonest (MySQL, 44 % misses), on every measure available.

### 2026-09-10 · shadow-stack maintenance off · `d3bf9f8c39fe` — **delivered, three conclusive gains**
`-tsan-instrument-func-entry-exit=false` on top of the sound bundle. Loses no race — every access is still
instrumented and recorded — but reports lose their calling context. The claim that L1 and L2 keys would move
was a prediction and it was wrong; see the 2026-09-13 entry above for what was measured. Alexey's ruling:
ships as a measured configuration, not a default.

Four candidate predictors of *why* Redis gains most were proposed and falsified: caller-side attribution as a
general multiplier (refuted by FFmpeg), entries per access in ratio and in count (refuted by memcached, which
executes 53 % more function entries and gains nothing), workload mismatch between profile and benchmark
(refuted — the profiled subset gains the same as the rest), and function shape (refuted on a desk check).
The surviving candidate is the shadow-stack share of instrumented cycles.

### 2026-09-09 · yield branch · `tsan-yield-d98873cda906` — **no effect**
Seven changes measured as A/B pairs inside one compiler, four applications, 16 pairs, N = 5. Not one interval
excludes 1.0; tightest bound FFmpeg's sound pair at 1.000 [0.992, 1.008]. The static counts predicted it before
any timing: largest static difference 0.23 % against a best resolution of about 1 point.

### 2026-09-09 · Stage B campaign · `tsan-perf-d3bf9f8c39fe` — **the baseline**
Five applications, 58 configuration rows with a speedup, 500 clean runs, N = 5. Five rows separate from stock
TSan; everything else — every single analysis, both AllOpt bundles, whole-program summaries, thread-free names,
loop peeling — straddles 1.0. Full write-up: `tools/notes/stageb-results-2026-09-09.md`.

### Earlier
- The analyses' reach collapsed when they were made sound: 44 % of accesses removed on SQLite under the paper
  compiler, 3.2 % on the hardened one (`tools/notes/sqlite-2.77x-not-reproducible-2026-09-05.md`).
- Compile time is the one thing that improved by a large factor, and only on MySQL, where escape-analysis
  builds went from 3.05–3.65× stock to 1.04–1.10×. Not an execution result and not in this ledger's tables.

---

## Why the submitted numbers were higher

Three mechanisms, all measured, none of them the compiler getting worse. A fourth — machine load — was
proposed here on 13 September and withdrawn the same day; it is left in place below rather than deleted,
because a withdrawn explanation that quietly vanishes is how it comes back. This is diagnosis, not a target to
recover: the camera-ready and the artifact are being reconciled to the Stage B tables above, so the March
columns exist here only so that nobody re-derives them and wonders.

**1. WITHDRAWN — the machine-load explanation, and what it cost.** This section first claimed the March
machine was carrying other load, on the evidence that FFmpeg's identical commands ran up to 1.96x slower on
17 March than on 4 March with the same user CPU time. The commands were not identical: 4 March used
`-threads 8` and 17 March used `-threads 4`, on every row of both files. At `-threads 4` the 17 March native
h264 row achieves 4.01 CPUs of parallelism, which is perfect scaling rather than a degraded run. Each thread
count was run on exactly one date, so the FFmpeg artefacts cannot separate date from thread count even in
principle, and they carry no contention evidence at all. The statistic was doubly unsound: libx265 and the
mjpeg encoder size their own worker pools from the machine, so two of the four codecs show 7.6 and 9.7 CPUs
busy at `-threads 4` and a user-to-wall ratio is not a contention measure for them.

**What replaces it is more useful than what it replaced.** `summary_ffmpeg_benchmark.csv`, the 17 March file
the paper's 1.474 and 1.570 come from, carries `-threads 4` in all 42 command templates — **the same thread
count Stage B uses**. So FFmpeg has no concurrency gap between the paper's setup and the corrected campaign,
and restoring "the March thread count" for FFmpeg restores the number it already has. The gap is real for
memcached (`run-memcached.sh:18` is `NTHREADS=$(nproc)`, unchanged through March, against Stage B's `-t 24`)
and for MySQL (`nproc*3/4`, which is 84 on this machine, against Stage B's measured `--threads=18`) — a factor
of 4.7 there, and the largest single difference between the two setups.

**2. The March memcached comparison had different N in its two arms.** `nosql/memcached/run-bench.sh` still
carries the comment recording the removal: *"the paper-era 'x5 iterations when the type is tsan' rule was
removed: unequal N inside the comparison"*. In March the TSan arm ran five times as many memtier iterations as
the native arm, so the slowdown and every speedup taken against it compare two different amounts of work. This
is a workload-definition defect, not sampling noise, and no number of repetitions would have revealed it.

**3. memtier ran at its default request count.** No `--requests` was passed, so each client did 10 000 — about
a second per iteration, which is below what memtier can time accurately; it reports 57 M ops/s for native under
that setting. March native reads 914 k ops/s against 5.08 M today. Stage B passes `--requests 100000`.

**And the analyses' reach collapsed when they were made sound**, which is the only one of the four that is
about the compiler: 44 % of accesses removed on SQLite under the paper compiler, 3.2 % on the hardened one
(`tools/notes/sqlite-2.77x-not-reproducible-2026-09-05.md`).

Full provenance work, including what the March artefacts do and do not record about the machine — they record
no hostname, kernel, OS, CPU count, governor or pinning at all — is in
`tools/notes/march-provenance-2026-09-13.md`. Two conclusions from it that correct earlier statements: the host
is the same machine the paper names and has never run Ubuntu 22.04 (the paper's OS line is wrong), and the
March contention sweeps ran with **40** CPUs visible, not the 112 this machine has, so "March ran unpinned
across all 112 CPUs" is withdrawn.

---

## Method notes that keep these numbers honest

- **A shared denominator transmits one odd measurement into every row at once — within a session and across them.** Every speedup in an application
  divides by the same stock-TSan runs, so a deviation in stock TSan's own run 1 moves every configuration's
  ratio the same way. Dropping run 1 shifts Stage B speedups by a median of 0.70 pp and up to 3.77 pp, and the
  sign of the baseline's own run-1 deviation predicts the sign of that shift in four applications of five. The
  harness has no warm-up. Two consequences: configurations within an application are **not independent trials**,
  so a sign test across them counts one fact many times and its p-value is descriptive only; and a
  per-configuration interval does not show this, because it is correlated error across rows rather than noise
  within one. The same hazard operates **between sessions**: on 2026-09-14 stock TSan itself moved between
  dates, harder than the light arms, and eight of thirteen Redis rows changed verdict together rather than
  scattering — which is the signature of a shared denominator rather than of noise.
  `tools/notes/run1-cold-start-2026-09-13.md`.
- **Never divide across sources.** Two headline figures died in one week from a numerator and denominator taken
  from different runs or directories. `tools/notes/foreign-load-bands-2026-09-08.md`.
- **A positive control is not sensitivity.** It proves the harness can report the effect, not that the
  experiment can detect the loss being looked for. Five checks in one day would each have produced a clean
  result from a manipulation that was absent — no transformed code in the probe, the optimiser dissolving the
  shape, a source order with no window, a parameter sweep covering one residue class of a period-4 mechanism,
  and a compiler copy without the transform in it.
- **Verified against a different fixpoint is not verified.** When an equivalence is carried from one compiler
  state to another, the pair that establishes it must be built from **one source state with only the switch in
  question differing** — never two builds from two states. The granule-merge freeze did it correctly: one
  branch, counters on and off, both verified to fire. The case that prompted the rule: a compile-time fix whose
  verdict-identity was established against a flow-sensitive analysis cannot be assumed to hold once the branch
  runs `-tsan-ea-flow-insensitive` instead, because the fixpoint whose skipped-block equivalence the verifier
  checks is not the same fixpoint.
- **A number that confirms you is the one nobody checks twice.** Two unit errors in one evening, on opposite
  sides of the same investigation, and in both cases the wrong number was the one that *supported* the
  hypothesis under test: milliseconds printed as a percentage made thermal throttling look like 3.40 % of wall
  time when it was 0.0034 %, and `ps pcpu` — a lifetime average, not a rate — made an idle process look like
  62 % of a core when it was drawing 7.4 %. Neither survived being recomputed from the raw counter over a fixed
  window. This is the same failure as "a positive control is not sensitivity" wearing a different face: a
  result that agrees with you is not evidence that your instrument works.
- **Name the refuting case before running it.** Every predictor that died was proposed by whoever had just seen
  a confirming case and killed by the first case named in advance as able to refute.
