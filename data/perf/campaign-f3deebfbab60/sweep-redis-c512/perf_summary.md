# P5 summary — perf-redis-20260922-213644

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| redis | orig | orig | 5 | 8.075 [7.655, 8.143] | 7.789 [7.457, 7.882] | — | 0 | pinned |
| redis | tsan | tsan | 5 | — | — | 8.08 [7.65, 8.14] | 37922 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.007 [0.999, 1.025] | 1.008 [0.999, 1.021] | 8.02 [7.56, 8.07] | 43272 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.983 [0.971, 0.995] | 0.984 [0.971, 0.994] | 8.22 [7.78, 8.30] | 43248 | pinned |
| redis | tsan-stmt | tsan-stmt | 5 | 0.975 [0.966, 0.991] | 0.975 [0.963, 0.990] | 8.28 [7.82, 8.34] | 37863 | pinned |
