# sqlite: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=d7af364ce939 started=2026-09-23T01:21:55

| config | N | walthread1 median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 5683 (5669 ± 41, 0.7 %) |
| tsan | 5 | 2929 (2924 ± 10, 0.3 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 2956 (2953 ± 14, 0.5 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 2903 (2902 ± 14, 0.5 %) |
| tsan-stmt | 5 | 2870 (2876 ± 9.8, 0.3 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 1.940 [1.913, 1.966] | — (single metric, pooled CV 0.5%) | — | 0 | pinned | walthread1:1.94 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 0.5%) | 1.94 [1.91, 1.97] | 57996 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.009 [1.000, 1.020] | — (single metric, pooled CV 0.5%) | 1.92 [1.89, 1.95] | 61931 | pinned | walthread1:1.01 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.991 [0.983, 1.005] | — (single metric, pooled CV 0.5%) | 1.96 [1.92, 1.98] | 61897 | pinned | walthread1:0.99 |
| tsan-stmt | tsan-stmt | 5 | 0.980 [0.978, 0.994] | — (single metric, pooled CV 0.5%) | 1.98 [1.94, 1.99] | 57957 | pinned | walthread1:0.98 |
