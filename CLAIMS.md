# Claims and how to check them

Every claim the paper makes, the script that produces it, and what counts as a match. If a number is not
here, the artifact does not claim it.

Every performance row: compiler `f3deebfbab60` (the image's `TSAN_AUDIT_HASH`); one discarded warm-up, then
N = 5 runs per configuration (our campaign; an evaluator's default is N = 2, see
"What an evaluator actually has to run"); pinned to 48 logical processors that are 24 physical cores with both SMT
threads of each (CPUs 4-27 and 60-83 on our machine, siblings n and n+56); one measurement at a time, in run-major
order. The statistic is the geometric mean over an application's tests of per-test medians, with a 95% confidence
interval from 2000 bootstrap resamples over runs (seed 1). Our machine: Intel Xeon w9-3495X, 56 cores / 112 threads,
250 GB RAM, Ubuntu 24.04, kernel 6.8. All campaign parameters: `docs/campaign-parameters.md`.

## Terms used below

- **Configuration**: one compiler setting per build, named as the harness names it. Names compose per
  hyphen token, so any subset can be built and measured. Every configuration row is a ratio against `tsan`
  on the same machine in the same session; above 1.0 is faster than stock.

  | Name | What it builds |
  |---|---|
  | `orig` | native, no ThreadSanitizer |
  | `tsan` | stock ThreadSanitizer, the baseline of every ratio |
  | `tsan-st`, `tsan-swmr`, `tsan-lo`, `tsan-ea`, `tsan-dom` | one analysis alone: STC, SWMR, LO, EA, DE |
  | `tsan-dom_peeling` | DE with loop peeling |
  | `tsan-stmt` | DynSTC, the dynamic single-threaded-context transformation |
  | `tsan-sound` | the four sound analyses together: STC, SWMR, LO, EA |
  | `tsan-dom-ea-lo-st-swmr` | those four with DE, no peeling; the tables label it `AllOpt-peel` |
  | `tsan-dom_peeling-ea-lo-st-swmr` | the same with peeling: the paper's AllOpt, labelled `AllOpt+peel` |
  | `tsan-dom_peeling-ea-lo-st-swmr-stmt` | AllOpt with peeling and DynSTC; the tables print the name itself, for the reason recorded in `data/tools/perf/aggregate.py` |
  | suffix `-wp` | with whole-program summaries; defined for memcached, Redis and SQLite only |
  | suffix `-nofe` | with the upstream flag `-tsan-instrument-func-entry-exit=false`, not this paper's contribution (its own section below) |
- **Cell, leg, root**: one application, configuration and run; one application's cells in run-major order; a
  directory of legs recorded under one compiler (`data/perf/campaign-f3deebfbab60/primary`).
- **Disturbed, retired, the gate**: a pinned cell whose processors outside its set were more than 0.10 busy is
  retired from the statistics and re-run; it ships beside its replacement (`docs/confounds.md`).
- **Headline column, resolvable column**: the geometric mean over all of an application's subtests, and over
  the subtests stable enough under stock to resolve a change of a few per cent (section 5).
- **Point estimate, interval, same side**: N = 5 gives a 95% bootstrap interval, N = 2 a point compared with the
  shipped interval; "same side" of 1.0 as ours applies to rows whose shipped interval excludes 1.0.
- **L1, L2, L3**: how closely two race reports must agree to count as the same race: kind and both stacks with
  file and line (L1), the functions alone (L2), the location and its writer (L3).
- **input_is_reference**: FFmpeg's input clip has the reference sha256; a regenerated clip is valid but its
  rows are not compared.
- **Session drift**: byte-identical binaries measured days apart on one host differed by 14%; the
  stock-against-native ratio is reported and not judged for that reason.

---

## 1. Race detection is preserved (deterministic)

| Claim | Script | Match criterion |
|---|---|---|
| No configuration loses a race that stock ThreadSanitizer reports, over ThreadSanitizer's own regression suite | `scripts/30-preservation-suite.sh` | exact: no candidate lost race, that is, no test failing every repeat under a configuration and never under stock. Of the vendored suite's 383 tests `lit` marks 90 unsupported on this platform (47 Darwin, 37 libdispatch, 1 libcxx, 5 behind their own feature gates such as `getline_nohang.cpp`, unsupported from glibc 2.38 on; each named in `data/suite/unsupported/`), so 293 execute in each of 12 configurations, K repeats each. Shipped run (`f3deebfbab60`, K = 5, 60 repeats; `data/suite/preservation-suite-20260921T052239Z`): 292 pass and 1 is expectedly failed, 0 fail and 0 time out in every repeat, always-fail = 0 and ever-fail = 0 in every configuration; on a 64-processor AMD host, 0 and 0 in 60 repeats. An earlier run on the same compiler (`data/suite/preservation-suite-20260917T075005Z`, 0 failures in 60 repeats) predates the fix to the lit configuration's glibc detection: 91 unsupported, 292 executed (`docs/nondeterministic-tests.md`). Each run's README gives the command that re-derives its numbers |
| The harness can detect a loss at all | `scripts/30-preservation-suite.sh --self-test` | required first: with load and store instrumentation switched off, the harness must report the losses; otherwise a silent suite cannot be told from a blind harness |
| Every race test reports the same race as under stock ThreadSanitizer (report keys at L1 and L2) | recorded, not re-run by the evaluator: a K = 5 replay of the executable tests (293 in that run) under the 12 configurations on compiler `aa8a6dd8a2e8`, keyed by `harness/tools/preservation/tsan_reports.py` (`data/suite/replay-aa8a6dd8a2e8/`); it holds for `f3deebfbab60`, whose three extra commits change none of the 112 corpus rows and none of the 17 application configurations' site counts, and leave Redis's whole-program summaries byte-identical | no L1 or L2 key differs on any test. The other bucket: `pthread_atfork_deadlock2.c` lost a report under STC alone (the only loss; a thread-leak diagnostic, not a data race); `fd_location_closed.cpp` (STC, AllOpt with peeling), `race_on_barrier2.c` (STC, DE) and `fork_atexit.cpp` (9 of the 11 compared configurations) gained one, all three non-deterministic under stock itself (`docs/nondeterministic-tests.md`). The replay's 293 is the compiler source tree's suite, counted independently of the first row's. `scripts/30-preservation-suite.sh` compares pass and fail per test, not report text (`lit -q` captures no reports). Not for the `-nofe` rows: that flag removes the shadow stack the keys are built from (both frames at L1, the functions at L2, the writer and heap locations at L3); their preservation rests on the suite's pass or fail per test and on the applications' race counts and kinds |
| No test that expects no report produces one | `scripts/30-preservation-suite.sh` | exact |
| On the applications, no race site that stock ThreadSanitizer reports in every run is absent from an optimized configuration in every run | `scripts/31-preservation-apps.sh <app> 10` (N = 10 as we ran it; at the default N = 2 the script prints the frequencies and no verdict) | comparative, on your own runs, never against a fixed set, since detection is schedule-dependent. Each site, by the configuration's count of N: KEPT if reported in at least one run, whatever stock's frequency; LOST if never, while stock reports it in every run; UNDETERMINED at this N if never, while stock reports it only in some; ONLY-OPTIMIZED if stock never reports it (labelled, not dropped: shadow eviction can produce it). Non-zero exit only on LOST. Ours: `f3deebfbab60`, N = 10, stock, the sound bundle and AllOpt with peeling, gating at L3 (`data/preservation/*/2026-09-17-shipped-f3deebfbab60/verdict-L3.txt`, all three levels printed). **SQLite: no site lost at any level**; at L3 `walRestartHdr` 68034 and 68035 and `walIndexRecover` 67450, KEPT everywhere, the weakest at 2 / 2 / 3 of 10. **memcached: no site lost at L3**; four sites at 10 of 10 under all three (`clock_handler` on `current_time`, `do_item_link` and `do_item_unlink` on `stats_state` and `memory_allocated`); seven UNDETERMINED (once in ten under stock and under the sound bundle, never under AllOpt with peeling); one only in the optimized builds (`lru_maintainer_juggle` reading `current_time`, 0 / 2 / 2 of 10). **One relocation, reported rather than suppressed**: at L1 and L2, reader `conn_new@memcached.c:761` paired with writer `clock_handler` on `current_time` is 10 of 10 under stock and the sound bundle and 0 of 10 under AllOpt with peeling, which reports that race on that location 10 of 10 through `do_item_link`, `lru_maintainer_thread` and `try_read_command_ascii`. Line 761 is instrumented identically in all three builds (campaign binaries, and IR with the campaign's flags: `conn_new` 20 reads, 35 writes, 60 `__tsan_*` calls, 403 instructions, two calls at line 761, among them the `__tsan_read4` of `current_time`, the function's only reference to it; `clock_handler` 15 calls). Which reader's record survives the four shadow slots is eviction arithmetic, shifted by AllOpt with peeling's 382 extra instrumented sites; the sound bundle, DE alone and DE with peeling each keep the pairing at 10 of 10. L3, the paper's criterion, holds. Earlier trees under `data/preservation/` are from earlier compilers of the same lineage, shipped as data |

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
| Static instrumentation sites per application and configuration | `scripts/20-static-counts.sh` | exact for the differences between configurations (what each analysis removes or adds, a property of the compiler); absolute counts to within a constant offset from the build environment. Redis built in the container has 37 922 sites under stock and 43 272 under AllOpt with peeling, against 37 941 and 43 291 host-built: 19 fewer in each, removed and added counts identical, because without libsystemd in the image Redis's Makefile compiles out `redisCommunicateSystemd` and the branches in its four callers (every image shows the same 19). Redis stamps its build time, so its campaign binaries match no sha256 in `static-counts.csv` and are tied to their counts by sources and flags; the other four applications' binaries hash-match their rows |
| Static instrumentation reduction, the submitted paper's headline figure (up to 65 %) | `scripts/20-static-counts.sh` against `data/perf/campaign-f3deebfbab60/static-counts.csv` | exact: on the shipped compiler AllOpt without peeling removes 5.0 % (memcached), 2.3 % (Redis), 7.8 % (FFmpeg) and 3.3 % (SQLite) of the static memory-access sites, and AllOpt with peeling carries more sites than stock on every application (+5.7, +14.1, +5.5, +6.8, MySQL +6.3 %), because peeling duplicates loop bodies. The paper's 60.8, 34.7, 64.9, 55.6 and 14.5 % came from the submitted compiler, whose reach relied on an unsound same-location test in the dominance elimination that the soundness fixes closed; the camera-ready reports the new figures |
| The compiler built from the shipped patch series behaves like the frozen compiler the performance numbers were measured on | `scripts/12-compiler-equivalence.sh` | exact: 28 vendored LLVM IR modules recompiled under 4 configurations; all 112 `__tsan_*` symbol histograms must equal the campaign compiler's reference table, and the `TSAN_AUDIT_HASH` stamp is checked separately. "Behaves like", not "is": the three compile-time commits change none of the 112 rows. A control requires the reference table to separate the configurations (24 of 28 modules do) |
| The three compile-time commits added to that compiler changed no instrumentation decision on any application | recorded, not re-run by the evaluator (the corpus and its reference table in `data/equivalence/`) | the same 112 corpus rows against the previous compiler, plus the 17 application configurations built on both compilers (MySQL 640 355 sites and 1 263 905 calls; all 14 Redis rows) and Redis's whole-program analysis summaries byte-identical between them |
| Executed instrumentation per unit of work | not measured on this compiler; the recorded counter runs are shipped under `data/perf/*-counters` and are from an earlier one | exact from the shipped data; within run-to-run noise when re-measured |

## 3b. Every shipped run is attributable (deterministic)

| Claim | Script | Match criterion |
|---|---|---|
| Every run of the campaign (`data/perf/campaign-f3deebfbab60/{primary,r2}`: 290 and 110 measured runs beside their warm-ups) records its compiler, the hash of its binary, the hash of its input where it has one (FFmpeg), its processor set and mode, the foreign-activity share the gate saw and the size of the set it watched (56 of the 64 processors outside the pinned set; eight were excluded during the campaign, which the shipped default no longer does), and its place in a full set of N | `scripts/91-verify-provenance.sh` | exact: exit 0 only when every run is attributable; an empty root fails, and a root with no runs directly is expanded to its sub-roots. Six assertions, each tested against its fault: a pre-audit binary measured as current; a configuration whose binary changed mid-leg; an input path that satisfied the runner and recorded an empty hash; pinned and unpinned runs pooled; a run above the gate that was kept; a thin row that looked complete. The earlier trees, on earlier compilers and predating these fields, support no claim and are reported for information only |

This is the property the paper's setup section rests on. It does not check a configuration's flags (the build
guard does) or whether a number is right: a tree can pass this and be wrong, but not pass it and be
unattributable.

## 4. Compile-time overhead

| Claim | Script | Match criterion |
|---|---|---|
| Compile-time overhead of the analyses over an uninstrumented build | `scripts/21-compile-time.sh` | same order of magnitude; a few per cent tolerance, since it depends on the machine and the parallelism. Every repetition rebuilds from scratch with native and stock as controls; on memcached, a build of about ten seconds, the control shows the resolution is worse than the effect (ratios 1.00 to 1.05, 0.0% variation between control repetitions), and the script says so instead of printing a ratio |

## 5. Performance (machine-dependent)

The "Paper" column of each table is the submitted manuscript's figure, measured before the soundness fixes
and kept for the record; the camera-ready reports the numbers in this file.

The campaign of 15-17 September 2026 on `f3deebfbab60`: 400 measured runs beside their warm-ups
(`data/perf/campaign-f3deebfbab60/{primary,r2}`, 290 and 110), three cells retired and re-run
(`docs/campaign-parameters.md`). **Of the 48 rows at the primary concurrency, four
separate from stock, and all four are DynSTC: a 5.6% cost on Redis and an 11.3% gain on FFmpeg, alone and inside
AllOpt.** Every other row crosses 1.0. At 16 threads, FFmpeg's default in the artifact, three rows are above stock,
all from the paper's own transforms: DynSTC, AllOpt with peeling and their combination. Rows with the upstream flag
are measured, not claimed.

A row is claimed to differ from stock only when its interval over all five runs excludes 1.0 and its point over
runs 2-5 (four runs, no interval) lies inside that interval; "no measurable change" means the interval contains
1.0, not that the effect is zero. "Resolvable subtests" is the speedup over the subtests whose pooled run-to-run
variation under stock is at most 5%, the set fixed once per leg for every row. It needs at least three runs, so at
the default N = 2 the artifact prints "pooled CV not estimable at this N -- NOT A STABILITY CLAIM" instead.

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

DynSTC, alone and inside AllOpt with peeling, is the one Redis effect. Condition on every Redis row: session drift,
measured on Redis as 14% (stock) and 5% (native) in throughput between byte-identical binaries six days apart
(`docs/confounds.md`); ratios within one session are what is claimed, and a few points of disagreement with an
evaluator's run is inside that effect. At 112 clients (the `r2` leg, N = 5; the 112 row of the Redis curves below)
DynSTC and its combination with AllOpt with peeling stay below stock and every other row crosses 1.0 within about
two points (`data/perf/campaign-f3deebfbab60/r2/`); stock against native 7.96x [7.83, 8.11]. The peeling pair,
AllOpt with against without peeling on the resolvable subtests: 1.0105 [0.9905, 1.0326].

Script: `scripts/40-perf.sh redis` (about 15 minutes at the default N = 2 and four configurations; about 2
hours at N = 5 and fourteen, on 48 CPUs).

### memcached 1.6.29 (`memtier_benchmark` 2.1.1, 10 threads x 50 clients, pipeline 16, 100 000 requests per client, averaged over 5 iterations, server at 48 threads; session of 15 Sep, pinned)

Stock ThreadSanitizer against native: 3.20x [2.97, 3.40] (the paper: 2.5x). **No configuration is resolved on
memcached**: all twelve instrumented configurations have intervals 11.9 to 15.7 points wide that contain 1.0 (the
`orig` row, native against stock, 42.8). memcached reports one metric, so the interval is its run-to-run variance at
N = 5, and only more runs would narrow it. The paper's bars (1.00 to 1.07) lie inside, neither confirmed nor
contradicted.

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

Redis's DynSTC cost does not appear here (0.986, the narrowest interval), whether by a real difference or by
memcached's noise. The peeling pair: 1.0332 [0.9593, 1.0567]. With the server at 112 threads (the paper's `nproc`
value; the `r2` leg, the 112 row of the memcached curves below) both rows measured cross 1.0, with intervals 25 to
27 points wide; stock against native 5.11x [4.48, 5.22].

Script: `scripts/40-perf.sh memcached` (about 34 minutes at the default N = 2 and four configurations;
4 hours at N = 5 and fourteen).

### SQLite 3.50.2 (`threadtest3`, all seven subtests at their default thread counts; session of 16 Sep 00:30, pinned)

Stock ThreadSanitizer against native: 2.96x [2.79, 3.28] (the paper: 2.4x), the widest slowdown interval, because
SQLite's uninstrumented build varies by 37.9% run to run. Resolvable subtests: 5 of 7 (`dynamic_triggers` and
`stress1` excluded).

**Nothing is claimed for SQLite: every headline interval contains 1.0**, over all seven subtests and on both run
ranges. The paper's largest single claim, AllOpt 1.71 on SQLite, is not reproduced: the campaign measures 1.020.

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

On the resolvable subtests every row is within about 2% of stock, with intervals three to five times narrower; the
bold DynSTC entry is not claimed, because a row is claimed on the headline column only. The peeling pair on the
resolvable subtests: 0.9967 [0.9650, 1.0118], resolution floor 3.5%.

Script: `scripts/40-perf.sh sqlite` (about 70 minutes at the default N = 2 and four configurations; about 7
hours at N = 5 and fourteen, on 48 CPUs).

### MySQL 8.0.39 (sysbench 1.0.20, five scripts at 180 s, 36 threads; four configurations; session of 16 Sep 07:27, pinned)

Stock ThreadSanitizer against native: 9.70x [9.29, 10.08], the largest of the five applications (the
paper: 7.1x). Resolvable subtests: 4 of 5 (`oltp_read_only` excluded at 6.1% pooled variation; the
others are between 1.8 and 3.8%). Four configurations only (section 7).

| Configuration | Paper | All five runs [95%] | Runs 2-5, point | Resolvable subtests [95%] | Verdict |
|---|---|---|---|---|---|
| AllOpt with peeling | 1.16 and 1.11 on the two scripts the paper plots (`select-random-points`, `write-only`); the campaign's figure is a geometric mean over five scripts | 1.042 [0.985, 1.062] | 1.025 | 1.027 [0.991, 1.052] | no measurable change |
| AllOpt with peeling and DynSTC | not in the paper | 1.018 [0.967, 1.037] | 1.009 | 1.000 [0.964, 1.023] | no measurable change |

Neither row separates from stock, and both runs-2-5 points lie inside their intervals. At 84 threads (the paper's
`nproc*3/4` value; the `r2` leg, N = 5), AllOpt with peeling 1.011 [0.978, 1.049] and with DynSTC 0.992 [0.966, 1.023]
cross 1.0; stock against native 8.77x [8.56, 9.37].

Script: `scripts/40-perf.sh mysql` (four configurations only; about 3.4 hours at the default N = 2,
6.7 at N = 5, on 48 CPUs; builds in about 8 minutes each with the shipped compiler, 459 s measured at 56 jobs).

### FFmpeg 4.3.9 at `-threads 16` (libx264, libx265, mjpeg, stream copy; the Tears of Steel reference clip; session of 21-22 Sep 2026, pinned; the artifact's default thread count)

The table an evaluator's default run is compared with: 16 threads (`FF_THREADS` empty in `env.sh`), libx265's
frame-thread ceiling (`X265_MAX_FRAME_THREADS`), chosen after the campaign from its thread sweep (next section), with
AllOpt with peeling and DynSTC added to the four default configurations. A run with `FF_THREADS=4`, the paper's
count, is compared with the next section's table: the comparator reads the count from these headings and from each
run's `meta.json`, and judges a run only against the rows of its own count.

Stock ThreadSanitizer against native: 2.883x [2.799, 2.916]. Resolvable subtests: all four.

| Configuration | Paper | All five runs [95%] | Runs 2-5, point | Verdict |
|---|---|---|---|---|
| DynSTC | 1.15 (the paper's bar, measured at `-threads 4`; the paper has no 16-thread figure) | **1.133 [1.114, 1.146]** | 1.132 | **above stock** |
| AllOpt with peeling | not in the paper | **1.067 [1.050, 1.079]** | 1.069 | **above stock** |
| AllOpt with peeling and DynSTC | not in the paper | **1.187 [1.171, 1.201]** | 1.191 | **above stock** |

About 19 per cent over stock, the largest gain of the paper's own transforms on the shipped compiler: the transcode
runs 2.43x [2.36, 2.46] slower than native instead of 2.88x, the two effects composing about multiplicatively (1.067
x 1.133 = 1.209 against 1.187). At 8 threads (`data/perf/ffmpeg-threadsweep-f3deebfbab60/threads-8-dynstc/`) the
combination is 1.190 [1.167, 1.211], DynSTC 1.138 [1.112, 1.161] and stock against native 2.822 [2.755, 2.889]:
16 is chosen for libx265's ceiling, not for a better number. AllOpt with peeling carries more static sites than stock
(535 690 against 507 825), so its gain is a runtime effect. Runs (N = 5, the campaign's set and shape):
`data/perf/campaign-f3deebfbab60/ffmpeg-t16/` (35 cells, none retired; also the flag section's FFmpeg rows) and
`threads-8-dynstc/` (20 cells, two retired by the gate and re-run, both shipped), both regenerated by
`scripts/90-tables.sh` and checked strictly by `scripts/91-verify-provenance.sh`.

### FFmpeg 4.3.9 (libx264, libx265, mjpeg, stream copy at `-threads 4`; the Tears of Steel clip; session of 16 Sep 22:02, pinned; the paper's thread count)

The paper's thread count and the campaign's table; a run with `FF_THREADS=4` exported is compared with it.

Stock ThreadSanitizer against native: 2.76x [2.70, 2.80] (the paper: 2.9x, on a different clip).
Twelve configurations (FFmpeg has no whole-program summary generator); the resolvable set is all four codecs, and
`check_ffmpeg_codecs.py` fails any cell that did not emit all four (hence `docker/run.sh --shm-size=1g`).

The thread sweep on the same clip, reported and not claimed (the four default configurations, N = 5, 20 cells per
arm, none disturbed; `data/perf/ffmpeg-threadsweep-f3deebfbab60`, 80 cells, checked strictly):

| Configuration | `-threads 2` | `-threads 4` | `-threads 8` | `-threads 16` |
|---|---|---|---|---|
| DynSTC | 1.113 [1.098, 1.131] | 1.113 [1.096, 1.128] | 1.116 [1.087, 1.130] | 1.114 [1.102, 1.125] |
| AllOpt with peeling | 1.005 [0.998, 1.021] | 1.010 [0.999, 1.021] | 1.063 [1.052, 1.069] | 1.065 [1.055, 1.076] |
| Stock against native | 2.94 | 2.78 | 2.66 | 2.70 |

DynSTC's gain does not depend on the thread count; AllOpt with peeling gains about 6 per cent at 8 and 16 threads
only (the sweep has no AllOpt without peeling, so peeling's share of that is not isolated).

**The paper's FFmpeg column differs from this one because of the compiler, not the input.** A control leg on the
paper's clip (sha256 `92eea6ec…`; it cannot be redistributed, so its runs are not shipped), on this compiler at
`-threads 4` and N = 5, gives the same ratios as the reference clip (ratios only; absolute times are not compared):

| Configuration | Retired clip, N = 5 | Reference clip, N = 5 |
|---|---|---|
| stock ThreadSanitizer against native | 2.833 [2.768, 2.867] | 2.759 [2.700, 2.803] |
| AllOpt without peeling | 1.005 [0.934, 1.016] | 1.012 [0.996, 1.029] |
| AllOpt with peeling | 1.009 [1.001, 1.018] | 1.006 [0.990, 1.024] |
| DynSTC | 1.126 [1.114, 1.140] | 1.113 [1.099, 1.129] |

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

At this thread count DynSTC is the one transform with a measurable effect, and its sign depends on the application:
an 11.3% gain here, where the transcode's long single-threaded phases let the guard skip instrumentation, against a
5.6% cost on Redis, whose background threads start before the first client, so the guard never pays back. The
peeling pair, the tightest of the four at a resolution floor of 2.5%: 0.9941 [0.9753, 1.0125].

Script: `scripts/40-perf.sh ffmpeg` (about 21 minutes at the default N = 2 and five configurations at 16 threads;
2.2 hours at N = 5 and twelve). Only runs on the reference clip (`ART_FFMPEG_CLIP_URL`, by default this repository's
GitHub release `inputs-v1`) are compared; a re-encode of the Blender source (`docs/ffmpeg-input.md`) has another
sha256, and every run records its input's sha256 and `input_is_reference` (the campaign's own FFmpeg runs predate
the field and carry the reference sha256). Stage B (`data/perf/stageB-d3bf9f8c39fe`) is an earlier compiler's,
shipped as data.

### Upstream flag `-tsan-instrument-func-entry-exit=false` (measured, not claimed)

**Not this paper's contribution.** An upstream option (`ClInstrumentFuncEntryExit` in LLVM's `ThreadSanitizer.cpp`,
default on): off, no `__tsan_func_entry` or `__tsan_func_exit` calls and so no shadow call stack, every memory access
still instrumented. No badge rests on these rows, the comparator reports them as "measured, not claimed", the
submitted paper does not use the flag, and `scripts/40-perf.sh` runs them only when asked (`--configs` with
`tsan-nofe`, `tsan-sound-nofe`, `tsan-dom_peeling-ea-lo-st-swmr-nofe` or `tsan-dom_peeling-ea-lo-st-swmr-stmt-nofe`;
the token composes for every application).

**What it costs: report content, not races.** Section 1's suite gate with `tsan-nofe` and
`tsan-dom_peeling-ea-lo-st-swmr-stmt-nofe` (K = 5, second host,
`data/suite/preservation-suite-20260921T135253Z-nofe-amd/`, stock 0 failures) finds the same 20 candidate losses under
each (its `report.txt`): eighteen report the race without the frames below the top one, `suppressions_mutex` loses a
suppression by function name, and `unaligned_race` reports 128 races instead of 224. On memcached and SQLite
(`scripts/31-preservation-apps.sh <app> 10`, second host; per-site counts in
`data/preservation/{sqlite,memcached}/2026-09-21-nofe-amd-f3deebfbab60/verdict-L3.txt`) no site is LOST under either
configuration at any level, and AllOpt with peeling and the flag shows section 1's `conn_new` relocation, which is
therefore the bundle's and not the flag's. The trade: about 11 per cent on Redis for report stacks of one frame.

Rows: N = 5, the campaign's set and shape, 21-22 Sep 2026 (`data/perf/campaign-f3deebfbab60/flag-<application>/`
and `ffmpeg-t16/`; two Redis cells retired and re-run). SQLite's "resolvable" is 4 of 7 subtests in this leg.

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
| SQLite | stock with the flag | 1.022 [0.919, 1.134] | 1.022 | the flag alone; resolvable subtests 1.021 [0.994, 1.040] |
| SQLite | AllOpt with peeling | 1.058 [0.935, 1.120] | 1.062 | ours alone, this leg; resolvable 1.005 [0.980, 1.029] |
| SQLite | AllOpt with peeling and the flag | 1.020 [0.918, 1.083] | 1.023 | resolvable 1.023 [0.991, 1.049]; nothing resolved |
| MySQL (36 threads) | stock with the flag | 1.094 [1.068, 1.154] | 1.102 | the flag alone, and the largest effect it has on any application here |
| MySQL (36 threads) | AllOpt with peeling and the flag | 1.090 [1.057, 1.157] | 1.101 | ours on top of it: the same, within the intervals |

No combination gains more than the product of its two parts (Redis 1.116, FFmpeg 1.016 x 1.187 = 1.206, both inside
the measured intervals). Stock ThreadSanitizer with the flag against native, then without: Redis 7.60x [7.41, 7.81]
and 8.42x; FFmpeg at 16 threads 2.84x [2.75, 2.87] and 2.88x; memcached 3.68x [3.59, 3.92] and 3.68x [3.54, 3.77];
SQLite 3.27x [2.90, 3.54] and 3.34x [2.97, 3.60]; MySQL 9.04x [8.44, 9.37] and 9.90x [9.31, 10.43]. An earlier leg on
the previous compiler (`data/perf/nofe-d3bf9f8c39fe`, 15 Sep 2026, the sound bundle with the flag: Redis 1.233 [1.183,
1.254], MySQL 1.136 [1.081, 1.188], SQLite 1.044 [1.025, 1.060]) is shipped as data; this leg reproduces neither its
SQLite gain nor its Redis figure (the session drift of `docs/confounds.md`).

### Concurrency curves and whole-program summaries, measured after the campaign (not claims)

**Not claims**: no badge rests on these rows, and the comparator judges none of these tables (none has an
"All five runs [95%]" column); the claims are the sections above, at the concurrency fixed before the campaign
(`data/notes/preregistration-2026-09-13.md`). Measured afterwards on the shipped compiler with the campaign's method
(N = 5 after a warm-up, run-major, its set and shape on each host: 4-27,60-83 here, 0-23,32-55 on the second host;
quiet machine, 0.10 gate; two cells retired on the second host, re-run and shipped). Data: `sweep-*` and
`wp-dynstc-*` under `data/perf/campaign-f3deebfbab60/`, and `data/perf/sweep-amd-f3deebfbab60/` (layout:
`docs/campaign-parameters.md`, "Curves measured after the campaign"), regenerated by `scripts/90-tables.sh` and
checked strictly by `scripts/91-verify-provenance.sh`; earlier-compiler curves in `data/perf/contention-d3bf9f8c39fe`.

**No default changed.** The rule, set before the legs ran: a value replaces the campaign's default only if, at five
runs on our host, its interval for the best configuration is no wider and its point higher. memcached at 24 server
threads (1.021 against 1.019, width 0.119 against 0.128) and Redis at 512 clients (1.007 against 1.000, 0.026 against
0.043) meet it by the letter and were not adopted: both gaps are far inside the intervals, 24 threads breaks the
one-thread-per-pinned-processor rule, and on the second host the same Redis change goes the other way.

#### memcached: server threads (`MC_THREADS`), five runs, one warm-up

| Server threads | Host | Stock vs native | AllOpt+peel | AllOpt+peel+DynSTC | DynSTC |
|---|---|---|---|---|---|
| 24 | ours | 4.53 [4.24, 4.76] | 1.021 [0.935, 1.054] | 1.018 [0.953, 1.063] | 1.012 [0.958, 1.053] |
| 48, the campaign's | ours | 3.20 [2.97, 3.40] | 1.019 [0.951, 1.079] | 1.003 [0.961, 1.099] | 0.986 [0.944, 1.063] |
| 96 | ours | 5.18 [4.58, 5.61] | 1.063 [0.864, 1.200] | 0.980 [0.848, 1.117] | 0.974 [0.837, 1.144] |
| 112 | ours | 5.60 [5.39, 6.43] | 0.996 [0.891, 1.180] | 1.006 [0.884, 1.189] | 0.900 [0.842, 1.170] |
| 112, the `r2` leg of 16 Sep | ours | 5.11 [4.49, 5.22] | 1.006 [0.890, 1.161] | 1.089 [0.875, 1.129] | — |
| 24 | second host | 4.72 [4.58, 4.91] | 1.008 [0.940, 1.055] | 0.979 [0.949, 1.042] | 1.008 [0.942, 1.081] |
| 48 | second host | 4.04 [3.69, 4.43] | 1.005 [0.960, 1.037] | 0.997 [0.947, 1.038] | 1.019 [0.976, 1.043] |
| 96 | second host | 5.23 [4.95, 5.78] | 0.995 [0.930, 1.076] | 1.027 [0.960, 1.118] | 1.005 [0.925, 1.080] |
| 112 | second host | 5.98 [5.70, 6.40] | 1.023 [0.959, 1.077] | 1.035 [1.014, 1.085] | 1.019 [0.945, 1.071] |

Twenty-five of the twenty-six configuration entries contain 1.0; our host's intervals widen from 0.10-0.14 at 24 and
48 threads to 0.27-0.34 at 96 and 112, the second host's stay at 0.07-0.16. The one separating row (second host, 112
threads, AllOpt with peeling and DynSTC) is not claimed: one in twenty-six is about chance at 95 %, and it reproduces
at no other count on that host nor at 112 on ours.

#### Redis: `redis-benchmark` clients (`REDIS_BENCH_CLIENTS`), pipeline 1024

| Clients | Host | Stock vs native | AllOpt+peel | AllOpt+peel+DynSTC | DynSTC |
|---|---|---|---|---|---|
| 50, the tool's default and the campaign's | ours | 8.01 [7.83, 8.21] | 1.000 [0.983, 1.026] | 0.958 [0.944, 0.985] | 0.944 [0.927, 0.970] |
| 112, the `r2` leg | ours | 7.96 [7.83, 8.12] | 1.006 [0.990, 1.026] | 0.974 [0.949, 0.988] | 0.967 [0.948, 0.988] |
| 256 | ours | 8.34 [8.21, 8.52] | 1.007 [0.988, 1.026] | 0.973 [0.954, 0.997] | 0.975 [0.958, 0.993] |
| 512 | ours | 8.08 [7.66, 8.14] | 1.007 [0.999, 1.025] | 0.983 [0.971, 0.995] | 0.975 [0.966, 0.991] |
| 50 | second host | 8.76 [8.40, 8.99] | 1.014 [0.937, 1.030] | 0.980 [0.942, 1.002] | 0.985 [0.926, 1.006] |
| 112 | second host | 8.45 [7.66, 9.11] | 1.041 [0.936, 1.100] | 1.028 [0.911, 1.072] | 1.035 [0.958, 1.090] |
| 256 | second host | 7.79 [7.23, 8.73] | 1.041 [1.008, 1.149] | 0.999 [0.913, 1.073] | 1.008 [0.970, 1.111] |
| 512 | second host | 6.78 [6.77, 8.49] | 0.991 [0.936, 1.135] | 0.976 [0.866, 1.072] | 0.971 [0.928, 1.116] |

**On our host DynSTC's cost holds at every client count; on the second host it does not.** On ours DynSTC, alone and
with AllOpt with peeling, excludes 1.0 in all eight rows; the smaller magnitude at 256 and 512 is not a client-count
effect (at pipeline depth 1024 stock GET reads 3.74, 3.83 and 3.72 million operations per second at 50, 256 and 512,
within the spread between runs). On the second host DynSTC changes sign twice with no interval excluding 1.0. Redis's
DynSTC cost is a result on the campaign's host, robust there to a tenfold change of client count, and not a portable
one. The second host's AllOpt with peeling at 256 clients (1.041) is corroborated nowhere and not claimed.

#### SQLite: `threadtest3 walthread1` threads (`SQLITE_W1_THREADS`), our host

| walthread1 threads | Stock vs native | AllOpt+peel | AllOpt+peel+DynSTC | DynSTC |
|---|---|---|---|---|
| 8 | 1.834 [1.740, 1.861] | 1.006 [0.992, 1.021] | 0.987 [0.971, 1.019] | 0.986 [0.959, 0.996] |
| 16 | 1.852 [1.747, 1.887] | 1.002 [0.977, 1.014] | 0.984 [0.964, 0.995] | 0.988 [0.962, 0.990] |
| 32 | 1.893 [1.835, 1.914] | 1.004 [0.991, 1.028] | 0.985 [0.970, 0.997] | 0.976 [0.962, 0.994] |
| 48 | 1.930 [1.859, 1.967] | 1.005 [0.994, 1.021] | 0.990 [0.976, 0.999] | 0.980 [0.968, 0.989] |
| 96 | 1.944 [1.904, 1.975] | 1.003 [0.993, 1.016] | 0.984 [0.975, 0.998] | 0.976 [0.965, 0.986] |
| 112 | 1.940 [1.913, 1.966] | 1.009 [1.000, 1.020] | 0.991 [0.983, 1.005] | 0.980 [0.978, 0.994] |

walthread1 alone resolves a two per cent effect: DynSTC's cost excludes 1.0 at all six counts, and with AllOpt with
peeling at four; AllOpt with peeling is a well-resolved null (1.002 to 1.009, no interval wider than 0.04). It is a
different workload from the campaign's seven subtests (stock against native 1.83 to 1.94 against 2.96), and the
campaign's DynSTC row, 0.995 [0.928, 1.082], contains every number here: SQLite's campaign rows are unresolved rather
than null, and the SQLite claim stays on the seven subtests.

#### Whole-program summaries on top of DynSTC (`-wp`), our host, five runs

| Program | AllOpt+peel+WP | AllOpt+peel+DynSTC | AllOpt+peel+DynSTC+WP | static sites, +DynSTC then +WP |
|---|---|---|---|---|
| Redis | 1.025 [1.000, 1.038] | 0.987 [0.970, 1.005] | 0.984 [0.963, 1.006] | 43 248 → 40 682 |
| SQLite | 1.026 [0.916, 1.101] | 0.951 [0.880, 1.020] | 0.969 [0.901, 1.062] | 61 897 → 61 793 |
| memcached | 1.000 [0.935, 1.046] | 0.991 [0.930, 1.036] | 1.004 [0.950, 1.028] | 7 183 → 6 743 |

A measured null, alone and on top of DynSTC: the summaries remove sites (2 566 on Redis, 440 on memcached, 104 on
SQLite) but not time, since, as the results ledger found for dominance elimination, the runtime's fast path already
answers those accesses in about fifteen cycles. The counters' earlier finding of 5.73 % more executed accesses on
SQLite remains an open discrepancy (`data/tools/perf/RESULTS.md`) that this time-only leg does not address.

### What an evaluator actually has to run

All five applications at fourteen configurations and N = 5 took our campaign 32 hours of measurement after about 7
hours of builds. The claims are per row, so a subset reproduces a subset, and the cost is linear in configurations
and runs. From the per-cell costs (Redis 86 s, memcached 169 s, FFmpeg 110 s, SQLite 291 s, MySQL 1012 s), with one
warm-up plus N runs per configuration:

| Mode | Runs | Configurations | Time on 48 processors | What a row yields |
|---|---|---|---|---|
| **default** | N = 2 | four: native, stock, AllOpt with peeling, DynSTC (FFmpeg: five, the fifth being the single configuration AllOpt with peeling and DynSTC, at 16 threads) | measured on this host and on a 64-processor AMD host: Redis 13-15 min, memcached 28-36, FFmpeg 21 (five configurations at 16 threads), SQLite 65-68: **about 2 h 30 min** together; MySQL a further 3.4 h (estimated) | a point estimate, no interval |
| everything at the default | N = 2 | all fourteen (MySQL four) | Redis 1.0 h, memcached 2.0, FFmpeg 1.2, SQLite 3.4, MySQL 3.4: **about 11 h**, 14 h with the builds | a point estimate, no interval |
| our campaign | N = 5 | any of the above | twice the figures above (one warm-up plus five runs against one plus two); everything, 32 h of legs plus builds | a 95% interval |

The times assume a quiet machine: a retired cell is run once more before it is dropped, so foreign load can double
a leg and leave no data. The four default configurations decide everything the paper's figure turns on; Redis,
memcached and FFmpeg, about an hour and a quarter together, cover what the campaign found.

```
./docker/run.sh scripts/40-perf.sh redis                 # default: four configurations, N = 2
ART_RUNS=5 ./docker/run.sh scripts/40-perf.sh redis      # our setting: intervals
./docker/run.sh scripts/40-perf.sh redis --all-configs   # all fourteen
```

Our own evaluator-style runs on both hosts: `docs/evaluator-runs.md`. Below five runs a row is a point labelled
"N = k, no interval; compare with the shipped interval", never a bootstrap over too few samples
(`docs/confounds.md`, "Lower N is not a smaller interval"). `ART_SMOKE=1` only checks that the pipeline runs, and
prints "not a measurement"; it does not shorten SQLite (`docs/campaign-parameters.md`, "Smoke mode").

**The comparison condition.** A run is compared with these intervals when it is pinned to 24 physical cores with both
SMT threads of each (48 logical processors; `evaluate.sh` chooses such a set itself where the machine has one,
4-27,60-83 here and 0-23,32-55 on the second host), the machine is otherwise quiet, and the thread counts follow the
campaign's rule: the memcached server one thread per logical processor, sysbench three quarters of that, FFmpeg an
absolute 16 (48, 36 and 16 on the 48-processor set; each cell's `meta.json` records its value). On another shape or
processor count a row is reported with its thread count rather than compared (`docs/campaign-parameters.md`). The
two runs of 22 Sep 2026 under exactly this condition, ours and the second host's (N = 2 each, no cell retired):

| Row | This host | The second host | Shipped interval (N = 5) |
|---|---|---|---|
| FFmpeg, AllOpt with peeling | 1.068 | 1.024 | 1.067 [1.050, 1.079] |
| FFmpeg, DynSTC | 1.130 | 1.115 | 1.133 [1.114, 1.146] |
| FFmpeg, AllOpt with peeling and DynSTC | 1.186 | 1.155 | 1.187 [1.171, 1.201] |
| memcached, AllOpt with peeling | 1.038 | 0.987 | 1.019 [0.951, 1.079] |
| memcached, DynSTC | 0.974 | 1.017 | 0.986 [0.944, 1.063] |
| Redis, AllOpt with peeling | 1.005 | 1.121 | 1.000 [0.983, 1.026] |
| Redis, DynSTC | 0.979 | 1.066 | 0.944 [0.927, 0.970] |
| SQLite, AllOpt with peeling | 1.032 | 1.113 | 1.023 [0.942, 1.061] |
| SQLite, DynSTC | 0.930 | 1.122 | 0.995 [0.928, 1.082] |

**Match criterion for every configuration row.** At the default N = 2: the evaluator's point estimate falls inside
our 95% interval, and for the rows whose interval excludes 1.0 (Redis under DynSTC, alone and with AllOpt with
peeling; FFmpeg's three rows at 16 threads; FFmpeg's DynSTC row and its AllOpt-with-peeling-and-DynSTC row at 4
threads) on the same side of 1.0. At N = 5: the evaluator's interval overlaps ours, a row whose interval contains 1.0
here contains 1.0 there, and a row that excludes it excludes it on comparable hardware. The criterion applies to the
configuration rows, each a ratio against stock ThreadSanitizer on the same machine in the same session, and not to the
stock-against-native ratio at the top of each application, which the session drift governs: a value a few per cent
outside that interval is the drift, not a mismatch. What makes each application's rows vary: `docs/confounds.md`.

**What to conclude from a row outside its interval.** The comparator prints the distance. At N = 2 it is first a
two-run point against a five-run interval: re-run that application with
`ART_RUNS=5 ./docker/run.sh scripts/40-perf.sh <app>` (about twice the default's time; `docs/evaluator-runs.md` has an
example). If it is still outside, a directional row (DynSTC's cost on Redis, its gain on FFmpeg, the FFmpeg rows at 16
threads) is reproduced when the evaluator's interval lies on the same side of 1.0 and not otherwise; a row claimed as
no measurable change is reproduced by any interval containing 1.0, whatever its width, and one excluding 1.0 is an
effect we did not see, to be reported as such. A machine of the same shape with another processor is judged all the
same: on the second host FFmpeg's DynSTC gain appears, while Redis's DynSTC cost does not reproduce (1.066 at N = 2;
0.971 to 1.035 at N = 5 across four client counts, no interval excluding 1.0).

## 6. Bounded shadow state

The shipped data here come from compilers `f80e80b1dbe6` (the two-race experiment) and `e90a3fc41004` and
`89e5d0078d2f` (the occupied-granule experiment), as `data/README.md` records; the script re-runs the
occupied-granule experiment on the shipped compiler.

| Claim | Script | Match criterion |
|---|---|---|
| ThreadSanitizer itself fails to report a planted race in about a quarter of runs on a fully occupied granule; the optimized builds sit in the same range where the burst remains instrumented | `scripts/50-eviction-stress.sh` | within the confidence intervals: stock about 75%, optimized 74 to 76% |
| Dominance elimination trades losses against gains rather than only losing. The program plants two races on one granule, A-B and C-B, and a third thread's burst evicts A's record in 236 of 1000 runs (the same 236 under every build, since the burst is the same). **In those 236 runs DE reports A-B in 0 and stock in 54**: stock's second, dominated store of A re-inserts the record, and DE has removed that store. In the other 764 runs both report A-B in exactly 174, so DE's loss on A-B is confined to the evicted runs. Conversely, that re-inserting store evicts C's record in 71 runs, all among the 236; stock reports C-B in none of those 71 (165 of 236), while DE, which never executes it, reports C-B in 236 of 236. Overall 0.93 reports per run against stock's 0.91 | recorded in `data/eviction-stress/de2-2026-09-03-f80e80b1dbe6/report.md`, not re-run: `scripts/50-eviction-stress.sh` runs experiment (a) only | the conditional counts, within their intervals: A-B given the eviction near 0 under DE and near a fifth under stock; C-B given the eviction all of them under DE and about two thirds under stock; outside the eviction the two builds equal |

## 7. Not claimed here

Six things the submitted paper reports that this artifact does not support:
- **The static-reduction figures of the submitted version** (up to 65 %; 60.8, 34.7, 64.9, 55.6 and 14.5 % per
  application), measured with the submitted compiler. On the shipped compiler AllOpt without peeling removes 2 to 8
  per cent and AllOpt with peeling adds 5 to 14 per cent (section 3); the camera-ready reports those.
- **Executed instrumentation per unit of work** (the paper's dynamic-reduction figures, 23 to 58 per cent). Not
  re-measured on the shipped compiler; the counter runs under `data/perf/*-counters` are from an earlier compiler
  and carry no stock baseline, so no comparison can be derived from them.
- **Memory overhead** (the paper's shadow-memory reduction figures). Not measured; no data is shipped for it.
- **The ReX comparison and the access-trace oracle** (the paper's appendix). The filter is research code behind a
  build flag that is off by default and the oracle a tool on an internal branch; neither is in this repository, and
  neither number can be reproduced from it.
- **Chromium.** No performance number. Our only Chromium build is on an earlier compiler and corresponds to no
  measurement in the paper; `docs/chromium.md` records the revision (`bdef6783a05f0b3f885591e7d2c7b2aec1a89dea`),
  the configuration and the timeout patch.
- **Loop peeling in isolation.** The peeling pair (AllOpt with against without peeling) crosses 1.0 on all four
  applications where it was measured, at resolution floors of 2.5 to 5.7 per cent (section 5). The artifact claims
  the static cost peeling carries (section 3) and no runtime verdict either way.

Expensive rather than unclaimed: **MySQL performance is claimed** in section 5, from campaign runs that ship with the
rest. Re-running it takes the time its script line gives and about 100 GB of disk; `scripts/90-tables.sh` regenerates
its table from the shipped runs without running anything. Four configurations rather than fourteen, because the
configuration set was fixed when a build with the escape analysis took about 2.2 hours on the previous compiler
(`docs/mysql.md`).
