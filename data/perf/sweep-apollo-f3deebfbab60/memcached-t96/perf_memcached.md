# memcached: performance (higher is better per test)

Session: mode=pinned cpuset=0-23,32-55 governor=schedutil no_turbo= host=dd937d2eefd9 started=2026-09-22T10:35:29

| config | N | ops_sec median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 5.301e+06 (5.311e+06 ± 1.4e+05, 2.6 %) |
| tsan | 5 | 1.013e+06 (1.001e+06 ± 3.5e+04, 3.5 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 1.008e+06 (1.004e+06 ± 2.2e+04, 2.2 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.041e+06 (1.034e+06 ± 2.6e+04, 2.5 %) |
| tsan-stmt | 5 | 1.018e+06 (1.009e+06 ± 2.7e+04, 2.7 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 5.231 [4.946, 5.781] | — (single metric, pooled CV 2.7%) | — | 0 | pinned | ops_sec:5.23 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 2.7%) | 5.23 [4.95, 5.78] | 6748 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 0.995 [0.930, 1.076] | — (single metric, pooled CV 2.7%) | 5.26 [5.02, 5.69] | 7130 | pinned | ops_sec:0.99 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.027 [0.960, 1.118] | — (single metric, pooled CV 2.7%) | 5.09 [4.83, 5.52] | 7183 | pinned | ops_sec:1.03 |
| tsan-stmt | tsan-stmt | 5 | 1.005 [0.925, 1.080] | — (single metric, pooled CV 2.7%) | 5.21 [5.00, 5.73] | 6810 | pinned | ops_sec:1.01 |
