# memcached: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=8b43fa2b8482 started=2026-09-22T18:57:50

| config | N | ops_sec median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 7.869e+06 (7.889e+06 ± 1.7e+05, 2.1 %) |
| tsan | 5 | 1.737e+06 (1.749e+06 ± 4.3e+04, 2.5 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 1.773e+06 (1.754e+06 ± 3.9e+04, 2.2 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.768e+06 (1.766e+06 ± 2.8e+04, 1.6 %) |
| tsan-stmt | 5 | 1.758e+06 (1.759e+06 ± 1.9e+04, 1.1 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 4.530 [4.239, 4.755] | — (single metric, pooled CV 2.0%) | — | 0 | pinned | ops_sec:4.53 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 2.0%) | 4.53 [4.24, 4.75] | 6748 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.021 [0.935, 1.054] | — (single metric, pooled CV 2.0%) | 4.44 [4.30, 4.76] | 7130 | pinned | ops_sec:1.02 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.018 [0.953, 1.063] | — (single metric, pooled CV 2.0%) | 4.45 [4.26, 4.67] | 7183 | pinned | ops_sec:1.02 |
| tsan-stmt | tsan-stmt | 5 | 1.012 [0.958, 1.053] | — (single metric, pooled CV 2.0%) | 4.48 [4.30, 4.65] | 6810 | pinned | ops_sec:1.01 |
