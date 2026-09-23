# memcached: performance (higher is better per test)

Session: mode=pinned cpuset=0-23,32-55 governor=schedutil no_turbo= host=745f6c1b110b started=2026-09-22T09:07:29

| config | N | ops_sec median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 5.435e+06 (5.488e+06 ± 3.1e+05, 5.7 %) |
| tsan | 5 | 1.347e+06 (1.357e+06 ± 2.4e+04, 1.8 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 1.354e+06 (1.358e+06 ± 1.6e+04, 1.2 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.343e+06 (1.351e+06 ± 2.5e+04, 1.8 %) |
| tsan-stmt | 5 | 1.373e+06 (1.377e+06 ± 1.2e+04, 0.8 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 4.036 [3.685, 4.429] | — (single metric, pooled CV 2.9%) | — | 0 | pinned | ops_sec:4.04 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 2.9%) | 4.04 [3.69, 4.43] | 6748 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.005 [0.960, 1.037] | — (single metric, pooled CV 2.9%) | 4.02 [3.72, 4.41] | 7130 | pinned | ops_sec:1.01 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.997 [0.947, 1.038] | — (single metric, pooled CV 2.9%) | 4.05 [3.72, 4.47] | 7183 | pinned | ops_sec:1.00 |
| tsan-stmt | tsan-stmt | 5 | 1.019 [0.976, 1.043] | — (single metric, pooled CV 2.9%) | 3.96 [3.70, 4.34] | 6810 | pinned | ops_sec:1.02 |
