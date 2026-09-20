# P5 summary — perf-sqlite-20260918-052657

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| sqlite | orig | orig | 5 | 3.468 [2.871, 3.679] | 2.861 [2.787, 2.949] | — | 0 | pinned |
| sqlite | tsan | tsan | 5 | — | — | 3.47 [2.87, 3.68] | 57996 | pinned |
| sqlite | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.041 [0.943, 1.129] | 1.004 [0.984, 1.032] | 3.33 [2.81, 3.56] | 61931 | pinned |
| sqlite | tsan-stmt | tsan-stmt | 5 | 1.035 [0.912, 1.111] | 0.980 [0.945, 1.003] | 3.35 [2.85, 3.67] | 57957 | pinned |
