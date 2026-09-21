# memcached: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=ee905f4aa461 started=2026-09-21T16:26:33

| config | N | ops_sec median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 6.637e+06 (6.636e+06 ± 3.2e+04, 0.5 %) |
| tsan | 5 | 1.804e+06 (1.806e+06 ± 3.6e+04, 2.0 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 1.864e+06 (1.838e+06 ± 5.3e+04, 2.9 %) |
| tsan-dom_peeling-ea-lo-st-swmr-nofe | 5 | 1.838e+06 (1.805e+06 ± 6.5e+04, 3.6 %) |
| tsan-nofe | 5 | 1.803e+06 (1.779e+06 ± 5.4e+04, 3.0 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 3.680 [3.541, 3.774] | — (single metric, pooled CV 2.6%) | — | 0 | pinned | ops_sec:3.68 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 2.6%) | 3.68 [3.54, 3.77] | 6748 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.033 [0.945, 1.068] | — (single metric, pooled CV 2.6%) | 3.56 [3.49, 3.79] | 7130 | pinned | ops_sec:1.03 |
| tsan-dom_peeling-ea-lo-st-swmr-nofe | tsan-dom_peeling-ea-lo-st-swmr-nofe | 5 | 1.019 [0.925, 1.058] | — (single metric, pooled CV 2.6%) | 3.61 [3.52, 3.87] | 7130 | pinned | ops_sec:1.02 |
| tsan-nofe | tsan-nofe | 5 | 1.000 [0.914, 1.040] | — (single metric, pooled CV 2.6%) | 3.68 [3.59, 3.92] | 6748 | pinned | ops_sec:1.00 |
