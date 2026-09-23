# memcached, N = 10, stock against the sound bundle and AllOpt with peeling (17 Sep 2026)

The application run behind `CLAIMS.md` section 1, last row, for memcached. Compiler `f3deebfbab60`; server at
112 threads, `memtier_benchmark` with 10 threads, 25 iterations and pipeline 16 (`manifest.json` holds the
exact command lines and the compiler stamp); configurations `tsan`, `tsan-sound` and
`tsan-dom_peeling-ea-lo-st-swmr`, ten runs each (`runs.jsonl`, the reports under `logs/`). `verdict-L3.txt` is
the verdict script's output over `logs/`, all three levels printed, gating at L3; regenerate it with
`python3 harness/tools/preservation/preservation_verdict.py --results-dir <this dir>/logs --app memcached --baseline tsan`.
The key levels are defined in `CLAIMS.md`, "Terms used below".

## Result at L3

No site is LOST. Four locations are reported in 10 of 10 runs under all three configurations: `current_time`
written by `clock_handler`, `stats_state` written by `do_item_link` and by `do_item_unlink`, and
`memory_allocated` written by `do_item_unlink`. Seven are UNDETERMINED: stock and the sound bundle report each
once in ten runs, AllOpt with peeling never, and N = 10 cannot separate that from stock's own detection noise.

## The one report that moves to another reader

At L1 and L2 the verdict file prints one row as LOST: the reader `conn_new@memcached.c:761` paired with the writer
`clock_handler` on `current_time` is reported in 10 of 10 runs under stock and under the sound bundle, and in 0 of
10 under AllOpt with peeling. AllOpt with peeling still reports the race on that location in 10 of 10 runs,
paired with other readers of `current_time` (`do_item_link`, `lru_maintainer_thread` and
`try_read_command_ascii`), which is why the L3 row for `current_time` is KEPT. At L1 and L2 one row appears only
in the optimized builds: `lru_maintainer_juggle` reading `current_time`, 0, 2 and 2 of 10 under stock, AllOpt
with peeling and the sound bundle; at L3 it joins the same `current_time` row.

Line 761 is instrumented identically in all three builds (the campaign binaries, and the IR compiled with the
campaign's flags: `conn_new` has 20 reads, 35 writes, 60 `__tsan_*` calls and 403 instructions, with two calls at
line 761, one of them the `__tsan_read4` of `current_time`, the function's only reference to it; `clock_handler`
has 15 calls). We attribute the move to shadow-slot eviction: ThreadSanitizer keeps four records per granule, so
which reader's record is still there when `clock_handler` writes depends on how many instrumented accesses run in
between, and AllOpt with peeling carries 382 more static sites than stock on memcached (7 130 against 6 748,
`data/perf/campaign-f3deebfbab60/static-counts.csv`). DE alone and DE with peeling each keep the pairing at 10 of
10 (`../2026-09-17-transform-f3deebfbab60/verdict-L3.txt`), as does the sound bundle here, so no single analysis
removes the report. The same move appears with the upstream flag on top of AllOpt with peeling
(`../2026-09-21-nofe-amd-f3deebfbab60/`), so it belongs to the bundle and not to the flag.
