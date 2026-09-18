# memcached: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-16T14:04:39

| config | N | ops_sec median (mean ± σ, CV) |
|---|---|---|
| orig | 4 | 5.104e+06 (5.09e+06 ± 7.8e+04, 1.5 %) |
| tsan | 4 | 9.989e+05 (1.025e+06 ± 5.8e+04, 5.6 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 4 | 1.025e+06 (1.047e+06 ± 7.2e+04, 6.9 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 4 | 1.051e+06 (1.048e+06 ± 6.8e+04, 6.5 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 4 | 5.110 (N=4, no interval; compare with the shipped interval) | — (single metric, pooled CV 5.6%) | — | — | pinned | ops_sec:5.11 |
| tsan | tsan | 4 | — | — (single metric, pooled CV 5.6%) | 5.11 (N=4, no interval; compare with the shipped interval) | — | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 4 | 1.026 (N=4, no interval; compare with the shipped interval) | — (single metric, pooled CV 5.6%) | 4.98 (N=4, no interval; compare with the shipped interval) | — | pinned | ops_sec:1.03 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 4 | 1.052 (N=4, no interval; compare with the shipped interval) | — (single metric, pooled CV 5.6%) | 4.86 (N=4, no interval; compare with the shipped interval) | — | pinned | ops_sec:1.05 |
