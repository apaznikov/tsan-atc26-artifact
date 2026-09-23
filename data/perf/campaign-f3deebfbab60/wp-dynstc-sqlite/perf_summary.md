# P5 summary — perf-sqlite-20260922-113303

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| sqlite | orig | orig | 5 | 2.967 [2.709, 3.298] | 2.762 [2.695, 2.823] | — | 0 | pinned |
| sqlite | tsan | tsan | 5 | — | — | 2.97 [2.71, 3.30] | 57996 | pinned |
| sqlite | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.951 [0.880, 1.020] | 0.988 [0.967, 1.015] | 3.12 [2.85, 3.49] | 61897 | pinned |
| sqlite | tsan-dom_peeling-ea-lo-st-swmr-stmt-wp | AllOpt+peel+DynSTC (WP summaries) | 5 | 0.969 [0.901, 1.062] | 0.988 [0.970, 1.011] | 3.06 [2.76, 3.38] | 61793 | pinned |
| sqlite | tsan-dom_peeling-ea-lo-st-swmr-wp | AllOpt+peel (WP summaries) | 5 | 1.026 [0.916, 1.101] | 1.008 [0.976, 1.027] | 2.89 [2.66, 3.32] | 61827 | pinned |
