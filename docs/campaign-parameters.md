# Campaign parameters

Every parameter of the performance campaign that `CLAIMS.md` section 5 rests on
(`data/perf/campaign-f3deebfbab60/`), so that any run can be repeated exactly. The concurrency of each
application was fixed before the campaign ran (`data/notes/preregistration-2026-09-13.md`).

## Machine and compiler

| Item | Value |
|---|---|
| Host | Intel Xeon w9-3495X, 56 cores / 112 threads, 250 GB, Ubuntu 24.04, kernel 6.8.0-40 |
| Benchmark processor set | 4-27,60-83: 48 logical processors that are 24 physical cores with both SMT siblings of each (siblings n and n+56), `taskset`-pinned, one measurement at a time; recorded as `data/perf/campaign-f3deebfbab60/shape.json` |
| Compiler | `f3deebfbab60` (the image's `TSAN_AUDIT_HASH`): `aa8a6dd8a2e8` plus three commits that change compile time only (412d1d513f3d, 2dcc82078a60, c38c1e7e94ec). Against `aa8a6dd8a2e8`: 112 of 112 corpus rows identical; the 17 application configurations built on both compilers identical (MySQL 640 355 memory-access sites and 1 263 905 `__tsan_*` calls; all 14 Redis rows); Redis's whole-program summaries byte-identical. MySQL with AllOpt and peeling builds in 459 s at 56 jobs (8 321 s on `aa8a6dd8a2e8`, under different load). Every instrumented configuration was built with `-tsan-ea-report-abandoned`: zero abandoned functions on all five applications |

## Per-application parameters

| Application | Workload | Concurrency | Second concurrency (`r2`) | Configurations |
|---|---|---|---|---|
| FFmpeg 4.3.9 | libx264, libx265, mjpeg and stream copy of the reference clip (`docs/ffmpeg-input.md`), `-c:v` only | `-threads 4`, the paper's | none in the campaign; `-threads 16`, the artifact's default, measured in separate legs (`ffmpeg-t16/`) | 12 |
| Redis 7.0.15 | `redis-benchmark`, 19 tests, `-P 1024 -n <per-test>` | `-c 50`, the tool's default | `-c 112` | 14 |
| SQLite 3.50.2 | `threadtest3`, all seven subtests (`SQLITE_TESTS='*'`) | threadtest3's own thread counts | none | 14 |
| memcached 1.6.29 | `memtier_benchmark -t 10 -x 5 --pipeline 16 -P memcache_text --random-data --requests 100000` (10 threads x 50 clients); server `-c 4096` | server `-t 48` | server `-t 112` | 14 |
| MySQL 8.0.39 | sysbench 1.0.20, five scripts, `--time=180` | `--threads=36` | `--threads=84` | 4 |

FFmpeg, SQLite and Redis run at the parameters of the paper's original measurements. memcached and MySQL run
at the pinned set's values, with the whole-machine values (112 and 84, the paper's original policy) as the
second row. FFmpeg's resolvable set is all four codecs; SQLite's resolvable set is decided per leg from the
stock baseline's pooled coefficient of variation (`CLAIMS.md` section 5).

**The thread rule.** The memcached server runs one thread per logical processor of the set it is pinned to,
sysbench three quarters of that, and FFmpeg an absolute `-threads 16` (libx265's ceiling: it refuses more
than 16 frame threads). On the 48-processor set that gives 48 and 36. The campaign's FFmpeg rows were taken
at the paper's `-threads 4`, which `FF_THREADS=4` reproduces; the 16-thread default was chosen after the
campaign from the thread sweep, and each set of rows is compared only with runs at its own count. Every cell
records `threads_setting` (the value it ran with) and `threads_from_env` (whether `MC_THREADS`,
`MYSQL_THREADS` or `FF_THREADS` overrode it). On another processor count the rule yields that machine's
point, and such a row is reported with its thread count rather than compared.

**Fixed at every thread count.** `--requests 100000` for memtier (10 000 gives iterations of about a second
and a meaningless throughput); equal N per arm; `report_bugs=0` on every instrumented arm; a provenance gate
on every binary (the compiler stamp in `build_info.txt` must equal the campaign's hash).

## Configurations

Fourteen for Redis, SQLite and memcached (`ALL14` in `scripts/40-perf.sh`; flag sets in
`harness/config_definitions.sh`): native; stock ThreadSanitizer; EA, LO, STC, SWMR, DE and DE with peeling,
each alone; DynSTC; AllOpt without peeling; AllOpt with peeling; AllOpt with peeling and DynSTC; AllOpt with
peeling with whole-program summaries; the four sound analyses with whole-program summaries. FFmpeg runs the
twelve without whole-program summaries, which need a summary generator FFmpeg does not have. MySQL runs
four: native, stock, AllOpt with peeling, and AllOpt with peeling and DynSTC.

**Static counts** (`data/perf/campaign-f3deebfbab60/static-counts.csv`). Against stock ThreadSanitizer,
AllOpt without peeling removes 5.0 % (memcached), 2.3 % (Redis), 7.8 % (FFmpeg) and 3.3 % (SQLite) of the
static memory-access sites; AllOpt with peeling carries more sites than stock on every application (+5.7,
+14.1, +5.5, +6.8 %; MySQL +6.3 %). The rise is loop peeling alone: DE to DE with peeling adds 11.7 %
(memcached), 16.8 % (Redis), 10.5 % (SQLite) and 14.3 % (FFmpeg), and the same delta appears with the four
sound analyses on or off. DynSTC guards accesses rather than removing them and stays within 1 % of its base
configuration (Redis 37 882 sites against stock's 37 941; memcached 6 810 against 6 748). Each whole-program
row differs from its per-unit counterpart (AllOpt with peeling: memcached 7 130 to 6 699, Redis 43 291 to
40 691, SQLite 61 931 to 61 827), which shows that its summaries were consumed.

## Runs and statistics

| Item | Value |
|---|---|
| Runs per cell | one discarded warm-up, then N = 5 |
| What "warm" means | SQLite: database built and kept; FFmpeg: input in page cache; memcached, Redis: allocator and connection path warm, data set rebuilt by the benchmark; MySQL: server initialised, buffer pool populated |
| Order | run-major (repetition outer, configuration inner) |
| Statistic | geometric mean over the application's tests of per-test medians; 95 % bootstrap interval, B = 2000, seed 1, resampling runs |
| Resolvable-subtest column | set taken once from the stock baseline's pooled coefficient of variation, applied to every row |
| Cross-check | every row reported over all five runs with its interval and over runs 2-5 as a point (four runs get no interval); the runs-2-5 point must lie inside the all-five interval |
| Disturbance gate | a cell whose busy share on the processors outside the pinned set exceeds 0.10 (`P5_FOREIGN_MAX`) is retired and re-run |
| Provenance rule | a cell that overlapped a logged foreign-work window is retired whatever it measured |
| Reported as | the full table; "best configuration per application" is derived from it, never a substitute |

Retired cells are renamed, not deleted, and ship beside their replacements. The campaign ran from 15 Sep
18:49 to 17 Sep 03:03 (2026): 400 measured runs plus 80 warm-ups, `primary` 290 (Redis, memcached and SQLite
70 each, FFmpeg 60, MySQL 20) and `r2` 110 (Redis 70, memcached 20, MySQL 20). Three cells were retired, one
by the provenance rule (`primary/sqlite/tsan-lo/run2.foreign-window-030844`) and two by the disturbance gate
(`r2/redis/tsan-stmt/run1.disturbed.025858`, `r2/redis/tsan-dom/run1.disturbed.030107`). Every FFmpeg run
carries all four codecs and the reference clip's sha256. Every table is computed from run directories, never from a
completion marker. Builds and timed legs cannot share the machine: a parallel LLVM build pinned away from the
bench set still puts the outside processors several times over the gate.

## The shape of the processor set

Equal logical-processor counts are not equal machines. The campaign's 48 logical processors are 24 physical
cores with both SMT siblings of each; 48 contiguous processors on another host can be 48 separate cores, twice
the compute under the same count, or, on a 2-socket 16-core host, 32 cores with 16 of them doubled. Every cell
records `n_physical_cores` and `smt_pairs_complete` (from `tools/perf/cpu_snapshot.py --topology`); the
campaign's cells predate those fields, so its shape ships as `shape.json`. `evaluate.sh` chooses the first 24
complete sibling pairs the Docker daemon grants (4-27,60-83 on our host; 0-23,32-55 on the AMD host), and the
comparator refuses a run of another shape. `docs/evaluator-runs.md` shows what another shape did to memcached.

One field is not what it looks like: `session.json`'s `host` is `os.uname().nodename` inside the container,
the container's id for every containerised run, so it names the run and not the machine.

## Smoke mode

`ART_SMOKE=1` runs one unwarmed run per configuration and marks its output NOT A MEASUREMENT: a single run
has no interval. The workload is cut only for memcached (`MC_REQUESTS=2000`) and MySQL
(`MYSQL_SECONDS=20`). FFmpeg encodes the whole clip at 16 threads and Redis runs its full workload once.
SQLite is not shortened: smoke mode exports `SQLITE_TESTS=walthread1`, but `run_sqlite_test.sh` reads that
variable only on its `--w1-threads` path, so threadtest3 runs the whole seven-subtest suite on each build
(459.8 s for the uninstrumented cell alone). In a smoke cell `threads_from_env` reads true whatever the
reader set, because the smoke branch of `40-perf.sh` exports `FF_THREADS` and the flag is decided from the
three variables together; `threads_setting` is still the value the cell ran with.

## Curves measured after the campaign

On the shipped compiler, after the campaign: memcached's server threads at 24, 96 and 112, Redis's clients at
256 and 512, SQLite's walthread1 threads at six counts, whole-program summaries with DynSTC, and the memcached
and Redis curves on the AMD host. A value would have replaced the campaign's default only if, at five runs on
the campaign's host, its interval for the best configuration were no wider and its point higher; no default
changed. The arms, their intervals and the reasons are in `CLAIMS.md` section 5, "Concurrency curves and
whole-program summaries"; the data is under `data/perf/campaign-f3deebfbab60/sweep-*`,
`data/perf/campaign-f3deebfbab60/wp-dynstc-*` and `data/perf/sweep-amd-f3deebfbab60/`. These cells record the
thread count but not Redis's clients or SQLite's walthread1 threads, so `sweep-legs.log` and `sweep-legs.sh`
(and `legs.log`, `legs.sh` on the AMD root) name each arm with its knob value; the harness now writes the knob
into every cell's metadata.

## Earlier trees

The trees shipped beside the campaign were recorded on earlier compilers and support no claim;
`scripts/91-verify-provenance.sh` checks each against its own compiler. Stage B
(`data/perf/stageB-d3bf9f8c39fe`) is internally consistent: 500 runs, one compiler, one processor set, one
mode. Its FFmpeg runs record an empty input hash (a relative input path, fixed in the campaign's harness), and
five of its 500 runs sit above today's 0.10 gate (0.103 to 0.166), inside the 0.25 gate in force when they
were taken. The counter and profile trees (`combo-counters`, `merge-counters`, `profile-2026-09-09*`) record
no compiler per run; their compiler is named in their build logs and in `data/README.md`.
