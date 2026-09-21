# P5 summary — perf-sqlite-20260921-173333

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| sqlite | orig | orig | 5 | 3.341 [2.969, 3.598] | 2.322 [2.246, 2.398] | — | 0 | pinned |
| sqlite | tsan | tsan | 5 | — | — | 3.34 [2.97, 3.60] | 57996 | pinned |
| sqlite | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.058 [0.935, 1.120] | 1.005 [0.980, 1.029] | 3.16 [2.94, 3.49] | 61931 | pinned |
| sqlite | tsan-dom_peeling-ea-lo-st-swmr-nofe | tsan-dom_peeling-ea-lo-st-swmr-nofe | 5 | 1.020 [0.918, 1.083] | 1.023 [0.991, 1.049] | 3.28 [3.02, 3.54] | 61928 | pinned |
| sqlite | tsan-nofe | tsan-nofe | 5 | 1.022 [0.919, 1.134] | 1.021 [0.994, 1.040] | 3.27 [2.90, 3.54] | 58008 | pinned |
