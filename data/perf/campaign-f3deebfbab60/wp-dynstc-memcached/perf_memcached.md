# memcached: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=fb6150aba554 started=2026-09-22T14:27:22

| config | N | ops_sec median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 6.62e+06 (6.651e+06 ± 1.5e+05, 2.2 %) |
| tsan | 5 | 1.801e+06 (1.807e+06 ± 1.8e+04, 1.0 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.785e+06 (1.79e+06 ± 6.2e+04, 3.5 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt-wp | 5 | 1.809e+06 (1.796e+06 ± 3.7e+04, 2.0 %) |
| tsan-dom_peeling-ea-lo-st-swmr-wp | 5 | 1.802e+06 (1.799e+06 ± 6e+04, 3.4 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 3.675 [3.523, 3.821] | — (single metric, pooled CV 2.6%) | — | 0 | pinned | ops_sec:3.68 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 2.6%) | 3.68 [3.52, 3.82] | 6748 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.991 [0.930, 1.036] | — (single metric, pooled CV 2.6%) | 3.71 [3.49, 4.01] | 7183 | pinned | ops_sec:0.99 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt-wp | AllOpt+peel+DynSTC (WP summaries) | 5 | 1.004 [0.950, 1.028] | — (single metric, pooled CV 2.6%) | 3.66 [3.51, 3.92] | 6743 | pinned | ops_sec:1.00 |
| tsan-dom_peeling-ea-lo-st-swmr-wp | AllOpt+peel (WP summaries) | 5 | 1.000 [0.935, 1.046] | — (single metric, pooled CV 2.6%) | 3.67 [3.45, 3.99] | 6699 | pinned | ops_sec:1.00 |
