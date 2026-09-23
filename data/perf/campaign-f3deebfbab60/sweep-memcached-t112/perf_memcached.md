# memcached: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=04e81ef1077b started=2026-09-22T17:14:21

| config | N | ops_sec median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 6.351e+06 (6.317e+06 ± 6.1e+04, 1.0 %) |
| tsan | 5 | 1.133e+06 (1.094e+06 ± 7.7e+04, 7.0 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 1.129e+06 (1.103e+06 ± 6.1e+04, 5.5 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.141e+06 (1.126e+06 ± 6e+04, 5.4 %) |
| tsan-stmt | 5 | 1.02e+06 (1.04e+06 ± 7e+04, 6.7 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 5.603 [5.394, 6.426] | — (single metric, pooled CV 5.6%) | — | 0 | pinned | ops_sec:5.60 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 5.6%) | 5.60 [5.39, 6.43] | 6748 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 0.996 [0.891, 1.180] | — (single metric, pooled CV 5.6%) | 5.62 [5.35, 6.17] | 7130 | pinned | ops_sec:1.00 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.006 [0.884, 1.189] | — (single metric, pooled CV 5.6%) | 5.57 [5.31, 6.22] | 7183 | pinned | ops_sec:1.01 |
| tsan-stmt | tsan-stmt | 5 | 0.900 [0.842, 1.170] | — (single metric, pooled CV 5.6%) | 6.23 [5.39, 6.53] | 6810 | pinned | ops_sec:0.90 |
