# P5 summary — perf-redis-20260922-200553

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| redis | orig | orig | 5 | 8.343 [8.206, 8.521] | 8.344 [8.185, 8.476] | — | 0 | pinned |
| redis | tsan | tsan | 5 | — | — | 8.34 [8.21, 8.52] | 37922 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.007 [0.988, 1.026] | 1.009 [0.990, 1.023] | 8.28 [8.17, 8.44] | 43272 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.973 [0.954, 0.997] | 0.978 [0.962, 0.993] | 8.58 [8.41, 8.73] | 43248 | pinned |
| redis | tsan-stmt | tsan-stmt | 5 | 0.975 [0.958, 0.993] | 0.979 [0.962, 0.991] | 8.56 [8.44, 8.69] | 37863 | pinned |
