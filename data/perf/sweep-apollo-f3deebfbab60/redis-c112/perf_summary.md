# P5 summary — perf-redis-20260922-195955

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| redis | orig | orig | 5 | 8.453 [7.663, 9.109] | — (only 0 of 19 within 5% - TOO FEW TO RESTRICT) | — | 0 | pinned |
| redis | tsan | tsan | 5 | — | — (only 0 of 19 within 5% - TOO FEW TO RESTRICT) | 8.45 [7.66, 9.11] | 37922 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.041 [0.936, 1.100] | — (only 0 of 19 within 5% - TOO FEW TO RESTRICT) | 8.12 [7.51, 9.05] | 43272 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.028 [0.911, 1.072] | — (only 0 of 19 within 5% - TOO FEW TO RESTRICT) | 8.22 [7.71, 9.31] | 43248 | pinned |
| redis | tsan-stmt | tsan-stmt | 5 | 1.035 [0.958, 1.090] | — (only 0 of 19 within 5% - TOO FEW TO RESTRICT) | 8.17 [7.55, 8.83] | 37863 | pinned |
