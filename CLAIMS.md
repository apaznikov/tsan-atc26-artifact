# Claims and how to check them

Every claim the paper makes, the script that produces it, and what counts as a match. This file is
the contract between the paper and this artifact: if a number is not here, the artifact does not
claim it.

Measurement provenance for every performance row: compiler `<SHIPPED_HASH>`, five applications,
N = 5 runs per configuration, pinned to 48 processors (CPUs 4-27 and 60-83 on our machine), one
measurement at a time in run-major order. The statistic is the geometric mean over an
application's tests of per-test medians, with a 95% confidence interval from 2000 bootstrap
resamples over runs (seed 1). Our machine: Intel Xeon w9-3495X, 56 cores / 112 threads, 250 GB
RAM, Ubuntu 24.04, kernel 6.8.

---

## 1. Race detection is preserved (deterministic)

| Claim | Script | Match criterion |
|---|---|---|
| In each of 12 configurations, all 293 tests of ThreadSanitizer's regression suite pass | `scripts/30-preservation-suite.sh` | exact: 293/0 in every configuration |
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
| 22 code shapes in which an optimized build could fail to report a race are fixed; each has a test that fails on its parent commit and a positive control | `scripts/11-soundness-shapes.sh` | exact: 22 of 22 pass, printed shape by shape against the ledger |
| The ledger records, per function, the contract, the paper proposition it implements, a verdict and a covering test | `compiler/TSanAnalysesAudit.md` | document, no script |

## 3. Instrumentation removed (deterministic)

| Claim | Script | Match criterion |
|---|---|---|
| Static instrumentation sites per application and configuration | `scripts/20-static-counts.sh` | exact; the counts are a property of the compiler, not of the machine |
| The shipped compiler emits the same instrumentation as the compiler the performance numbers were measured on | `scripts/12-compiler-equivalence.sh` | exact on all five applications, 112 modules |
| Executed instrumentation per unit of work | `scripts/90-tables.sh --reach` | exact from the shipped data; within run-to-run noise when re-measured |

## 4. Compile-time overhead

| Claim | Script | Match criterion |
|---|---|---|
| Compile-time overhead of the analyses over an uninstrumented build | `scripts/21-compile-time.sh` | same order of magnitude; a few per cent tolerance, since it depends on the machine and the parallelism |

## 5. Performance (machine-dependent)

Speedups over stock ThreadSanitizer, best configuration per application. **Only the first two
intervals exclude 1.0.** For memcached and MySQL the intervals are 12.2 and 14.1 points wide, so
those rows report an effect below the resolution of the measurement, not the absence of one.

| Application | Configuration | Speedup [95%] | Script |
|---|---|---|---|
| FFmpeg | DynSTC | 1.113 [1.097, 1.124] | `scripts/40-perf.sh ffmpeg` |
| Redis | AllOpt with peeling and whole-program summaries | 1.027 [1.008, 1.051] | `scripts/40-perf.sh redis` |
| SQLite | AllOpt without peeling | 1.036 [0.924, 1.110] | `scripts/40-perf.sh sqlite` |
| MySQL | escape analysis | 1.034 [0.959, 1.080] | not reproducible here, see `docs/mysql.md` |
| memcached | dominance elimination | 1.000 [0.919, 1.056] | `scripts/40-perf.sh memcached` |

Two further rows separate from stock in the other direction, and the artifact claims them too:
Redis under DynSTC 0.969 [0.950, 0.990] and SQLite under DynSTC 0.983 [0.978, 0.995] on its
resolvable subtests. DynSTC is signed: it helps FFmpeg and costs Redis and SQLite, so it is only
ever quoted per application.

Stock ThreadSanitizer against an uninstrumented build: memcached 2.83x, FFmpeg 2.81x, SQLite
3.18x, Redis 7.93x, MySQL 10.84x.

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
