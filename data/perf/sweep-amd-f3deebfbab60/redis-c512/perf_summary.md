# P5 summary — perf-redis-20260922-173707

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| redis | orig | orig | 5 | 6.784 [6.774, 8.490] | — (only 1 of 19 within 5% - TOO FEW TO RESTRICT) | — | 0 | pinned |
| redis | tsan | tsan | 5 | — | — (only 1 of 19 within 5% - TOO FEW TO RESTRICT) | 6.78 [6.77, 8.49] | 37922 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 0.991 [0.936, 1.135] | — (only 1 of 19 within 5% - TOO FEW TO RESTRICT) | 6.85 [6.60, 8.16] | 43272 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.976 [0.866, 1.072] | — (only 1 of 19 within 5% - TOO FEW TO RESTRICT) | 6.95 [6.98, 8.84] | 43248 | pinned |
| redis | tsan-stmt | tsan-stmt | 5 | 0.971 [0.928, 1.116] | — (only 1 of 19 within 5% - TOO FEW TO RESTRICT) | 6.99 [6.72, 8.22] | 37863 | pinned |
