# mysql: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-09T04:54:40

| config | N | oltp_read_only median (mean ± σ, CV) | oltp_read_write median (mean ± σ, CV) | oltp_write_only median (mean ± σ, CV) | select_random_points median (mean ± σ, CV) | select_random_ranges median (mean ± σ, CV) |
|---|---|---|---|---|---|---|
| orig | 5 | 1.574e+06 (1.614e+06 ± 1.2e+05, 7.5 %) | 1.555e+06 (1.562e+06 ± 1.8e+05, 11.2 %) | 1.591e+06 (1.577e+06 ± 1.2e+05, 7.6 %) | 5.245e+05 (5.208e+05 ± 2.4e+04, 4.6 %) | 1.001e+06 (1.006e+06 ± 1.1e+05, 10.7 %) |
| tsan | 5 | 1.228e+05 (1.261e+05 ± 1.2e+04, 9.4 %) | 1.232e+05 (1.261e+05 ± 1.2e+04, 9.3 %) | 1.433e+05 (1.436e+05 ± 5.1e+03, 3.6 %) | 6.03e+04 (5.945e+04 ± 3.5e+03, 6.0 %) | 1.047e+05 (1.048e+05 ± 4.1e+03, 3.9 %) |
| tsan-dom | 5 | 1.233e+05 (1.229e+05 ± 1.1e+04, 8.8 %) | 1.242e+05 (1.274e+05 ± 6e+03, 4.7 %) | 1.473e+05 (1.461e+05 ± 3.2e+03, 2.2 %) | 5.887e+04 (5.766e+04 ± 3.1e+03, 5.3 %) | 1.076e+05 (1.077e+05 ± 2.9e+03, 2.7 %) |
| tsan-dom-ea-lo-st-swmr | 5 | 1.336e+05 (1.318e+05 ± 1e+04, 7.8 %) | 1.266e+05 (1.263e+05 ± 6.3e+03, 5.0 %) | 1.458e+05 (1.453e+05 ± 5.1e+03, 3.5 %) | 5.862e+04 (5.769e+04 ± 2.7e+03, 4.6 %) | 1.054e+05 (1.064e+05 ± 8.2e+03, 7.7 %) |
| tsan-dom_peeling | 5 | 1.233e+05 (1.265e+05 ± 9.7e+03, 7.7 %) | 1.254e+05 (1.274e+05 ± 6.1e+03, 4.8 %) | 1.439e+05 (1.437e+05 ± 3.8e+03, 2.6 %) | 5.637e+04 (5.585e+04 ± 3.3e+03, 6.0 %) | 1.086e+05 (1.068e+05 ± 6.1e+03, 5.8 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 1.241e+05 (1.292e+05 ± 1.2e+04, 9.1 %) | 1.231e+05 (1.286e+05 ± 8.6e+03, 6.7 %) | 1.468e+05 (1.481e+05 ± 3.9e+03, 2.7 %) | 6.014e+04 (5.998e+04 ± 1.6e+03, 2.6 %) | 1.079e+05 (1.082e+05 ± 5.9e+03, 5.4 %) |
| tsan-ea | 5 | 1.351e+05 (1.328e+05 ± 5.4e+03, 4.0 %) | 1.333e+05 (1.302e+05 ± 7.1e+03, 5.5 %) | 1.456e+05 (1.45e+05 ± 2e+03, 1.4 %) | 5.674e+04 (5.735e+04 ± 1.9e+03, 3.4 %) | 1.089e+05 (1.088e+05 ± 3.5e+03, 3.2 %) |
| tsan-lo | 5 | 1.236e+05 (1.225e+05 ± 1.2e+04, 9.5 %) | 1.247e+05 (1.233e+05 ± 6.6e+03, 5.4 %) | 1.429e+05 (1.389e+05 ± 7.8e+03, 5.6 %) | 5.546e+04 (5.63e+04 ± 1.6e+03, 2.8 %) | 1.042e+05 (1.034e+05 ± 5.1e+03, 4.9 %) |
| tsan-sound | 5 | 1.301e+05 (1.322e+05 ± 9.4e+03, 7.1 %) | 1.311e+05 (1.291e+05 ± 5.4e+03, 4.2 %) | 1.465e+05 (1.448e+05 ± 7.1e+03, 4.9 %) | 5.575e+04 (5.595e+04 ± 2.1e+03, 3.8 %) | 1.089e+05 (1.073e+05 ± 8.4e+03, 7.8 %) |
| tsan-st | 5 | 1.201e+05 (1.246e+05 ± 1.3e+04, 10.7 %) | 1.254e+05 (1.275e+05 ± 6.9e+03, 5.4 %) | 1.405e+05 (1.422e+05 ± 5.6e+03, 4.0 %) | 5.554e+04 (5.302e+04 ± 6.9e+03, 13.1 %) | 1.068e+05 (1.05e+05 ± 3.9e+03, 3.7 %) |
| tsan-stmt | 5 | 1.204e+05 (1.222e+05 ± 9.4e+03, 7.7 %) | 1.218e+05 (1.243e+05 ± 1e+04, 8.4 %) | 1.449e+05 (1.429e+05 ± 4.6e+03, 3.2 %) | 5.725e+04 (5.646e+04 ± 2.4e+03, 4.3 %) | 1.034e+05 (1.055e+05 ± 5.8e+03, 5.5 %) |
| tsan-swmr | 5 | 1.363e+05 (1.322e+05 ± 1.2e+04, 8.9 %) | 1.199e+05 (1.239e+05 ± 1.3e+04, 10.7 %) | 1.453e+05 (1.441e+05 ± 4.4e+03, 3.1 %) | 5.64e+04 (5.704e+04 ± 2.3e+03, 4.0 %) | 1.052e+05 (1.031e+05 ± 8e+03, 7.7 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 10.836 [9.867, 11.728] | — | — | 0 | pinned | oltp_read_only:12.82, oltp_read_write:12.63, oltp_write_only:11.11, select_random_points:8.70, select_random_ranges:9.56 |
| tsan | tsan | 5 | — | — | 10.84 [9.87, 11.73] | 602434 | pinned |  |
| tsan-dom | tsan-dom | 5 | 1.009 [0.933, 1.069] | — | 10.74 [9.95, 11.65] | 578658 | pinned | oltp_read_only:1.00, oltp_read_write:1.01, oltp_write_only:1.03, select_random_points:0.98, select_random_ranges:1.03 |
| tsan-dom-ea-lo-st-swmr | AllOpt-peel | 5 | 1.022 [0.938, 1.082] | — | 10.61 [9.83, 11.55] | 574085 | pinned | oltp_read_only:1.09, oltp_read_write:1.03, oltp_write_only:1.02, select_random_points:0.97, select_random_ranges:1.01 |
| tsan-dom_peeling | tsan-dom_peeling | 5 | 0.999 [0.923, 1.065] | — | 10.85 [9.98, 11.74] | 645512 | pinned | oltp_read_only:1.00, oltp_read_write:1.02, oltp_write_only:1.00, select_random_points:0.93, select_random_ranges:1.04 |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.012 [0.954, 1.096] | — | 10.71 [9.67, 11.36] | 640355 | pinned | oltp_read_only:1.01, oltp_read_write:1.00, oltp_write_only:1.02, select_random_points:1.00, select_random_ranges:1.03 |
| tsan-ea | tsan-ea | 5 | 1.034 [0.959, 1.080] | — | 10.48 [9.78, 11.35] | 597140 | pinned | oltp_read_only:1.10, oltp_read_write:1.08, oltp_write_only:1.02, select_random_points:0.94, select_random_ranges:1.04 |
| tsan-lo | tsan-lo | 5 | 0.986 [0.903, 1.040] | — | 10.99 [10.23, 12.05] | 602434 | pinned | oltp_read_only:1.01, oltp_read_write:1.01, oltp_write_only:1.00, select_random_points:0.92, select_random_ranges:1.00 |
| tsan-sound | tsan-sound | 5 | 1.021 [0.938, 1.078] | — | 10.62 [9.82, 11.55] | 597140 | pinned | oltp_read_only:1.06, oltp_read_write:1.06, oltp_write_only:1.02, select_random_points:0.92, select_random_ranges:1.04 |
| tsan-st | tsan-st | 5 | 0.983 [0.896, 1.056] | — | 11.02 [10.05, 12.11] | 602434 | pinned | oltp_read_only:0.98, oltp_read_write:1.02, oltp_write_only:0.98, select_random_points:0.92, select_random_ranges:1.02 |
| tsan-stmt | tsan-stmt | 5 | 0.983 [0.912, 1.053] | — | 11.02 [10.09, 11.90] | 602809 | pinned | oltp_read_only:0.98, oltp_read_write:0.99, oltp_write_only:1.01, select_random_points:0.95, select_random_ranges:0.99 |
| tsan-swmr | tsan-swmr | 5 | 1.006 [0.917, 1.073] | — | 10.78 [9.90, 11.83] | 602434 | pinned | oltp_read_only:1.11, oltp_read_write:0.97, oltp_write_only:1.01, select_random_points:0.94, select_random_ranges:1.00 |
