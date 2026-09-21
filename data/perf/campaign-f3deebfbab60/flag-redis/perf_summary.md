# P5 summary — perf-redis-20260921-152206

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| redis | orig | orig | 5 | 8.416 [8.181, 8.573] | 8.519 [8.277, 8.700] | — | 0 | pinned |
| redis | tsan | tsan | 5 | — | — | 8.42 [8.18, 8.57] | 37922 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.008 [0.989, 1.030] | 1.007 [0.989, 1.031] | 8.35 [8.14, 8.47] | 43272 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr-nofe | tsan-dom_peeling-ea-lo-st-swmr-nofe | 5 | 1.138 [1.109, 1.161] | 1.134 [1.107, 1.155] | 7.40 [7.21, 7.54] | 43287 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr-stmt-nofe | tsan-dom_peeling-ea-lo-st-swmr-stmt-nofe | 5 | 1.083 [1.061, 1.107] | 1.081 [1.061, 1.110] | 7.77 [7.56, 7.89] | 43265 | pinned |
| redis | tsan-nofe | tsan-nofe | 5 | 1.107 [1.072, 1.131] | 1.107 [1.069, 1.130] | 7.60 [7.41, 7.81] | 37933 | pinned |
| redis | tsan-sound | tsan-sound | 5 | 0.995 [0.972, 1.017] | 0.993 [0.972, 1.019] | 8.46 [8.24, 8.61] | 37588 | pinned |
| redis | tsan-sound-nofe | tsan-sound-nofe | 5 | 1.115 [1.090, 1.144] | 1.114 [1.090, 1.142] | 7.55 [7.32, 7.68] | 37600 | pinned |
