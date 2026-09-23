# P5 summary — perf-redis-20260922-161531

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| redis | orig | orig | 5 | 7.792 [7.232, 8.731] | — (only 2 of 19 within 5% - TOO FEW TO RESTRICT) | — | 0 | pinned |
| redis | tsan | tsan | 5 | — | — (only 2 of 19 within 5% - TOO FEW TO RESTRICT) | 7.79 [7.23, 8.73] | 37922 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.041 [1.008, 1.149] | — (only 2 of 19 within 5% - TOO FEW TO RESTRICT) | 7.49 [6.86, 8.02] | 43272 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.999 [0.913, 1.073] | — (only 2 of 19 within 5% - TOO FEW TO RESTRICT) | 7.80 [7.38, 8.81] | 43248 | pinned |
| redis | tsan-stmt | tsan-stmt | 5 | 1.008 [0.970, 1.111] | — (only 2 of 19 within 5% - TOO FEW TO RESTRICT) | 7.73 [7.11, 8.30] | 37863 | pinned |
