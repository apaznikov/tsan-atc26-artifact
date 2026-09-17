# Claims and how to check them

Every claim the paper makes, the script that produces it, and what counts as a match. This file is
the contract between the paper and this artifact: if a number is not here, the artifact does not
claim it.

Measurement provenance for every performance row: compiler `f3deebfbab60` (the commit the image reproduces and
every run's `TSAN_AUDIT_HASH` names; it sits on branch `artifact/atc26`, whose tip has since moved past
it by two documentation-only commits restoring and completing the audit ledger, so the stamp and not
the branch identifies the measured compiler), five applications, one discarded warm-up then N = 5 runs per configuration (our campaign; the artifact's default for a reviewer is N = 2, see "What an evaluator actually has to run"), pinned to 48 processors (CPUs 4-27 and 60-83 on our machine), one
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
| On the applications, no race site that stock ThreadSanitizer reports in every run is absent from an optimized configuration in every run | `scripts/31-preservation-apps.sh <app>` | comparative, on your own runs, never against a fixed set: detection is schedule-dependent, so the script prints the per-site frequency (k of N) under stock and under each configuration and classifies each site by the configuration's count first: KEPT if the configuration reports it in at least one run, whatever stock's frequency; LOST if the configuration never reports it and stock reports it in every run; UNDETERMINED at this N if the configuration never reports it and stock reports it only in some runs, so an unlucky schedule cannot be told from a loss without more runs; and ONLY-OPTIMIZED if the configuration reports a site stock never does, which is labelled rather than dropped because the shadow-eviction effect can produce exactly that. It exits non-zero only on LOST. Measured on the shipped compiler `f3deebfbab60` on 17 Sep, N = 10, configurations stock, the sound bundle and AllOpt with peeling, gating at L3 (`data/preservation/*/2026-09-17-shipped-f3deebfbab60/verdict-L3.txt`, all three levels printed). **SQLite: no site lost at any level**; at L3 three sites (`walRestartHdr` 68034 and 68035, `walIndexRecover` 67450), KEPT under every configuration, the weakest at 2 / 2 / 3 of 10. **memcached: no site lost at L3**; four sites at 10 of 10 under all three configurations (`clock_handler` on `current_time`, `do_item_link` and `do_item_unlink` on `stats_state` and `memory_allocated`), seven sites stock itself saw once in ten and no configuration saw, UNDETERMINED, and one site reported only by the optimized builds (`lru_maintainer_juggle` reading `current_time`, 0 / 2 / 2 of 10). **One relocation, reported rather than suppressed**: at L1 and L2 the pairing of the reader `conn_new@memcached.c:761` with the writer `clock_handler` on `current_time` is 10 of 10 under stock and under the sound bundle and 0 of 10 under AllOpt with peeling, while the same race on the same location is reported 10 of 10 under AllOpt with peeling by `do_item_link`, `lru_maintainer_thread` and `try_read_command_ascii`. The read at line 761 is instrumented under AllOpt with peeling exactly as under stock, checked three ways, twice on the campaign binaries and once at the IR level from source with the campaign's own flags (the call multiset in `conn_new` identical, the `__tsan_read4` of `current_time` at line 761 present, and that line the only reference to `current_time` in the function): `conn_new` carries 20 reads, 35 writes, 60 `__tsan_*` calls and 403 instructions in all three builds, with two calls attributed to line 761 in each, and `clock_handler` 15 calls in each. Nothing was elided; which reader's record survives the four shadow slots on that granule is eviction arithmetic, and AllOpt with peeling carries 382 more instrumented sites than stock (peeling duplicates first iterations), which is enough to change it; and no single transform does it alone: under the sound bundle, under DE alone and under DE with peeling the pairing stays at 10 of 10, and only the full combination relocates it. The paper's stated criterion is the location and writer (L3), and the relocation is visible to any evaluator at N = 10, so it is stated here. The earlier trees under `data/preservation/` are from earlier compilers of the same lineage and are shipped as data |

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
| Static instrumentation sites per application and configuration | `scripts/20-static-counts.sh` | exact for the differences between configurations (what each analysis removes or adds), which are a property of the compiler; the absolute count of a binary may carry a small constant offset from the build environment: Redis built inside the container has 37 922 sites under stock and 43 272 under AllOpt with peeling against 37 941 and 43 291 for the campaign's host-built binaries, 19 fewer in each, the removed and added counts identical. Named, not guessed: Redis's Makefile auto-detects libsystemd and links it when present; the host had it, the image does not, so the container build compiles out `redisCommunicateSystemd` and the branches in its four callers. It is deterministic and every evaluator's image will show the same 19. Compare your differences with ours exactly and your absolute counts to within such an offset |
| The compiler built from the shipped patch series behaves like the frozen compiler the performance numbers were measured on | `scripts/12-compiler-equivalence.sh` | exact: it recompiles 28 vendored LLVM IR modules under 4 configurations and requires all 112 `__tsan_*` symbol histograms to equal a reference table produced by the campaign compiler, checking the `TSAN_AUDIT_HASH` stamp separately. It says "behaves like", not "is": an identical corpus does not identify the commit, since the three compile-time commits change none of the 112 rows. A control asserts the reference table separates the configurations at all (24 of 28 modules do), so agreement is not free |
| The three compile-time commits added to that compiler changed no instrumentation decision on any application | recorded in `data/equivalence/` and `docs/campaign-parameters.md`; not re-run by the evaluator | the same 112 corpus rows against the previous compiler, plus the 17 application configurations built on both compilers (MySQL 640 355 sites and 1 263 905 calls; all 14 Redis rows) and Redis's whole-program analysis summaries byte-identical between them |
| Executed instrumentation per unit of work | `scripts/90-tables.sh --reach` | exact from the shipped data; within run-to-run noise when re-measured |

## 3b. Every shipped run is attributable (deterministic)

| Claim | Script | Match criterion |
|---|---|---|
| Every run of the campaign (`data/perf/campaign-*`, the roots every performance claim rests on) records the compiler that built it, the hash of the binary it ran, the hash of its input, its processor set and mode, the foreign-activity share the gate saw, and its place in a full set of N. The earlier trees shipped beside them were recorded before the harness wrote every one of those fields and on earlier compilers; they support no claim and the script reports them for information only | `scripts/91-verify-provenance.sh` | exact: six assertions, each of which fails on a fault we have actually produced (a pre-audit binary measured as current; a configuration whose binary changed mid-leg; an input path that satisfied the runner and recorded an empty hash; pinned and unpinned runs pooled; a run above the gate that was kept; a thin row that looked complete) |

This is the property the paper's setup section rests on. It does not check that a configuration's
flags were the intended ones, which is the build guard's job at build time, and it says nothing
about whether a number is right: a tree can pass this and still be wrong, but it cannot pass this
and be unattributable.

## 4. Compile-time overhead

| Claim | Script | Match criterion |
|---|---|---|
| Compile-time overhead of the analyses over an uninstrumented build | `scripts/21-compile-time.sh` | same order of magnitude; a few per cent tolerance, since it depends on the machine and the parallelism. The script rebuilds from scratch for every repetition and forces native and stock in as controls; on memcached, whose whole build takes about ten seconds, its own control reports that the resolution is worse than the effect (ratios 1.00 to 1.05 with 0.0% variation between control repetitions), and it says so rather than printing a ratio to be believed |

## 5. Performance (machine-dependent)

All five applications, from the campaign of 15-17 September on compiler `f3deebfbab60`: 330 cells,
none retired by the disturbance gate, provenance verified on every root. **Of the 48 rows at the
primary concurrency, four separate from stock, and all four are DynSTC: a 5.6% cost on Redis and an
11.3% gain on FFmpeg, alone and inside AllOpt.** Every other configuration of every application
crosses 1.0. Every configuration of the paper's figure is
listed with the paper's bar beside it, plus the three configurations the paper does not show.
Each row carries its interval over all five measured runs and, beside it, the point estimate over
runs 2-5 with no interval (four runs never get one). The two share four runs, so overlap of two
intervals was never a test; the check is that the runs-2-5 point lies inside the all-five interval,
which says that the first measured run did not drive the result. A row is claimed to differ from
stock only when the all-five interval excludes 1.0 and that check holds; "no measurable change"
means the interval contains 1.0, not that the effect is zero. "Stable subtests" repeats the speedup over the subtests whose pooled
run-to-run variation is at most 5%; the set is a property of the workload and applies to every row.

### Redis 7.0.15 (`redis-benchmark`, 19 commands, 50 clients, pipeline 1024; session of 15 Sep 18:49, pinned, governor powersave)

Stock ThreadSanitizer against native: 8.01x [7.83, 8.21] (the paper: 9.2x). Stable subtests: 16 of 19
(`PING_MBULK`, `ZPOPMIN`, `MSET` excluded).

| Configuration | Paper | All five runs [95%] | Runs 2-5, point | Stable subtests, all five [95%] | Verdict |
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
points of 1.0). Stock against native at 112 clients: 7.96x [7.83, 8.12]. The peeling pair on
Redis, AllOpt with against without peeling on the stable subtests: 1.0105 [0.9905, 1.0326].

Script: `scripts/40-perf.sh redis` (about 2 hours at N = 5 on 48 CPUs; `--smoke` in minutes, not a
measurement).

### memcached 1.6.29 (`memtier_benchmark` 2.1.1, 10 threads x 5 clients, pipeline 16, 100 000 requests each, server at 48 threads; session of 15 Sep, pinned)

Stock ThreadSanitizer against native: 3.20x [2.97, 3.40] (the paper: 2.83x). **No configuration is
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
to 27 points, wider still than at 48 threads. Stock against native at 112 threads: 5.11x [4.49, 5.22].

Script: `scripts/40-perf.sh memcached` (about 34 minutes at the default N = 2 and four configurations;
4 hours at N = 5 and fourteen).

### SQLite 3.50.2 (`threadtest3`, all seven subtests at their default thread counts; session of 16 Sep 00:30, pinned)

Stock ThreadSanitizer against native: 2.96x [2.79, 3.28] (the paper: 3.18x). This is the campaign's
widest slowdown column, because SQLite's uninstrumented build varies by 37.9% run to run; that is the
workload, not the measurement. Resolvable subtests: 5 of 7 (`stress1` and `stress2` excluded).

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

What the resolvable-subtest column does say, once `stress1` and `stress2` are set aside: on SQLite
every configuration sits within about 2% of stock, with intervals two to four times narrower than
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

AllOpt with peeling at 1.042 is the nearest any row in this campaign comes to separating from stock
in its favour, and it does not. Both runs-2-5 points lie inside their all-five intervals.

Second concurrency row, 84 threads (the paper's `nproc*3/4` value; N = 5): AllOpt with peeling 1.011
[0.978, 1.049], with DynSTC 0.992 [0.966, 1.023]; both cross 1.0. Stock against native at 84 threads:
8.77x [8.56, 9.37].

Script: `scripts/40-perf.sh mysql` (four configurations only; about 3.4 hours at the default N = 2,
6.7 at N = 5, on 48 CPUs; builds about half an hour each with the shipped compiler).

### FFmpeg 4.3.9 (libx264, libx265, mjpeg, stream copy at `-threads 4`; the Tears of Steel clip; session of 17 Sep, pinned)

Stock ThreadSanitizer against native: 2.76x [2.70, 2.80] (the paper: 2.9x, on a different clip).
Every FFmpeg run carries all four codecs, checked per run; the resolvable set is all four, so the
headline column is the stable column. Twelve configurations rather than fourteen: FFmpeg has no
whole-program summary generator.

**The paper's FFmpeg column is not comparable with this one in either direction**: it was measured on
a clip that cannot be redistributed, and a difference between the two could be the input as much as
the compiler. Within this table every configuration shares one input, so the rows compare with each
other exactly. A control leg on the retired clip, five configurations on this compiler, separates the
two contributions for the paper's text; its numbers are not shipped (`docs/ffmpeg-input.md`).

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

Script: `scripts/40-perf.sh ffmpeg` (about 24 minutes at the default N = 2 and four configurations;
2.4 hours at N = 5 and twelve). The input is produced before the build by one of three paths, in this
order: a prepared copy of the reference clip from `ART_FFMPEG_CLIP_URL`, checked against the sha256 in
`docs/ffmpeg-input.md`; a local copy of the Blender source in `ART_FFMPEG_SOURCE`, cut with the recorded
command; or, with neither set, the 557 MB Blender source downloaded, verified and cut. The second and
third paths re-encode, and a re-encode's sha256 differs from the reference by construction, so every
run records `input_is_reference` beside the input's sha256. The point-in-interval comparison for this
row is made only on the reference clip; on a regenerated clip the run is valid, its build and run times
are what an evaluator pays, but its ratios are not compared with the intervals above and the script says
so. The reference clip becomes downloadable with the artifact's Zenodo record at submission, and
`env.sh` will then default `ART_FFMPEG_CLIP_URL` to it; until then the default path regenerates. Our
own rehearsal of 17 Sep ran on a regenerated clip and reports the FFmpeg row as not comparable for that
reason. FFmpeg additionally carries a control leg on the
retired clip, so that the difference from the paper's FFmpeg column can be attributed to the
compiler or to the input; see `docs/ffmpeg-input.md`. Until then the artifact claims no performance
number for them; the recorded Stage B runs under `data/perf/stageB-d3bf9f8c39fe` are from an
earlier compiler and are shipped as data, not as claims.

### What an evaluator actually has to run

Reproducing all five applications at fourteen configurations with five runs each is 43 hours; that is
our campaign and not what anyone should be asked for. The claims are per row, so a subset reproduces
a subset, and the cost is linear in configurations and in runs. Measured from the campaign's per-cell
costs (Redis 86 s, memcached 169 s, FFmpeg 119 s, SQLite 291 s, MySQL 1012 s), with one warm-up plus
N runs per configuration:

| Mode | Runs | Configurations | Time on 48 processors | What a row yields |
|---|---|---|---|---|
| **default** | N = 2 | four: native, stock, AllOpt with peeling, DynSTC | Redis 17 min, memcached 34, FFmpeg 24, SQLite 58: **about 2 h** together; MySQL a further 3.4 h | a point estimate, no interval |
| everything at the default | N = 2 | all fourteen (MySQL four) | Redis 1.0 h, memcached 2.0, FFmpeg 1.2, SQLite 3.4, MySQL 3.4: **about 11 h**, 14 h with the builds | a point estimate, no interval |
| our campaign | N = 5 | any of the above | 2.5 times the figures above; everything, 43 h | a 95% interval |

```
./docker/run.sh scripts/40-perf.sh redis                 # default: four configurations, N = 2
ART_RUNS=5 ./docker/run.sh scripts/40-perf.sh redis      # our setting: intervals
./docker/run.sh scripts/40-perf.sh redis --all-configs   # all fourteen
```

The four configurations decide everything the paper's figure turns on, and Redis, memcached and
FFmpeg together, about an hour and a quarter, cover the two things this campaign found: DynSTC's
cost on Redis, and the absence of a measurable effect elsewhere. MySQL is the expensive one and its
table ships, so `scripts/90-tables.sh` gives it without running anything.

Two runs give no confidence interval, and the artifact does not print one: below five runs a row is
rendered as a point estimate labelled "N = k, no interval; compare with the shipped interval", never
as a bootstrap over too few samples (at N = 3 such an interval is narrower than at N = 5 while the
point moves by about four points with the choice of runs, which is precision that is not there).
`--smoke` is for checking that the pipeline runs and prints "not a measurement" on its own output.

**Match criterion for every row.** At the default N = 2: the evaluator's point estimate falls inside
our 95% interval, and for the rows whose interval excludes 1.0 (Redis under DynSTC, alone and with
AllOpt) it falls on the same side of 1.0. At N = 5: the evaluator's interval overlaps ours, a row whose
interval contains 1.0 here contains 1.0 there, and a row that excludes it excludes it on comparable
hardware. `docs/confounds.md` lists what makes this vary: memcached's wall time is
bimodal with a 10 to 12 per cent coefficient of variation, SQLite's seven subtests are
heterogeneous and three of them carry 16 to 20 per cent run-to-run variation, and absolute
overheads are not comparable across compiler trees even when ratios are.

## 6. Bounded shadow state

| Claim | Script | Match criterion |
|---|---|---|
| ThreadSanitizer itself fails to report a planted race in about a quarter of runs on a fully occupied granule; the optimized builds sit in the same range where the burst remains instrumented | `scripts/50-eviction-stress.sh` | within the confidence intervals: stock about 75%, optimized 74 to 76% |
| Dominance elimination trades losses against gains rather than only losing. The program plants two races on one granule, A-B and C-B, and a third thread's burst evicts A's record in 236 of 1000 runs (the same 236 under every build, since the burst is the same). **In those 236 runs DE reports A-B in 0 and stock in 54**: stock's second, dominated store of A re-inserts the record, DE has removed that store. In the other 764 runs both report A-B in exactly 174, so DE's loss on A-B is confined to the evicted runs. Conversely that re-inserting store of stock's evicts C's record in 71 runs, all among the 236, and stock reports C-B in none of those 71 (165 of 236), while DE, which never executes it, reports C-B in 236 of 236. Overall 0.93 reports per run against stock's 0.91 | `scripts/50-eviction-stress.sh` (experiment b in its report) | the conditional counts, within their intervals: A-B given the eviction near 0 under DE and near a fifth under stock; C-B given the eviction all of them under DE and about two thirds under stock; outside the eviction the two builds equal |

## 7. Not claimed here

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
