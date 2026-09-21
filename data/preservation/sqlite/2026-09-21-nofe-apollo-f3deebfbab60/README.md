# sqlite, N = 10, stock against the upstream flag `-tsan-instrument-func-entry-exit=false` (21 Sep 2026)

The application check behind the "Upstream flag (measured, not claimed)" section of `CLAIMS.md`. Run on the second
host (AMD EPYC 9115, 64 threads, Ubuntu 24.04) from a scratch clone of the artifact at `c280f2b`, inside the
artifact's own image (compiler `f3deebfbab60`, the manifest's `build_info` carries the exact flags of each
binary), with `scripts/31-preservation-apps.sh sqlite 10 --configs tsan-nofe,tsan-dom_peeling-ea-lo-st-swmr-nofe`
(stock is always built and run as the baseline). `verdict-L3.txt` is the verdict script's output over `logs/`,
all three levels printed, gating at L3; regenerate it with
`python3 data/tools/preservation/preservation_verdict.py --results-dir <this dir>/logs --app sqlite --baseline tsan`.
Same layout as `../2026-09-17-shipped-f3deebfbab60`.
