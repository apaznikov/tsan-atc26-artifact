# sqlite: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=618ef42f2db9 started=2026-09-18T05:29:08

| config | N | walthread1 median (mean ± σ, CV) | walthread2 median (mean ± σ, CV) | dynamic_triggers median (mean ± σ, CV) | checkpoint_starvation_1 median (mean ± σ, CV) | checkpoint_starvation_2 median (mean ± σ, CV) | stress1 median (mean ± σ, CV) | stress2 median (mean ± σ, CV) |
|---|---|---|---|---|---|---|---|---|
| orig | 5 | 4908 (4947 ± 82, 1.7 %) | 1.666e+04 (1.663e+04 ± 1.1e+02, 0.7 %) | 6.556e+05 (6.991e+05 ± 1.1e+05, 15.3 %) | 9.305e+05 (9.359e+05 ± 4.6e+04, 4.9 %) | 782 (782 ± 0, 0.0 %) | 3.635e+05 (3.118e+05 ± 9.5e+04, 30.5 %) | 1.753e+05 (1.735e+05 ± 5.5e+03, 3.1 %) |
| tsan | 5 | 2696 (2681 ± 26, 1.0 %) | 6336 (6328 ± 16, 0.2 %) | 1.1e+05 (1.098e+05 ± 5.6e+03, 5.1 %) | 1.551e+05 (1.541e+05 ± 5.6e+03, 3.6 %) | 766 (766 ± 0, 0.0 %) | 6.872e+04 (8.171e+04 ± 2.3e+04, 28.4 %) | 2.683e+04 (2.695e+04 ± 1e+03, 3.7 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 2694 (2700 ± 27, 1.0 %) | 6311 (6319 ± 27, 0.4 %) | 1.254e+05 (1.228e+05 ± 1.5e+04, 12.0 %) | 1.579e+05 (1.574e+05 ± 2.8e+03, 1.8 %) | 766 (766 ± 0, 0.0 %) | 7.824e+04 (8.908e+04 ± 2e+04, 22.9 %) | 2.699e+04 (2.707e+04 ± 1e+03, 3.8 %) |
| tsan-stmt | 5 | 2610 (2590 ± 96, 3.7 %) | 6179 (6150 ± 59, 1.0 %) | 1.138e+05 (1.143e+05 ± 1.8e+04, 15.4 %) | 1.514e+05 (1.504e+05 ± 4e+03, 2.7 %) | 766 (766 ± 0, 0.0 %) | 9.358e+04 (9.685e+04 ± 2.3e+04, 23.6 %) | 2.627e+04 (2.592e+04 ± 1.1e+03, 4.4 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

**SU stable** repeats the speedup over the 5 of 7 subtests whose pooled run-to-run CV, taken over every configuration rather than off the baseline alone, is at most 5 %. The set is a property of the workload, not of a configuration, and applies to every row alike. Excluded here: `dynamic_triggers` (pooled CV 12.7 %); `stress1` (pooled CV 26.5 %). Report the all-subtest column as the headline and this one as what the data can resolve.

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 3.468 [2.871, 3.679] | 2.861 [2.787, 2.949] | — | 0 | pinned | walthread1:1.82, walthread2:2.63, dynamic_triggers:5.96, checkpoint_starvation_1:6.00, checkpoint_starvation_2:1.02, stress1:5.29, stress2:6.53 |
| tsan | tsan | 5 | — | — | 3.47 [2.87, 3.68] | 57996 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.041 [0.943, 1.129] | 1.004 [0.984, 1.032] | 3.33 [2.81, 3.56] | 61931 | pinned | walthread1:1.00, walthread2:1.00, dynamic_triggers:1.14, checkpoint_starvation_1:1.02, checkpoint_starvation_2:1.00, stress1:1.14, stress2:1.01 |
| tsan-stmt | tsan-stmt | 5 | 1.035 [0.912, 1.111] | 0.980 [0.945, 1.003] | 3.35 [2.85, 3.67] | 57957 | pinned | walthread1:0.97, walthread2:0.98, dynamic_triggers:1.03, checkpoint_starvation_1:0.98, checkpoint_starvation_2:1.00, stress1:1.36, stress2:0.98 |
