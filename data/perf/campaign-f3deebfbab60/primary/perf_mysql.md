# mysql: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-16T07:27:05

| config | N | oltp_read_only median (mean ± σ, CV) | oltp_read_write median (mean ± σ, CV) | oltp_write_only median (mean ± σ, CV) | select_random_points median (mean ± σ, CV) | select_random_ranges median (mean ± σ, CV) |
|---|---|---|---|---|---|---|
| orig | 5 | 1.221e+06 (1.23e+06 ± 8.4e+04, 6.8 %) | 1.19e+06 (1.184e+06 ± 4e+04, 3.4 %) | 1.563e+06 (1.543e+06 ± 5.2e+04, 3.4 %) | 4.588e+05 (4.648e+05 ± 1.7e+04, 3.6 %) | 8.81e+05 (8.902e+05 ± 2.1e+04, 2.3 %) |
| tsan | 5 | 1.212e+05 (1.235e+05 ± 6.2e+03, 5.0 %) | 1.146e+05 (1.155e+05 ± 5.5e+03, 4.8 %) | 1.346e+05 (1.346e+05 ± 1.3e+03, 0.9 %) | 5.486e+04 (5.451e+04 ± 9.5e+02, 1.7 %) | 1.043e+05 (1.046e+05 ± 2e+03, 1.9 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 1.339e+05 (1.286e+05 ± 8.7e+03, 6.8 %) | 1.213e+05 (1.195e+05 ± 4.1e+03, 3.4 %) | 1.363e+05 (1.358e+05 ± 1.2e+03, 0.9 %) | 5.572e+04 (5.578e+04 ± 8.4e+02, 1.5 %) | 1.065e+05 (1.068e+05 ± 1.8e+03, 1.6 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.327e+05 (1.292e+05 ± 7.3e+03, 5.6 %) | 1.203e+05 (1.184e+05 ± 3.9e+03, 3.3 %) | 1.344e+05 (1.344e+05 ± 5.7e+02, 0.4 %) | 5.276e+04 (5.261e+04 ± 1e+03, 1.9 %) | 1.035e+05 (1.028e+05 ± 1.3e+03, 1.3 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

**SU stable** repeats the speedup over the 4 of 5 subtests whose pooled run-to-run CV, taken over every configuration rather than off the baseline alone, is at most 5 %. The set is a property of the workload, not of a configuration, and applies to every row alike. Excluded here: `oltp_read_only` (pooled CV 6.1 %). Report the all-subtest column as the headline and this one as what the data can resolve.

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 9.699 [9.293, 10.082] | 9.609 [9.270, 9.970] | — | — | pinned | oltp_read_only:10.07, oltp_read_write:10.38, oltp_write_only:11.62, select_random_points:8.36, select_random_ranges:8.45 |
| tsan | tsan | 5 | — | — | 9.70 [9.29, 10.08] | — | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.042 [0.985, 1.062] | 1.027 [0.991, 1.052] | 9.31 [9.07, 9.89] | — | pinned | oltp_read_only:1.10, oltp_read_write:1.06, oltp_write_only:1.01, select_random_points:1.02, select_random_ranges:1.02 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.018 [0.967, 1.037] | 1.000 [0.964, 1.023] | 9.52 [9.26, 10.05] | — | pinned | oltp_read_only:1.09, oltp_read_write:1.05, oltp_write_only:1.00, select_random_points:0.96, select_random_ranges:0.99 |
