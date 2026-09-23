# Claims and how to check them

Every claim the paper makes, the script that produces it, and what counts as a match. If a number is not
here, the artifact does not claim it.

The artifact is submitted for the **Available** and **Functional** badges. Its performance harness and the
runs of its performance campaign (`data/perf/`) ship with it and are not submitted for evaluation.

Each row says how it is checked: **checked by `./evaluate.sh functional`** (the correctness set runs its
script), **script outside the tiers** (run it yourself; `README.md`, "Running one experiment at a time", gives
its time), or **recorded, not re-run** (the shipped data carry the claim).

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
  | `tsan-dom_peeling-ea-lo-st-swmr` | the same with peeling, labelled `AllOpt+peel` |
  | `tsan-dom_peeling-ea-lo-st-swmr-stmt` | AllOpt with peeling and DynSTC; the tables print the name itself, for the reason recorded in `data/tools/perf/aggregate.py` |
  | suffix `-wp` | with whole-program summaries; defined for memcached, Redis and SQLite only |
  | suffix `-nofe` | with the upstream flag `-tsan-instrument-func-entry-exit=false`, not this paper's contribution; measured, not claimed (`data/suite/preservation-suite-20260921T135253Z-nofe-amd/`) |

  MySQL was measured with AllOpt with peeling only.
- **L1, L2, L3**: how closely two race reports must agree to count as the same race. L1: the kind, both
  stacks' frames (the first application frame of each access, as function@file:line) and the location. L2:
  the same, with frames and location compared by function only. L3: the kind, the location and its writer's
  frame, readers collapsed, so a race found through another reader of the same location counts as the same
  race.

---

## 1. Race detection is preserved (deterministic)

| Claim | Script | Match criterion |
|---|---|---|
| No configuration loses a race that stock ThreadSanitizer reports, over ThreadSanitizer's own regression suite | `scripts/30-preservation-suite.sh`; checked by `./evaluate.sh functional` (K = 5) | exact: no candidate lost race, that is, no test failing every repeat under a configuration and never under stock. Of the vendored suite's 383 tests `lit` marks 90 unsupported on this platform (47 Darwin, 37 libdispatch, 1 libcxx, 5 behind their own feature gates such as `getline_nohang.cpp`, unsupported from glibc 2.38 on; each named in `data/suite/unsupported/`), so 293 execute in each of 12 configurations, K repeats each. Shipped run (`f3deebfbab60`, K = 5, 60 repeats; `data/suite/preservation-suite-20260921T052239Z`): 292 pass and 1 is expectedly failed, 0 fail and 0 time out in every repeat, always-fail = 0 and ever-fail = 0 in every configuration; on a 64-processor AMD host, 0 and 0 in 60 repeats. An earlier run on the same compiler (`data/suite/preservation-suite-20260917T075005Z`, 0 failures in 60 repeats) predates the fix to the lit configuration's glibc detection: 91 unsupported, 292 executed (`docs/nondeterministic-tests.md`). Each run's README gives the command that re-derives its numbers |
| The harness can detect a loss at all | `scripts/30-preservation-suite.sh --self-test`; checked by `./evaluate.sh functional` | required first: with load and store instrumentation switched off, the harness must report the losses; otherwise a silent suite cannot be told from a blind harness |
| Every race test reports the same race as under stock ThreadSanitizer (report keys at L1 and L2) | recorded, not re-run: a K = 5 replay of the executable tests (293 in that run) under the 12 configurations on compiler `aa8a6dd8a2e8`, keyed by `harness/tools/preservation/tsan_reports.py` (`data/suite/replay-aa8a6dd8a2e8/`); it holds for `f3deebfbab60`, whose three extra commits change none of the 112 corpus rows and none of the 17 application configurations' site counts, and leave Redis's whole-program summaries byte-identical | no L1 or L2 key differs on any test. The other bucket: `pthread_atfork_deadlock2.c` lost a report under STC alone (the only loss; a thread-leak diagnostic, not a data race); `fd_location_closed.cpp` (STC, AllOpt with peeling), `race_on_barrier2.c` (STC, DE) and `fork_atexit.cpp` (9 of the 11 compared configurations) gained one, all three non-deterministic under stock itself (`docs/nondeterministic-tests.md`). The replay's 293 is the compiler source tree's suite, counted independently of the first row's. `scripts/30-preservation-suite.sh` compares pass and fail per test, not report text (`lit -q` captures no reports). Not for the `-nofe` rows: that flag removes the shadow stack the keys are built from (both stacks' frames at L1, their functions at L2, the writer's frame and a heap location's allocation frame at L3); their preservation rests on the suite's pass or fail per test and on the applications' race counts and kinds |
| No test that expects no report produces one | `scripts/30-preservation-suite.sh`; checked by `./evaluate.sh functional` | exact |
| On SQLite and memcached, no race that stock ThreadSanitizer reports in every run goes unreported, at L3, by an optimized configuration in every run | `scripts/31-preservation-apps.sh <app> 10`; script outside the tiers (N = 10 as we ran it; at the default N = 2 it prints the frequencies and no verdict) | comparative, on your own runs, since detection is schedule-dependent: per site, KEPT if the configuration reports it in at least one of N runs, LOST if never while stock reports it in every run, UNDETERMINED if never while stock reports it only in some, ONLY-OPTIMIZED if stock never does, and the script exits non-zero only on LOST at the gating level, L3. Ours (`f3deebfbab60`, N = 10, stock, the sound bundle and AllOpt with peeling; `data/preservation/{sqlite,memcached}/2026-09-17-shipped-f3deebfbab60/verdict-L3.txt`): no site LOST at L3 on either application, and one memcached report moves to another reader of the same location, as `data/preservation/memcached/2026-09-17-shipped-f3deebfbab60/README.md` details |

The 12 configurations: stock, each analysis alone (STC, SWMR, LO, EA, DE), DE with peeling, the
four sound analyses combined, AllOpt with and without peeling, and each of the last two with
DynSTC.

## 2. Soundness of the analyses (deterministic)

| Claim | Script | Match criterion |
|---|---|---|
| 23 code shapes in which an optimized build could fail to report a race are fixed; each has a test that fails on its parent commit and a positive control that still removes the instrumentation | `scripts/11-soundness-shapes.sh`; checked by `./evaluate.sh functional` | exact: all 62 IR tests in `tests/ir/` pass, and with the analysis flags stripped each of the 50 that assert a removal fails; the 11 that assert only that instrumentation stays pass either way, one multi-step test (`ipa-summary-external.ll`) is not re-run, and none is vacuous |

**Assumptions.** The soundness argument holds under five assumptions. The program starts at `main`, which is
never called again, and no static constructor of another unit starts a thread (a constructor of the unit
itself that does is handled). A library function's name binds to that library, libc or libstdc++; EA's and
LO's library tables share this assumption. A plain `pthread_mutex_lock` does not fail. DE's covering access
keeps its record in shadow memory until the covered access arrives, which ThreadSanitizer's four slots per
granule do not guarantee (section 6 measures it). Whole-program summaries (`-wp`) assume that nothing outside
the linked module calls into it except through addresses it takes itself and `main`; the `-wp` configurations
are outside the soundness claim, and none is among the 12 configurations of section 1.

**Open item.** One defect is pending rather than fixed: when a defined callee is absent from the bottom-up
summary map, `getIPAFuncRetEscStatus` answers that its return value does not escape. No test in section 1 or 2 reaches it, and we have not shown
whether the map can lack a defined callee; the fix is to answer "escapes" in that case.

## 3. Instrumentation removed (deterministic)

| Claim | Script | Match criterion |
|---|---|---|
| Static instrumentation sites per application and configuration | `scripts/20-static-counts.sh`; script outside the tiers, after `scripts/40-perf.sh <app> --build-only` has built the configurations it counts | exact for the differences between configurations (what each analysis removes or adds, a property of the compiler); absolute counts to within a constant offset from the build environment. Redis built in the container has 37 922 sites under stock and 43 272 under AllOpt with peeling, against 37 941 and 43 291 host-built: 19 fewer in each, removed and added counts identical, because without libsystemd in the image Redis's Makefile compiles out `redisCommunicateSystemd` and the branches in its four callers (every image shows the same 19). Redis stamps its build time, so its campaign binaries match no sha256 in `static-counts.csv` and are tied to their counts by sources and flags; the other four applications' binaries hash-match their rows |
| Static instrumentation reduction, the submitted paper's headline figure (up to 65 %) | `scripts/20-static-counts.sh` against `data/perf/campaign-f3deebfbab60/static-counts.csv`; script outside the tiers, as above | exact: on the shipped compiler AllOpt without peeling removes 5.0 % (memcached), 2.3 % (Redis), 7.8 % (FFmpeg) and 3.3 % (SQLite) of the static memory-access sites, and AllOpt with peeling carries more sites than stock on every application (+5.7, +14.1, +5.5, +6.8, MySQL +6.3 %), because peeling duplicates loop bodies. The paper's 60.8, 34.7, 64.9, 55.6 and 14.5 % came from the submitted compiler, whose reach relied on an unsound same-location test in the dominance elimination that the soundness fixes closed; the camera-ready reports the new figures |
| The compiler built from the shipped patch series behaves like the frozen compiler the performance numbers were measured on | `scripts/12-compiler-equivalence.sh`; checked by `./evaluate.sh functional` | exact: 28 vendored LLVM IR modules recompiled under 4 configurations; all 112 `__tsan_*` symbol histograms must equal the campaign compiler's reference table, and the `TSAN_AUDIT_HASH` stamp is checked separately. "Behaves like", not "is": the comparison covers the corpus. A control requires the reference table to separate the configurations (24 of 28 modules do) |
| The three compile-time commits added to that compiler changed no instrumentation decision on any application | recorded, not re-run (the corpus and its reference table in `data/equivalence/`) | none of the 112 corpus rows differs between the previous compiler (`aa8a6dd8a2e8`) and the shipped one; the 17 application configurations built on both have identical site counts (MySQL 640 355 sites and 1 263 905 calls; all 14 Redis rows); Redis's whole-program analysis summaries are byte-identical between them |

## 3b. Every shipped run is attributable (deterministic)

| Claim | Script | Match criterion |
|---|---|---|
| Every run of the campaign (`data/perf/campaign-f3deebfbab60/{primary,r2}`: 290 and 110 measured runs beside their warm-ups) records its compiler, the hash of its binary, the hash of its input where it has one (FFmpeg), its processor set and mode, the foreign-activity share the gate saw and the size of the set it watched (56 of the 64 processors outside the pinned set; eight were excluded during the campaign, which the shipped default does not do), and its place in a full set of N | `scripts/91-verify-provenance.sh`; checked by `./evaluate.sh functional` | exact: exit 0 only when every run is attributable; an empty root fails, and a root with no runs directly is expanded to its sub-roots. Six assertions, each tested against its fault: a pre-audit binary measured as current; a configuration whose binary changed mid-leg; an input path that satisfied the runner and recorded an empty hash; pinned and unpinned runs pooled; a run above the gate that was kept; a thin row that looked complete. The earlier trees, on earlier compilers and predating these fields, support no claim and are reported for information only |

This is the property the paper's setup section rests on. It does not check a configuration's flags (the build
guard does) or whether a number is right: a tree can pass this and be wrong, but not pass it and be
unattributable.

## 4. Compile-time overhead

| Claim | Script | Match criterion |
|---|---|---|
| The compile-time overhead of the analyses over an uninstrumented build is measured by a shipped script; no figure is claimed from the shipped data | `scripts/21-compile-time.sh <app>`; script outside the tiers | each repetition rebuilds from scratch (three per configuration by default), with native and stock as controls, and the script prints each configuration's median build time against native; a result matches when the analyses' overhead is of the same order of magnitude as stock ThreadSanitizer's own. The shipped control (`data/perf/compile-time-memcached-f3deebfbab60`: memcached, a build of about 10 s timed to the second, 2 repetitions) cannot resolve the effect: every configuration reads 10 or 11 s, 1.00 to 1.05 of native |

## 6. Bounded shadow state

The shipped data here come from compilers `f80e80b1dbe6` (the two-race experiment) and `e90a3fc41004` and
`89e5d0078d2f` (the occupied-granule experiment), as `data/README.md` records; the script re-runs the
occupied-granule experiment on the shipped compiler.

| Claim | Script | Match criterion |
|---|---|---|
| ThreadSanitizer itself fails to report a planted race in about a quarter of runs on a fully occupied granule; the optimized builds sit in the same range where the burst remains instrumented | `scripts/50-eviction-stress.sh`; script outside the tiers | within the confidence intervals: stock about 75%, optimized 74 to 76% |
| Dominance elimination trades losses against gains rather than only losing. The program plants two races on one granule, A-B and C-B, and a third thread's burst evicts A's record in 236 of 1000 runs (the same 236 under every build, since the burst is the same). **In those 236 runs DE reports A-B in 0 and stock in 54**: stock's second, dominated store of A re-inserts the record, and DE has removed that store. In the other 764 runs both report A-B in exactly 174, so DE's loss on A-B is confined to the evicted runs. Conversely, that re-inserting store evicts C's record in 71 runs, all among the 236; stock reports C-B in none of those 71 (165 of 236), while DE, which never executes it, reports C-B in 236 of 236. Overall 0.93 reports per run against stock's 0.91 | recorded, not re-run, in `data/eviction-stress/de2-2026-09-03-f80e80b1dbe6/report.md`: `scripts/50-eviction-stress.sh` runs experiment (a) only | the conditional counts, within their intervals: A-B given the eviction near 0 under DE and near a fifth under stock; C-B given the eviction all of them under DE and about two thirds under stock; outside the eviction the two builds equal |

## 7. Not claimed here

Six things the submitted paper reports that this artifact does not support:
- **The static-reduction figures of the submitted version** (up to 65 %; 60.8, 34.7, 64.9, 55.6 and 14.5 % per
  application), measured with the submitted compiler. On the shipped compiler AllOpt without peeling removes 2 to 8
  per cent and AllOpt with peeling adds 5 to 14 per cent (section 3); the camera-ready reports those.
- **Executed instrumentation per unit of work** (the paper's dynamic-reduction figures, 23 to 58 per cent). Not
  measured on the shipped compiler, and no data for it ships.
- **Memory overhead** (the paper's shadow-memory reduction figures). Every performance run's `meta.json` records
  the peak resident set (`max_rss_kb`), but no comparison is derived from it and none is claimed.
- **The ReX comparison and the access-trace oracle** (the paper's appendix). The filter's runtime hook is in the
  patch series: `compiler/patches/0001-paper-state-e90a3fc41004.patch` adds it with the `enable_filter` runtime
  flag, and a later patch (0012) compiles it only with `-DCOMPILER_RT_TSAN_REX_FILTER=ON`, which the image does not set. The comparison
  itself and the oracle, a tool on an internal branch, are not in this repository, and neither number can be
  reproduced from it.
- **Chromium.** No performance number. Our only Chromium build is on an earlier compiler and corresponds to no
  measurement in the paper; `docs/chromium.md` records the revision (`bdef6783a05f0b3f885591e7d2c7b2aec1a89dea`),
  the workload and the setup, and describes the build configuration and the Telemetry timeout changes, which are
  not shipped.
- **Loop peeling in isolation.** The peeling pair (AllOpt with against without peeling) crosses 1.0 on all four
  applications where it was measured, at resolution floors of 2.5 to 5.7 per cent (`data/perf/campaign-f3deebfbab60/`). The artifact claims
  the static cost peeling carries (section 3) and no runtime verdict either way.
