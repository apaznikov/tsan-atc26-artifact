# mysql: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-16T15:26:54

| config | N | oltp_read_only median (mean ± σ, CV) | oltp_read_write median (mean ± σ, CV) | oltp_write_only median (mean ± σ, CV) | select_random_points median (mean ± σ, CV) | select_random_ranges median (mean ± σ, CV) |
|---|---|---|---|---|---|---|
| orig | 4 | 1.002e+06 (1.038e+06 ± 8.3e+04, 8.0 %) | 7.359e+05 (7.359e+05 ± 4.5e+04, 6.1 %) | 1.324e+06 (1.32e+06 ± 6.3e+04, 4.8 %) | 4.041e+05 (4.107e+05 ± 1.6e+04, 3.9 %) | 8.992e+05 (8.979e+05 ± 1.8e+04, 2.0 %) |
| tsan | 4 | 1.232e+05 (1.234e+05 ± 7.8e+03, 6.3 %) | 7.645e+04 (7.655e+04 ± 2e+03, 2.6 %) | 1.177e+05 (1.177e+05 ± 6.8e+02, 0.6 %) | 5.319e+04 (5.294e+04 ± 1.2e+03, 2.3 %) | 1.099e+05 (1.104e+05 ± 2.2e+03, 2.0 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 4 | 1.255e+05 (1.246e+05 ± 8e+03, 6.4 %) | 7.802e+04 (7.825e+04 ± 1.6e+03, 2.1 %) | 1.205e+05 (1.207e+05 ± 2e+03, 1.7 %) | 5.358e+04 (5.346e+04 ± 5.4e+02, 1.0 %) | 1.129e+05 (1.128e+05 ± 3e+03, 2.7 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 4 | 1.298e+05 (1.292e+05 ± 1.9e+03, 1.5 %) | 7.563e+04 (7.586e+04 ± 1.1e+03, 1.4 %) | 1.192e+05 (1.188e+05 ± 1.3e+03, 1.1 %) | 5.169e+04 (5.175e+04 ± 5.1e+02, 1.0 %) | 1.087e+05 (1.087e+05 ± 1.7e+03, 1.6 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

**SU stable** repeats the speedup over the 4 of 5 subtests whose pooled run-to-run CV, taken over every configuration rather than off the baseline alone, is at most 5 %. The set is a property of the workload, not of a configuration, and applies to every row alike. Excluded here: `oltp_read_only` (pooled CV 6.1 %). Report the all-subtest column as the headline and this one as what the data can resolve.

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 4 | 8.866 (N=4, no interval; compare with the shipped interval) | 9.058 (N=4, no interval; compare with the shipped interval) | — | — | pinned | oltp_read_only:8.14, oltp_read_write:9.63, oltp_write_only:11.25, select_random_points:7.60, select_random_ranges:8.18 |
| tsan | tsan | 4 | — | — | 8.87 (N=4, no interval; compare with the shipped interval) | — | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 4 | 1.019 (N=4, no interval; compare with the shipped interval) | 1.020 (N=4, no interval; compare with the shipped interval) | 8.70 (N=4, no interval; compare with the shipped interval) | — | pinned | oltp_read_only:1.02, oltp_read_write:1.02, oltp_write_only:1.02, select_random_points:1.01, select_random_ranges:1.03 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 4 | 1.003 (N=4, no interval; compare with the shipped interval) | 0.991 (N=4, no interval; compare with the shipped interval) | 8.84 (N=4, no interval; compare with the shipped interval) | — | pinned | oltp_read_only:1.05, oltp_read_write:0.99, oltp_write_only:1.01, select_random_points:0.97, select_random_ranges:0.99 |
