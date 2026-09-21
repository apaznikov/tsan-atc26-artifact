# sqlite: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=d66e49eb47b8 started=2026-09-21T17:36:07

| config | N | walthread1 median (mean ± σ, CV) | walthread2 median (mean ± σ, CV) | dynamic_triggers median (mean ± σ, CV) | checkpoint_starvation_1 median (mean ± σ, CV) | checkpoint_starvation_2 median (mean ± σ, CV) | stress1 median (mean ± σ, CV) | stress2 median (mean ± σ, CV) |
|---|---|---|---|---|---|---|---|---|
| orig | 5 | 5099 (5078 ± 1e+02, 2.0 %) | 1.653e+04 (1.66e+04 ± 2.9e+02, 1.8 %) | 6.734e+05 (6.615e+05 ± 8.9e+04, 13.5 %) | 8.833e+05 (9.024e+05 ± 5.8e+04, 6.4 %) | 782 (785.2 ± 7.2, 0.9 %) | 3.684e+05 (3.929e+05 ± 7.5e+04, 19.1 %) | 1.666e+05 (1.669e+05 ± 5.7e+03, 3.4 %) |
| tsan | 5 | 2694 (2680 ± 29, 1.1 %) | 6273 (6321 ± 98, 1.6 %) | 1.04e+05 (1.208e+05 ± 3.4e+04, 28.0 %) | 1.546e+05 (1.574e+05 ± 5.3e+03, 3.4 %) | 766 (772.4 ± 8.8, 1.1 %) | 8.862e+04 (8.792e+04 ± 1e+04, 11.4 %) | 2.805e+04 (2.824e+04 ± 2.2e+03, 7.8 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 2714 (2708 ± 26, 0.9 %) | 6293 (6347 ± 1.2e+02, 1.9 %) | 1.074e+05 (1.085e+05 ± 3e+03, 2.8 %) | 1.562e+05 (1.589e+05 ± 5.2e+03, 3.3 %) | 766 (769.2 ± 7.2, 0.9 %) | 1.235e+05 (1.161e+05 ± 2.4e+04, 20.3 %) | 2.832e+04 (2.893e+04 ± 1.6e+03, 5.6 %) |
| tsan-dom_peeling-ea-lo-st-swmr-nofe | 5 | 2782 (2763 ± 47, 1.7 %) | 6417 (6451 ± 93, 1.4 %) | 1.142e+05 (1.144e+05 ± 1.2e+04, 10.6 %) | 1.571e+05 (1.599e+05 ± 7.5e+03, 4.7 %) | 782 (778.8 ± 7.2, 0.9 %) | 7.977e+04 (8.317e+04 ± 1.1e+04, 13.6 %) | 2.978e+04 (2.954e+04 ± 9.2e+02, 3.1 %) |
| tsan-nofe | 5 | 2751 (2749 ± 15, 0.5 %) | 6400 (6468 ± 1e+02, 1.6 %) | 1.112e+05 (1.197e+05 ± 2.4e+04, 20.2 %) | 1.583e+05 (1.603e+05 ± 4.4e+03, 2.8 %) | 782 (775.6 ± 8.8, 1.1 %) | 8.538e+04 (9.491e+04 ± 2.3e+04, 23.8 %) | 2.907e+04 (2.923e+04 ± 1.4e+03, 4.7 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

**SU stable** repeats the speedup over the 4 of 7 subtests whose pooled run-to-run CV, taken over every configuration rather than off the baseline alone, is at most 5 %. The set is a property of the workload, not of a configuration, and applies to every row alike. Excluded here: `dynamic_triggers` (pooled CV 17.3 %); `stress1` (pooled CV 18.2 %); `stress2` (pooled CV 5.2 %). Report the all-subtest column as the headline and this one as what the data can resolve.

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 3.341 [2.969, 3.598] | 2.322 [2.246, 2.398] | — | 0 | pinned | walthread1:1.89, walthread2:2.63, dynamic_triggers:6.47, checkpoint_starvation_1:5.71, checkpoint_starvation_2:1.02, stress1:4.16, stress2:5.94 |
| tsan | tsan | 5 | — | — | 3.34 [2.97, 3.60] | 57996 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.058 [0.935, 1.120] | 1.005 [0.980, 1.029] | 3.16 [2.94, 3.49] | 61931 | pinned | walthread1:1.01, walthread2:1.00, dynamic_triggers:1.03, checkpoint_starvation_1:1.01, checkpoint_starvation_2:1.00, stress1:1.39, stress2:1.01 |
| tsan-dom_peeling-ea-lo-st-swmr-nofe | tsan-dom_peeling-ea-lo-st-swmr-nofe | 5 | 1.020 [0.918, 1.083] | 1.023 [0.991, 1.049] | 3.28 [3.02, 3.54] | 61928 | pinned | walthread1:1.03, walthread2:1.02, dynamic_triggers:1.10, checkpoint_starvation_1:1.02, checkpoint_starvation_2:1.02, stress1:0.90, stress2:1.06 |
| tsan-nofe | tsan-nofe | 5 | 1.022 [0.919, 1.134] | 1.021 [0.994, 1.040] | 3.27 [2.90, 3.54] | 58008 | pinned | walthread1:1.02, walthread2:1.02, dynamic_triggers:1.07, checkpoint_starvation_1:1.02, checkpoint_starvation_2:1.02, stress1:0.96, stress2:1.04 |
