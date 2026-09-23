# sqlite: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=c1c6e4cea265 started=2026-09-23T00:15:15

| config | N | walthread1 median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 4910 (4854 ± 1.1e+02, 2.3 %) |
| tsan | 5 | 2677 (2680 ± 19, 0.7 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 2692 (2695 ± 9.8, 0.4 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 2641 (2656 ± 32, 1.2 %) |
| tsan-stmt | 5 | 2639 (2631 ± 19, 0.7 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 1.834 [1.740, 1.861] | — (single metric, pooled CV 1.2%) | — | 0 | pinned | walthread1:1.83 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 1.2%) | 1.83 [1.74, 1.86] | 57996 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.006 [0.992, 1.021] | — (single metric, pooled CV 1.2%) | 1.82 [1.74, 1.84] | 61931 | pinned | walthread1:1.01 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.987 [0.971, 1.019] | — (single metric, pooled CV 1.2%) | 1.86 [1.74, 1.88] | 61897 | pinned | walthread1:0.99 |
| tsan-stmt | tsan-stmt | 5 | 0.986 [0.959, 0.996] | — (single metric, pooled CV 1.2%) | 1.86 [1.78, 1.90] | 57957 | pinned | walthread1:0.99 |
