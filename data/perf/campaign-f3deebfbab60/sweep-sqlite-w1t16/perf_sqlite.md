# sqlite: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=0125dd88a990 started=2026-09-23T00:28:24

| config | N | walthread1 median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 5051 (4995 ± 1.2e+02, 2.5 %) |
| tsan | 5 | 2728 (2736 ± 20, 0.7 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 2734 (2734 ± 24, 0.9 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 2685 (2688 ± 14, 0.5 %) |
| tsan-stmt | 5 | 2694 (2686 ± 13, 0.5 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 1.852 [1.747, 1.887] | — (single metric, pooled CV 1.3%) | — | 0 | pinned | walthread1:1.85 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 1.3%) | 1.85 [1.75, 1.89] | 57996 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.002 [0.977, 1.014] | — (single metric, pooled CV 1.3%) | 1.85 [1.75, 1.90] | 61931 | pinned | walthread1:1.00 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.984 [0.964, 0.995] | — (single metric, pooled CV 1.3%) | 1.88 [1.79, 1.92] | 61897 | pinned | walthread1:0.98 |
| tsan-stmt | tsan-stmt | 5 | 0.988 [0.962, 0.990] | — (single metric, pooled CV 1.3%) | 1.87 [1.79, 1.93] | 57957 | pinned | walthread1:0.99 |
