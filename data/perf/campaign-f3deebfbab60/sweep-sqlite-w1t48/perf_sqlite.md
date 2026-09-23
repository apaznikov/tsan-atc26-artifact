# sqlite: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=a94af9e6d386 started=2026-09-23T00:54:55

| config | N | walthread1 median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 5468 (5454 ± 93, 1.7 %) |
| tsan | 5 | 2833 (2833 ± 16, 0.6 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 2847 (2854 ± 14, 0.5 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 2806 (2804 ± 9.7, 0.3 %) |
| tsan-stmt | 5 | 2777 (2776 ± 6.6, 0.2 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 1.930 [1.859, 1.967] | — (single metric, pooled CV 0.9%) | — | 0 | pinned | walthread1:1.93 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 0.9%) | 1.93 [1.86, 1.97] | 57996 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.005 [0.994, 1.021] | — (single metric, pooled CV 0.9%) | 1.92 [1.85, 1.95] | 61931 | pinned | walthread1:1.00 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.990 [0.976, 0.999] | — (single metric, pooled CV 0.9%) | 1.95 [1.89, 1.99] | 61897 | pinned | walthread1:0.99 |
| tsan-stmt | tsan-stmt | 5 | 0.980 [0.968, 0.989] | — (single metric, pooled CV 0.9%) | 1.97 [1.91, 2.00] | 57957 | pinned | walthread1:0.98 |
