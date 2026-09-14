# memcached: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-09T06:06:57

| config | N | ops_sec median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 5.42e+06 (5.476e+06 ± 1.9e+05, 3.5 %) |
| tsan | 5 | 1.604e+06 (1.603e+06 ± 8.5e+03, 0.5 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 1.623e+06 (1.612e+06 ± 5.9e+04, 3.6 %) |
| tsan-dom_peeling-ea-lo-st-swmr-yoff | 5 | 1.63e+06 (1.615e+06 ± 2.9e+04, 1.8 %) |
| tsan-sound | 5 | 1.613e+06 (1.592e+06 ± 4.6e+04, 2.9 %) |
| tsan-sound-yoff | 5 | 1.613e+06 (1.613e+06 ± 2.8e+04, 1.8 %) |
| tsan-stmt | 5 | 1.601e+06 (1.587e+06 ± 2.6e+04, 1.7 %) |
| tsan-stmt-yoff | 5 | 1.609e+06 (1.591e+06 ± 5e+04, 3.1 %) |
| tsan-yoff | 5 | 1.636e+06 (1.621e+06 ± 2.8e+04, 1.8 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 3.378 [3.271, 3.590] | — | — | 0 | pinned | ops_sec:3.38 |
| tsan | tsan | 5 | — | — | 3.38 [3.27, 3.59] | 6748 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.012 [0.944, 1.059] | — | 3.34 [3.13, 3.75] | 7127 | pinned | ops_sec:1.01 |
| tsan-dom_peeling-ea-lo-st-swmr-yoff | tsan-dom_peeling-ea-lo-st-swmr-yoff | 5 | 1.016 [0.978, 1.031] | — | 3.33 [3.22, 3.62] | 7130 | pinned | ops_sec:1.02 |
| tsan-sound | tsan-sound | 5 | 1.005 [0.945, 1.026] | — | 3.36 [3.23, 3.75] | 6640 | pinned | ops_sec:1.01 |
| tsan-sound-yoff | tsan-sound-yoff | 5 | 1.006 [0.970, 1.031] | — | 3.36 [3.22, 3.65] | 6643 | pinned | ops_sec:1.01 |
| tsan-stmt | tsan-stmt | 5 | 0.998 [0.956, 1.008] | — | 3.39 [3.29, 3.70] | 6810 | pinned | ops_sec:1.00 |
| tsan-stmt-yoff | tsan-stmt-yoff | 5 | 1.003 [0.943, 1.026] | — | 3.37 [3.23, 3.75] | 6810 | pinned | ops_sec:1.00 |
| tsan-yoff | tsan-yoff | 5 | 1.019 [0.983, 1.034] | — | 3.31 [3.21, 3.60] | 6748 | pinned | ops_sec:1.02 |
