# sqlite: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-09T10:37:45

| config | N | walthread1 median (mean ± σ, CV) | walthread2 median (mean ± σ, CV) | dynamic_triggers median (mean ± σ, CV) | checkpoint_starvation_1 median (mean ± σ, CV) | checkpoint_starvation_2 median (mean ± σ, CV) | stress1 median (mean ± σ, CV) | stress2 median (mean ± σ, CV) |
|---|---|---|---|---|---|---|---|---|
| orig | 5 | 5052 (5026 ± 1.2e+02, 2.3 %) | 1.554e+04 (1.581e+04 ± 6.3e+02, 4.0 %) | 5.254e+05 (5.374e+05 ± 9.8e+04, 18.3 %) | 7.93e+05 (8.132e+05 ± 9.6e+04, 11.9 %) | 782 (782 ± 0, 0.0 %) | 2.745e+05 (2.791e+05 ± 4e+04, 14.2 %) | 1.589e+05 (1.584e+05 ± 6.1e+03, 3.9 %) |
| tsan | 5 | 2761 (2760 ± 22, 0.8 %) | 6321 (6402 ± 1.7e+02, 2.6 %) | 1.17e+05 (1.227e+05 ± 2.5e+04, 20.6 %) | 1.451e+05 (1.482e+05 ± 9.8e+03, 6.6 %) | 766 (766 ± 0, 0.0 %) | 1.327e+05 (1.265e+05 ± 1.6e+04, 12.6 %) | 2.949e+04 (2.935e+04 ± 1.1e+03, 3.7 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 2738 (2735 ± 12, 0.4 %) | 6222 (6264 ± 1.1e+02, 1.8 %) | 1.092e+05 (1.247e+05 ± 3.1e+04, 25.2 %) | 1.458e+05 (1.447e+05 ± 6.2e+03, 4.3 %) | 782 (775.6 ± 8.8, 1.1 %) | 1.304e+05 (1.277e+05 ± 1.2e+04, 9.1 %) | 2.978e+04 (2.97e+04 ± 5.2e+02, 1.8 %) |
| tsan-dom_peeling-ea-lo-st-swmr-yoff | 5 | 2729 (2731 ± 22, 0.8 %) | 6191 (6210 ± 76, 1.2 %) | 1.262e+05 (1.185e+05 ± 1.8e+04, 15.0 %) | 1.454e+05 (1.453e+05 ± 8.8e+03, 6.1 %) | 766 (766 ± 0, 0.0 %) | 1.218e+05 (1.234e+05 ± 4.1e+03, 3.4 %) | 2.878e+04 (2.893e+04 ± 7.6e+02, 2.6 %) |
| tsan-sound | 5 | 2689 (2712 ± 54, 2.0 %) | 6201 (6273 ± 2.2e+02, 3.5 %) | 1.05e+05 (1.114e+05 ± 1.2e+04, 10.6 %) | 1.453e+05 (1.475e+05 ± 1.1e+04, 7.7 %) | 766 (766 ± 0, 0.0 %) | 1.198e+05 (1.19e+05 ± 6.4e+03, 5.4 %) | 2.881e+04 (2.886e+04 ± 9.3e+02, 3.2 %) |
| tsan-sound-yoff | 5 | 2751 (2748 ± 49, 1.8 %) | 6265 (6256 ± 2.5e+02, 3.9 %) | 1.352e+05 (1.244e+05 ± 2.8e+04, 22.4 %) | 1.412e+05 (1.408e+05 ± 6.6e+03, 4.7 %) | 766 (769.4 ± 7.1, 0.9 %) | 1.264e+05 (1.297e+05 ± 1.1e+04, 8.4 %) | 2.941e+04 (2.906e+04 ± 8e+02, 2.8 %) |
| tsan-stmt | 5 | 2683 (2688 ± 24, 0.9 %) | 6201 (6204 ± 2.5e+02, 4.1 %) | 1.322e+05 (1.308e+05 ± 1.5e+04, 11.1 %) | 1.421e+05 (1.446e+05 ± 1.3e+04, 8.8 %) | 766 (766 ± 0, 0.0 %) | 1.417e+05 (1.328e+05 ± 1.8e+04, 13.4 %) | 2.849e+04 (2.873e+04 ± 8.2e+02, 2.9 %) |
| tsan-stmt-yoff | 5 | 2695 (2694 ± 40, 1.5 %) | 6174 (6222 ± 2.1e+02, 3.3 %) | 1.45e+05 (1.364e+05 ± 2.2e+04, 16.3 %) | 1.44e+05 (1.479e+05 ± 1.1e+04, 7.4 %) | 766 (766 ± 0, 0.0 %) | 1.243e+05 (1.221e+05 ± 1.4e+04, 11.7 %) | 2.764e+04 (2.786e+04 ± 8.7e+02, 3.1 %) |
| tsan-yoff | 5 | 2745 (2757 ± 36, 1.3 %) | 6348 (6450 ± 1.6e+02, 2.5 %) | 1.336e+05 (1.274e+05 ± 2e+04, 15.5 %) | 1.466e+05 (1.482e+05 ± 9.6e+03, 6.5 %) | 766 (769.2 ± 7.2, 0.9 %) | 1.259e+05 (1.297e+05 ± 1.2e+04, 9.4 %) | 2.996e+04 (2.958e+04 ± 8.5e+02, 2.9 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

**SU stable** repeats the speedup over the 4 of 7 subtests whose pooled run-to-run CV, taken over every configuration rather than off the baseline alone, is at most 5 %. The set is a property of the workload, not of a configuration, and applies to every row alike. Excluded here: `dynamic_triggers` (pooled CV 17.8 %); `checkpoint_starvation_1` (pooled CV 7.4 %); `stress1` (pooled CV 10.3 %). Report the all-subtest column as the headline and this one as what the data can resolve.

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 2.772 [2.540, 3.052] | 2.230 [2.161, 2.310] | — | 0 | pinned | walthread1:1.83, walthread2:2.46, dynamic_triggers:4.49, checkpoint_starvation_1:5.46, checkpoint_starvation_2:1.02, stress1:2.07, stress2:5.39 |
| tsan | tsan | 5 | — | — | 2.77 [2.54, 3.05] | 57996 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 0.989 [0.918, 1.101] | 1.002 [0.976, 1.024] | 2.80 [2.53, 3.04] | 61872 | pinned | walthread1:0.99, walthread2:0.98, dynamic_triggers:0.93, checkpoint_starvation_1:1.00, checkpoint_starvation_2:1.02, stress1:0.98, stress2:1.01 |
| tsan-dom_peeling-ea-lo-st-swmr-yoff | tsan-dom_peeling-ea-lo-st-swmr-yoff | 5 | 0.991 [0.908, 1.057] | 0.986 [0.964, 1.012] | 2.80 [2.63, 3.09] | 61931 | pinned | walthread1:0.99, walthread2:0.98, dynamic_triggers:1.08, checkpoint_starvation_1:1.00, checkpoint_starvation_2:1.00, stress1:0.92, stress2:0.98 |
| tsan-sound | tsan-sound | 5 | 0.961 [0.905, 1.046] | 0.983 [0.958, 1.018] | 2.88 [2.66, 3.09] | 57006 | pinned | walthread1:0.97, walthread2:0.98, dynamic_triggers:0.90, checkpoint_starvation_1:1.00, checkpoint_starvation_2:1.00, stress1:0.90, stress2:0.98 |
| tsan-sound-yoff | tsan-sound-yoff | 5 | 1.008 [0.907, 1.083] | 0.996 [0.963, 1.023] | 2.75 [2.56, 3.08] | 57025 | pinned | walthread1:1.00, walthread2:0.99, dynamic_triggers:1.16, checkpoint_starvation_1:0.97, checkpoint_starvation_2:1.00, stress1:0.95, stress2:1.00 |
| tsan-stmt | tsan-stmt | 5 | 1.012 [0.921, 1.087] | 0.980 [0.952, 1.010] | 2.74 [2.56, 3.04] | 57961 | pinned | walthread1:0.97, walthread2:0.98, dynamic_triggers:1.13, checkpoint_starvation_1:0.98, checkpoint_starvation_2:1.00, stress1:1.07, stress2:0.97 |
| tsan-stmt-yoff | tsan-stmt-yoff | 5 | 1.004 [0.911, 1.075] | 0.972 [0.947, 1.002] | 2.76 [2.57, 3.05] | 57957 | pinned | walthread1:0.98, walthread2:0.98, dynamic_triggers:1.24, checkpoint_starvation_1:0.99, checkpoint_starvation_2:1.00, stress1:0.94, stress2:0.94 |
| tsan-yoff | tsan-yoff | 5 | 1.015 [0.934, 1.095] | 1.004 [0.978, 1.034] | 2.73 [2.54, 3.01] | 57996 | pinned | walthread1:0.99, walthread2:1.00, dynamic_triggers:1.14, checkpoint_starvation_1:1.01, checkpoint_starvation_2:1.00, stress1:0.95, stress2:1.02 |
