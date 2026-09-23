# Recorded data

The runs the paper's tables rest on, as recorded, plus the scripts that turn them into tables.
`scripts/90-tables.sh` regenerates every table from here without running anything, and fails if any
shipped table does not follow from its shipped runs.

Trees whose names end in `f3deebfbab60` were recorded on the shipped compiler; the performance claims rest on
`perf/campaign-f3deebfbab60/` and `perf/ffmpeg-threadsweep-f3deebfbab60/`. The other trees were recorded on
earlier compilers and are shipped as data; of those, only the report-key replay (`CLAIMS.md` section 1) and
the bounded-shadow experiments (section 6) support a claim, on the compilers they name.
`scripts/91-verify-provenance.sh` checks every performance tree against its own compiler. Run metadata
contains absolute paths of the recording machine; nothing reads them.

| Directory | What it is | Compiler | Notes |
|---|---|---|---|
| `perf/campaign-f3deebfbab60/primary/`, `perf/campaign-f3deebfbab60/r2/` | **the campaign every performance claim rests on**: five applications, up to 14 configurations, N = 5, pinned 48 CPUs, run-major, 15-17 Sep 2026. 290 and 110 measured runs | `f3deebfbab60` | the roots `CLAIMS.md` section 5 cites; `scripts/91-verify-provenance.sh` checks them strictly |
| `perf/campaign-f3deebfbab60/ffmpeg-t16/` | FFmpeg at `-threads 16`, the artifact's default thread count: native, stock, DynSTC, AllOpt with peeling, AllOpt with peeling and DynSTC, and the upstream flag on stock and on that combination; N = 5, 21-22 Sep 2026, the campaign's set and shape | `f3deebfbab60` | the 16-thread FFmpeg table in `CLAIMS.md` |
| `perf/campaign-f3deebfbab60/flag-<app>/` | the upstream flag `-tsan-instrument-func-entry-exit=false` on stock and on our configurations, N = 5, 21-22 Sep 2026, the campaign's set; measured and not claimed (`CLAIMS.md`, the section on the flag) | `f3deebfbab60` | the flag's rows are reported with the suite's gate result beside them |
| `perf/campaign-f3deebfbab60/sweep-<app>-<knob>/` | the concurrency curves measured after the campaign, the campaign's set and shape, N = 5: memcached's server threads at 24, 96 and 112, Redis's clients at 256 and 512, SQLite's walthread1 threads at 8, 16, 32, 48, 96 and 112 | `f3deebfbab60` | measured and not claimed (`CLAIMS.md`, the curves section). `sweep-legs.log` and `sweep-legs.sh` beside them name each arm with its knob value and its times, because a cell records the thread count but not Redis's clients or SQLite's walthread1 threads |
| `perf/campaign-f3deebfbab60/wp-dynstc-<app>/` | whole-program summaries together with DynSTC: Redis, SQLite and memcached, five configurations, N = 5 | `f3deebfbab60` | a measured null on all three |
| `perf/sweep-amd-f3deebfbab60/` | the same memcached and Redis curves on the second host (AMD EPYC 9115, 48 of its 64 threads pinned as 0-23,32-55), N = 5, eight arms | `f3deebfbab60` | a separate root because it is a different machine; checked strictly, one processor set per arm, with its own `legs.log` and `legs.sh` |
| `perf/ffmpeg-threadsweep-f3deebfbab60/` | the FFmpeg thread sweep on the reference clip: 2, 4, 8 and 16 encoder threads, four configurations, plus `threads-8-dynstc/` (native, stock, DynSTC and AllOpt with peeling and DynSTC at 8 threads), N = 5 | `f3deebfbab60` | checked strictly too |
| `perf/compile-time-memcached-f3deebfbab60/` | the compile-time control on memcached | `f3deebfbab60` | the build is ten seconds, so the control reports that the resolution is worse than the effect |
| `perf/n2-spread-sqlite-n5-20260918/` | a SQLite leg at N = 5 (four configurations), used to show what two-run subsets of an N = 5 leg read (`docs/evaluator-runs.md`) | `f3deebfbab60` | claimed for nothing |
| `perf/stageB-d3bf9f8c39fe/` | the earlier campaign, superseded by the one above: five applications, 14 configurations, N = 5, pinned 48 CPUs, run-major | `d3bf9f8c39fe` | see the drift note below and `docs/campaign-parameters.md`, "Earlier trees" |
| `perf/contention-d3bf9f8c39fe/` | the earlier concurrency sweep: SQLite walthread1 2-112 threads, Redis 50-512 clients, FFmpeg 2-16 threads, four configurations, N = 5 | `d3bf9f8c39fe` | each comparison is within one window |
| `perf/redis-recheck-2026-09-14/`, `perf/redis-stageB-repeat-2026-09-14/` | the same Redis binaries as Stage B, re-measured six days later | `d3bf9f8c39fe` | the baseline drift evidence |
| `perf/nofe-d3bf9f8c39fe/` | the upstream `-tsan-instrument-func-entry-exit=false` flag on the earlier compiler | `d3bf9f8c39fe` | not a contribution of the paper and not in its tables |
| `perf/merge-timing-*`, `perf/yield-*`, `perf/profile-2026-09-09*`, `perf/combo-counters/`, `perf/merge-counters/` | the trees the results ledger reads: granule-merge timing, the yield branch, where instrumented cycles go, executed-access counters, dynamic reach | as named | shipped so `results_ledger.py` regenerates every section of the ledger; `perf.data` excluded |
| `suite/` | the regression-suite runs: `preservation-suite-20260921T052239Z` (the run `CLAIMS.md` section 1, first row, cites), `preservation-suite-20260917T075005Z` (the same compiler before the lit glibc fix), `preservation-suite-20260921T135253Z-nofe-amd` (the upstream flag), `replay-aa8a6dd8a2e8` (the report-key replay, section 1, third row) and `unsupported/` (how many tests run on this platform) | `f3deebfbab60`; the replay `aa8a6dd8a2e8` | each directory's README gives the command that re-derives its numbers |
| `equivalence/` | the 28-module IR corpus, its reference `__tsan_*` histograms and per-configuration reach, read by `scripts/12-compiler-equivalence.sh` | `f3deebfbab60` | |
| `preservation/` | race reports per run for SQLite, memcached and FFmpeg under stock, sound and AllOpt; L1/L2/L3 keys | several, named per tree | `*/2026-09-17-shipped-f3deebfbab60/` is the tree `CLAIMS.md` section 1, last row, cites; `memcached-10k` excluded: a short-iteration client artefact |
| `preservation/{sqlite,memcached}/2026-09-21-nofe-amd-f3deebfbab60/` | the application check for the upstream flag: stock, `tsan-nofe` and AllOpt with peeling and the flag, N = 10, on the second host, with `verdict-L3.txt` (all three levels) and a README | `f3deebfbab60` | no site lost under the flag alone at any level on either application; AllOpt with peeling and the flag shows the same `conn_new` relocation as AllOpt with peeling without it (`CLAIMS.md` section 1, last row) |
| `eviction-stress/` | the synthetic bounded-shadow experiments, 1000 runs per cell | `f80e80b1dbe6` and earlier | `*.mod4-artefact` excluded: a sweep that sampled one residue class of a period-4 mechanism |
| `eviction-counters/` | per-granule eviction counters on SQLite | runtime `a08292850aee`, `43111f84d936` | `clock-samples.csv` excluded: a misleading three-CPU sampler |
| `tools/perf/` | `aggregate.py`, `report.py`, `results_ledger.py` and `RESULTS.md`, unchanged from the harness; `results` is a symlink to `../../perf` because the scripts locate trees relative to themselves | | |
| `tools/preservation/tsan_reports.py`, `tools/static_count_tsan_instrumentation.py` | report keys and the static instrumentation counter | | |
| `nosql/redis/`, `sql/sqlite/`, `projects/ffmpeg/` | the three per-application result parsers `aggregate.py` loads from these repo-shaped paths | | |
| `notes/preregistration-2026-09-13.md` | the pre-registration of the concurrency rule and the combinations leg | | |

Every performance run carries a `meta.json` with the binary's sha256, the compiler stamp, the CPU
set, the governor and turbo state, the load before and after, the foreign-CPU share and a
"disturbed" flag; `session.json` per leg records the host state. `tools/perf/RESULTS.md` is the
standing summary of what each configuration is worth, regenerated from these trees.

**Drift note.** Byte-identical Redis binaries measured on 8 Sep (Stage B) and on 14 Sep give stock
ThreadSanitizer 14% less throughput on the later date and native 5% less, so Stage B's Redis rows
and the repeat's disagree by up to 12 points. The cause was not found; `CLAIMS.md` states the condition
with every Redis row, and `docs/confounds.md` lists the hypotheses eliminated.
