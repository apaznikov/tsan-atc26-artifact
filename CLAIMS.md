# Claims and how to check them

Every claim the paper makes, the script that produces it, and what counts as a match. This file is
the contract between the paper and this artifact: if a number is not here, the artifact does not
claim it.

Measurement provenance for every performance row: compiler `f3deebfbab60` (the commit the image reproduces and
every run's `TSAN_AUDIT_HASH` names; it sits on branch `artifact/atc26`, whose tip has since moved past
it by two documentation-only commits restoring and completing the audit ledger, so the stamp and not
the branch identifies the measured compiler), five applications, one discarded warm-up then N = 5 runs per configuration (our campaign; the artifact's default for a reviewer is N = 2, see "What an evaluator actually has to run"), pinned to 48 logical processors that are 24 physical cores with both SMT threads of each (CPUs 4-27 and 60-83 on our machine, siblings n and n+56), one
measurement at a time in run-major order. The statistic is the geometric mean over an
application's tests of per-test medians, with a 95% confidence interval from 2000 bootstrap
resamples over runs (seed 1). Our machine: Intel Xeon w9-3495X, 56 cores / 112 threads, 250 GB
RAM, Ubuntu 24.04, kernel 6.8.

## Terms used below

- **Configuration**: one compiler setting per build. The tables name them as the harness does: `orig`
  native, `tsan` stock ThreadSanitizer, `tsan-dom_peeling-ea-lo-st-swmr` AllOpt with peeling (the paper's
  AllOpt), `tsan-stmt` DynSTC; the full legend is in `README.md`. Every configuration row is a ratio
  against `tsan` on the same machine in the same session; above 1.0 is faster than stock.
- **Cell, leg, root**: a cell is one application, one configuration, one run; a leg is one application's
  sequence of cells in run-major order; a root is a directory of legs recorded under one compiler
  (`data/perf/campaign-f3deebfbab60/primary`).
- **Disturbed, retired, the gate**: every pinned cell records the busy share of the processors outside its
  set. Above 0.10 the cell is disturbed, retired from the statistics and re-run; the retired cell ships
  beside its replacement (`docs/confounds.md`).
- **Headline column, resolvable column**: the headline is the geometric mean over all of an application's
  subtests; the resolvable column is the same over the subtests whose run-to-run variation under stock
  (the pooled coefficient of variation, with the threshold stated per application) is small enough to
  resolve a change of a few per cent.
- **Point estimate, interval, same side**: at N = 5 a row carries a 95% bootstrap interval; at N = 2 a
  point only, compared against the shipped interval. For a row whose shipped interval excludes 1.0, "same
  side" is whether the evaluator's value lies on the same side of 1.0 as ours.
- **L1, L2, L3**: how closely two race reports must agree to count as the same race: kind and both stacks
  with file and line (L1), the functions alone (L2), the location and its writer (L3).
- **input_is_reference**: FFmpeg's input clip has the reference sha256; a regenerated clip is valid but its
  rows are not compared.
- **Session drift**: byte-identical binaries measured days apart on one host differed by 14%; the
  stock-against-native ratio is reported and not judged for that reason.

---

## 1. Race detection is preserved (deterministic)

| Claim | Script | Match criterion |
|---|---|---|
| No configuration loses a race that stock ThreadSanitizer reports, over ThreadSanitizer's own regression suite | `scripts/30-preservation-suite.sh` | exact: no candidate lost race. The vendored suite discovers 383 tests; `lit` marks 90 unsupported on this platform before anything is compiled (47 Darwin, 37 libdispatch, 1 libcxx and 5 behind their own feature gates, among them `getline_nohang.cpp`, unsupported from glibc 2.38 on; each named in `data/suite/unsupported/`), so 293 execute in each of 12 configurations, K repeats each, and a test counts as a candidate lost race only when it fails every repeat under a configuration and never fails under stock. Run of 21 Sep 2026 with the shipped compiler (`f3deebfbab60`, K = 5, 12 configurations, 60 repeats, 25 lit jobs on the 104 processors the daemon granted; ships as `data/suite/preservation-suite-20260921T052239Z`, stamped in UTC): 292 pass and 1 is expectedly failed, 0 fail and 0 time out in every one of the 60 repeats, every configuration always-fail = 0 and ever-fail = 0, so no candidate lost race; the same suite on a 64-processor AMD host the same day, 0 and 0 in 60 repeats. This 293 is the vendored suite's count and not the 293 of the report-key replay in the row below, which counted a different test set (the source tree's suite in its September state). The earlier run of 17 Sep (`data/suite/preservation-suite-20260917T075005Z`, 60 repeats, 0 failures) was made with a lit configuration that did not detect glibc under Python 3.12: 91 unsupported and 292 executed, `getline_nohang.cpp` running although upstream marks it unsupported on this glibc and stalling to its timeout in 48 of the 60 repeats (a timeout, never a failure under the rule), and two tests requiring glibc 2.30 skipped. The fix (`tests/lit.common.cfg.py`, 21 Sep) moves exactly those three tests, 91 + 1 - 2 = 90, predicted before the measurement and confirmed by it on both hosts (`docs/nondeterministic-tests.md`). Every number here is re-derivable from the shipped runs: their READMEs give the command for each |
| The harness can detect a loss at all | `scripts/30-preservation-suite.sh --self-test` | required first: it runs a detector with load and store instrumentation switched off and requires the harness to report the losses. A suite reporting nothing looks the same whether races are preserved or the harness is blind |
| Every race test reports the same race as under stock ThreadSanitizer (report keys at L1, kind and both stacks with file and line, and at L2, functions) | recorded, not re-run by the evaluator: a K = 5 replay of the executable tests (293 in that run) under the 12 configurations, keyed by `harness/tools/preservation/tsan_reports.py`, made on compiler `aa8a6dd8a2e8` during the gate of 15 Sep 2026 and carried to the shipped `f3deebfbab60` on the verdict-identity evidence (the three commits between them change none of the 112 corpus rows, none of the 17 application configurations' site counts, and leave Redis's whole-program summaries byte-identical); the replay's output ships as `data/suite/replay-aa8a6dd8a2e8/` | on that run no L1 or L2 key differs on any test. Four tests land in the other bucket: `pthread_atfork_deadlock2.c` lost a report under STC alone (the only lost entry; a thread-leak diagnostic, not a data race), and `fd_location_closed.cpp` (under STC and AllOpt with peeling), `race_on_barrier2.c` (STC and DE) and `fork_atexit.cpp` (9 of the 11 compared configurations) gained one; the last three are the tests `docs/nondeterministic-tests.md` names as non-deterministic under stock itself. The 293 is that run's test set, the source tree's suite in its September state, not the vendored suite's 292. `scripts/30-preservation-suite.sh` compares pass and fail per test, not report text: `lit -q` does not capture the reports, so the shipped logs carry none. This row covers the twelve configurations named in section 5's tables and not the rows measured with the upstream flag `-tsan-instrument-func-entry-exit=false`: that flag removes the shadow stack the report keys are built from (both frames at L1, the functions at L2, the writer and heap locations at L3), so for those rows report keys are not comparable by construction, and their preservation rests on the suite's pass or fail per test and on the applications' race counts and kinds |
| No test that expects no report produces one | `scripts/30-preservation-suite.sh` | exact |
| On the applications, no race site that stock ThreadSanitizer reports in every run is absent from an optimized configuration in every run | `scripts/31-preservation-apps.sh <app> 10` (N = 10 as we ran it; at the default N = 2 the script prints the frequencies and no verdict) | comparative, on your own runs, never against a fixed set: detection is schedule-dependent, so the script prints the per-site frequency (k of N) under stock and under each configuration and classifies each site by the configuration's count first: KEPT if the configuration reports it in at least one run, whatever stock's frequency; LOST if the configuration never reports it and stock reports it in every run; UNDETERMINED at this N if the configuration never reports it and stock reports it only in some runs, so an unlucky schedule cannot be told from a loss without more runs; and ONLY-OPTIMIZED if the configuration reports a site stock never does, which is labelled rather than dropped because the shadow-eviction effect can produce exactly that. It exits non-zero only on LOST. Measured on the shipped compiler `f3deebfbab60` on 17 Sep, N = 10, configurations stock, the sound bundle and AllOpt with peeling, gating at L3 (`data/preservation/*/2026-09-17-shipped-f3deebfbab60/verdict-L3.txt`, all three levels printed). **SQLite: no site lost at any level**; at L3 three sites (`walRestartHdr` 68034 and 68035, `walIndexRecover` 67450), KEPT under every configuration, the weakest at 2 / 2 / 3 of 10. **memcached: no site lost at L3**; four sites at 10 of 10 under all three configurations (`clock_handler` on `current_time`, `do_item_link` and `do_item_unlink` on `stats_state` and `memory_allocated`), seven sites that stock and the sound bundle each saw once in ten and AllOpt with peeling never saw, UNDETERMINED, and one site reported only by the optimized builds (`lru_maintainer_juggle` reading `current_time`, 0 / 2 / 2 of 10). **One relocation, reported rather than suppressed**: at L1 and L2 the pairing of the reader `conn_new@memcached.c:761` with the writer `clock_handler` on `current_time` is 10 of 10 under stock and under the sound bundle and 0 of 10 under AllOpt with peeling, while the same race on the same location is reported 10 of 10 under AllOpt with peeling by `do_item_link`, `lru_maintainer_thread` and `try_read_command_ascii`. The read at line 761 is instrumented under AllOpt with peeling exactly as under stock, checked three ways, twice on the campaign binaries and once at the IR level from source with the campaign's own flags (the call multiset in `conn_new` identical, the `__tsan_read4` of `current_time` at line 761 present, and that line the only reference to `current_time` in the function): `conn_new` carries 20 reads, 35 writes, 60 `__tsan_*` calls and 403 instructions in all three builds, with two calls attributed to line 761 in each, and `clock_handler` 15 calls in each. Nothing was elided; which reader's record survives the four shadow slots on that granule is eviction arithmetic, and AllOpt with peeling carries 382 more instrumented sites than stock (peeling duplicates first iterations), which is enough to change it; and no single transform does it alone: under the sound bundle, under DE alone and under DE with peeling the pairing stays at 10 of 10, and only the full combination relocates it. The paper's stated criterion is the location and writer (L3), and the relocation is visible to any evaluator at N = 10, so it is stated here. The earlier trees under `data/preservation/` are from earlier compilers of the same lineage and are shipped as data |

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
| Static instrumentation sites per application and configuration | `scripts/20-static-counts.sh` | exact for the differences between configurations (what each analysis removes or adds), which are a property of the compiler; the absolute count of a binary may carry a small constant offset from the build environment: Redis built inside the container has 37 922 sites under stock and 43 272 under AllOpt with peeling against 37 941 and 43 291 for the campaign's host-built binaries, 19 fewer in each, the removed and added counts identical. (The campaign's Redis binaries record a sha256 that matches no row of `static-counts.csv`: Redis stamps each build, and Redis was rebuilt on 15 Sep after the count was taken, `docs/campaign-parameters.md`; so for Redis the counts are linked to the measured binaries by sources and flags, not by hash. The other four applications' binaries hash-match their rows.) Named, not guessed: Redis's Makefile auto-detects libsystemd and links it when present; the host had it, the image does not, so the container build compiles out `redisCommunicateSystemd` and the branches in its four callers. It is deterministic and every evaluator's image will show the same 19. Compare your differences with ours exactly and your absolute counts to within such an offset |
| Static instrumentation reduction, the submitted paper's headline figure (up to 65 %) | `scripts/20-static-counts.sh` against `data/perf/campaign-f3deebfbab60/static-counts.csv` | exact: on the shipped compiler AllOpt without peeling removes 5.0 % (memcached), 2.3 % (Redis), 7.8 % (FFmpeg) and 3.3 % (SQLite) of the static memory-access sites, and AllOpt with peeling carries more sites than stock on every application (+5.7, +14.1, +5.5, +6.8, MySQL +6.3 %), because peeling duplicates loop bodies. The paper's figures (60.8, 34.7, 64.9, 55.6 and 14.5 %) were measured with the submitted compiler, whose reach came from an unsound same-location test in the dominance elimination that the soundness fixes closed; the camera-ready reports these |
| The compiler built from the shipped patch series behaves like the frozen compiler the performance numbers were measured on | `scripts/12-compiler-equivalence.sh` | exact: it recompiles 28 vendored LLVM IR modules under 4 configurations and requires all 112 `__tsan_*` symbol histograms to equal a reference table produced by the campaign compiler, checking the `TSAN_AUDIT_HASH` stamp separately. It says "behaves like", not "is": an identical corpus does not identify the commit, since the three compile-time commits change none of the 112 rows. A control asserts the reference table separates the configurations at all (24 of 28 modules do), so agreement is not free |
| The three compile-time commits added to that compiler changed no instrumentation decision on any application | recorded in `data/equivalence/` and `docs/campaign-parameters.md`; not re-run by the evaluator | the same 112 corpus rows against the previous compiler, plus the 17 application configurations built on both compilers (MySQL 640 355 sites and 1 263 905 calls; all 14 Redis rows) and Redis's whole-program analysis summaries byte-identical between them |
| Executed instrumentation per unit of work | not measured on this compiler; the recorded counter runs are shipped under `data/perf/*-counters` and are from an earlier one | exact from the shipped data; within run-to-run noise when re-measured |

## 3b. Every shipped run is attributable (deterministic)

| Claim | Script | Match criterion |
|---|---|---|
| Every run of the campaign (`data/perf/campaign-f3deebfbab60/{primary,r2}`, shipped since 18 Sep 2026: 290 and 110 measured runs beside their warm-ups, the roots every performance claim rests on) records the compiler that built it, the hash of the binary it ran, the hash of its input where the workload reads one (FFmpeg), its processor set and mode, the foreign-activity share the gate saw and the size of the set it watched (56 of the 64 processors outside the pinned set: eight are reserved for other users of this machine and were excluded, which the shipped default no longer does), and its place in a full set of N; `scripts/91-verify-provenance.sh` opens every one of them and exits 0 only when all are attributable, an empty root is a failure ("nothing was verified, which is not a pass": a first version passed vacuously on a root whose runs lay one level down), and a root that holds no runs directly is expanded to its sub-roots. The earlier trees shipped beside them were recorded before the harness wrote every one of those fields and on earlier compilers; they support no claim and the script reports them for information only | `scripts/91-verify-provenance.sh` | exact: six assertions, each of which fails on a fault we have actually produced (a pre-audit binary measured as current; a configuration whose binary changed mid-leg; an input path that satisfied the runner and recorded an empty hash; pinned and unpinned runs pooled; a run above the gate that was kept; a thin row that looked complete) |

This is the property the paper's setup section rests on. It does not check that a configuration's
flags were the intended ones, which is the build guard's job at build time, and it says nothing
about whether a number is right: a tree can pass this and still be wrong, but it cannot pass this
and be unattributable.

## 4. Compile-time overhead

| Claim | Script | Match criterion |
|---|---|---|
| Compile-time overhead of the analyses over an uninstrumented build | `scripts/21-compile-time.sh` | same order of magnitude; a few per cent tolerance, since it depends on the machine and the parallelism. The script rebuilds from scratch for every repetition and forces native and stock in as controls; on memcached, whose whole build takes about ten seconds, its own control reports that the resolution is worse than the effect (ratios 1.00 to 1.05 with 0.0% variation between control repetitions), and it says so rather than printing a ratio to be believed |

## 5. Performance (machine-dependent)

The "Paper" column of each table is the submitted manuscript's figure, measured before the soundness fixes
and kept for the record; the camera-ready reports the numbers in this file.

All five applications, from the campaign of 15-17 September on compiler `f3deebfbab60`: 400 measured
runs (290 and 110) beside their warm-ups, provenance verified on every root. Three cells were retired
and re-run to completion, two by the disturbance gate and one (`primary/sqlite/tsan-lo/run2.foreign-window-030844`,
gate reading 0.0072) by the provenance rule, because it overlapped a foreign-work window recorded in the lab
log at 03:08:44 on 16 Sep (that log is not shipped); both the retired cell and its replacement ship, so
the sets the statistics are computed over are clean and the retirements stay visible
(`primary/sqlite/tsan-lo/run2.foreign-window-030844`, `r2/redis/tsan-stmt/run1.disturbed.025858`,
`r2/redis/tsan-dom/run1.disturbed.030107`). **Of the 48 rows at the
primary concurrency, four separate from stock, and all four are DynSTC: a 5.6% cost on Redis and an
11.3% gain on FFmpeg, alone and inside AllOpt.** Every other configuration of every application
crosses 1.0. The legs of 21-22 Sep at FFmpeg's best thread count (the first FFmpeg section below) add three
rows above stock, all from the paper's own transforms, the largest 1.187 [1.171, 1.201]; the rows with the
upstream flag are measured and not claimed (the section after FFmpeg). Every configuration of the paper's figure is
listed with the paper's bar beside it, plus the configurations the paper does not show (AllOpt with peeling, its
combination with DynSTC, and the two whole-program rows where they exist).
Each row carries its interval over all five measured runs and, beside it, the point estimate over
runs 2-5 with no interval (four runs never get one). The two share four runs, so overlap of two
intervals was never a test; the check is that the runs-2-5 point lies inside the all-five interval,
which says that the first measured run did not drive the result. A row is claimed to differ from
stock only when the all-five interval excludes 1.0 and that check holds; "no measurable change"
means the interval contains 1.0, not that the effect is zero. "Resolvable subtests" repeats the speedup over the subtests whose pooled
run-to-run variation is at most 5%; the set is a property of the workload and applies to every row. That
variation can be estimated only with at least three runs per configuration, so the column exists at our
N = 5 and not at the reviewer's default N = 2: below three runs the artifact prints "pooled CV not estimable
at this N -- NOT A STABILITY CLAIM" rather than a bound, because an unmeasured coefficient of variation is
not a passed one, and reading it as zero would render the unmeasured case as the best case. So the column
has three states, not two: the subtests are within the bound (the good case), too few are within it to
restrict the claim (the cautionary case), and at N = 2 there is no estimate and no column (the absent case),
and each reads differently in the output.

### Redis 7.0.15 (`redis-benchmark`, 19 commands, 50 clients, pipeline 1024; session of 15 Sep 18:49, pinned, governor powersave)

Stock ThreadSanitizer against native: 8.01x [7.83, 8.21] (the paper: 9.2x). Resolvable subtests: 16 of 19
(`PING_MBULK`, `ZPOPMIN`, `MSET` excluded).

| Configuration | Paper | All five runs [95%] | Runs 2-5, point | Resolvable subtests, all five [95%] | Verdict |
|---|---|---|---|---|---|
| EA | 1.00 | 0.994 [0.974, 1.019] | 0.989 | 0.991 [0.972, 1.019] | no measurable change |
| LO | 1.00 | 0.981 [0.967, 1.010] | 0.980 | 0.981 [0.969, 1.009] | no measurable change |
| STC | 1.12 | 0.980 [0.962, 1.003] | 0.979 | 0.978 [0.959, 1.002] | no measurable change (on the boundary: the upper limit is 1.003) |
| SWMR | 1.00 | 0.988 [0.971, 1.015] | 0.987 | 0.982 [0.970, 1.014] | no measurable change |
| DE | 1.35 | 0.992 [0.970, 1.015] | 0.992 | 0.992 [0.972, 1.017] | no measurable change |
| DE + peeling | 1.25 | 0.996 [0.977, 1.024] | 0.997 | 0.990 [0.971, 1.021] | no measurable change |
| DynSTC | 1.12 | 0.944 [0.927, 0.970] | 0.944 | 0.939 [0.922, 0.963] | **below stock** |
| AllOpt without peeling | 1.45 (the paper's AllOpt bar; the paper does not say whether peeling was on) | 0.989 [0.975, 1.015] | 0.984 | 0.984 [0.968, 1.011] | no measurable change |
| AllOpt with peeling | not in the paper | 1.000 [0.983, 1.026] | 0.994 | 0.994 [0.978, 1.024] | no measurable change |
| AllOpt with peeling and DynSTC | not in the paper | 0.958 [0.944, 0.985] | 0.963 | 0.951 [0.940, 0.981] | **below stock** |
| four sound analyses, whole-program summaries | not in the paper | 0.996 [0.971, 1.017] | 0.993 | 0.994 [0.968, 1.015] | no measurable change |
| AllOpt with peeling, whole-program summaries | not in the paper | 0.998 [0.980, 1.027] | 0.996 | 0.997 [0.976, 1.023] | no measurable change |

Condition that travels with every Redis row: byte-identical Redis binaries measured six days apart
on this host differed by 14% (stock) and 5% (native) in throughput for reasons we could not
identify (`docs/confounds.md`). Ratios within one session are what is claimed; a disagreement of a
few points with an evaluator's run is inside that effect. The second concurrency point, 112 clients, the
post-hoc rule's value, measured at the end of the campaign (session of 17 Sep, N = 5): DynSTC 0.967
[0.948, 0.988] and AllOpt with peeling and DynSTC 0.974 [0.949, 0.988], both still below stock, so
the sign is a property of the application and not of the client count; every other row at 112
clients crosses 1.0 (EA 0.986, LO 0.985, STC 0.989, SWMR 0.987, DE 1.000, DE+peeling 1.001, AllOpt
without peeling 1.005, with peeling 1.006, whole-program 0.984 and 1.004, each within about two
points of 1.0). Stock against native at 112 clients: 7.96x [7.83, 8.11]. The peeling pair on
Redis, AllOpt with against without peeling on the resolvable subtests: 1.0105 [0.9905, 1.0326].

Script: `scripts/40-perf.sh redis` (about 2 hours at N = 5 on 48 CPUs; `ART_SMOKE=1` in minutes, not a
measurement).

### memcached 1.6.29 (`memtier_benchmark` 2.1.1, 10 threads x 50 clients, pipeline 16, 100 000 requests per client, averaged over 5 iterations, server at 48 threads; session of 15 Sep, pinned)

Stock ThreadSanitizer against native: 3.20x [2.97, 3.40] (the paper: 2.5x). **No configuration is
resolved on memcached**: across the twelve instrumented configurations every speedup interval is between 11.9 and 15.7 points wide and contains 1.0 (the thirteenth row of that column, `orig`, is native against stock, a baseline ratio rather than a speedup, and is 42.8 points wide). The cause is the
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

Redis's DynSTC cost does not appear here (0.986, interval 11.9 points wide, the narrowest of the twelve); whether that is a real
difference between the two applications or memcached's noise cannot be told from this measurement.
The peeling pair on memcached, AllOpt with against without peeling: 1.0332 [0.9593, 1.0567].

Second concurrency row, the server at 112 threads (the paper's `nproc` value; N = 5): AllOpt with
peeling 1.006 [0.890, 1.161], with DynSTC 1.089 [0.875, 1.129]; both cross 1.0 with intervals of 25
to 27 points, wider still than at 48 threads. Stock against native at 112 threads: 5.11x [4.48, 5.22].

Script: `scripts/40-perf.sh memcached` (about 34 minutes at the default N = 2 and four configurations;
4 hours at N = 5 and fourteen).

### SQLite 3.50.2 (`threadtest3`, all seven subtests at their default thread counts; session of 16 Sep 00:30, pinned)

Stock ThreadSanitizer against native: 2.96x [2.79, 3.28] (the paper: 2.4x). This is the campaign's
widest slowdown column, because SQLite's uninstrumented build varies by 37.9% run to run; that is the
workload, not the measurement. Resolvable subtests: 5 of 7 (`dynamic_triggers` and `stress1` excluded).

**Nothing is claimed for SQLite: every headline interval contains 1.0**, over all seven subtests and
on both run ranges. The paper's SQLite bars, which include its largest single claim (AllOpt 1.71),
are not reproduced: the campaign measures 1.020 for the same configuration.

| Configuration | Paper | All five runs [95%] | Runs 2-5, point | Resolvable subtests [95%] |
|---|---|---|---|---|
| EA | 1.17 | 1.016 [0.962, 1.100] | 1.007 | 1.003 [0.987, 1.017] |
| LO | 1.01 | 0.990 [0.931, 1.048] | 0.977 | 0.994 [0.968, 1.010] |
| STC | 1.00 | 1.016 [0.940, 1.079] | 1.017 | 0.997 [0.972, 1.014] |
| SWMR | 1.00 | 1.006 [0.940, 1.089] | 1.014 | 0.995 [0.959, 1.009] |
| DE | 1.21 | 1.003 [0.947, 1.071] | 0.997 | 1.002 [0.985, 1.018] |
| DE + peeling | 1.24 | 1.006 [0.958, 1.088] | 1.011 | 0.999 [0.990, 1.020] |
| DynSTC | 1.00 | 0.995 [0.928, 1.082] | 0.992 | **0.980 [0.966, 0.999]** |
| AllOpt without peeling | 1.71 | 1.020 [0.947, 1.076] | 1.020 | 1.002 [0.985, 1.027] |
| AllOpt with peeling | not in the paper | 1.023 [0.942, 1.061] | 1.013 | 0.998 [0.975, 1.013] |
| AllOpt with peeling and DynSTC | not in the paper | 0.994 [0.938, 1.087] | 1.004 | 0.987 [0.967, 1.005] |
| four sound analyses, whole-program summaries | not in the paper | 1.013 [0.942, 1.099] | 1.023 | 0.999 [0.978, 1.015] |
| AllOpt with peeling, whole-program summaries | not in the paper | 1.049 [0.988, 1.113] | 1.042 | 0.998 [0.984, 1.017] |

One entry above is bold because it excludes 1.0 in one column and not in the headline one, and it
is not claimed: DynSTC excludes it on the resolvable subtests (0.980, a 2% cost) while the headline
column contains it. A row is claimed only on the headline column, so it is reported as no measurable
change, with the disagreement shown rather than resolved by choosing the column that separates.

What the resolvable-subtest column does say, once `dynamic_triggers` and `stress1` are set aside: on SQLite
every configuration sits within about 2% of stock, with intervals three to five times narrower than
the headline ones. SQLite is not a workload on which these analyses do nothing measurable in
principle; it is one on which they do nothing worth more than 2%.

The peeling pair on SQLite, AllOpt with against without peeling on the resolvable subtests:
0.9967 [0.9650, 1.0118], resolution floor 3.5%.

Script: `scripts/40-perf.sh sqlite` (about 7 hours at N = 5 on 48 CPUs).

### MySQL 8.0.39 (sysbench 1.0.20, five scripts at 180 s, 36 threads; four configurations; session of 16 Sep 07:27, pinned)

Stock ThreadSanitizer against native: 9.70x [9.29, 10.08], the largest of the five applications (the
paper: 7.1x). Resolvable subtests: 4 of 5 (`oltp_read_only` excluded at 6.1% pooled variation; the
others are between 1.8 and 3.8%, far tighter than the earlier campaign this workload was expected
from). Only four configurations are measured, because each configuration with the escape analysis
takes about 2.2 hours to build on the previous compiler; `docs/mysql.md`.

| Configuration | Paper | All five runs [95%] | Runs 2-5, point | Resolvable subtests [95%] | Verdict |
|---|---|---|---|---|---|
| AllOpt with peeling | 1.16 and 1.11 on the two scripts the paper plots (`select-random-points`, `write-only`); the campaign's figure is a geometric mean over five scripts | 1.042 [0.985, 1.062] | 1.025 | 1.027 [0.991, 1.052] | no measurable change |
| AllOpt with peeling and DynSTC | not in the paper | 1.018 [0.967, 1.037] | 1.009 | 1.000 [0.964, 1.023] | no measurable change |

AllOpt with peeling at 1.042 is the largest MySQL point in the campaign, and it does not separate from
stock (lower bound 0.985; FFmpeg's DE row, lower bound 0.996, comes nearest in the whole campaign). Both runs-2-5 points lie inside their all-five intervals.

Second concurrency row, 84 threads (the paper's `nproc*3/4` value; N = 5): AllOpt with peeling 1.011
[0.978, 1.049], with DynSTC 0.992 [0.966, 1.023]; both cross 1.0. Stock against native at 84 threads:
8.77x [8.56, 9.37].

Script: `scripts/40-perf.sh mysql` (four configurations only; about 3.4 hours at the default N = 2,
6.7 at N = 5, on 48 CPUs; builds in about 8 minutes each with the shipped compiler, 459 s measured at 56 jobs, against 2.2 hours on the previous one).

### FFmpeg 4.3.9 at `-threads 16` (libx264, libx265, mjpeg, stream copy; the Tears of Steel reference clip; session of 21-22 Sep 2026, pinned; the artifact's default thread count)

This is the FFmpeg table an evaluator's default run is compared with: from 22 Sep 2026 the harness's thread
rule for FFmpeg is 16 (`FF_THREADS` empty in `env.sh` means the rule; `FF_THREADS=4` reproduces the paper's
count), and `scripts/40-perf.sh ffmpeg` measures AllOpt with peeling and DynSTC beside the four
default configurations. The thread count was chosen after the data and from it, and is reported as such:
the thread sweep of 18 Sep (next section) found that AllOpt with peeling gains nothing at the paper's
`-threads 4` and about 6 per cent at 8 and 16, that DynSTC's gain is the same at every count, and 16 is
libx265's frame-thread ceiling (`X265_MAX_FRAME_THREADS`) and the highest point of the sweep. The paper's
own count, 4, keeps its table in the next section; an evaluator who exports `FF_THREADS=4` is compared with
that one. The comparator reads the count from these headings and from each run's `meta.json`, so a run is
judged only against the rows of its own count.

Stock ThreadSanitizer against native: 2.883x [2.799, 2.916]. Resolvable subtests: all four.

| Configuration | Paper | All five runs [95%] | Runs 2-5, point | Verdict |
|---|---|---|---|---|
| DynSTC | 1.15 (the paper's bar, measured at `-threads 4`; the paper has no 16-thread figure) | **1.133 [1.114, 1.146]** | 1.132 | **above stock** |
| AllOpt with peeling | not in the paper | **1.067 [1.050, 1.079]** | 1.069 | **above stock** |
| AllOpt with peeling and DynSTC | not in the paper | **1.187 [1.171, 1.201]** | 1.191 | **above stock** |

The two effects compose about multiplicatively: 1.067 x 1.133 = 1.209 against 1.187 measured, the
combination's interval two points below the product. This is where the paper's own transforms reach the most on
the shipped compiler in any measurement we have made: about 19 per cent over stock ThreadSanitizer at 8 and at
16 threads (one interval, below), the transcode 2.43x [2.36, 2.46] slower than native instead of 2.88x. At 8 threads (a second leg the same
night, `data/perf/ffmpeg-threadsweep-f3deebfbab60/threads-8-dynstc/`) the same row is 1.190 [1.167, 1.211]
and DynSTC alone 1.138 [1.112, 1.161], stock against native 2.822 [2.755, 2.889], so the combination's gain
is flat between 8 and 16 threads and the choice of 16 over 8 is libx265's ceiling, not a better number.
AllOpt with peeling carries more static sites than stock at every count (535 690 against 507 825: peeling
duplicates loop bodies), so the gain is a runtime effect and not a static-count one.

Legs: a fresh clone of the artifact at `c280f2b` on this host, `ART_CPUSET=4-27,60-83 ART_RUNS=5
ART_WARMUP=1`, the campaign's set and shape, the machine quiet by announcement, the evening and night of 21-22 Sep on this host's clock (the trees' UTC
stamps read 21 Sep, 13:58 to 17:33). The 16-thread leg: 35
measured cells beside their warm-ups, none retired. The 8-thread leg: 20 cells, two retired by the
disturbance gate (a transient load outside the set) and re-run to completion, the retired cells shipped
beside their replacements. Runs under `data/perf/campaign-f3deebfbab60/ffmpeg-t16/` (this table's leg, which also
carries the two FFmpeg rows of the upstream-flag section below) and the sweep root above;
`scripts/90-tables.sh` regenerates both tables byte-identically and `scripts/91-verify-provenance.sh`
checks both strictly against the shipped compiler.

### FFmpeg 4.3.9 (libx264, libx265, mjpeg, stream copy at `-threads 4`; the Tears of Steel clip; session of 16 Sep 22:02, pinned; the paper's thread count)

The paper's thread count, and the campaign's table. The artifact's default since 22 Sep 2026 is 16 threads
(the section above); a run with `FF_THREADS=4` exported is compared with this table.

Stock ThreadSanitizer against native: 2.76x [2.70, 2.80] (the paper: 2.9x, on a different clip).
Every shipped FFmpeg run carries all four codecs, checked over the recorded runs with
`check_ffmpeg_codecs.py`, which runs as a gate on every cell as it is produced: a cell whose workload
did not emit all four codecs fails at that moment rather than being noticed in a later sweep, so a
table cannot be assembled from incomplete cells. The resolvable set is all four, so the headline column
is the stable column.
On the evaluator path the same check runs per cell and a cell missing a codec is a failed cell, not a
geomean over the survivors: the workload writes each codec's output to `/dev/shm`, a container's default
`/dev/shm` is 64 MB, and the stream-copy and mjpeg outputs exceed it, so without the size `docker/run.sh`
passes two of the four codecs fail silently and the row measures a different quantity (found by the
rehearsal of 17 Sep, whose FFmpeg cells carried two codecs; the rehearsal of the same evening, with the
size and the `-threads 4` cap in force together, carried all four, the two recovered codecs costing about
4 seconds of a 90-second run between them). Twelve configurations rather than fourteen: FFmpeg has no
whole-program summary generator.

The thread sweep on the same clip (18 Sep 2026, `-threads` 2, 4, 8 and 16, the four default configurations,
N = 5, 20 cells per arm, none disturbed, pre-flight worst 0.016) says what the single `-threads 4` row cannot:
DynSTC's speedup is a property of the transform and not of the concurrency, 1.113 [1.098, 1.131], 1.113
[1.096, 1.128], 1.116 [1.087, 1.130] and 1.114 [1.102, 1.125] across an eightfold range, every interval
excluding 1.0. AllOpt with peeling does depend on it: it crosses 1.0 at 2 and 4 threads (1.005 [0.998,
1.021], 1.010 [0.999, 1.021]) and excludes it at 8 and 16 (1.063 [1.052, 1.069], 1.065 [1.055, 1.076]), a gain
of about 6 per cent that is absent at the campaign's thread count. That is one sweep and is reported as an
observation, not claimed; it is the first place in the campaign where peeling pays, and it says where to look.
Stock ThreadSanitizer's overhead falls over most of the range, and not monotonically: 2.94, 2.78, 2.66 and 2.70 at 2, 4, 8 and 16 threads.

**The paper's FFmpeg column differs from this one because of the compiler, not the input, and that is
measured rather than assumed.** The paper's column was taken on a clip that cannot be redistributed; a
control leg on that retired clip, on this compiler, at the same `-threads 4` and N = 5, gives the same
ratios as the reference clip (ratios only; absolute times differ between the clips and are not compared;
the retired clip's runs predate the `input_is_reference` field and are identified by the clip's sha256,
`92eea6ec…`; the control's root is not shipped, as decided, and the numbers are these):

| Configuration | Retired clip, N = 5 | Reference clip, N = 5 |
|---|---|---|
| stock ThreadSanitizer against native | 2.833 [2.768, 2.867] | 2.759 [2.700, 2.803] |
| AllOpt without peeling | 1.005 [0.934, 1.016] | 1.012 [0.996, 1.029] |
| AllOpt with peeling | 1.009 [1.001, 1.018] | 1.006 [0.990, 1.024] |
| DynSTC | 1.126 [1.114, 1.140] | 1.113 [1.099, 1.129] |

Every row overlaps, DynSTC excludes 1.0 on both clips, so the input changes none of the ratios, and the
paper's FFmpeg column (EA 1.05, DE 1.30, DE with peeling 1.42, AllOpt 1.57) differs from this table's
(about 1.0) because of the compiler. Within this table every configuration shares one input, so the rows
compare with each other exactly. The thread sweep's runs ship as
`data/perf/ffmpeg-threadsweep-f3deebfbab60` (80 cells, four arms, their tables beside them), checked
strictly against the shipped compiler like the campaign roots.

| Configuration | Paper (retired clip) | All five runs [95%] | Runs 2-5, point | Verdict |
|---|---|---|---|---|
| EA | 1.05 | 0.996 [0.980, 1.011] | 0.997 | no measurable change |
| LO | 1.00 | 1.001 [0.962, 1.013] | 1.003 | no measurable change |
| STC | 1.00 | 1.000 [0.976, 1.011] | 1.001 | no measurable change |
| SWMR | 1.00 | 1.004 [0.992, 1.019] | 1.008 | no measurable change |
| DE | 1.30 | 1.006 [0.996, 1.020] | 1.009 | no measurable change |
| DE + peeling | 1.42 | 1.010 [0.994, 1.023] | 1.013 | no measurable change |
| DynSTC | 1.15 | **1.113 [1.099, 1.129]** | 1.114 | **above stock** |
| AllOpt without peeling | 1.57 | 1.012 [0.996, 1.029] | 1.015 | no measurable change |
| AllOpt with peeling | not in the paper | 1.006 [0.990, 1.024] | 1.008 | no measurable change |
| AllOpt with peeling and DynSTC | not in the paper | **1.123 [1.112, 1.142]** | 1.125 | **above stock** |

DynSTC is the one analysis with a measurable runtime effect anywhere in this campaign, and its sign
depends on the application: an 11.3% gain here, where the transcode has long single-threaded phases
and the guard skips instrumentation during them, against a 5.6% cost on Redis, whose background
threads start before the first client so the guard is paid for and never pays back. Both intervals
are far from 1.0 and both survive the second concurrency point on Redis. The peeling pair on FFmpeg,
the tightest of the four at a resolution floor of 2.5%: 0.9941 [0.9753, 1.0125], crossing 1.0 like
the other three.

Script: `scripts/40-perf.sh ffmpeg` (about 30 minutes at the default N = 2 and five configurations at 16 threads;
2.2 hours at N = 5 and twelve). The input is produced before the build by one of three paths, in this
order: a prepared copy of the reference clip from `ART_FFMPEG_CLIP_URL` (a URL or a local path), checked against
the sha256 in `docs/ffmpeg-input.md` whichever way it arrived; a local copy of the Blender source in `ART_FFMPEG_SOURCE`, cut with the recorded
command; or, with neither set, the 557 MB Blender source downloaded, verified and cut. The second and
third paths re-encode, and a re-encode's sha256 differs from the reference by construction, so every run
records the input's sha256, and every run taken since 17 September 2026 records `input_is_reference`
beside it; the campaign's own FFmpeg runs predate the field and carry the sha256 alone, which equals
the reference clip's, while the thread sweep carries both. The point-in-interval comparison for this
row is made only on the reference clip; on a regenerated clip the run is valid, its build and run times
are what an evaluator pays, but its ratios are not compared with the intervals above and the script says
so. The reference clip is downloadable from this repository's GitHub release `inputs-v1` (the Zenodo record
carries the same file), `env.sh` defaults `ART_FFMPEG_CLIP_URL` to it, and an evaluator's FFmpeg rows are
therefore compared unless the variable is exported empty. Our
own rehearsal of 17 Sep ran on a regenerated clip and reports the FFmpeg row as not comparable for that
reason. FFmpeg additionally carries a control leg on the
retired clip, so that the difference from the paper's FFmpeg column can be attributed to the
compiler or to the input; see `docs/ffmpeg-input.md`. The recorded Stage B runs under `data/perf/stageB-d3bf9f8c39fe` are from
an earlier compiler and are shipped as data, not as claims.

Workload thread counts follow the campaign's rule, set by the harness and recorded per cell: the memcached
server runs one thread per processor of the pinned set, sysbench three quarters of that, FFmpeg an
absolute 16 since 22 Sep 2026 (the sweep's best and libx265's ceiling; the campaign's own FFmpeg rows were
taken at the paper's 4, which `FF_THREADS=4` reproduces); on the 48-processor set the intervals describe,
that is 48 and 36, and each cell's
`meta.json` carries the value it ran with. To compare a point with these intervals, pin the campaign's shape, 24 physical cores with both SMT threads (48 logical processors; `evaluate.sh` chooses such a set when the machine has one); on
another count the rule yields that machine's point and the row is reported with its thread count rather
than compared (`docs/campaign-parameters.md`). The rehearsal of 17 Sep found the shipped defaults off by
one `/2` (24 and 18 on this set) while the campaign's values lived only in a lab launcher; a memcached row
measured at 24 threads is reported as not comparable for that reason, not as a match.

A disturbed leg costs about double: every cell the gate retires is run once more before it is dropped,
so a two-hour leg on a machine with foreign load can take four hours and end with no data (our rehearsal of
17 Sep: SQLite 97 minutes against the 58 estimated, 15 cells attempted for 8 slots, 14 retired). The
estimates below are for a quiet machine.

### Upstream flag `-tsan-instrument-func-entry-exit=false` (measured, not claimed)

**An upstream flag, not this paper's contribution.** The option is ThreadSanitizer's own
(`ClInstrumentFuncEntryExit` in upstream LLVM's `ThreadSanitizer.cpp`, default on); with it off the compiler
emits no `__tsan_func_entry` and `__tsan_func_exit` calls, so the runtime keeps no shadow call stack, and
every memory access stays instrumented exactly as before. It is orthogonal to the five analyses: they
remove memory-access instrumentation, the flag removes the shadow-stack maintenance, and the two costs
multiply. The rows below measure the flag on stock ThreadSanitizer and on our configurations, on the
shipped compiler, so that the question "does the flag gain more with our analyses than without" is
answered by data rather than argued. They are not rows of the paper: the "Paper" column is absent on
purpose, no badge rests on them, the comparator reports a run of these configurations as measured and
not claimed and never counts it toward a verdict, and `scripts/40-perf.sh` runs them only when asked
(`--configs` with the `-nofe` names: `tsan-nofe`, `tsan-sound-nofe`, `tsan-dom_peeling-ea-lo-st-swmr-nofe`,
`tsan-dom_peeling-ea-lo-st-swmr-stmt-nofe`; the token composes for every application).

**What the flag costs, measured on the shipped compiler, which is why it is not claimed.** The
regression-suite gate of section 1 (row 22: a test that passes under stock ThreadSanitizer and fails under
the configuration is a candidate lost race) was run with `tsan-nofe` and
`tsan-dom_peeling-ea-lo-st-swmr-stmt-nofe` added to the matrix, K = 5, on the second host (AMD EPYC 9115,
21 Sep 2026; `data/suite/preservation-suite-20260921T135253Z-nofe-apollo/`: stock and the two flag configurations,
stock 0 failures; the twelve paper configurations' K = 5 result is the run of the same day on this host,
`data/suite/preservation-suite-20260921T052239Z/`, row 22): **20 candidate losses under each, the same twenty**: `atexit4`, `atexit5`,
`deadlock_detector_stress_test`, `deep_stack1`, `free_race`, `free_race2`, `ignorelist2`, `longjmp3`,
`longjmp4`, `mutex_held_wrong_context`, `on_exit`, `race_on_heap`, `race_with_finished_thread`,
`signal_errno`, `signal_malloc`, `simple_stack`, `simple_stack2`, `sleep_sync`, `suppressions_mutex`,
`unaligned_race`. Classified by running each with `lit -v -a` and reading the reports: eighteen fail on
report content, the race is reported and the frames below the top one are missing (the top frame comes
from the access's own PC, the rest from the shadow stack the flag removed); `suppressions_mutex` fails
because a suppression by function name no longer matches a frame that is no longer there; `unaligned_race`
reports 128 races instead of 224, adjacent unaligned accesses in one function collapsing into one report
once their stacks are identical. So in the suite the flag loses no race at the location level and changes what a
report says: reports name the accessing function and nothing below it, suppressions keyed on callers stop
working, and reports that differ only in their callers merge. On the applications
(`scripts/31-preservation-apps.sh <app> 10` on the second host, stock against `tsan-nofe` and against AllOpt with
peeling and the flag; `data/preservation/{sqlite,memcached}/2026-09-21-nofe-apollo-f3deebfbab60/`, verdicts at all
three levels): no site LOST under either configuration on either application, and the report keys are the same
strings under the flag as under stock at L1, L2 and L3, because the keys are built from the access PC. memcached:
every site stock reports in ten of ten runs (eight at L1) is reported in ten of ten under the flag alone; under
AllOpt with peeling and the flag it shows the one relocation row 24 describes for AllOpt with peeling without the
flag (`conn_new@memcached.c:761` paired with `clock_handler` 0 of 10 at L1 and L2, the location kept 10 of 10 at
L3), the same shape, so it is the bundle's and not the flag's. SQLite resolves less on that host, where stock itself
reports its sites in 1 to 6 of 10 runs (10 of 10 for two of them on this host on 17 Sep, row 24): the site stock
reports most often, `walIndexRecover`, 6 of 10, is KEPT under the flag (3 of 10) and under the bundle with the flag
(2 of 10); the three sites stock reports 1 or 2 times in 10 are 0 of 10 under the flag and UNDETERMINED at this N,
which is what the rule says of a site that stock itself misses in most runs, and is why the check is comparative and
not a fixed list. That is the trade: about 11 per cent on Redis for report stacks of one frame. The submitted paper
does not use the flag, the camera-ready decision on it is the authors', and the artifact reports it
because an evaluator who reads the harness finds these configuration names and should know what they
measure.

Rows (N = 5, 95% intervals, the campaign's set and shape, the legs of 21-22 Sep described under FFmpeg
above; the Redis leg had two cells retired by the disturbance gate, `outside_busy` 0.107 against the bar
of 0.10, and re-run to completion; the memcached leg, 25 measured cells (five configurations), none retired; "stock" is stock
ThreadSanitizer; runs under
`data/perf/campaign-f3deebfbab60/flag-<application>/` and, for FFmpeg, `ffmpeg-t16/`):

| Application | Configuration | All five runs [95%] | Runs 2-5, point | Reading (no row here is the paper's) |
|---|---|---|---|---|
| Redis (50 clients) | stock with the flag | 1.107 [1.072, 1.131] | 1.108 | the flag alone |
| Redis | four sound analyses | 0.995 [0.972, 1.017] | 0.991 | the sound bundle alone, this leg |
| Redis | four sound analyses with the flag | 1.115 [1.090, 1.144] | 1.112 | the flag on the sound bundle |
| Redis | AllOpt with peeling | 1.008 [0.989, 1.030] | 1.001 | ours alone, this leg |
| Redis | AllOpt with peeling and the flag | 1.138 [1.109, 1.161] | 1.141 | the highest Redis row on the shipped compiler, and the flag's, not the paper's |
| Redis | AllOpt with peeling, DynSTC and the flag | 1.083 [1.061, 1.107] | 1.077 | DynSTC's Redis cost, under the flag |
| FFmpeg (16 threads) | stock with the flag | 1.016 [1.002, 1.029] | 1.018 | the flag alone |
| FFmpeg (16 threads) | AllOpt with peeling, DynSTC and the flag | 1.200 [1.185, 1.221] | 1.211 | the flag on top of the paper's 1.187; the difference is the flag's |
| memcached (48 threads) | stock with the flag | 1.000 [0.914, 1.040] | 0.981 | the flag alone: nothing resolved on memcached |
| memcached (48 threads) | AllOpt with peeling | 1.033 [0.945, 1.068] | 1.015 | ours alone, this leg |
| memcached (48 threads) | AllOpt with peeling and the flag | 1.019 [0.925, 1.058] | 1.018 | nothing resolved |
| SQLite, MySQL | measured the night of 21-22 Sep; rows added when the legs end | | | |

**Does the flag gain more with our analyses than on stock?** No more than the product of the two, on both
applications where anything is resolved. Redis: the flag alone 1.107, AllOpt with peeling alone 1.008, their product
1.116, and the combination 1.138 [1.109, 1.161], whose interval contains the product and overlaps the
flag-alone interval; the data allows an interaction of up to about three points in our favour and does not
establish one. FFmpeg: 1.016 x 1.187 = 1.206 against 1.200 [1.185, 1.221] measured. So the sentence the
data supports is that the flag's gain is the flag's, and our analyses gain the same on top of it as without
it: the two are independent, as their mechanisms say they should be. memcached resolves nothing either way:
the flag alone 1.000 [0.914, 1.040], the combination 1.019 [0.925, 1.058], intervals twelve to thirteen points
wide as in the campaign (its memtier workload varies that much run to run), every one containing 1.0 and the
product. Stock ThreadSanitizer with the flag against native, for the record: Redis 7.60x [7.41, 7.81] against
8.42x without; FFmpeg at 16 threads 2.84x [2.75, 2.87] against 2.88x; memcached 3.68x [3.59, 3.92] against
3.68x [3.54, 3.77], the flag buying nothing measurable there.

The earlier leg on the previous compiler (`data/perf/nofe-d3bf9f8c39fe`, 15 Sep 2026, the sound bundle
with and without the flag: Redis 1.233 [1.183, 1.254], MySQL 1.136 [1.081, 1.188], SQLite 1.044 [1.025,
1.060]) is shipped as data. Its Redis figure exceeds this leg's 1.115 by more than either interval, which
is the Redis session drift `docs/confounds.md` describes and the reason ratios are compared within one
session only.

### What an evaluator actually has to run

Reproducing all five applications at fourteen configurations with five runs each took our campaign
32 hours of measurement (the legs ran from 15 Sep 18:49 to 17 Sep 03:03) after about 7 hours of builds;
that is not what anyone should be asked for. The claims are per row, so a subset reproduces
a subset, and the cost is linear in configurations and in runs. Measured from the campaign's per-cell
costs (Redis 86 s, memcached 169 s, FFmpeg 110 s, SQLite 291 s, MySQL 1012 s), with one warm-up plus
N runs per configuration:

| Mode | Runs | Configurations | Time on 48 processors | What a row yields |
|---|---|---|---|---|
| **default** | N = 2 | four: native, stock, AllOpt with peeling, DynSTC (FFmpeg five: plus AllOpt with peeling and DynSTC, at 16 threads) | measured on this host and on a 64-processor AMD host: Redis 13-15 min, memcached 28-36, FFmpeg about 30 (an estimate for the five-configuration 16-thread default from the measured 20-25 for four at 4 threads), SQLite 65-68: **about 2 h 30 min** together; MySQL a further 3.4 h (estimated) | a point estimate, no interval |
| everything at the default | N = 2 | all fourteen (MySQL four) | Redis 1.0 h, memcached 2.0, FFmpeg 1.2, SQLite 3.4, MySQL 3.4: **about 11 h**, 14 h with the builds | a point estimate, no interval |
| our campaign | N = 5 | any of the above | twice the figures above (one warm-up plus five runs against one plus two); everything, 32 h of legs plus builds | a 95% interval |

```
./docker/run.sh scripts/40-perf.sh redis                 # default: four configurations, N = 2
ART_RUNS=5 ./docker/run.sh scripts/40-perf.sh redis      # our setting: intervals
./docker/run.sh scripts/40-perf.sh redis --all-configs   # all fourteen
```

**What the default mode measured when we ran it as an evaluator would** (17-18 Sep 2026, the pushed
checkout in the container, the campaign's own 48 processors (4-27,60-83) pinned, N = 2, four configurations, nothing else on the machine;
those runs are not shipped, the figures are what the scripts printed; the Redis rows are from the run of
17 Sep 14:15, memcached and FFmpeg from the run of 17 Sep 23:07, which followed the thread-count and
shared-memory fixes and carried `input_is_reference: true`, SQLite from the run of 18 Sep 11:47):
the functional check 52 s; Redis 15 min; memcached 28 min at the rule's 48 server threads; FFmpeg 25 min
on the reference clip with all four codecs; SQLite 68 min. Seven of the eight configuration rows landed
inside our interval, both rows whose interval excludes 1.0 on the same side, and one row landed outside:

| Application | Row | Evaluator's point (N = 2) | Shipped interval (N = 5) | Verdict |
|---|---|---|---|---|
| Redis | AllOpt with peeling | 1.004 | 1.000 [0.983, 1.026] | inside |
| Redis | DynSTC | 0.968 | 0.944 [0.927, 0.970] | inside, below 1.0 like ours |
| memcached | AllOpt with peeling | 0.991 | 1.019 [0.951, 1.079] | inside |
| memcached | DynSTC | 0.983 | 0.986 [0.944, 1.063] | inside |
| FFmpeg | AllOpt with peeling | 1.017 | 1.006 [0.990, 1.024] | inside |
| FFmpeg | DynSTC | 1.127 | 1.113 [1.099, 1.129] | inside, above 1.0 like ours |
| SQLite | AllOpt with peeling | 1.078 | 1.023 [0.942, 1.061] | **outside** at N = 2, by 0.017; at N = 5, 1.041 [0.943, 1.129]: intervals overlap, inside |
| SQLite | DynSTC | 0.984 | 0.995 [0.928, 1.082] | inside; at N = 5, 1.035 [0.912, 1.111], inside |

The stock-against-native ratios of the same runs, reported and not judged, since the drift condition
governs them: Redis 8.26 against 8.01 [7.83, 8.21]; memcached 3.66 against 3.20 [2.97, 3.40] (4.66 before
the thread-count defect was fixed, so the fix closed three quarters of the gap and the rest is the size of
the documented session drift); FFmpeg 2.99 against 2.76 [2.70, 2.80]. The SQLite row that failed the
criterion at N = 2 was reported as a failure of the criterion, which was fixed before the run, and then
decided by the N = 5 run of the same leg (18 Sep, 20 cells, none disturbed): 1.041 [0.943, 1.129] against
the shipped 1.023 [0.942, 1.061], intervals overlapping and both containing 1.0, so the N = 2 point was
noise on SQLite's headline column, which this file describes above as heterogeneous (in the N = 2 run
`stress1` varied by 23 per cent between its two runs). At N = 5 the resolvable-subtest column, the
comparable one, also exists: AllOpt with peeling 1.004 [0.984, 1.032] against the shipped 0.998
[0.975, 1.013], overlapping and both containing 1.0; DynSTC 0.980 [0.945, 1.003] against the shipped
0.980 [0.966, 0.999], the same point estimate, with one nuance stated rather than rounded away: the
shipped interval excludes 1.0 by 0.001 and the evaluator's contains it by 0.003, which by the letter of
the N = 5 criterion is a mismatch and by the numbers is a knife-edge on a bound of 0.999 with identical
points. Both numbers are given so a reader sees the 0.001. A second run of the whole tier from a fresh clone on
the same set, 20 Sep 2026 (2 h 56 min: the correctness set 37 min on the 48 pinned processors, Redis 15,
memcached 27, FFmpeg 24, SQLite 73 minutes; no cell disturbed, outside busy share at most 0.014), put five
of six judged rows inside (Redis 1.015 and 0.961, the latter on the same side of 1.0; memcached 0.982 and
0.977; SQLite DynSTC 0.989) and the SQLite AllOpt row outside again at N = 2, 1.076 by 0.015, the same row
at nearly the same value as on 18 Sep, which the N = 5 run above decided; FFmpeg was not comparable there
because the reference clip is not yet downloadable and the run regenerated it. A third run the same night,
the performance subset alone from another fresh clone on the same set, every cell recording its shape (24
cores, 24 complete SMT pairs; 2 h 23 min; no cell disturbed), put four of six inside (memcached 1.017 and
0.958, Redis AllOpt 1.023, SQLite DynSTC 1.029) and two outside: SQLite AllOpt 1.063 by 0.002 and Redis DynSTC
0.984 by 0.014, on the same side of 1.0. The two are different cases, and both are derivable from shipped data
with `harness/tools/perf/subset_spread.py`, which recomputes the headline statistic over every two-run subset
of an N = 5 leg through the aggregator's own estimator. SQLite AllOpt: over the ten two-run subsets of the
N = 5 leg of 18 Sep (shipped as `data/perf/n2-spread-sqlite-n5-20260918`, claimed for nothing) the point
ranges from 0.977 to 1.104 with median 1.028 around the leg's 1.041, and 3 of the 10 exceed the shipped bound
of 1.061; so this row reads outside for about a third of evaluators at N = 2 for reasons unrelated to their
machine (the subsets share runs, so this is within-session spread, not a probability), and our three N = 2
readings of 1.078, 1.076 and 1.063 are that spread. Redis DynSTC: the campaign's own ten two-run subsets range
from 0.926 to 0.965 (1 of 10 outside), and our three N = 2 readings of 0.968, 0.961 and 0.984 sit at or above
that maximum, so they are not the N = 2 spread: the cost of DynSTC on Redis is 2 to 4 per cent on this host
now against the campaign's 5.6, the size of change the documented between-session Redis drift (14 per cent in
the stock baseline six days apart) produces in a ratio, with the sign kept in every run. The table is generated from this
file's own interval tables and each run's `perf_<app>.md`, not transcribed, by
`harness/tools/perf/compare_with_claims.py`, which ships and is the last step of `evaluate.sh reproduced`:
one line per configuration row (the evaluator's point or interval, the shipped interval, inside or outside,
the same-side test where the shipped interval excludes 1.0), "not judged" for the stock-against-native
ratio and for a run that records no thread count, "not comparable" for a run on a non-reference clip or a
different thread count, and a count of rows judged; its exit status is 0 only when every judged row is
inside, and its silence is never a pass.

On other hardware the criterion does not apply, and a full run there says what travels. An AMD EPYC
9115 host (2 sockets of 16 cores with 2 threads each, 64 logical processors) ran the whole
`evaluate.sh reproduced` tier twice from fresh clones, on 19 and 20 Sep 2026, both times pinned to 0-47 by
the rule `evaluate.sh` had until 20 Sep (the first 48 processors the daemon grants), which on that host is
all 32 physical cores, 16 of them with both SMT threads and 16 with one: a shape the campaign (24 cores with
both threads of each) never used. N = 2, no cell disturbed, the runs not shipped. Their cells carry no
session record (the harness's session writer read an Intel-only sysfs file and failed silently there, fixed
19 Sep); the set and the pinned mode come from every cell's own `meta.json`. Judged by the comparator of
those days; since 20 Sep the tool declines a tree whose set records no shape and whose cpuset is not ours,
so it would not judge these rows today:

| Application | Row | 19 Sep (N = 2) | 20 Sep (N = 2) | Shipped interval (N = 5) | Verdict on those days |
|---|---|---|---|---|---|
| Redis | AllOpt with peeling | 1.001 | 1.018 | 1.000 [0.983, 1.026] | inside, inside |
| Redis | DynSTC | 0.971 | 0.977 | 0.944 [0.927, 0.970] | outside by 0.001 and by 0.007, both on the same side of 1.0 |
| memcached | AllOpt with peeling | 1.059 | 1.104 | 1.019 [0.951, 1.079] | inside; outside by 0.025 |
| memcached | DynSTC | 0.942 | 1.162 | 0.986 [0.944, 1.063] | outside by 0.002 below; outside by 0.099 above |
| SQLite | AllOpt with peeling | 0.944 | 1.016 | 1.023 [0.942, 1.061] | inside, inside |
| SQLite | DynSTC | 0.968 | 0.959 | 0.995 [0.928, 1.082] | inside, inside |
| FFmpeg | both rows | 0.999, 1.115 | 1.008, 1.130 | | not comparable: the clip was regenerated there |

What travels: the sign of the Redis DynSTC row on both days (below 1.0 by 2.9 and 2.3 per cent, against the
campaign's 5.6), and SQLite's "no measurable change". What does not: memcached, whose swing from 0.942 to
1.162 in a day is not the compiler. On that host every instrumented memcached run lands in one of two modes,
about 200 s (1.40 to 1.46 million operations per second) or about 230 s (1.20 to 1.25 million): on 19 Sep
stock drew one of each, AllOpt with peeling two fast, DynSTC two slow; on 20 Sep stock two slow, AllOpt one of
each, DynSTC two fast. At N = 2 a ratio there is which mode each pair drew. This is the bimodality
`docs/confounds.md` records for memcached on the earlier campaign on our host, absent from the shipped
campaign (1 to 3 per cent per configuration at N = 5) and present on this host's 32-core set; whether the
shape or the host produces it is what a run on that host's sibling-paired set (0-23,32-55, the set
`evaluate.sh` chooses there since 20 Sep) will say. The refusals are the machinery working rather than a
gap: FFmpeg is declined because that host regenerated the clip, and every stock-against-native ratio
(memcached 4.56 and 4.85 on the two days against our 3.20 [2.97, 3.40]) is reported and not judged because
the drift condition governs it. The SQLite AllOpt row was 0.909 and outside on that host's run of 18 Sep,
then 0.944 and 1.016 and inside, which is the size of the N = 2 variation on that column and the reason the
criterion asks for five runs before it is strict. Wall time there on 20 Sep: 2 h 48 min for the whole tier
(the correctness set 30 min on 64 processors; Redis 13, memcached 36, FFmpeg 20, SQLite 69 minutes).

The same host, the same night, on the campaign's shape: `evaluate.sh` now chooses the first 24 complete SMT
pairs, which there is 0-23,32-55 (24 cores with both threads, every cell recording it), and the whole tier ran
again from a fresh clone (2 h 49 min). The comparator judged six rows: memcached inside on both (1.016 and
0.983), Redis inside on both (0.986; DynSTC 0.939, on the same side of 1.0, a cost of 6.1 per cent against the
campaign's 5.6), SQLite outside on both (AllOpt 0.913 by 0.029 below, DynSTC 1.123 by 0.041 above). Two things
follow. The memcached two-mode behaviour above was the shape, not the host: on the paired set all eight
instrumented runs landed in the fast mode (194 to 207 s, 1.37 to 1.49 million operations per second) and both
rows fell inside, where on the 32-core set the pairs had split between the modes on two days running. And
SQLite's headline column is wide on that host at N = 2 in either direction (0.909, 0.944, 1.016 and 0.913 for
AllOpt over four runs; 0.851, 0.968, 0.959 and 1.123 for DynSTC), wider than on ours, so on that host the row
is one that only an N = 5 run can decide; the resolvable-subtest column, which the shipped tables carry, is
the one to read there.

The four configurations decide everything the paper's figure turns on, and Redis, memcached and
FFmpeg together, about an hour and a quarter, cover the two things this campaign found: DynSTC's
cost on Redis, and the absence of a measurable effect elsewhere. MySQL is the expensive one and its
table ships, so `scripts/90-tables.sh` gives it without running anything.

Two runs give no confidence interval, and the artifact does not print one: below five runs a row is
rendered as a point estimate labelled "N = k, no interval; compare with the shipped interval", never
as a bootstrap over too few samples (at N = 3 such an interval is narrower than at N = 5 while the
point moves by about four points with the choice of runs, which is precision that is not there).
`ART_SMOKE=1` is for checking that the pipeline runs and prints "not a measurement" on its own output.

**Match criterion for every configuration row.** At the default N = 2: the evaluator's point estimate
falls inside our 95% interval, and for the rows whose interval excludes 1.0 (Redis under DynSTC, alone
and with AllOpt) it falls on the same side of 1.0. At N = 5: the evaluator's interval overlaps ours, a
row whose interval contains 1.0 here contains 1.0 there, and a row that excludes it excludes it on
comparable hardware. The criterion applies to the configuration rows, each a ratio against stock
ThreadSanitizer on the same machine in the same session. It does not apply to the stock-against-native
ratio printed at the top of each application: that number is governed by the drift condition stated
with the Redis rows (byte-identical binaries differed by 14% and 5% six days apart on this host), and an
evaluator's value a few per cent outside its interval is that condition, not a mismatch. Our own
rehearsal of 17 Sep, N = 2 in the container on 48 pinned processors, gave Redis stock-against-native
8.26 against 8.01 [7.83, 8.21], outside by 0.6% of the upper limit, while both configuration rows fell
inside their intervals (AllOpt with peeling 1.004 in [0.983, 1.026]; DynSTC 0.968 in [0.927, 0.970],
below 1.0 like ours). `docs/confounds.md` lists what makes this vary: memcached's throughput
varies 1 to 3 per cent per configuration at N = 5 while its speedup intervals are 12 to 16 points wide
(a ratio's bootstrap over five runs), SQLite's seven subtests are
heterogeneous and two of them carry about 15 per cent run-to-run variation, and absolute
overheads are not comparable across compiler trees even when ratios are.

**What to conclude from a row outside its interval.** The comparator prints the distance. At N = 2 an
outside row is first of all a two-run point against a five-run interval: re-run that application with
`ART_RUNS=5 ./docker/run.sh scripts/40-perf.sh <app>` (about 2.5 times the default's time) and apply the
N = 5 criterion, which is what we did for SQLite above. If it still falls outside: for a row whose shipped
interval excludes 1.0 (the directional claims, DynSTC's cost on Redis and its gain on FFmpeg), the claim is
reproduced when the evaluator's interval lies on the same side of 1.0 and not reproduced otherwise; for a
row whose shipped interval contains 1.0 (claimed as no measurable change), an evaluator's interval that
also contains 1.0 reproduces the claim whatever its width, and one that excludes 1.0 is a measurable
effect we did not see, to be reported as such. On hardware unlike ours (another vendor, or fewer than 48
pinned processors) the AMD table above is what such a run says: the signs travel, the magnitudes need not,
and the criterion is not applied.

## 6. Bounded shadow state

The shipped data here come from compilers `f80e80b1dbe6` (the two-race experiment) and
`e90a3fc41004` and `89e5d0078d2f` (the occupied-granule experiment), as `data/README.md` records; the
script re-runs the occupied-granule experiment on the shipped compiler.

| Claim | Script | Match criterion |
|---|---|---|
| ThreadSanitizer itself fails to report a planted race in about a quarter of runs on a fully occupied granule; the optimized builds sit in the same range where the burst remains instrumented | `scripts/50-eviction-stress.sh` | within the confidence intervals: stock about 75%, optimized 74 to 76% |
| Dominance elimination trades losses against gains rather than only losing. The program plants two races on one granule, A-B and C-B, and a third thread's burst evicts A's record in 236 of 1000 runs (the same 236 under every build, since the burst is the same). **In those 236 runs DE reports A-B in 0 and stock in 54**: stock's second, dominated store of A re-inserts the record, DE has removed that store. In the other 764 runs both report A-B in exactly 174, so DE's loss on A-B is confined to the evicted runs. Conversely that re-inserting store of stock's evicts C's record in 71 runs, all among the 236, and stock reports C-B in none of those 71 (165 of 236), while DE, which never executes it, reports C-B in 236 of 236. Overall 0.93 reports per run against stock's 0.91 | recorded in `data/eviction-stress/de2-2026-09-03-f80e80b1dbe6/report.md`, not re-run: `scripts/50-eviction-stress.sh` runs experiment (a) only | the conditional counts, within their intervals: A-B given the eviction near 0 under DE and near a fifth under stock; C-B given the eviction all of them under DE and about two thirds under stock; outside the eviction the two builds equal |

## 7. Not claimed here

Five things the submitted paper reports that this artifact does not support, named here so that a reader
following the paper does not look for them:
- **The static-reduction figures of the submitted version** (up to 65 %; 60.8, 34.7, 64.9, 55.6 and 14.5 %
  per application). Measured with the submitted compiler; the shipped compiler's are 2 to 8 per cent
  (section 3), and the camera-ready reports those.

- **Executed instrumentation per unit of work** (the paper's dynamic-reduction figures, 23 to 58 per
  cent). Not re-measured on the shipped compiler. The counter runs under `data/perf/*-counters` are
  from an earlier compiler and carry no stock baseline, so no comparison can be derived from them.
- **Memory overhead** (the paper's shadow-memory reduction figures). Not measured in this campaign and
  no data is shipped for it.
- **The ReX comparison and the access-trace oracle** (the paper's appendix). The filter is research
  code behind a build flag that is off by default, and the oracle is a tool on an internal branch;
  neither is in this repository, and neither number can be reproduced from it.
- **Chromium**, for the reason given below.


- **Chromium.** No performance number. The only Chromium build we have is on an earlier compiler
  and corresponds to no measurement in the paper. `docs/chromium.md` records the revision
  (`bdef6783a05f0b3f885591e7d2c7b2aec1a89dea`), the configuration and the timeout patch.
- **Loop peeling in isolation.** Its runtime effect is smaller than any of these workloads resolves,
  so the artifact claims the static cost it carries and not a runtime verdict either way; see
  `docs/campaign-parameters.md`.

Expensive rather than unclaimed, and the distinction matters: **MySQL performance is claimed** in
section 5 like every other application, from campaign runs that ship with the rest. What it is not is
cheap to re-run: four configurations, four builds (their cost on the shipped compiler is measured by the
rehearsal of 17 Sep and recorded in section 5), about 3.4 hours of runs at the default N = 2 and
seven at N = 5, and about 100 GB of disk. An evaluator who does not spend that gets the table from the shipped runs with
`scripts/90-tables.sh`, which regenerates it without running anything; one who does gets the same
comparison we made. It is measured at four configurations rather than fourteen because a build with
the escape analysis takes about 2.2 hours, and `docs/mysql.md` gives the reason in full.
