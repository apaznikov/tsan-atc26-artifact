# sqlite: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=392019959bdd started=2026-09-22T11:50:39

| config | N | walthread1 median (mean ± σ, CV) | walthread2 median (mean ± σ, CV) | dynamic_triggers median (mean ± σ, CV) | checkpoint_starvation_1 median (mean ± σ, CV) | checkpoint_starvation_2 median (mean ± σ, CV) | stress1 median (mean ± σ, CV) | stress2 median (mean ± σ, CV) |
|---|---|---|---|---|---|---|---|---|
| orig | 5 | 4973 (4933 ± 1e+02, 2.0 %) | 1.68e+04 (1.685e+04 ± 93, 0.6 %) | 6.496e+05 (6.367e+05 ± 7.5e+04, 11.8 %) | 7.882e+05 (7.844e+05 ± 1.4e+04, 1.8 %) | 782 (782 ± 0, 0.0 %) | 2.502e+05 (2.814e+05 ± 9.2e+04, 32.5 %) | 1.823e+05 (1.826e+05 ± 5e+03, 2.7 %) |
| tsan | 5 | 2689 (2674 ± 28, 1.0 %) | 6438 (6428 ± 37, 0.6 %) | 1.19e+05 (1.222e+05 ± 1.1e+04, 8.7 %) | 1.631e+05 (1.613e+05 ± 4.2e+03, 2.6 %) | 766 (766 ± 0, 0.0 %) | 1.086e+05 (1.125e+05 ± 2.1e+04, 18.3 %) | 2.7e+04 (2.741e+04 ± 1.2e+03, 4.4 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 2675 (2676 ± 25, 0.9 %) | 6300 (6319 ± 42, 0.7 %) | 1.224e+05 (1.219e+05 ± 1.6e+04, 12.8 %) | 1.633e+05 (1.629e+05 ± 1.4e+03, 0.9 %) | 766 (766 ± 0, 0.0 %) | 7.915e+04 (8.091e+04 ± 1.4e+04, 17.8 %) | 2.604e+04 (2.625e+04 ± 1.1e+03, 4.3 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt-wp | 5 | 2667 (2665 ± 18, 0.7 %) | 6348 (6330 ± 49, 0.8 %) | 1.108e+05 (1.258e+05 ± 2.8e+04, 22.2 %) | 1.633e+05 (1.63e+05 ± 1e+03, 0.6 %) | 766 (766 ± 0, 0.0 %) | 9.903e+04 (9.837e+04 ± 1.3e+04, 13.6 %) | 2.603e+04 (2.622e+04 ± 8e+02, 3.0 %) |
| tsan-dom_peeling-ea-lo-st-swmr-wp | 5 | 2739 (2688 ± 1.2e+02, 4.4 %) | 6438 (6439 ± 38, 0.6 %) | 1.52e+05 (1.465e+05 ± 2.5e+04, 17.3 %) | 1.648e+05 (1.64e+05 ± 2.1e+03, 1.3 %) | 766 (766 ± 0, 0.0 %) | 9.785e+04 (9.831e+04 ± 2.2e+04, 22.7 %) | 2.728e+04 (2.74e+04 ± 3.6e+02, 1.3 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

**SU stable** repeats the speedup over the 5 of 7 subtests whose pooled run-to-run CV, taken over every configuration rather than off the baseline alone, is at most 5 %. The set is a property of the workload, not of a configuration, and applies to every row alike. Excluded here: `dynamic_triggers` (pooled CV 15.3 %); `stress1` (pooled CV 21.9 %). Report the all-subtest column as the headline and this one as what the data can resolve.

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 2.967 [2.709, 3.298] | 2.762 [2.695, 2.823] | — | 0 | pinned | walthread1:1.85, walthread2:2.61, dynamic_triggers:5.46, checkpoint_starvation_1:4.83, checkpoint_starvation_2:1.02, stress1:2.30, stress2:6.75 |
| tsan | tsan | 5 | — | — | 2.97 [2.71, 3.30] | 57996 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.951 [0.880, 1.020] | 0.988 [0.967, 1.015] | 3.12 [2.85, 3.49] | 61897 | pinned | walthread1:0.99, walthread2:0.98, dynamic_triggers:1.03, checkpoint_starvation_1:1.00, checkpoint_starvation_2:1.00, stress1:0.73, stress2:0.96 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt-wp | AllOpt+peel+DynSTC (WP summaries) | 5 | 0.969 [0.901, 1.062] | 0.988 [0.970, 1.011] | 3.06 [2.76, 3.38] | 61793 | pinned | walthread1:0.99, walthread2:0.99, dynamic_triggers:0.93, checkpoint_starvation_1:1.00, checkpoint_starvation_2:1.00, stress1:0.91, stress2:0.96 |
| tsan-dom_peeling-ea-lo-st-swmr-wp | AllOpt+peel (WP summaries) | 5 | 1.026 [0.916, 1.101] | 1.008 [0.976, 1.027] | 2.89 [2.66, 3.32] | 61827 | pinned | walthread1:1.02, walthread2:1.00, dynamic_triggers:1.28, checkpoint_starvation_1:1.01, checkpoint_starvation_2:1.00, stress1:0.90, stress2:1.01 |
