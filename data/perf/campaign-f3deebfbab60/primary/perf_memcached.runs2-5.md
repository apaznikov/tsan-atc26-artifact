# memcached: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-15T20:43:15

| config | N | ops_sec median (mean ± σ, CV) |
|---|---|---|
| orig | 4 | 5.236e+06 (5.199e+06 ± 1.1e+05, 2.1 %) |
| tsan | 4 | 1.636e+06 (1.626e+06 ± 4.7e+04, 2.9 %) |
| tsan-dom | 4 | 1.646e+06 (1.651e+06 ± 3.7e+04, 2.2 %) |
| tsan-dom-ea-lo-st-swmr | 4 | 1.634e+06 (1.639e+06 ± 3.3e+04, 2.0 %) |
| tsan-dom_peeling | 4 | 1.619e+06 (1.614e+06 ± 2.2e+04, 1.4 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 4 | 1.674e+06 (1.662e+06 ± 3.3e+04, 2.0 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 4 | 1.674e+06 (1.673e+06 ± 4e+04, 2.4 %) |
| tsan-dom_peeling-ea-lo-st-swmr-wp | 4 | 1.67e+06 (1.676e+06 ± 4.6e+04, 2.7 %) |
| tsan-ea | 4 | 1.606e+06 (1.609e+06 ± 3e+04, 1.8 %) |
| tsan-lo | 4 | 1.633e+06 (1.644e+06 ± 4.5e+04, 2.7 %) |
| tsan-sound-wp | 4 | 1.674e+06 (1.664e+06 ± 4.3e+04, 2.6 %) |
| tsan-st | 4 | 1.679e+06 (1.664e+06 ± 3.8e+04, 2.3 %) |
| tsan-stmt | 4 | 1.618e+06 (1.624e+06 ± 2.5e+04, 1.6 %) |
| tsan-swmr | 4 | 1.639e+06 (1.64e+06 ± 6e+04, 3.6 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 4 | 3.201 (N=4, no interval; compare with the shipped interval) | — (single metric, pooled CV 2.4%) | — | — | pinned | ops_sec:3.20 |
| tsan | tsan | 4 | — | — (single metric, pooled CV 2.4%) | 3.20 (N=4, no interval; compare with the shipped interval) | — | pinned |  |
| tsan-dom | tsan-dom | 4 | 1.006 (N=4, no interval; compare with the shipped interval) | — (single metric, pooled CV 2.4%) | 3.18 (N=4, no interval; compare with the shipped interval) | — | pinned | ops_sec:1.01 |
| tsan-dom-ea-lo-st-swmr | AllOpt-peel | 4 | 0.999 (N=4, no interval; compare with the shipped interval) | — (single metric, pooled CV 2.4%) | 3.20 (N=4, no interval; compare with the shipped interval) | — | pinned | ops_sec:1.00 |
| tsan-dom_peeling | tsan-dom_peeling | 4 | 0.990 (N=4, no interval; compare with the shipped interval) | — (single metric, pooled CV 2.4%) | 3.23 (N=4, no interval; compare with the shipped interval) | — | pinned | ops_sec:0.99 |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 4 | 1.024 (N=4, no interval; compare with the shipped interval) | — (single metric, pooled CV 2.4%) | 3.13 (N=4, no interval; compare with the shipped interval) | — | pinned | ops_sec:1.02 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 4 | 1.023 (N=4, no interval; compare with the shipped interval) | — (single metric, pooled CV 2.4%) | 3.13 (N=4, no interval; compare with the shipped interval) | — | pinned | ops_sec:1.02 |
| tsan-dom_peeling-ea-lo-st-swmr-wp | AllOpt+peel (WP summaries) | 4 | 1.021 (N=4, no interval; compare with the shipped interval) | — (single metric, pooled CV 2.4%) | 3.14 (N=4, no interval; compare with the shipped interval) | — | pinned | ops_sec:1.02 |
| tsan-ea | tsan-ea | 4 | 0.982 (N=4, no interval; compare with the shipped interval) | — (single metric, pooled CV 2.4%) | 3.26 (N=4, no interval; compare with the shipped interval) | — | pinned | ops_sec:0.98 |
| tsan-lo | tsan-lo | 4 | 0.998 (N=4, no interval; compare with the shipped interval) | — (single metric, pooled CV 2.4%) | 3.21 (N=4, no interval; compare with the shipped interval) | — | pinned | ops_sec:1.00 |
| tsan-sound-wp | sound (WP summaries) | 4 | 1.023 (N=4, no interval; compare with the shipped interval) | — (single metric, pooled CV 2.4%) | 3.13 (N=4, no interval; compare with the shipped interval) | — | pinned | ops_sec:1.02 |
| tsan-st | tsan-st | 4 | 1.027 (N=4, no interval; compare with the shipped interval) | — (single metric, pooled CV 2.4%) | 3.12 (N=4, no interval; compare with the shipped interval) | — | pinned | ops_sec:1.03 |
| tsan-stmt | tsan-stmt | 4 | 0.989 (N=4, no interval; compare with the shipped interval) | — (single metric, pooled CV 2.4%) | 3.24 (N=4, no interval; compare with the shipped interval) | — | pinned | ops_sec:0.99 |
| tsan-swmr | tsan-swmr | 4 | 1.002 (N=4, no interval; compare with the shipped interval) | — (single metric, pooled CV 2.4%) | 3.19 (N=4, no interval; compare with the shipped interval) | — | pinned | ops_sec:1.00 |
