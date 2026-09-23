# memcached: performance (higher is better per test)

Session: mode=pinned cpuset=0-23,32-55 governor=schedutil no_turbo= host=ee4d3536d00c started=2026-09-22T12:34:13

| config | N | ops_sec median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 5.227e+06 (5.229e+06 ± 1.3e+05, 2.5 %) |
| tsan | 5 | 8.747e+05 (8.725e+05 ± 1.8e+04, 2.1 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 8.951e+05 (8.895e+05 ± 2.2e+04, 2.5 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 9.057e+05 (9.056e+05 ± 4.8e+03, 0.5 %) |
| tsan-stmt | 5 | 8.91e+05 (8.745e+05 ± 3.1e+04, 3.5 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 5.976 [5.700, 6.396] | — (single metric, pooled CV 2.4%) | — | 0 | pinned | ops_sec:5.98 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 2.4%) | 5.98 [5.70, 6.40] | 6748 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.023 [0.959, 1.077] | — (single metric, pooled CV 2.4%) | 5.84 [5.58, 6.33] | 7130 | pinned | ops_sec:1.02 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.035 [1.014, 1.085] | — (single metric, pooled CV 2.4%) | 5.77 [5.54, 5.98] | 7183 | pinned | ops_sec:1.04 |
| tsan-stmt | tsan-stmt | 5 | 1.019 [0.945, 1.071] | — (single metric, pooled CV 2.4%) | 5.87 [5.61, 6.42] | 6810 | pinned | ops_sec:1.02 |
