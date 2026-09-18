# Recorded data

Every run the paper's tables rest on, as recorded, plus the scripts that turn them into tables.
`scripts/90-tables.sh` regenerates every table from here without running anything, and fails if any
shipped table does not follow from its shipped runs.

Two things to know before reading a run's metadata. The trees below `perf/campaign-f3deebfbab60/` are
the ones every claim rests on; every other tree predates the shipped compiler and supports no claim,
which `scripts/91-verify-provenance.sh` states per tree. And each run records the absolute paths of the
machine that produced it, including this lab's home directories, because a run's provenance is what it
was rather than what it would look like elsewhere; nothing reads those paths back.

| Directory | What it is | Compiler | Notes |
|---|---|---|---|
| `perf/campaign-f3deebfbab60/primary/`, `perf/campaign-f3deebfbab60/r2/` | **the campaign every performance claim rests on**: five applications, up to 14 configurations, N = 5, pinned 48 CPUs, run-major, 15-17 Sep 2026. 290 and 110 measured runs | `f3deebfbab60` | the roots `CLAIMS.md` section 5 cites; `scripts/91-verify-provenance.sh` checks them strictly |
| `perf/ffmpeg-threadsweep-f3deebfbab60/` | the FFmpeg thread sweep on the reference clip: 2, 4, 8 and 16 encoder threads, four configurations, N = 5 | `f3deebfbab60` | checked strictly too |
| `perf/compile-time-memcached-f3deebfbab60/` | the compile-time control on memcached | `f3deebfbab60` | the build is ten seconds, so the control reports that the resolution is worse than the effect |
| `perf/stageB-d3bf9f8c39fe/` | the earlier campaign, superseded by the one above and shipped as data: five applications, 14 configurations, N = 5, pinned 48 CPUs, run-major: five applications, 14 configurations, N = 5, pinned 48 CPUs, run-major | `d3bf9f8c39fe` | measured 8-9 Sep 2026; see the drift note below |
| `perf/contention-d3bf9f8c39fe/` | the concurrency sweep: SQLite walthread1 2-112 threads, Redis 50-512 clients, FFmpeg 2-16 threads, four configurations, N = 5 | `d3bf9f8c39fe` | 13-14 Sep; each comparison is within one window |
| `perf/redis-recheck-2026-09-14/`, `perf/redis-stageB-repeat-2026-09-14/` | the same Redis binaries as Stage B, re-measured six days later | `d3bf9f8c39fe` | the baseline drift evidence |
| `perf/nofe-d3bf9f8c39fe/` | the upstream `-tsan-instrument-func-entry-exit=false` flag, measured for completeness | `d3bf9f8c39fe` | not a contribution of the paper and not in its tables |
| `perf/merge-timing-*`, `perf/yield-*`, `perf/profile-2026-09-09*`, `perf/combo-counters/`, `perf/merge-counters/` | the trees the results ledger reads: granule-merge timing, the yield branch, where instrumented cycles go, executed-access counters, dynamic reach | as named | shipped so `results_ledger.py` regenerates every section of the ledger; `perf.data` excluded |
| `preservation/` | race reports per run for SQLite, memcached, FFmpeg, Redis under stock, sound and AllOpt; L1/L2/L3 keys | several, named per tree | `memcached-10k` excluded: a short-iteration client artefact |
| `eviction-stress/` | the synthetic bounded-shadow experiments, 1000 runs per cell | `f80e80b1dbe6` and earlier | `*.mod4-artefact` excluded: a sweep that sampled one residue class of a period-4 mechanism |
| `eviction-counters/` | per-granule eviction counters on SQLite | runtime `a08292850aee`, `43111f84d936` | `clock-samples.csv` excluded: a misleading three-CPU sampler |
| `tools/perf/` | `aggregate.py`, `report.py`, `results_ledger.py` and `RESULTS.md`, unchanged from the harness; `results` is a symlink to `../../perf` because the scripts locate trees relative to themselves | | |
| `tools/preservation/tsan_reports.py`, `tools/static_count_tsan_instrumentation.py` | report keys and the static instrumentation counter | | |
| `nosql/redis/`, `sql/sqlite/`, `projects/ffmpeg/` | the three per-application result parsers `aggregate.py` loads from these repo-shaped paths | | |
| `notes/` | the pre-registration, the campaign definition, the run-1 note, the March provenance note, the L1/L2/L3 preservation table and the method document | | |

Every performance run carries a `meta.json` with the binary's sha256, the compiler stamp, the CPU
set, the governor and turbo state, the load before and after, the foreign-CPU share and a
"disturbed" flag; `session.json` per leg records the host state. `tools/perf/RESULTS.md` is the
standing summary of what each configuration is worth, regenerated from these trees.

**Drift note.** Byte-identical Redis binaries measured on 8 Sep (Stage B) and on 14 Sep give stock
ThreadSanitizer 14% less throughput on the later date and native 5% less, so Stage B's Redis rows
and the repeat's disagree by up to 12 points. The cause was under investigation when this snapshot
was taken; `notes/run1-cold-start-2026-09-13.md` has the eliminated hypotheses. Which set the paper
reports, and the clean re-measurement that replaces Stage B, are stated in `CLAIMS.md`.
