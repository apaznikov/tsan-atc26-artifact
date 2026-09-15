# Campaign parameters, fixed 14 September 2026, primaries revised to R3 on 15 September

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
| Compiler for the campaign | `tsan-line-f3deebfbab60` (branch `artifact/paper-sound` at `f3deebfbab60` = `aa8a6dd8a2e8` plus the three EA compile-time commits 412d1d513f3d, 2dcc82078a60, c38c1e7e94ec; decision of 15 Sep 15:50; gate passed 15 Sep ~16:50): 112/112 static-count rows identical to `tsan-line-aa8a6dd8a2e8` on the 28-module corpus (stock, EA, the four sound analyses, and AllOpt with dominance elimination, so DE rows included); zero abandoned functions per TU on the corpus and the MYSQLparse extract; five IR suites 126/0 (1 unsupported); 12-configuration matrix 12 x 292/0; check-tsan 371/0 in each of five configurations; K=5 replay 293 x 5 x 12 with L2 = 0 everywhere (the one flagged bucket, `fork_atexit.cpp`, is a thread-leak diagnostic flaky under stock itself, 0/5-3/5, Fisher p = 0.444); frozen at `/extra/alexey/builds/tsan-line-f3deebfbab60`, `ldd` 87 libraries from the copy and none from a worktree. Gates ran while application builds used the other half of the machine (load 20-30), re-run serially after an overlapping-lit contamination of the first pass. Fallback if any gate is red: `tsan-line-aa8a6dd8a2e8` (tag `artifact-paper-sound-aa8a6dd8a2e8`), whose builds were kept. The series changes compile time only. On the `MYSQLparse` extract (1.9 MB bitcode, the ledger's proxy for sql_yacc.cc, full campaign flag set, same core, same input): `f3deebfbab60` 13.55 s and 1.98 GB peak, rc = 0; `aa8a6dd8a2e8` did not finish within a 30-minute cap (> 1800 s, 3.14 GB peak, rc = 124). That is a lower bound of 133x, not a measured ratio; the ledger's pre-series figure of 1 091.6 s for the same extract was taken on a different tree and is not this measurement. Memory is uncensored: 37% lower. On the whole MySQL build, same configuration both sides finishing: AllOpt+peel 8 321 s on `aa8a6dd8a2e8` (-j40, half the machine, a clang rebuild on the other half) against 459 s on `f3deebfbab60` (-j56, quiet machine), 18.1x raw; the two non-EA configurations price the conditions at about 1.3x (native 435 -> 319 s, stock 456 -> 365 s), leaving about 14x attributable to the series. Static counts on the MySQL binary identical on both compilers: 640 355 memory-access sites, 1 263 905 TSan calls |
| Abandoned-function check on the applications | every instrumented configuration is built with `TSAN_EXTRA_MLLVM="-mllvm -tsan-ea-report-abandoned"` (an environment variable tied to the compiler, because the flag does not exist in the fallback compiler; configuration identities are unchanged; native takes no TSan flags). The rebuild chain fails if any instrumented `build_info.txt` `flags:` line lacks the flag, and fails if it examined zero configurations, so a zero cannot mean "flag absent" or "nothing checked" (its first version checked nothing: an invalid `find -newermt` spec and provenance files outside the repository for MySQL, FFmpeg and Redis). On 15 Sep it flagged `redis-tsan`, whose provenance file omitted the flag the compiler had received; Redis was rebuilt so the record matches the build. Counts are reported per application and per translation unit; zero required per application, FFmpeg included. Result 15 Sep 18:18: zero on all five applications, every translation unit |
| Identity of `f3deebfbab60` with `aa8a6dd8a2e8` on the applications | The fallback chain was stopped at 17:00 with three MySQL configurations built, so only those three rows exist in both trees: 3/3 identical (640 355 sites, 1 263 905 calls); the 14 Redis rows were built on the fallback afterwards for a direct diff (result recorded by tsan-exp). memcached and SQLite are covered at translation-unit level by the 112-row corpus identity (26 memcached modules, sqlite3.c, shell.c); FFmpeg is not directly compared and rests on zero abandoned TUs plus the series' construction (preserved evaluation order, verified journals and pointee views). Informational only: against Stage B (`d3bf9f8c39fe`, which is not an ancestor of this branch) 45 of 53 shared rows identical and 8 EA-bearing rows of Redis and FFmpeg exactly one site lower. Two independent measurements (112 corpus rows, 3/3 MySQL rows) put that difference outside the three compile-time commits; it lies in the divergence between the perf line and the audited line and is not yet attributed to a commit |
| Machine state | must be recorded per leg (`session.json`: load, governor, turbo, foreign CPU share) and the remote-development stack question settled first (see "Open" below) |

## Per-application parameters

**Decision of 15 Sep (Alexey, by default of the operating plan): the pre-registered rule R3 is
primary.** R3 was written on 13 Sep before the concurrency sweep ran: "FFmpeg, SQLite and Redis run
at their March parameters unchanged", because those three have no concurrency gap with the paper.
The post-hoc rule of 14 Sep ("highest valid concurrency on the bench set", which had landed on the
maximum of the FFmpeg and Redis curves) is retained only as the second row, and the full sweep curves
ship beside every point plot (`data/perf/contention-d3bf9f8c39fe`). memcached and MySQL, which do
have a gap, follow R1 (pinned-48 values primary, since the SQLite curve did not rise through 48) and
R2 (the whole-machine values as a second row).

| Application | Workload | Primary (R3 / R1) | Second row | Notes |
|---|---|---|---|---|
| FFmpeg | 4 codecs (h264, h265, mjpeg, stream copy), CC-BY input, `-c:v` only; **12 configurations** (no whole-program rows: FFmpeg has no summary generator, and the paper's FFmpeg figure has none either) | `-threads 4` (March) | `-threads 16` (libx265's ceiling) | sweep: AllOpt+peel 1.008 at 4, 1.055 at 16; DynSTC ~1.12 throughout |
| Redis | `redis-benchmark`, 19 tests, `-P 1024 -n <per-test>` | `-c 50` (tool default, March) | `-c 112` (logical CPU count) | sweep: DynSTC 1.068 at 50, 1.039 at 112, no trend; AllOpt+peel 1.021 at 50, 0.992 at 112 |
| SQLite | `threadtest3`, all 7 subtests (`SQLITE_TESTS='*'`); resolvable set = walthread1, walthread2, checkpoint_starvation_1, checkpoint_starvation_2 | no thread argument (March) | `--w1-threads 112` for walthread1 | sweep: flat 2-112 |
| memcached | `memtier_benchmark -t 10 -x 5 --pipeline 16 -P memcache_text --random-data --requests 100000`; server `-c 4096` | server `-t 48` (R1) | server `-t 112` (March `nproc`, R2) | no sweep |
| MySQL | sysbench, 5 scripts, `--time=180`; four configurations only | `--threads=36` (R1) | `--threads=84` (March `nproc*3/4`, R2) | EA build 2.22 h on the campaign copy; fits |

Harness note (tsan-exp, 14 Sep): `run_sqlite_test.sh` passes `--w1-threads N walthread1` unless
`SQLITE_TESTS='*'` is set, in which case threadtest3's own default selection runs (all subtests);
a bare `--w1-threads N` with no test name prints usage.

MySQL fallback ladder if the campaign runs over: `--time=120` at N = 5, then N = 3 reported without
intervals, then fewer configurations.

Workload definitions that stay fixed at every thread count: `--requests 100000` for memtier (the
paper-era default of 10 000 produced ~1 s iterations and meaningless throughput); equal N per arm;
`report_bugs=0` on both arms; provenance gate on every binary (`build_info.txt` compiler stamp must
equal the campaign hash).

FFmpeg input (decision 4, default applied; cut 15 Sep 12:58): Tears of Steel (Blender Foundation,
CC-BY 3.0), `TearsOfSteel-1366x768-100s.mkv`, sha256 `43b0fba97eb05a0e…`, 100 s from 06:00 at
1366x768, 30 fps, yuv420p, 6.52 Mbit/s H.264 in Matroska with Vorbis audio, produced by the ffmpeg
command in `docs/ffmpeg-input.md` (crop 1422x800 then scale, because the source is 2.40:1; 24 to
30 fps duplicates one frame in five). The file is not shipped. Nothing measured on the retired clip
is cited; the sweep's FFmpeg arm is re-run on this clip after the campaign.

Sweep evidence, reported as curves rather than used for selection: SQLite walthread1 flat from 2 to
112 threads (AllOpt+peel 1.016 at 2 and 1.016 at 112, peak 1.027 at 16); Redis flat and non-monotone
over 50 to 512 clients; FFmpeg AllOpt+peel rising from 1.007 at 2 threads to 1.055 at 16, DynSTC flat
at about 1.12. At the rule values the point-plot expectations are therefore: FFmpeg AllOpt+peel 1.055
and DynSTC 1.115; Redis at the primary c=112 (measured 14 Sep, N = 5): DynSTC 1.039 [1.02, 1.07] and AllOpt+peel
0.992 [0.97, 1.02], the lowest of the five swept points for both configurations — the rule, chosen
to be indifferent to the outcome, landed on the minimum on its first application and stays as it
is; the curve (DynSTC 1.068 / 1.039 / 1.050 / 1.034 / 1.086 over 50 / 112 / 128 / 256 / 512 clients,
no trend) ships beside the point, and no Redis number is quotable until the baseline drift is
resolved; SQLite walthread1 AllOpt+peel 1.016 [1.00, 1.02].

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
summaries variants: fourteen for memcached, Redis and SQLite. FFmpeg runs twelve (the whole-program
variants need a summary generator FFmpeg does not have; handing it a `-wp` row made the build exit
without its completion marker on 5 Sep). MySQL runs four. Flag sets are in
`tsan-experiments/config_definitions.sh`. The campaign is 58 builds, started 15 Sep 12:55 in the
order MySQL, Redis, FFmpeg, memcached, SQLite, serialised on the machine memory lock.

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
unpinned since; full `-j28` LLVM builds ran on 14 Sep 15:37-16:44 and from 17:15 (the Redis c=112 point
sits between them; every kept run passed the foreign-activity gate). All are conditions, not
explanations.

**Builds and benchmark legs cannot share the machine.** A 29-way LLVM build correctly pinned away from
the bench set still puts the bench CPUs four to five times over the 0.10 foreign-activity gate and
retires every run in flight; the harness retries disturbed runs once at the end of the leg, and if
the build is still running the retry fails too and the leg reports DONE with cells missing (14 Sep:
the Redis c=112 leg lost runs 3-5 of every configuration this way). Every table is therefore computed
from run directories, never from a completion marker. For the campaign, either the machine is
exclusive for its duration or builds are announced in advance so a leg can be paused; this is
Alexey's decision and is recorded here as a condition either way.

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
