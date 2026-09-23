# sqlite: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=8da423a7f522 started=2026-09-23T00:41:36

| config | N | walthread1 median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 5312 (5284 ± 64, 1.2 %) |
| tsan | 5 | 2806 (2807 ± 14, 0.5 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 2816 (2820 ± 27, 0.9 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 2764 (2762 ± 15, 0.6 %) |
| tsan-stmt | 5 | 2739 (2740 ± 21, 0.8 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 1.893 [1.835, 1.914] | — (single metric, pooled CV 0.8%) | — | 0 | pinned | walthread1:1.89 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 0.8%) | 1.89 [1.84, 1.91] | 57996 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.004 [0.991, 1.028] | — (single metric, pooled CV 0.8%) | 1.89 [1.81, 1.91] | 61931 | pinned | walthread1:1.00 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.985 [0.970, 0.997] | — (single metric, pooled CV 0.8%) | 1.92 [1.87, 1.95] | 61897 | pinned | walthread1:0.99 |
| tsan-stmt | tsan-stmt | 5 | 0.976 [0.962, 0.994] | — (single metric, pooled CV 0.8%) | 1.94 [1.87, 1.96] | 57957 | pinned | walthread1:0.98 |
