# memcached: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=195f003deb64 started=2026-09-22T15:35:54

| config | N | ops_sec median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 6.3e+06 (6.283e+06 ± 8.1e+04, 1.3 %) |
| tsan | 5 | 1.216e+06 (1.22e+06 ± 8.7e+04, 7.1 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 1.292e+06 (1.28e+06 ± 7.2e+04, 5.6 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.192e+06 (1.205e+06 ± 5.7e+04, 4.7 %) |
| tsan-stmt | 5 | 1.184e+06 (1.208e+06 ± 7.2e+04, 5.9 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 5.179 [4.581, 5.614] | — (single metric, pooled CV 5.3%) | — | 0 | pinned | ops_sec:5.18 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 5.3%) | 5.18 [4.58, 5.61] | 6748 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.063 [0.864, 1.200] | — (single metric, pooled CV 5.3%) | 4.87 [4.55, 5.45] | 7130 | pinned | ops_sec:1.06 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.980 [0.848, 1.117] | — (single metric, pooled CV 5.3%) | 5.28 [4.88, 5.56] | 7183 | pinned | ops_sec:0.98 |
| tsan-stmt | tsan-stmt | 5 | 0.974 [0.837, 1.144] | — (single metric, pooled CV 5.3%) | 5.32 [4.77, 5.63] | 6810 | pinned | ops_sec:0.97 |
