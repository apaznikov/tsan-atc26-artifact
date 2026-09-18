# memcached: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-16T14:04:39

| config | N | ops_sec median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 5.116e+06 (5.095e+06 ± 6.9e+04, 1.3 %) |
| tsan | 5 | 1.001e+06 (1.026e+06 ± 5e+04, 4.9 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 1.007e+06 (1.037e+06 ± 6.7e+04, 6.4 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.09e+06 (1.061e+06 ± 6.6e+04, 6.2 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 5.110 [4.485, 5.216] | — (single metric, pooled CV 5.1%) | — | — | pinned | ops_sec:5.11 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 5.1%) | 5.11 [4.48, 5.22] | — | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.006 [0.890, 1.161] | — (single metric, pooled CV 5.1%) | 5.08 [4.33, 5.22] | — | pinned | ops_sec:1.01 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.089 [0.875, 1.129] | — (single metric, pooled CV 5.1%) | 4.69 [4.46, 5.32] | — | pinned | ops_sec:1.09 |
