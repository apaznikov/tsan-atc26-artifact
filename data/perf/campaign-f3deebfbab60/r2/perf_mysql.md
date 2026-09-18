# mysql: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-16T15:26:54

| config | N | oltp_read_only median (mean ± σ, CV) | oltp_read_write median (mean ± σ, CV) | oltp_write_only median (mean ± σ, CV) | select_random_points median (mean ± σ, CV) | select_random_ranges median (mean ± σ, CV) |
|---|---|---|---|---|---|---|
| orig | 5 | 1.012e+06 (1.054e+06 ± 8e+04, 7.6 %) | 7.059e+05 (7.299e+05 ± 4.1e+04, 5.6 %) | 1.349e+06 (1.326e+06 ± 5.6e+04, 4.2 %) | 4.074e+05 (4.138e+05 ± 1.6e+04, 3.8 %) | 8.949e+05 (8.96e+05 ± 1.6e+04, 1.8 %) |
| tsan | 5 | 1.288e+05 (1.245e+05 ± 7.2e+03, 5.8 %) | 7.579e+04 (7.632e+04 ± 1.8e+03, 2.4 %) | 1.18e+05 (1.181e+05 ± 9.6e+02, 0.8 %) | 5.287e+04 (5.293e+04 ± 1e+03, 2.0 %) | 1.111e+05 (1.11e+05 ± 2.3e+03, 2.1 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 1.302e+05 (1.257e+05 ± 7.3e+03, 5.8 %) | 7.746e+04 (7.764e+04 ± 2e+03, 2.5 %) | 1.193e+05 (1.204e+05 ± 1.9e+03, 1.6 %) | 5.364e+04 (5.36e+04 ± 5.6e+02, 1.0 %) | 1.104e+05 (1.118e+05 ± 3.4e+03, 3.0 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.296e+05 (1.271e+05 ± 5e+03, 3.9 %) | 7.604e+04 (7.606e+04 ± 1e+03, 1.4 %) | 1.192e+05 (1.189e+05 ± 1.1e+03, 0.9 %) | 5.147e+04 (5.169e+04 ± 4.6e+02, 0.9 %) | 1.076e+05 (1.08e+05 ± 2.1e+03, 1.9 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

**SU stable** repeats the speedup over the 4 of 5 subtests whose pooled run-to-run CV, taken over every configuration rather than off the baseline alone, is at most 5 %. The set is a property of the workload, not of a configuration, and applies to every row alike. Excluded here: `oltp_read_only` (pooled CV 5.9 %). Report the all-subtest column as the headline and this one as what the data can resolve.

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 8.772 [8.560, 9.368] | 9.017 [8.739, 9.425] | — | — | pinned | oltp_read_only:7.86, oltp_read_write:9.31, oltp_write_only:11.43, select_random_points:7.71, select_random_ranges:8.06 |
| tsan | tsan | 5 | — | — | 8.77 [8.56, 9.37] | — | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.011 [0.978, 1.049] | 1.010 [0.989, 1.040] | 8.68 [8.43, 9.26] | — | pinned | oltp_read_only:1.01, oltp_read_write:1.02, oltp_write_only:1.01, select_random_points:1.01, select_random_ranges:0.99 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.992 [0.966, 1.023] | 0.989 [0.968, 1.008] | 8.84 [8.64, 9.39] | — | pinned | oltp_read_only:1.01, oltp_read_write:1.00, oltp_write_only:1.01, select_random_points:0.97, select_random_ranges:0.97 |
