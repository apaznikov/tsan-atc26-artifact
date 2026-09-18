# memcached: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-15T20:43:15

| config | N | ops_sec median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 5.276e+06 (5.221e+06 ± 1.1e+05, 2.1 %) |
| tsan | 5 | 1.647e+06 (1.64e+06 ± 5.2e+04, 3.1 %) |
| tsan-dom | 5 | 1.625e+06 (1.638e+06 ± 4.3e+04, 2.6 %) |
| tsan-dom-ea-lo-st-swmr | 5 | 1.625e+06 (1.63e+06 ± 3.5e+04, 2.1 %) |
| tsan-dom_peeling | 5 | 1.631e+06 (1.627e+06 ± 3.6e+04, 2.2 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 1.678e+06 (1.665e+06 ± 2.9e+04, 1.8 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.652e+06 (1.666e+06 ± 3.8e+04, 2.3 %) |
| tsan-dom_peeling-ea-lo-st-swmr-wp | 5 | 1.686e+06 (1.679e+06 ± 4e+04, 2.4 %) |
| tsan-ea | 5 | 1.629e+06 (1.619e+06 ± 3.5e+04, 2.2 %) |
| tsan-lo | 5 | 1.653e+06 (1.647e+06 ± 3.9e+04, 2.4 %) |
| tsan-sound-wp | 5 | 1.656e+06 (1.662e+06 ± 3.7e+04, 2.2 %) |
| tsan-st | 5 | 1.674e+06 (1.661e+06 ± 3.3e+04, 2.0 %) |
| tsan-stmt | 5 | 1.624e+06 (1.625e+06 ± 2.2e+04, 1.4 %) |
| tsan-swmr | 5 | 1.681e+06 (1.65e+06 ± 5.6e+04, 3.4 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 3.203 [2.972, 3.400] | — (single metric, pooled CV 2.4%) | — | — | pinned | ops_sec:3.20 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 2.4%) | 3.20 [2.97, 3.40] | — | pinned |  |
| tsan-dom | tsan-dom | 5 | 0.986 [0.935, 1.085] | — (single metric, pooled CV 2.4%) | 3.25 [2.98, 3.35] | — | pinned | ops_sec:0.99 |
| tsan-dom-ea-lo-st-swmr | AllOpt-peel | 5 | 0.986 [0.940, 1.078] | — (single metric, pooled CV 2.4%) | 3.25 [3.00, 3.33] | — | pinned | ops_sec:0.99 |
| tsan-dom_peeling | tsan-dom_peeling | 5 | 0.990 [0.934, 1.077] | — (single metric, pooled CV 2.4%) | 3.24 [3.00, 3.35] | — | pinned | ops_sec:0.99 |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.019 [0.951, 1.079] | — (single metric, pooled CV 2.4%) | 3.14 [2.99, 3.29] | — | pinned | ops_sec:1.02 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.003 [0.961, 1.099] | — (single metric, pooled CV 2.4%) | 3.19 [2.94, 3.26] | — | pinned | ops_sec:1.00 |
| tsan-dom_peeling-ea-lo-st-swmr-wp | AllOpt+peel (WP summaries) | 5 | 1.023 [0.961, 1.112] | — (single metric, pooled CV 2.4%) | 3.13 [2.90, 3.26] | — | pinned | ops_sec:1.02 |
| tsan-ea | tsan-ea | 5 | 0.989 [0.933, 1.064] | — (single metric, pooled CV 2.4%) | 3.24 [3.03, 3.35] | — | pinned | ops_sec:0.99 |
| tsan-lo | tsan-lo | 5 | 1.003 [0.946, 1.090] | — (single metric, pooled CV 2.4%) | 3.19 [2.96, 3.31] | — | pinned | ops_sec:1.00 |
| tsan-sound-wp | sound (WP summaries) | 5 | 1.005 [0.947, 1.089] | — (single metric, pooled CV 2.4%) | 3.19 [2.97, 3.30] | — | pinned | ops_sec:1.01 |
| tsan-st | tsan-st | 5 | 1.016 [0.948, 1.082] | — (single metric, pooled CV 2.4%) | 3.15 [2.98, 3.30] | — | pinned | ops_sec:1.02 |
| tsan-stmt | tsan-stmt | 5 | 0.986 [0.944, 1.063] | — (single metric, pooled CV 2.4%) | 3.25 [3.04, 3.31] | — | pinned | ops_sec:0.99 |
| tsan-swmr | tsan-swmr | 5 | 1.020 [0.932, 1.089] | — (single metric, pooled CV 2.4%) | 3.14 [2.96, 3.36] | — | pinned | ops_sec:1.02 |
