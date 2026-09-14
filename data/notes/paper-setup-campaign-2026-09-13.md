# Pre-registered parameter set and costing for the paper-setup campaign

Written 2026-09-13, **before any run of this campaign**, at the tsan-paper lane's request. Applies to the
planned artifact compiler: a branch from the submitted revision `e90a3fc41004` with the soundness fixes
applied. Companion to [preregistration-2026-09-13.md](preregistration-2026-09-13.md), which covers the
concurrency sweep and the combinations leg.

**Read the schedule finding first (§7). It is not the benchmarks that threaten 19 September.**

## 1. What the March drivers actually did, and where the gap is

Read out of the scripts as they stood in March, not from memory:

| application | March parameter | source | at pinned 48 | at the whole machine | gap? |
|---|---|---|---|---|---|
| memcached | server `-t $(nproc)` | `run-memcached.sh:18`, unchanged through March | 48 | 112 | **yes, Stage B used 24** |
| MySQL | `--threads=$(( nproc * 3/4 ))` | `callmysql-export-main-vars.sh:32` | 36 | 84 | **yes, Stage B used 18** |
| FFmpeg | `-threads 4` | all 42 rows of `summary_ffmpeg_benchmark.csv` | 4 | 4 | **no** |
| SQLite | `threadtest3`, no thread argument | `run_sqlite_test.sh` default path | as-is | as-is | **no** |
| Redis | `-P 1024 -n <per-test>`, no `-c` → tool default 50 | `redis.sh:333` | 50 | 50 | **no** |

**Only two applications have a concurrency gap.** FFmpeg's paper column used the same `-threads 4` the current
campaign uses — this corrects an earlier claim of mine and removes FFmpeg from the argument entirely
(`march-provenance-2026-09-13.md` §4). SQLite and Redis derive nothing from `nproc`, so their parameters are
already the paper's.

MySQL is the largest gap: 18 against 84, a factor of 4.7. Stage B's 18 comes from `bench_one.sh` computing
`NCPU/2*3/4` on 48 logical CPUs; it is read here out of the Stage B run log (`--threads=18`), not from the
formula.

## 2. Corrected definitions that stay corrected at any thread count

These are defects, not parameters, and they do not come back:

- memtier `--requests 100000`. March passed none, taking the tool's default of 10 000 per client, which makes
  an iteration about a second and puts native at 57 M ops/s.
- **Equal N per arm.** March gave the TSan arm five times the memtier iterations of the native arm
  (`run-bench.sh`, comment recording the removal). Every arm gets the same N.
- `report_bugs=0` on both arms of every timed run, as now.
- The provenance gate: every binary's `build_info.txt` must stamp the campaign's compiler hash.
- **One discarded warm-up run per configuration, then N = 5 measured runs.** The campaign reports
  **steady-state** performance. This is fixed before any run, for the stated reason — it is conventional for
  server and database benchmarks and it removes the shared-denominator exposure of
  [run1-cold-start-2026-09-13.md](run1-cold-start-2026-09-13.md) — and not by which mode gives larger numbers.
  It could not be chosen that way in any case: the Stage B run-1 shifts run +1.92 pp on memcached and
  −0.79 pp on Redis, so no single mode favours our configurations uniformly. The artifact ships the scripts,
  so a reviewer can run either mode.
  **"Warm" means three different things and the definition says which applies where:** SQLite's warm-up builds
  the `walthread1` database and leaves it in place; FFmpeg's warms the input file into page cache; memcached's
  and Redis's warm the allocator and the connection path, while the benchmark rebuilds its own data set each
  run. MySQL's warm-up additionally leaves the server initialised and the buffer pool populated.

## 3. Parameter rules, written as rules so the sweep's outcome cannot choose them

The queued concurrency sweep reports before this campaign starts. Its result must not be allowed to pick a
parameter after the fact, so the rules are fixed here:

- **R1.** If SQLite's speedup curve rises monotonically from 16 to 48 threads with a 95 % interval excluding
  1.0 at 48, run memcached and MySQL at their **whole-machine** values (112, 84). Otherwise run them at their
  **pinned-48** values (48, 36).
- **R2.** Whichever branch R1 takes, run memcached and MySQL at the *other* value too, for those two
  applications only, as a second row. The gap is the open question; measuring one side of it answers nothing.
- **R3.** FFmpeg, SQLite and Redis run at their March parameters unchanged in every branch, because §1 shows
  those are already the paper's.
- **R4.** If the sweep's curve falls, that is reported as the finding and R1's "otherwise" branch applies; it
  does not trigger a search for a thread count that makes it rise.

## 4. Configuration list — fourteen, fixed

The paper's twelve (`orig`, `tsan`, `tsan-ea`, `tsan-lo`, `tsan-st`, `tsan-swmr`, `tsan-stmt`, `tsan-dom`,
`tsan-dom_peeling`, `tsan-dom-ea-lo-st-swmr`, `tsan-dom_peeling-ea-lo-st-swmr`,
`tsan-dom_peeling-ea-lo-st-swmr-stmt`) plus the two summaries variants (`tsan-sound-wp`,
`tsan-dom_peeling-ea-lo-st-swmr-wp`). N = 5 on five applications.

## 5. Aggregation — one, applied to every row

Identical to Stage B and to the other pre-registration: geometric mean over the application's tests on
per-test medians of N = 5 undisturbed runs; 95 % bootstrap interval (B = 2000, seed 1) resampling runs per
test; plus the resolvable-subtest column whose set is taken **once** from that application's stock-TSan
baseline pooled CV (≤ 5 %, suppressed when fewer than half survive) and applied unchanged to every
configuration. `aggregate.py`, unmodified.

## 6. Cost, split into builds and benchmarks

Benchmarks, from the Stage B per-run times (fixed-time workloads do not change with thread count):

| application | per run | 14 configs x N=5 |
|---|---|---|
| MySQL | 15 min | 17.5 h |
| SQLite | 11.3 min | 13.2 h |
| memcached | ~8 min at the paper's thread count | 9.3 h |
| FFmpeg | 2.0 min | 2.3 h |
| Redis | 1.3 min | 1.6 h |
| | | **~44 h** |

R2 adds memcached and MySQL a second time at the other thread value: **+27 h** if taken on all fourteen
configurations, or +8 h if restricted to `orig`, `tsan`, AllOpt+peel and AllOpt+peel+DynSTC, which is what I
would do.

Builds are where the campaign is decided, and the figure depends entirely on one question about the branch:

| | on `d3bf9f8c39fe` (current) | on the paper state `e90a3fc41004` |
|---|---|---|
| MySQL AllOpt+peel | 7 315 user-s = **2 CPU-hours**, 4:19 wall at -j56 | — |
| MySQL AllOpt+peel+DynSTC | — | 371 445 user-s = **103 CPU-hours**, 42:15:42 wall at -j7 |

**A 51-fold difference in CPU work for the same application.** The compile-time collapse is the one large
improvement this project made (`RESULTS.md`: MySQL escape-analysis builds went from 3.05-3.65x stock to
1.04-1.10x) and **it is not a soundness fix**, so a branch carrying only the soundness fixes inherits the
103-CPU-hour build. Worse, it does not parallelise away: the March build got 245 % CPU on `-j7` because one
translation unit (`sql_yacc.cc`) dominates, so even at `-j56` there is a multi-hour serial floor per
EA-bearing configuration, and MySQL builds take the build lock exclusively so they cannot overlap each other.

| | builds, paper-state branch | builds, with the compile-time fix cherry-picked |
|---|---|---|
| memcached + Redis + SQLite, 14 cfg | ~2 h | ~2 h |
| FFmpeg, 14 cfg (7 min each) | ~1.6 h | ~1.6 h |
| MySQL, 7 non-EA cfg | ~1.5 h | ~1.5 h |
| MySQL, 7 EA-bearing cfg | **~21-25 h** | ~1 h |
| **total** | **~28 h** | **~6 h** |

## 7. Does it fit before 19 September?

Builds and benchmarks cannot overlap: a benchmark needs the CPUs quiet, and these builds are the noisiest jobs
on the machine.

- **Branch exists 16 September, compile-time fix NOT in it:** 28 h builds + 44 h benchmarks = **72 h**, which
  is exactly the wall-clock from the 16th to the 19th with no slack for a failed leg, no top-up for retired
  runs, and nothing else running on the machine. **It does not fit.**
- **Branch exists 16 September, compile-time fix cherry-picked:** 6 h + 44 h = **50 h**, about two days.
  Tight but feasible, with R2's restricted form adding 8 h to make 58 h. This is the only version I would
  commit to.
- **Without MySQL:** 4 h + 26 h = **30 h** in either case. Comfortable, and it removes the entire schedule
  risk, at the cost of the application with the largest concurrency gap.

**The recommendation is therefore a question for tsan-dev-f, not a scheduling decision:** can the compile-time
fix be identified and cherry-picked onto the branch alongside the soundness fixes? If yes, the campaign fits.
If no, MySQL must either come out or start building on the 14th, before the branch is classified — which means
building a compiler state we have not agreed on.

## 7a. The cherry-pick is dead, and that changes the schedule answer (tsan-dev-f, 2026-09-13 19:40)

Tested rather than reasoned, by tsan-dev-f: on a worktree at the **March+10** tip — the ten soundness fixes
that apply to `e90a3fc41004` with no source edit — **0 of the 4 compile-time commits apply**. Every one
conflicts inside `EscapeAnalysis.cpp`, because the first commit's context carries `ClEAUnknownTop`,
`ClEAUnseenPointeeEscapes` and `ClEAFlowInsensitive`, switches introduced by shapes 4, 5 and 6 — three of the
eleven shapes that need hand-rework and did not make the clean ten. The compile-time work is **anchored on the
EA soundness fixes, not independent of them**, and can only land after they do. Their cost to port:
~16 h plus ~10 h re-verification, and the re-verification does not transfer because the assertion verifiers
(`-tsan-ea-verify-journal`, `-tsan-ea-verify-skips`) arrive inside the compile-time commits themselves.

Their independent measurement of the benefit agrees with §6 from the other direction: on the `MYSQLparse`
extract the series takes the flow-sensitive compile from 1 091.6 s to 14.7 s, and `vk.ll` from over 1 800 s
(capped) to 11.0 s. **The benefit is real and large; it is the separability that fails.**

One trap they flagged that would land on this campaign: the minimal soundness set drops shape 6 and runs
`-tsan-ea-flow-insensitive` instead. If that is the branch, the compile-time work would be applied to a
*different analysis* from the one it was verified against, and verdict-identity would have to be re-established
against the flow-insensitive rule. §7b's static-count check therefore becomes necessary rather than prudent.

### The schedule answer, recomputed

| option | compiler work | builds | benchmarks | total | fits by 19 Sep? |
|---|---|---|---|---|---|
| MySQL in, compile-time work ported | 26-36 h | ~6 h | 44 h | 76-86 h | **no** |
| MySQL in, no port (paper-state builds) | 0 | ~28 h | 44 h | 72 h | **no** — exactly the window, no slack |
| MySQL out | 0 | ~4 h | 26 h | 30 h | yes, comfortably |

### The fourth option, and why building on March+10 is NOT it (tsan-dev-f, 2026-09-13 19:55)

I proposed building MySQL early against the **March+10** tree so its 21-25 h would leave the critical path.
tsan-dev-f tested that base and the answer is no. Two things the paper lane has **already accepted into the
branch** are missing from March+10:

- **the capture fix `dbde56f2e3f7`**, measured today at **+1 979 stock instrumented sites on sqlite3 (+3.62 %)**
  and +3.35 % on memcached. A binary built without it is built against a different detector.
- **three review commits** — `d80253bbf55a` (+874/−416), `7dc26fa73c71` (+274/−43), `8f6899f5c5ff` (+619/−69),
  together **+1 761/−522 across 17 source files**, all applying clean. "Soundness defects in dominance" and
  "the sound flow-sensitive elision" move instrumentation; they are not cosmetic.

So MySQL built on March+10 would be wasted machine time. **A better base exists today**: March+13 (the clean
ten plus the three review commits) applies with no source edit and is already at
`/extra/alexey/worktrees/march-ct`; adding the capture fix conflicts in exactly one five-line hunk in
`ThreadSanitizer.cpp` (the `findAllocaForValue`-versus-`Addr` predicate), about fifteen minutes to March+14.
March+14 carries everything the branch has committed to except the eleven reworks — but shapes 4, 5, 6, 21 and
22 are all EA, and MySQL's expensive configurations are the EA-bearing ones, so its **codegen** will still move.

### What survives is the split, and it is the important part

**A timing measurement is far less base-sensitive than a codegen measurement.** What makes `sql_yacc.cc` take
42 hours is the old n⁴ closure and the pointee-view blow-up; neither the review commits nor the EA reworks
touch that machinery — the compile-time series does, and it is not going in. So a MySQL build **timed** on
March+13/14 gives the campaign's real serial floor to well inside my factor of two, even though its
instrumentation output will not be the branch's.

**Plan: build ONE EA-bearing MySQL configuration on March+14, timed under a wall-clock cap. Hold the other six
until the branch is real.**

### The cap and the decision rule — REVISED 2026-09-13 21:00 for the reduced MySQL set

**Why this is revised, since revising a pre-registered rule needs a reason that is not a result.** The rule
below changed because an *input* changed — Alexey ruled MySQL stays in, at **four** configurations instead of
fourteen — and not because any number was seen. The timing build has not run. Of the four (native, stock TSan,
AllOpt+peel, AllOpt+peel+DynSTC) exactly **two** carry escape analysis, not three: `orig` has no instrumentation
and `tsan` is stock with no analyses. So the campaign pays 2 × F rather than 7 × F, where F is the serial floor
this build measures, and the threshold moves out accordingly.

**Costed total, with the warm-up run and R2's second pass both included:**

| | hours |
|---|---|
| benchmarks, primary pass at R1's pinned-48 values (14 cfg × 4 apps + 4 cfg MySQL, 6 runs per cell) | 37.6 |
| benchmarks, R2 second pass at whole-machine values (memcached and MySQL, 4 cfg each) | 9.2 |
| builds, everything except MySQL's EA configurations | 3.7 |
| **fixed total** | **50.6** |
| MySQL's EA-bearing builds | **+ 2 F** |

Against a 72-hour window (branch on the 16th, camera-ready on the 19th) the **break-even is F = 10.7 h**.

- **Cap: 6 hours wall**, as before. At the cap the build is stopped and what it reached is recorded — objects
  completed, which translation unit is in flight, `outside_busy_share` over the window.
- **completes in ≤ 6 h** → total ≤ 62.6 h → **fits**, MySQL stays at four configurations. No further decision.
- **still running at 6 h** → the answer is no longer automatic, because the break-even is now 10.7 h rather
  than 3. The build continues to a **second cap of 11 hours**, and only while the machine is otherwise free.
  Completing by 11 h puts the total at 72.6 h, which is marginal and goes to Alexey with the number.
- **still running at 11 h**, or the campaign otherwise runs over → **first cut MySQL's N and `--time`, and only
  then its configurations** (Alexey, relayed 2026-09-13). Costed below.
- configurations come out **last**, which is Alexey's stated preference over excluding the application.

### Fallback step 1: MySQL at N = 3 and `--time=120`

**What it buys.** MySQL currently costs 4 configurations × 6 runs × 15 min = 6.0 h per pass, and R2 makes it
two passes: **12.0 h**. At N = 3 (four runs per cell including the warm-up) and `--time=120` (five sysbench
scripts at 120 s instead of 180, about 10.5 min per run) it costs 4 × 4 × 10.5 min = 2.8 h per pass, **5.6 h**
for both. **Saving 6.4 h**, which moves the break-even from F = 10.7 h to about F = 13.9 h.

**What it costs, measured rather than asserted.** Taking Stage B's real MySQL runs and recomputing the speedup
from every one of the ten 3-of-5 subsets:

| configuration | N = 5 speedup | N = 3 subsets, min | max | spread | s.d. |
|---|---|---|---|---|---|
| `tsan-sound` | 1.021 | 0.992 | 1.030 | 3.8 pp | 1.2 pp |
| AllOpt+peel | 1.012 | 1.004 | 1.043 | 3.9 pp | 1.3 pp |
| `tsan-ea` | 1.034 | 1.002 | 1.042 | 4.0 pp | 1.2 pp |
| `tsan-dom` | 1.009 | 0.985 | 1.027 | 4.2 pp | 1.4 pp |

So **which three of the five runs you happen to keep moves the point estimate by about 4 points**, on an
application whose effects are 1-3 points. The cut does not merely widen the interval; it makes the headline
number depend on the subset.

**And the interval will not warn you.** The same subsets give a *median bootstrap half-width of 5.2-6.7 pp
against 6.1-7.1 pp at N = 5* — that is, the interval gets **narrower** at N = 3, by 6-14 %. With three values
the empirical distribution the percentile bootstrap resamples is too coarse to represent the tails, so it
understates the uncertainty exactly where the estimate is least stable. A reader comparing N = 3 and N = 5
rows by their intervals would conclude the N = 3 rows were the better measured ones.

**Recommendation, for the record.** Cut `--time` before cutting N. `--time=180 → 120` at N = 5 saves 4.0 h of
the 6.4 h and costs only within-run averaging, which the interval does represent honestly; dropping to N = 3
saves the remaining 2.4 h and buys a 4-point subset dependence that the interval actively hides. If the whole
6.4 h is needed, take it, but MySQL's rows should then be reported without intervals rather than with
misleadingly tight ones.



The load is recorded beside the time because a serial-floor measurement on a loaded machine still measures
something, but only if the next reader can see the load next to it.

This build's **codegen is not the branch's** — shapes 4, 5, 6, 21 and 22 are all EA and MySQL's expensive
configurations are the EA-bearing ones — so nothing from it may be quoted as an instrumentation or speedup
number. It is a compile-time measurement and nothing else. **The output directory carries that in its name**,
`results/mysql-compiletime-march14-NOT-BRANCH-CODEGEN/`, because a warning in a note is read once and a
directory name is read every time someone goes looking for the number.

Base: **`march-22-soundness`**, tag `8df4ad9d7dc4` in `/extra/alexey/worktrees/march-ct` — 22 commits on
`e90a3fc41004`, +2 663/−632, with 16 of the 23 shapes closed.

**Superseding what this note said earlier.** The timing build was first specified against March+14
(`8f149507cbaf`, 14 commits), and that hash was handed over as a worktree name while the worktree kept moving
underneath it. Both states are now **tags** rather than branch tips, so neither can drift again:

| tag | commit | contents |
|---|---|---|
| `march-14-timing-base` | `8f149507cbaf` | 14 commits — what this note originally recorded |
| `march-22-soundness` | `8df4ad9d7dc4` | 22 commits, 16 of 23 shapes closed |

The build moved to the 22-commit tag for a reason that is about the measurement, not about convenience: it is
the tree closest to the branch, so its **link status** — the thing neither tree has ever been tested for — is
the unknown that matters, and one build then serves both the link test and this timing. For a compile-**time**
measurement it is at least as representative, because the eight added commits (shapes 4, 7, 9, 14, 17, 23 and
one EA prerequisite) touch none of the n⁴ closure or pointee-view machinery that makes `sql_yacc.cc`
expensive, and the compile-time series is out of the branch by ruling either way.

**State of verification.** All five touched analysis files pass `-fsyntax-only` on the 22 tree as they did on
the 14. **Neither tree has ever been linked**, and linking is what failed on the first attempt. Build with
`BUILD_SHARED_LIBS=ON`: a static configuration fails at `e90a3fc41004` with
`ld.lld: error: duplicate symbol: llvm::EmptyFieldPath`, because the header there declares
`FieldPathTy EmptyFieldPath;` as a non-inline non-const namespace-scope variable that three `.cpp` files each
define. Shared libraries hide it, which is why the project's usual configuration never showed it. The Second
review commit `7dc26fa73c71` changes it to `inline const` and is in both tags, so neither has the defect.

## 7b. If the compile-time fix is cherry-picked, one check comes first

Added 2026-09-13 after the paper lane reported tsan-dev-f's verdict that the compile-time fix is not a
soundness change and is verdict-identical. That verdict is theirs and concerns TSan's reports; it does not by
itself establish that the *instrumentation* is unchanged, and this campaign's numbers are ratios of
instrumented binaries.

So before any timed run on a branch carrying the fix: build one configuration that exercises escape analysis
(`tsan-dom_peeling-ea-lo-st-swmr`) on the branch with and without the fix, and compare
`tools/static_count_tsan_instrumentation.py` counts on the two binaries. They must be **equal**. A compile-time
fix can change pass ordering or inlining and move instrumentation counts while leaving every race verdict
intact, and a campaign that quotes speedups across such a pair would be comparing two different binaries.

Cost: two SQLite builds, about six minutes, plus the objdump counts. If the counts differ, the campaign runs
on the branch *with* the fix on both arms or not at all — never one arm each.

**Strengthened at tsan-dev-f's insistence, and they are right:** the pair must be built from **one source
state with only the compile-time switch differing**, never two builds from two states. That is the discipline
the granule-merge freeze used — one branch, counters on and off, both verified to fire — and it is the only
arrangement in which the counts mean anything. *Verified against a different fixpoint is not verified.*

## 8. What would make a row be withdrawn

A binary failing the provenance gate; a leg whose runs are retired above `P5_FOREIGN_MAX` faster than the
top-up replaces them; a configuration whose build did not finish; or an aggregation that had to change to make
a row readable. Withdrawn rows are reported with the reason, never dropped silently.
