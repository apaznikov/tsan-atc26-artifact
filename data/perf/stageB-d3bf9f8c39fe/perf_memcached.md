# memcached: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-09T04:34:23

| config | N | ops_sec median (mean ± σ, CV) |
|---|---|---|
| orig | 5 | 4.7e+06 (4.683e+06 ± 1.3e+05, 2.8 %) |
| tsan | 5 | 1.662e+06 (1.641e+06 ± 4e+04, 2.4 %) |
| tsan-dom | 5 | 1.662e+06 (1.626e+06 ± 6.8e+04, 4.2 %) |
| tsan-dom-ea-lo-st-swmr | 5 | 1.66e+06 (1.637e+06 ± 5.6e+04, 3.4 %) |
| tsan-dom_peeling | 5 | 1.598e+06 (1.601e+06 ± 2.8e+04, 1.8 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 1.616e+06 (1.62e+06 ± 3.1e+04, 1.9 %) |
| tsan-dom_peeling-ea-lo-st-swmr-wp | 5 | 1.638e+06 (1.635e+06 ± 6e+04, 3.7 %) |
| tsan-ea | 5 | 1.59e+06 (1.615e+06 ± 5.4e+04, 3.3 %) |
| tsan-lo | 5 | 1.607e+06 (1.626e+06 ± 5e+04, 3.1 %) |
| tsan-sound | 5 | 1.608e+06 (1.603e+06 ± 2.1e+04, 1.3 %) |
| tsan-sound-tfn | 5 | 1.617e+06 (1.633e+06 ± 4.3e+04, 2.6 %) |
| tsan-sound-tfn-wp | 5 | 1.596e+06 (1.614e+06 ± 4.5e+04, 2.8 %) |
| tsan-sound-wp | 5 | 1.611e+06 (1.627e+06 ± 4.1e+04, 2.5 %) |
| tsan-st | 5 | 1.649e+06 (1.65e+06 ± 5.9e+04, 3.6 %) |
| tsan-stmt | 5 | 1.619e+06 (1.63e+06 ± 5.8e+04, 3.5 %) |
| tsan-swmr | 5 | 1.65e+06 (1.657e+06 ± 1.5e+04, 0.9 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 2.828 [2.674, 3.021] | — | — | 0 | pinned | ops_sec:2.83 |
| tsan | tsan | 5 | — | — | 2.83 [2.67, 3.02] | 6748 | pinned |  |
| tsan-dom | tsan-dom | 5 | 1.000 [0.919, 1.056] | — | 2.83 [2.66, 3.12] | 6508 | pinned | ops_sec:1.00 |
| tsan-dom-ea-lo-st-swmr | AllOpt-peel | 5 | 0.998 [0.918, 1.047] | — | 2.83 [2.69, 3.13] | 6408 | pinned | ops_sec:1.00 |
| tsan-dom_peeling | tsan-dom_peeling | 5 | 0.961 [0.936, 1.030] | — | 2.94 [2.73, 3.07] | 7270 | pinned | ops_sec:0.96 |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 0.972 [0.946, 1.042] | — | 2.91 [2.70, 3.04] | 7130 | pinned | ops_sec:0.97 |
| tsan-dom_peeling-ea-lo-st-swmr-wp | AllOpt+peel (WP summaries) | 5 | 0.986 [0.925, 1.080] | — | 2.87 [2.60, 3.10] | 6699 | pinned | ops_sec:0.99 |
| tsan-ea | tsan-ea | 5 | 0.957 [0.934, 1.060] | — | 2.96 [2.65, 3.08] | 6653 | pinned | ops_sec:0.96 |
| tsan-lo | tsan-lo | 5 | 0.967 [0.948, 1.073] | — | 2.92 [2.62, 3.03] | 6739 | pinned | ops_sec:0.97 |
| tsan-sound | tsan-sound | 5 | 0.968 [0.943, 1.020] | — | 2.92 [2.76, 3.05] | 6643 | pinned | ops_sec:0.97 |
| tsan-sound-tfn | tsan-sound-tfn | 5 | 0.972 [0.947, 1.054] | — | 2.91 [2.67, 3.03] | 6590 | pinned | ops_sec:0.97 |
| tsan-sound-tfn-wp | tsan-sound-tfn-wp | 5 | 0.960 [0.944, 1.063] | — | 2.94 [2.64, 3.04] | 6227 | pinned | ops_sec:0.96 |
| tsan-sound-wp | sound (WP summaries) | 5 | 0.969 [0.946, 1.061] | — | 2.92 [2.65, 3.04] | 6280 | pinned | ops_sec:0.97 |
| tsan-st | tsan-st | 5 | 0.992 [0.939, 1.091] | — | 2.85 [2.58, 3.06] | 6747 | pinned | ops_sec:0.99 |
| tsan-stmt | tsan-stmt | 5 | 0.974 [0.929, 1.068] | — | 2.90 [2.63, 3.09] | 6810 | pinned | ops_sec:0.97 |
| tsan-swmr | tsan-swmr | 5 | 0.993 [0.980, 1.054] | — | 2.85 [2.67, 2.93] | 6748 | pinned | ops_sec:0.99 |
