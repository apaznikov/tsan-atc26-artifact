# What the March artefacts actually record about the machine they ran on

Asked by the tsan-paper lane (2026-09-13): were the paper's measurements taken on a different machine? This
note separates what the files record from what I infer. Nothing here is a new measurement; every figure is
re-read from the March artefacts with the repo's own parsers.

## 1. What the artefacts record: almost no machine metadata at all

March predates `tools/write_build_info.sh` and the session header every current `perf_<app>.md` carries
(`mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server`). Concretely:

- the March build trees (`nosql/memcached/old-builds/*.20260306`, `projects/ffmpeg/old-builds/*.20260306`)
  contain **no `build_info.txt`** — no compiler stamp, no flags, no host;
- `nosql/redis/redis-polygon/__results_redis__.paper-era-20260306/results.txt` is bare test names and numbers;
- no March file records a hostname, kernel, OS version, CPU count, governor or turbo state.

So there is **no recorded evidence either way**. What the artefacts do carry is mtimes, the command lines, and —
for FFmpeg — wall *and* user CPU time per cell, which turns out to settle the question.

Dates: FFmpeg main run A 2026-03-05 17:19 (`summary_ffmpeg_benchmark.csv.4march`); memcached and FFmpeg build
trees 2026-03-06; Redis 2026-03-06 18:57–19:32; FFmpeg main run B 2026-03-17 20:45
(`summary_ffmpeg_benchmark.csv`); SQLite contention 2026-03-17 14:46; FFmpeg contention 2026-03-18 14:29.

## 2. This host was never Ubuntu 22.04, and was 24.04 in March 2026

From the host, not the artefacts:

- CPU **Intel Xeon w9-3495X, 56 cores / 112 threads** — exactly the CPU the paper names.
- `/` born 2024-07-22; apt suites are `noble`; no release-upgrade record anywhere;
- `/var/log/dpkg.log.6.gz`, **2026-03-17 13:53**, installs `libtk8.6 8.6.14-1build1` against
  `libc-bin 2.39-0ubuntu8.5`. glibc 2.39 is Ubuntu 24.04; 22.04 ships 2.35.

So on the very day the SQLite contention sweep ran, this host was 24.04. **The paper's "Ubuntu 22.04 LTS" is a
misstatement, not evidence of a second machine.** The CPU model in the same sentence is correct.

## 3. One artefact that does not fit: `nproc` was 40 during the contention sweeps

Two independent drivers compute their sweep from `nproc`:

- `sql/sqlite/run_sqlite_test_all.sh:62`  `max_threads=$(nproc)`
- `projects/ffmpeg/bench_ffmpeg_all_threads-contention.sh:8`  `MAX_THREADS="$(nproc)"`

Both paths are the lab harness's, and neither driver is in the shipped `harness/`: they are the sweep loops
this artifact replaces with `40-perf.sh --all-configs`, and they were left out of it (`scripts/vendor-harness.sh`,
`LAB_ONLY`) rather than shipped as a second way to do the same thing. The two lines are quoted here because
this note is the record of what the March runs did, not an instruction to run them.

Both swept `seq 2 2 $MAX` and both stopped at **40**. This is not a truncated run: every one of the 12 SQLite
configurations has exactly 20 logs spanning 2..40, so the sweep completed for all of them at 40. An
interruption would have truncated the last configuration only.

`nproc` reports the caller's affinity mask, so the shell saw 40 CPUs of 112. Either a mask was in force or the
sweep ran elsewhere; given §2 the mask is much the better reading. **This corrects my earlier statement that
March "ran unpinned across all 112 CPUs".** What is true is narrower: no March script contains a `taskset`,
`numactl` or cpuset call — so the scripts did not pin — and on 17–18 March only 40 CPUs were visible to the
shell that started them. What was visible on 5–6 March, when the paper's main columns were produced, is not
recorded.

## 4. WITHDRAWN, and what replaced it (corrected 2026-09-13, same day)

**This section originally claimed the March machine was contended, on the evidence that FFmpeg's identical
commands ran up to 1.96x slower on 17 March than on 4 March with the same user CPU time. That claim was wrong
and is withdrawn.** The commands were not identical: the 4 March run used `-threads 8` and the 17 March run
used `-threads 4`, on every one of their 20 and 42 rows respectively. Reading the two dates as one workload was
a cross-source comparison of exactly the kind this lane has a standing rule against, and the rule caught it two
messages too late.

With the thread counts attached, the numbers say the opposite:

| codec | build | 4 Mar, `-threads 8` | 17 Mar, `-threads 4` |
|---|---|---|---|
| h264 | ffmpeg-orig | 39.48 s, 267.6 user, **6.78 CPUs** | 77.43 s, 310.2 user, **4.01 CPUs** |

4.01 CPUs at `-threads 4` is perfect scaling, not a degraded run. The wall-time difference is the thread count.

The "parallelism" statistic itself was also unsound for two of the four codecs: at `-threads 4` the 17 March
h265 row shows 9.66 CPUs busy and mjpeg 7.63, because libx265 and the mjpeg encoder size their own worker
pools from the machine rather than from `-threads`. A ratio of user to wall time is therefore not a
contention measure here at all.

**There is no contention evidence in the FFmpeg artefacts.** Each thread count was run on exactly one date, so
the data cannot separate date from thread count even in principle.

**What replaces it is a finding of its own: the paper's FFmpeg column used `-threads 4` — the same as Stage B.**
`summary_ffmpeg_benchmark.csv`, the 17 March file the paper's 1.474 and 1.570 come from, carries `-threads 4`
in all 42 command templates. So for FFmpeg there is **no concurrency gap** between the paper's setup and the
current campaign, and any plan to "restore the March thread count" for FFmpeg restores the number it already
has.

The same artefacts give one pre-existing data point on whether the speedup grows with thread count, and it does
not point one way. Speedup vs stock TSan, geometric mean over the four codecs, one run per cell:

| build | `-threads 8` (4 Mar) | `-threads 4` (17 Mar) |
|---|---|---|
| DE | 1.334 | 1.294 |
| DE + peeling | 1.352 | 1.432 |

DE falls slightly with fewer threads and DE+peeling rises; with one run per cell neither is a result. What it
does establish is that the effect of thread count on FFmpeg's speedup is small and of uncertain sign, which is
a prediction the queued sweep will test directly.

## 4b. What still stands, and what the SQLite anomaly now rests on

Sections 1-3, 5 and 6 are unaffected: they rest on file contents, `nproc` in two independent sweep drivers, the
dpkg log and a code comment, none of which came through the FFmpeg comparison.

The SQLite `stress1` anomaly also stands as a fact — the March stock-TSan baseline did 6 417 iterations where
the same compiler does 106 704 today, about seven times further from the median than the subtest's entire
65-run envelope. What is withdrawn is its *explanation*: "a contended machine" was a hypothesis whose support
was the FFmpeg comparison above, and that support is gone. The anomaly is unexplained again.

## 5. Two workload-definition defects in the March memcached column

- memtier was invoked with **no `--requests`**, i.e. its default of 10 000 per client (5 M per iteration),
  which makes an iteration last about a second;
  this is the artefact recorded in [memcached-variance-2026-09-04.md](memcached-variance-2026-09-04.md) — native reads back as 57 M ops/s, and March native reads
  914 k ops/s against 5.08 M today. The 100 000-request setting Stage B uses fixes it.
- `nosql/memcached/run-bench.sh` carries the comment *"(the paper-era 'x5 iterations when the type is tsan'
  rule was removed: unequal N inside the comparison)"*. In March the TSan arm got five times as many memtier
  iterations as native — the two arms of the comparison had different N.

## 6. Answer (revised)

Same host, same OS. Specifically: the paper's CPU is this machine's CPU; its "Ubuntu 22.04" is wrong (24.04
since install); and the contention sweeps ran with a 40-CPU affinity mask. **Nothing supports a second
machine.** What accounts for the gap is an unequal-N memcached comparison, a broken memtier request count and
the reach collapse when the analyses were made sound — plus, for SQLite, one baseline run that nobody has yet
explained. Machine load was a fourth candidate and it is withdrawn: the evidence for it was an FFmpeg
comparison across two different thread counts (§4).

The practical consequence for the camera-ready: a re-run in "the March configuration" cannot recover the March
numbers, because the thing that produced them was not a configuration — it was a degraded baseline.
