# Campaign parameters, fixed 14 September 2026

Every parameter of the point-plot campaign (fixed thread count, all configurations), written down
before the campaign runs so that any run can be repeated exactly. The pre-registration note with
the selection rules is `tsan-experiments/tools/notes/paper-setup-campaign-2026-09-13.md` and
`preregistration-2026-09-13.md`; this file is the values those rules produced, plus the sweep
evidence behind each thread count.

## Machine and compiler

| Item | Value |
|---|---|
| Host | Intel Xeon w9-3495X, 56 cores / 112 threads, 250 GB, Ubuntu 24.04, kernel 6.8.0-40 |
| Benchmark CPU set | 4-27,60-83 (48 logical CPUs), one measurement at a time, `taskset`-pinned |
| Compiler for the sweeps and Stage B | frozen copy `tsan-perf-d3bf9f8c39fe` (stamp in `clang --version`) |
| Compiler for the campaign | the `artifact/paper-sound` branch tip once its gate is green; until then `d3bf9f8c39fe` |
| Machine state | must be recorded per leg (`session.json`: load, governor, turbo, foreign CPU share) and the remote-development stack question settled first (see "Open" below) |

## Per-application parameters

**Selection rule, stated once and applied to every application:** the primary thread or client
count is *the highest concurrency at which the workload remains valid on the benchmark CPU set*,
where "valid" means every test of the workload still produces a result. The rule is independent of
any measured speedup; the sweep curves are reported in full alongside the point plots, and the
March value (the paper's) is always the second row. This replaces an earlier version of this file
that had chosen each primary at the maximum of its sweep curve, which would have been selection on
the outcome; that version is superseded and should not be used. **This rule was written on 14 Sep,
after the sweep, and lands on the top point of the FFmpeg and Redis curves; it must not be described
as pre-registered.** What makes the point plots defensible is that the full curves are published
beside them (`data/contention-*`), so no point is hidden. The pre-registered rule R3 (March values
unchanged for FFmpeg, SQLite and Redis) is honoured by the second row; the March values are the
second row by Alexey's decision of 14 Sep.

| Application | Workload | Primary (rule value) | Why that is the ceiling | Second row (March value) |
|---|---|---|---|---|
| FFmpeg | 4 codecs (h264, h265, mjpeg, stream copy), CC-BY input clip, `-c:v` only | `-threads 16` | libx265 refuses more than `X265_MAX_FRAME_THREADS` = 16; above it the h265 codec disappears from the results rather than failing | `-threads 4` |
| Redis | `redis-benchmark`, 19 tests, `-P 1024 -n <per-test>` | `-c 112` (decided 14 Sep; unswept, one 30-minute leg to measure) | the machine's logical CPU count, the same rule as SQLite and memcached; Redis has no hard limit and no saturation point (absolute throughput declines monotonically from c=50, 11% lower at 512), so the swept grid's edge is not a ceiling | `-c 50` (tool default) |
| SQLite | `threadtest3`, all 7 subtests listed explicitly; resolvable set = walthread1, walthread2, checkpoint_starvation_1, checkpoint_starvation_2 | `--w1-threads 112` (walthread1 is the only subtest with a thread argument) | the machine's logical CPU count, the top of the pre-registered grid | no thread argument (threadtest3's default) |
| memcached | `memtier_benchmark -t 10 -x 5 --pipeline 16 -P memcache_text --random-data --requests 100000`; server `-c 4096` | server `-t 112` | the paper's `$(nproc)`; R2 requires both values, and the rule picks the higher as primary | `-t 48` (R1 pinned-48 value) |
| MySQL | sysbench, 5 scripts, `--time=180` | `--threads=84` | the paper's `nproc*3/4`; R2 requires both, the rule picks the higher | `--threads=36` (R1 value) |

Sweep evidence, reported as curves rather than used for selection: SQLite walthread1 flat from 2 to
112 threads (AllOpt+peel 1.016 at 2 and 1.016 at 112, peak 1.027 at 16); Redis flat and non-monotone
over 50 to 512 clients; FFmpeg AllOpt+peel rising from 1.007 at 2 threads to 1.055 at 16, DynSTC flat
at about 1.12. At the rule values the point-plot expectations are therefore: FFmpeg AllOpt+peel 1.055
and DynSTC 1.115; Redis AllOpt+peel 1.025 and DynSTC 1.086 (both unquotable until the baseline drift
is resolved); SQLite walthread1 AllOpt+peel 1.016 [1.00, 1.02].

Harness note (tsan-exp, 14 Sep): `run_sqlite_test.sh` passes `--w1-threads N walthread1`, which
restricts the run to walthread1; to run all seven subtests with a thread count, every test name must
be listed explicitly on the threadtest3 command line (with flags and no names it prints usage). This
harness change is made once, before the campaign.

MySQL runs four configurations only (native, stock, AllOpt+peel, AllOpt+peel+DynSTC); fallback
ladder if the EA build's serial floor F exceeds the cap: `--time=120` at N = 5, then N = 3 reported
without intervals, then fewer configurations.

Workload definitions that stay fixed at every thread count: `--requests 100000` for memtier (the
paper-era default of 10 000 produced ~1 s iterations and meaningless throughput); equal N per arm;
`report_bugs=0` on both arms; provenance gate on every binary (`build_info.txt` compiler stamp must
equal the campaign hash).

## Configurations

The paper's twelve (native; stock TSan; EA, LO, STC, SWMR, DE, DE+peeling alone; DynSTC; the four
sound analyses; AllOpt without peeling; AllOpt with peeling) plus AllOpt+peel+DynSTC (the paper's
headline configuration, never yet measured on a corrected compiler) and the two whole-program
summaries variants. Flag sets are in `tsan-experiments/config_definitions.sh`.

## Runs and statistics

| Item | Value |
|---|---|
| Runs per cell | one discarded warm-up, then N = 5 |
| What "warm" means | SQLite: database built and kept; FFmpeg: input in page cache; memcached, Redis: allocator and connection path warm, data set rebuilt by the benchmark; MySQL: server initialised, buffer pool populated |
| Order | run-major (repetition outer, configuration inner) |
| Statistic | geometric mean over the application's tests of per-test medians; 95% bootstrap interval, B = 2000, seed 1, resampling runs |
| Resolvable-subtest column | set taken once from the stock baseline's pooled coefficient of variation, applied to every row |
| Cross-check | every curve reported on all five runs and on runs 2-5; if the two disagree in direction, neither is reported and the leg is repeated |
| Reported as | the full table; "best configuration per application" is derived from it, never a substitute |

## Conditions on record

Every leg records `session.json` (load, governor, turbo, foreign CPU share). Known changes of
machine state since Stage B: the JetBrains remote-development stack started 8 Sep 13:52 and has run
unpinned since; a full `-j28` LLVM build ran on 14 Sep between the Redis repeat and anything
measured after it. Both are conditions, not explanations.

## Open, and blocking

1. **Baseline drift.** Byte-identical Redis binaries give stock TSan 14% less throughput on
   14 Sep than on 8 Sep, native 5% less; eight of thirteen Redis rows change verdict between the two
   dates. Machine-wide (native moved), cause unknown, everything from load to thermal throttling
   eliminated; remaining candidate is the unpinned JetBrains remote-development stack started
   8 Sep 13:52. Until resolved: no Redis number is quoted, and the other four applications are
   unexamined, not clean. Next step needs Alexey: SIGSTOP that stack for five minutes and run perf
   LLC-miss counters on one instrumented and one native Redis arm, with and without.
2. **Headline configuration.** AllOpt+peel+DynSTC on four applications, 3.2 machine-hours, at
   the rule values above with the March values as second rows.
3. **One clean re-measurement of all five applications** replaces Stage B once the machine state
   is settled and written down (~30 h at N = 5).

## Smoke mode

The artifact's `--smoke` mode (N = 1, reduced test lists, short durations, for laptop-class
evaluators) prints its numbers with an explicit "not a measurement" marker: a single run has no
interval and cannot have one, and a bare figure would be quoted.
