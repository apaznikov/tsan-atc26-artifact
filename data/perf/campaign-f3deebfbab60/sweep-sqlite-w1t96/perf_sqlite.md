# sqlite: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=4dd32bd61c64 started=2026-09-23T01:08:16

| config | N | walthread1 median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 5666 (5656 ± 52, 0.9 %) |
| tsan | 5 | 2915 (2908 ± 16, 0.5 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 2925 (2920 ± 14, 0.5 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 2868 (2868 ± 12, 0.4 %) |
| tsan-stmt | 5 | 2844 (2838 ± 11, 0.4 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 1.944 [1.904, 1.975] | — (single metric, pooled CV 0.6%) | — | 0 | pinned | walthread1:1.94 |
| tsan | tsan | 5 | — | — (single metric, pooled CV 0.6%) | 1.94 [1.90, 1.98] | 57996 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.003 [0.993, 1.016] | — (single metric, pooled CV 0.6%) | 1.94 [1.90, 1.96] | 61931 | pinned | walthread1:1.00 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.984 [0.975, 0.998] | — (single metric, pooled CV 0.6%) | 1.98 [1.93, 2.00] | 61897 | pinned | walthread1:0.98 |
| tsan-stmt | tsan-stmt | 5 | 0.976 [0.965, 0.986] | — (single metric, pooled CV 0.6%) | 1.99 [1.96, 2.02] | 57957 | pinned | walthread1:0.98 |
