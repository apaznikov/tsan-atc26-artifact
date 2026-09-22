# mysql: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=8c5f1a231d57 started=2026-09-22T04:16:56

| config | N | oltp_read_only median (mean ± σ, CV) | oltp_read_write median (mean ± σ, CV) | oltp_write_only median (mean ± σ, CV) | select_random_points median (mean ± σ, CV) | select_random_ranges median (mean ± σ, CV) |
|---|---|---|---|---|---|---|
| orig | 5 | 1.377e+06 (1.326e+06 ± 1.3e+05, 9.5 %) | 1.185e+06 (1.176e+06 ± 5.7e+04, 4.9 %) | 1.577e+06 (1.538e+06 ± 8.9e+04, 5.8 %) | 4.778e+05 (4.727e+05 ± 1e+04, 2.2 %) | 8.888e+05 (9.107e+05 ± 4.3e+04, 4.7 %) |
| tsan | 5 | 1.344e+05 (1.284e+05 ± 9.4e+03, 7.3 %) | 1.178e+05 (1.177e+05 ± 3.1e+03, 2.7 %) | 1.315e+05 (1.304e+05 ± 3.2e+03, 2.4 %) | 5.393e+04 (5.36e+04 ± 1.3e+03, 2.5 %) | 1.025e+05 (1.026e+05 ± 5.2e+02, 0.5 %) |
| tsan-dom_peeling-ea-lo-st-swmr-nofe | 5 | 1.233e+05 (1.278e+05 ± 8.1e+03, 6.3 %) | 1.322e+05 (1.27e+05 ± 7.6e+03, 6.0 %) | 1.535e+05 (1.534e+05 ± 7.3e+02, 0.5 %) | 6.361e+04 (6.345e+04 ± 1.5e+03, 2.3 %) | 1.112e+05 (1.126e+05 ± 4.9e+03, 4.4 %) |
| tsan-nofe | 5 | 1.322e+05 (1.308e+05 ± 5.9e+03, 4.5 %) | 1.304e+05 (1.293e+05 ± 4.6e+03, 3.6 %) | 1.523e+05 (1.517e+05 ± 3e+03, 2.0 %) | 6.141e+04 (6.211e+04 ± 1.3e+03, 2.1 %) | 1.119e+05 (1.142e+05 ± 4.5e+03, 4.0 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

**SU stable** repeats the speedup over the 4 of 5 subtests whose pooled run-to-run CV, taken over every configuration rather than off the baseline alone, is at most 5 %. The set is a property of the workload, not of a configuration, and applies to every row alike. Excluded here: `oltp_read_only` (pooled CV 7.2 %). Report the all-subtest column as the headline and this one as what the data can resolve.

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 9.898 [9.314, 10.430] | 9.813 [9.345, 10.215] | — | 0 | pinned | oltp_read_only:10.25, oltp_read_write:10.06, oltp_write_only:12.00, select_random_points:8.86, select_random_ranges:8.67 |
| tsan | tsan | 5 | — | — | 9.90 [9.31, 10.43] | 602434 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr-nofe | tsan-dom_peeling-ea-lo-st-swmr-nofe | 5 | 1.090 [1.057, 1.157] | 1.138 [1.092, 1.173] | 9.08 [8.41, 9.47] | 636981 | pinned | oltp_read_only:0.92, oltp_read_write:1.12, oltp_write_only:1.17, select_random_points:1.18, select_random_ranges:1.08 |
| tsan-nofe | tsan-nofe | 5 | 1.094 [1.068, 1.154] | 1.124 [1.095, 1.170] | 9.04 [8.44, 9.37] | 600722 | pinned | oltp_read_only:0.98, oltp_read_write:1.11, oltp_write_only:1.16, select_random_points:1.14, select_random_ranges:1.09 |
