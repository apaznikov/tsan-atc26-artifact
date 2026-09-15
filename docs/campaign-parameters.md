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
| Compiler for the campaign | `tsan-line-aa8a6dd8a2e8` (branch `artifact/paper-sound` at `aa8a6dd8a2e8`, all 23 shapes, check-tsan green in five configurations) |
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
| FFmpeg | 4 codecs (h264, h265, mjpeg, stream copy), CC-BY input, `-c:v` only | `-threads 4` (March) | `-threads 16` (libx265's ceiling) | sweep: AllOpt+peel 1.008 at 4, 1.055 at 16; DynSTC ~1.12 throughout |
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

FFmpeg input (decision 4, default applied): Tears of Steel (Blender Foundation, CC-BY), a 100-second
cut at 1366x768, 30 fps, yuv420p, about 6.4 Mbit/s H.264 in Matroska, produced by the ffmpeg command
recorded in `docs/ffmpeg-input.md` together with the source URL; the file itself is not shipped.

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
