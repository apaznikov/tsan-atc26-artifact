# mysql: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-16T07:27:05

| config | N | oltp_read_only median (mean ± σ, CV) | oltp_read_write median (mean ± σ, CV) | oltp_write_only median (mean ± σ, CV) | select_random_points median (mean ± σ, CV) | select_random_ranges median (mean ± σ, CV) |
|---|---|---|---|---|---|---|
| orig | 4 | 1.19e+06 (1.199e+06 ± 5.3e+04, 4.4 %) | 1.191e+06 (1.193e+06 ± 4.1e+04, 3.4 %) | 1.574e+06 (1.554e+06 ± 5.3e+04, 3.4 %) | 4.557e+05 (4.601e+05 ± 1.5e+04, 3.2 %) | 8.793e+05 (8.857e+05 ± 2.1e+04, 2.4 %) |
| tsan | 4 | 1.21e+05 (1.237e+05 ± 7.1e+03, 5.8 %) | 1.177e+05 (1.164e+05 ± 6e+03, 5.1 %) | 1.351e+05 (1.348e+05 ± 1.3e+03, 1.0 %) | 5.43e+04 (5.43e+04 ± 9.4e+02, 1.7 %) | 1.036e+05 (1.038e+05 ± 1.3e+03, 1.2 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 4 | 1.277e+05 (1.269e+05 ± 8.9e+03, 7.0 %) | 1.184e+05 (1.184e+05 ± 3.8e+03, 3.2 %) | 1.365e+05 (1.361e+05 ± 1.1e+03, 0.8 %) | 5.54e+04 (5.547e+04 ± 5.4e+02, 1.0 %) | 1.069e+05 (1.068e+05 ± 2e+03, 1.9 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 4 | 1.335e+05 (1.314e+05 ± 6.2e+03, 4.7 %) | 1.177e+05 (1.173e+05 ± 3.7e+03, 3.2 %) | 1.341e+05 (1.343e+05 ± 4.8e+02, 0.4 %) | 5.239e+04 (5.257e+04 ± 1.2e+03, 2.2 %) | 1.025e+05 (1.025e+05 ± 1.2e+03, 1.2 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

**SU stable** repeats the speedup over the 4 of 5 subtests whose pooled run-to-run CV, taken over every configuration rather than off the baseline alone, is at most 5 %. The set is a property of the workload, not of a configuration, and applies to every row alike. Excluded here: `oltp_read_only` (pooled CV 5.6 %). Report the all-subtest column as the headline and this one as what the data can resolve.

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 4 | 9.627 (N=4, no interval; compare with the shipped interval) | 9.575 (N=4, no interval; compare with the shipped interval) | — | — | pinned | oltp_read_only:9.84, oltp_read_write:10.12, oltp_write_only:11.65, select_random_points:8.39, select_random_ranges:8.49 |
| tsan | tsan | 4 | — | — | 9.63 (N=4, no interval; compare with the shipped interval) | — | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 4 | 1.025 (N=4, no interval; compare with the shipped interval) | 1.017 (N=4, no interval; compare with the shipped interval) | 9.39 (N=4, no interval; compare with the shipped interval) | — | pinned | oltp_read_only:1.06, oltp_read_write:1.01, oltp_write_only:1.01, select_random_points:1.02, select_random_ranges:1.03 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 4 | 1.009 (N=4, no interval; compare with the shipped interval) | 0.987 (N=4, no interval; compare with the shipped interval) | 9.54 (N=4, no interval; compare with the shipped interval) | — | pinned | oltp_read_only:1.10, oltp_read_write:1.00, oltp_write_only:0.99, select_random_points:0.96, select_random_ranges:0.99 |
