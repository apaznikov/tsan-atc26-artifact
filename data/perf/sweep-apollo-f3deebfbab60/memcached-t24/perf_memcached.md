# memcached: performance (higher is better per test)

Session: mode=pinned cpuset=0-23,32-55 governor=schedutil no_turbo= host=deeef08b669c started=2026-09-22T14:39:54

| config | N | ops_sec median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 5.897e+06 (5.926e+06 ± 6e+04, 1.0 %) |
| tsan | 5 | 1.25e+06 (1.252e+06 ± 2.2e+04, 1.8 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 1.259e+06 (1.248e+06 ± 4.2e+04, 3.4 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.224e+06 (1.234e+06 ± 2.6e+04, 2.1 %) |
| tsan-stmt | 5 | 1.26e+06 (1.266e+06 ± 4.4e+04, 3.5 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 4.718 [4.584, 4.905] | — (single metric, pooled CV 2.5%) | — | 0 | pinned | ops_sec:4.72 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 2.5%) | 4.72 [4.58, 4.91] | 6748 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.008 [0.940, 1.055] | — (single metric, pooled CV 2.5%) | 4.68 [4.53, 5.00] | 7130 | pinned | ops_sec:1.01 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.979 [0.949, 1.042] | — (single metric, pooled CV 2.5%) | 4.82 [4.59, 4.95] | 7183 | pinned | ops_sec:0.98 |
| tsan-stmt | tsan-stmt | 5 | 1.008 [0.942, 1.081] | — (single metric, pooled CV 2.5%) | 4.68 [4.42, 4.99] | 6810 | pinned | ops_sec:1.01 |
