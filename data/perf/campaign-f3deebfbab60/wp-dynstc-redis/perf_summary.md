# P5 summary — perf-redis-20260922-104910

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| redis | orig | orig | 5 | 8.319 [8.169, 8.480] | 8.404 [8.274, 8.580] | — | 0 | pinned |
| redis | tsan | tsan | 5 | — | — | 8.32 [8.17, 8.48] | 37922 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.987 [0.970, 1.005] | 0.988 [0.972, 1.005] | 8.43 [8.29, 8.57] | 43248 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr-stmt-wp | AllOpt+peel+DynSTC (WP summaries) | 5 | 0.984 [0.963, 1.006] | 0.983 [0.967, 1.002] | 8.45 [8.28, 8.61] | 40682 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr-wp | AllOpt+peel (WP summaries) | 5 | 1.025 [1.000, 1.038] | 1.026 [1.004, 1.039] | 8.11 [8.02, 8.31] | 40672 | pinned |
