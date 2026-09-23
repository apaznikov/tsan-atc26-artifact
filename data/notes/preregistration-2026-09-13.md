# Pre-registration: the concurrency sweep and the combinations leg

Written 2026-09-13 **before either leg produced a number**, so that "we would have named this configuration in
advance" is checkable rather than asserted. The constraint: no configuration chosen after seeing its result,
and one aggregation for every row.

## Aggregation, fixed for every row in both legs

Geometric mean over the application's tests, taken on per-test medians of N = 5 undisturbed runs; 95 %
bootstrap interval (B = 2000, seed 1) resampling runs per test independently. Plus the resolvable-subtest
column, whose set is taken **once** from the Stage B baseline's pooled CV (≤ 5 %, suppressed when fewer than
half the subtests survive) and applied unchanged to every configuration. This is `aggregate.py`'s existing
code path, unmodified — the point of reusing it is that the combinations cannot be scored by a statistic
chosen to suit them.

## Leg 1 — does the speedup grow with the workload's concurrency?

The claim the paper's contention appendix makes. It matters because Stage B measures at roughly half the
concurrency the paper used: `nosql/memcached/run-memcached.sh:18` is `NTHREADS=$(nproc)` and git shows that
line unchanged through March, so the March server ran `-t $(nproc)` against Stage B's fixed `-t 24`; FFmpeg
runs `-threads 4` and sysbench 36. That difference is neither the corrected analyses nor the loaded machine.

| arm | knob | points | configurations | cells | cost |
|---|---|---|---|---|---|
| SQLite | `threadtest3 --w1-threads` | 2, 4, 8, 16, 32, 48, 72, 96, 112 | orig, tsan, DE, AllOpt+peel | 180 | ~2.0 h |
| Redis | `redis-benchmark -c` | 50, 128, 256, 512 | orig, tsan, DynSTC, AllOpt+peel | 80 | ~1.8 h |
| FFmpeg | `FF_THREADS` | 2, 4, 8, 16 | orig, tsan, DynSTC, AllOpt+peel | 80 | ~2.7 h |

**Direction fixed before the run:** if the appendix's claim holds, the speedup of AllOpt+peel over stock TSan
rises monotonically with the knob. A flat curve refutes it on this machine; a falling curve refutes it
strongly.

**Run-1 cross-check, fixed before the sweep's numbers exist (added 2026-09-13 20:20).** The harness has no
warm-up and run 1 is now known to deviate systematically (`docs/confounds.md`, "First execution"). The sweep's curve
is therefore reported on **all five runs** — the pre-registered aggregation, unchanged — and cross-checked on
**runs 2-5**. If the two disagree in the direction of the trend, **neither is reported as a result** and the
sweep is repeated with a discarded warm-up. The harness is not modified while the sweep is in flight, because a
warm-up added mid-sweep would make later thread points incomparable with earlier ones.

**The interpretation limit, stated in advance so it is not argued afterwards.** The sweep runs inside the
48-CPU bench set. Up to 48 threads it measures thread-count scaling at about one thread per CPU, which is the
paper's regime. Past 48 it measures scaling under **oversubscription**, which is not the paper's condition —
the paper had 112 threads on 112 cores, not 96 on 48. A curve already rising at 16 → 32 → 48 settles the
question; a rise appearing only past 48 does not, and does not substitute for a wider leg.

memcached is **excluded and the reason is not cost alone**: its cell is 6.6 minutes, so the same sweep is
11 machine-hours, and its Stage B speedup interval is ±12 points, so the arm could only resolve an effect
larger than that. It would be a separate leg with its own decision, not a silent addition.

## Leg 2 — the combinations, in order of priority

Priors are bets on whether the hours are worth spending, recorded before the numbers exist. They are not
predictions of the value, and a null on (1) is a publishable result rather than a wasted leg.

1. **AllOpt+peel+DynSTC (`tsan-dom_peeling-ea-lo-st-swmr-stmt`), every application.** The paper's own headline
   configuration — its March FFmpeg 1.57 and Redis 1.36 rows are this one — and the corrected campaign has no
   counterpart to it at all. Prior on a gain: high for FFmpeg (DynSTC alone is 1.113 there), low for Redis and
   SQLite where DynSTC is a measured loss (−3.0 %, −1.7 %), unknown for memcached and MySQL. ~3.2 h for four
   applications; MySQL adds ~4.5 h alone because escape analysis takes about three hours on `sql_yacc.cc`.
2. **AllOpt+peel with whole-program summaries on FFmpeg.** WP is the one bundle addition conclusive anywhere
   (Redis 1.008 → 1.027) and has never been built for FFmpeg or MySQL. Prior: medium. ~1.2 h.
3. **DE + whole-program summaries on Redis.** Both components are conclusive alone; if additive this is Redis's
   best analysis-only row. Prior: medium-low, cheapest item on the list. ~0.3 h.
4. **WP on MySQL.** Prior: low — MySQL resolves nothing at ±14 points and the build is expensive. Not bought.
5. **Anything with loop peeling as the variable.** Lowest; do not buy. Peeling is now a null on static reach,
   on timing, and on executed accesses (opposite signs below the noise floor on both applications).

## What withdraws a row

A configuration whose binary fails the provenance gate; a leg whose runs are retired above `P5_FOREIGN_MAX`
faster than the top-up can replace them; or an aggregation that had to be changed to make the row readable. In
each case the row is reported as withdrawn with the reason, not quietly dropped.
