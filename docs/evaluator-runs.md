# Our own evaluator-style runs

Every time we ran the artifact the way an evaluator runs it (a fresh clone, the container, N = 2 at the
default configurations unless noted), with what `harness/tools/perf/compare_with_claims.py` judged. The
criterion and the comparison condition are in `PERFORMANCE.md` ("The comparison condition", "Match criterion for every
configuration row"). These runs support no claim and are not
shipped, except the SQLite N = 5 leg (`data/perf/n2-spread-sqlite-n5-20260918`); the figures are what the
comparator printed. "Ours" is the Intel Xeon w9-3495X the intervals were measured on; "second host" is an
AMD EPYC 9115 (2 sockets x 16 cores x 2 threads).

| Run | Host | Date (2026) | Processor set | Wall time | Rows judged | Rows outside | Verdict |
|---|---|---|---|---|---|---|---|
| 1 | ours | 17-18 Sep | 4-27,60-83 | Redis 15 min, memcached 28, FFmpeg 25, SQLite 68 (three partial runs) | 8 (FFmpeg at 4 threads) | 1: SQLite AllOpt with peeling 1.078, by 0.017 | not clean at N = 2; decided by run 2 |
| 2 | ours | 18 Sep | 4-27,60-83 | SQLite only, N = 5, 20 cells | 2 | 0: AllOpt with peeling 1.041 [0.943, 1.129], DynSTC 1.035 [0.912, 1.111] | inside |
| 3 | ours | 20 Sep | 4-27,60-83 | 2 h 56 min (whole tier) | 6 (FFmpeg: regenerated clip, not compared) | 1: SQLite AllOpt with peeling 1.076, by 0.015 | not clean |
| 4 | ours | 20 Sep | 4-27,60-83 | 2 h 23 min (performance only) | 6 (FFmpeg: regenerated clip) | 2: SQLite AllOpt with peeling 1.063, by 0.002; Redis DynSTC 0.984, by 0.014, same side of 1.0 | not clean |
| 5 | ours | 22 Sep | 4-27,60-83 | 2 h 39 min | 9 (FFmpeg at 16 threads) | 1: Redis DynSTC 0.979, by 0.009, same side of 1.0 | not clean |
| 6 | ours | 23 Sep | 4-27,60-83 | 2 h 38 min | 9 | 0 | PASS |
| 7 | second host | 19 Sep | 0-47 (another shape: 32 cores, 16 with both SMT threads) | not recorded | 6 (FFmpeg: regenerated clip) | 2: Redis DynSTC 0.971, by 0.001, same side; memcached DynSTC 0.942, by 0.002 | not clean; not comparable under the comparison condition |
| 8 | second host | 20 Sep | 0-47 (the same other shape) | 2 h 48 min | 6 (FFmpeg: regenerated clip) | 3: Redis DynSTC 0.977, by 0.007, same side; memcached AllOpt with peeling 1.104, by 0.025; memcached DynSTC 1.162, by 0.099 | not clean; not comparable under the comparison condition |
| 9 | second host | 20 Sep | 0-23,32-55 (the campaign's shape) | 2 h 49 min | 6 | 2: SQLite AllOpt with peeling 0.913, by 0.029; SQLite DynSTC 1.123, by 0.041 | not clean |
| 10 | second host | 22 Sep | 0-23,32-55 | 2 h 39 min | 9 | 6: FFmpeg AllOpt with peeling 1.024 and with DynSTC 1.155; Redis AllOpt with peeling 1.121, DynSTC 1.066; SQLite 1.113 and 1.122 | not clean |

**Reading an outside row on our host.** An N = 2 point is compared with an N = 5 interval, and two rows
account for every outside reading here. SQLite's AllOpt-with-peeling headline column is wide at N = 2: over
the ten two-run subsets of run 2's N = 5 leg (`harness/tools/perf/subset_spread.py`, which recomputes the
headline statistic through the aggregator's own estimator) the point ranges from 0.977 to 1.104 and 3 of 10
exceed the shipped bound of 1.061, so readings of 1.078, 1.076 and 1.063 are that spread, and the N = 5 run
landed inside. Redis's DynSTC row read 0.957 to 0.984 in the five runs on our host, always on the cost side of
1.0, three of the five above the highest of the campaign's own ten two-run subsets (0.926 to 0.965): a cost of
2 to 4 per cent against the campaign's 5.6, the size of change the documented between-session Redis drift
produces in a ratio. Re-running an outside application at N = 5 decides it.

**The second host.** Runs 7 and 8 were pinned to a set of another shape, which the comparator declines;
on it memcached's instrumented runs split between two modes about 15 per cent apart and an N = 2 ratio was
whichever mode each pair drew (0.942 one day, 1.162 the next), while in run 9, on the campaign's shape, all
eight instrumented runs landed in one mode, and in runs 9 and 10 both memcached rows fell inside. What does not
travel is Redis's DynSTC cost: that row read 0.971, 0.977, 0.939 and 1.066 there, and the N = 5 curves on that
host (`PERFORMANCE.md`, the Redis curves) contain 1.0 at every client count. In run 10 both Redis rows moved together because
stock alone moved (slowdown against native 8.54 in run 9 and 9.59 in run 10, against 9.09 and 9.00 for DynSTC
and 8.66 and 8.55 for AllOpt with peeling); when several rows of one application fall outside on the same side,
check each configuration's slowdown against native before reading the ratios. FFmpeg's DynSTC gain appeared in
every run on both hosts (1.11 to 1.14), and SQLite's headline column is wider there at N = 2 than on ours.
