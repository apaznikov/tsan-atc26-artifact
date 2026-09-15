# Claims and how to check them

Every claim the paper makes, the script that produces it, and what counts as a match. This file is
the contract between the paper and this artifact: if a number is not here, the artifact does not
claim it.

Measurement provenance for every performance row: compiler `f3deebfbab60` (branch `artifact/paper-sound`,
the one the image reproduces), five applications, one discarded warm-up then N = 5 runs per configuration, pinned to 48 processors (CPUs 4-27 and 60-83 on our machine), one
measurement at a time in run-major order. The statistic is the geometric mean over an
application's tests of per-test medians, with a 95% confidence interval from 2000 bootstrap
resamples over runs (seed 1). Our machine: Intel Xeon w9-3495X, 56 cores / 112 threads, 250 GB
RAM, Ubuntu 24.04, kernel 6.8.

---

## 1. Race detection is preserved (deterministic)

| Claim | Script | Match criterion |
|---|---|---|
| No configuration loses a race that stock ThreadSanitizer reports, over ThreadSanitizer's own regression suite | `scripts/30-preservation-suite.sh` | exact: no candidate lost race. The vendored suite discovers 383 tests, of which 85 are unsupported on Linux before anything is compiled (47 Darwin, 37 libdispatch, 1 libcxx); the rest run in each of 12 configurations, K repeats each, and a test counts as a candidate lost race only when it fails every repeat under a configuration and never fails under stock |
| The harness can detect a loss at all | `scripts/30-preservation-suite.sh --self-test` | required first: it runs a detector with load and store instrumentation switched off and requires the harness to report the losses. A suite reporting nothing looks the same whether races are preserved or the harness is blind |
| Every race test's report is identical to stock ThreadSanitizer's: same kind, both stacks with file and line | `scripts/30-preservation-suite.sh --diff` | exact, except the three tests listed in `docs/nondeterministic-tests.md`, which are non-deterministic under stock as well (verified at K = 20) |
| No test that expects no report produces one | `scripts/30-preservation-suite.sh` | exact |
| On SQLite, the union of races over 10 runs is the set stock reports (5 sites) | `scripts/31-preservation-apps.sh sqlite` | same set; per-site frequencies vary with the schedule |
| On memcached, the sound configuration reports the stock set; AllOpt relocates one report in 1 of 30 runs, within the same function | `scripts/31-preservation-apps.sh memcached` | same set at the location level |

The 12 configurations: stock, each analysis alone (STC, SWMR, LO, EA, DE), DE with peeling, the
four sound analyses combined, AllOpt with and without peeling, and each of the last two with
DynSTC.

## 2. Soundness of the analyses (deterministic)

| Claim | Script | Match criterion |
|---|---|---|
| 23 code shapes in which an optimized build could fail to report a race are fixed; each has a test that fails on its parent commit and a positive control | `scripts/11-soundness-shapes.sh` | exact: the suite passes and every removal it claims is one it can detect (50 removal tests fail with the analysis flags stripped, 11 controls, 0 vacuous) |
| The ledger records, per function, the contract, the paper proposition it implements, a verdict and a covering test | `compiler/TSanAnalysesAudit.md` | document, no script |

## 3. Instrumentation removed (deterministic)

| Claim | Script | Match criterion |
|---|---|---|
| Static instrumentation sites per application and configuration | `scripts/20-static-counts.sh` | exact; the counts are a property of the compiler, not of the machine |
| The compiler built from the shipped patch series behaves like the frozen compiler the performance numbers were measured on | `scripts/12-compiler-equivalence.sh` | exact: it recompiles 28 vendored LLVM IR modules under 4 configurations and requires all 112 `__tsan_*` symbol histograms to equal a reference table produced by the campaign compiler, checking the `TSAN_AUDIT_HASH` stamp separately. It says "behaves like", not "is": an identical corpus does not identify the commit, since the three compile-time commits change none of the 112 rows. A control asserts the reference table separates the configurations at all (24 of 28 modules do), so agreement is not free |
| The three compile-time commits added to that compiler changed no instrumentation decision on any application | recorded in `data/equivalence/` and `docs/campaign-parameters.md`; not re-run by the evaluator | the same 112 corpus rows against the previous compiler, plus the 17 application configurations built on both compilers (MySQL 640 355 sites and 1 263 905 calls; all 14 Redis rows) and Redis's whole-program analysis summaries byte-identical between them |
| Executed instrumentation per unit of work | `scripts/90-tables.sh --reach` | exact from the shipped data; within run-to-run noise when re-measured |

## 4. Compile-time overhead

| Claim | Script | Match criterion |
|---|---|---|
| Compile-time overhead of the analyses over an uninstrumented build | `scripts/21-compile-time.sh` | same order of magnitude; a few per cent tolerance, since it depends on the machine and the parallelism |

## 5. Performance (machine-dependent)

Filled per application as the campaign of 15-17 September completes on compiler `f3deebfbab60`;
an application not yet listed is not yet claimed. Every configuration of the paper's figure is
listed with the paper's bar beside it, plus the three configurations the paper does not show.
Two intervals per row: over all five measured runs and over runs 2-5; a row is claimed to differ
from stock only when both exclude 1.0, and "no measurable change" means the interval contains 1.0,
not that the effect is zero. "Stable subtests" repeats the speedup over the subtests whose pooled
run-to-run variation is at most 5%; the set is a property of the workload and applies to every row.

### Redis 7.0.15 (`redis-benchmark`, 19 commands, 50 clients, pipeline 1024; session of 15 Sep 18:49, pinned, governor powersave)

Stock ThreadSanitizer against native: 8.01x [7.83, 8.21] (the paper: 9.2x). Stable subtests: 16 of 19
(`PING_MBULK`, `ZPOPMIN`, `MSET` excluded).

| Configuration | Paper | All five runs [95%] | Runs 2-5 [95%] | Stable subtests, all five [95%] | Verdict |
|---|---|---|---|---|---|
| EA | 1.00 | 0.994 [0.974, 1.019] | 0.989 [0.967, 1.008] | 0.991 [0.972, 1.019] | no measurable change |
| LO | 1.00 | 0.981 [0.967, 1.010] | 0.980 [0.965, 1.002] | 0.981 [0.969, 1.009] | no measurable change |
| STC | 1.12 | 0.980 [0.962, 1.003] | 0.979 [0.961, 0.997] | 0.978 [0.959, 1.002] | no measurable change (on the boundary: runs 2-5 exclude 1.0, all five do not) |
| SWMR | 1.00 | 0.988 [0.971, 1.015] | 0.987 [0.963, 1.007] | 0.982 [0.970, 1.014] | no measurable change |
| DE | 1.35 | 0.992 [0.970, 1.015] | 0.992 [0.967, 1.010] | 0.992 [0.972, 1.017] | no measurable change |
| DE + peeling | 1.25 | 0.996 [0.977, 1.024] | 0.997 [0.972, 1.018] | 0.990 [0.971, 1.021] | no measurable change |
| DynSTC | 1.12 | 0.944 [0.927, 0.970] | 0.944 [0.922, 0.962] | 0.939 [0.922, 0.963] | **below stock** |
| AllOpt without peeling | 1.45 (the paper's AllOpt bar; the paper does not say whether peeling was on) | 0.989 [0.975, 1.015] | 0.984 [0.965, 1.000] | 0.984 [0.968, 1.011] | no measurable change |
| AllOpt with peeling | not in the paper | 1.000 [0.983, 1.026] | 0.994 [0.974, 1.016] | 0.994 [0.978, 1.024] | no measurable change |
| AllOpt with peeling and DynSTC | not in the paper | 0.958 [0.944, 0.985] | 0.963 [0.944, 0.981] | 0.951 [0.940, 0.981] | **below stock** |
| four sound analyses, whole-program summaries | not in the paper | 0.996 [0.971, 1.017] | 0.993 [0.971, 1.013] | 0.994 [0.968, 1.015] | no measurable change |
| AllOpt with peeling, whole-program summaries | not in the paper | 0.998 [0.980, 1.027] | 0.996 [0.979, 1.019] | 0.997 [0.976, 1.023] | no measurable change |

Condition that travels with every Redis row: byte-identical Redis binaries measured six days apart
on this host differed by 14% (stock) and 5% (native) in throughput for reasons we could not
identify (`docs/confounds.md`). Ratios within one session are what is claimed; a disagreement of a
few points with an evaluator's run is inside that effect. The second concurrency point, 112
clients, is measured at the end of the campaign and added here when it lands. The peeling pair on
Redis, AllOpt with against without peeling on the stable subtests: 1.0105 [0.9905, 1.0326].

Script: `scripts/40-perf.sh redis` (about 2 hours at N = 5 on 48 CPUs; `--smoke` in minutes, not a
measurement).

### memcached 1.6.29 (`memtier_benchmark` 2.1.1, 10 threads x 5 clients, pipeline 16, 100 000 requests each, server at 48 threads; session of 15 Sep, pinned)

Stock ThreadSanitizer against native: 3.20x [2.97, 3.40] (the paper: 2.83x). **No configuration is
resolved on memcached**: every interval is 12 to 16 points wide and contains 1.0. The cause is the
workload, not the analyses: memcached reports one metric, operations per second, so the geometric
mean is over a single number and the whole interval is its run-to-run variance at N = 5. Only more
repetitions would narrow it; no subtest filter can, because there are no subtests. The paper's
memcached bars (1.00 to 1.07) lie inside these intervals, so the campaign neither confirms nor
contradicts them.

| Configuration | Paper | All five runs [95%] | Interval width | Verdict |
|---|---|---|---|---|
| EA | 1.00 | 0.989 [0.933, 1.064] | 13 points | no measurable change |
| LO | 1.01 | 1.003 [0.946, 1.090] | 14 points | no measurable change |
| STC | 1.00 | 1.016 [0.948, 1.082] | 13 points | no measurable change |
| SWMR | 1.00 | 1.020 [0.932, 1.089] | 16 points | no measurable change |
| DE | 1.03 | 0.986 [0.935, 1.085] | 15 points | no measurable change |
| DE + peeling | 1.03 | 0.990 [0.934, 1.077] | 14 points | no measurable change |
| DynSTC | 0.98 | 0.986 [0.944, 1.063] | 12 points | no measurable change |
| AllOpt without peeling | 1.07 | 0.986 [0.940, 1.078] | 14 points | no measurable change |
| AllOpt with peeling | not in the paper | 1.019 [0.951, 1.079] | 13 points | no measurable change |
| AllOpt with peeling and DynSTC | not in the paper | 1.003 [0.961, 1.099] | 14 points | no measurable change |
| four sound analyses, whole-program summaries | not in the paper | 1.005 [0.947, 1.089] | 14 points | no measurable change |
| AllOpt with peeling, whole-program summaries | not in the paper | 1.023 [0.961, 1.112] | 15 points | no measurable change |

Redis's DynSTC cost does not appear here (0.986, interval 12 points wide); whether that is a real
difference between the two applications or memcached's noise cannot be told from this measurement.
The peeling pair on memcached, AllOpt with against without peeling: 1.0332 [0.9593, 1.0567].

Script: `scripts/40-perf.sh memcached` (about 4 hours at N = 5 on 48 CPUs).

### FFmpeg, SQLite, MySQL

Filled when their legs complete (16-17 September). Until then the artifact claims no performance
number for them; the recorded Stage B runs under `data/perf/stageB-d3bf9f8c39fe` are from an
earlier compiler and are shipped as data, not as claims.

**Match criterion for every row**: the evaluator's confidence interval overlaps ours. A row whose
interval contains 1.0 here must contain 1.0 there; a row that excludes it should exclude it on
comparable hardware. `docs/confounds.md` lists what makes this vary: memcached's wall time is
bimodal with a 10 to 12 per cent coefficient of variation, SQLite's seven subtests are
heterogeneous and three of them carry 16 to 20 per cent run-to-run variation, and absolute
overheads are not comparable across compiler trees even when ratios are.

## 6. Bounded shadow state

| Claim | Script | Match criterion |
|---|---|---|
| ThreadSanitizer itself fails to report a planted race in about a quarter of runs on a fully occupied granule; the optimized builds sit in the same range where the burst remains instrumented | `scripts/50-eviction-stress.sh` | within the confidence intervals: stock about 75%, optimized 74 to 76% |
| Dominance elimination trades losses against gains rather than only losing: on a granule carrying two races it misses the first exactly when the dominating record was evicted (0 of 236 runs) and reports the second exactly when stock's re-inserting access evicted it (236 of 236 against stock's 165) | `scripts/50-eviction-stress.sh --de` | within the intervals; totals comparable (0.93 against 0.91 reports per run) |

## 7. Not claimed here

- **Chromium.** No performance number. The only Chromium build we have is on an earlier compiler
  and corresponds to no measurement in the paper. `docs/chromium.md` records the revision
  (`bdef6783a05f0b3f885591e7d2c7b2aec1a89dea`), the configuration and the timeout patch.
- **MySQL performance.** Scripts and recorded data ship, but a full run is about seven hours and
  the build about an hour, so it is documented rather than offered as a runnable claim.
- **Loop peeling in isolation.** Its effect is below the noise floor of every measurement we have.
