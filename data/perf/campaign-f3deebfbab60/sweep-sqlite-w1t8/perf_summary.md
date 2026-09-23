# P5 summary — perf-sqlite-20260923-001218

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| sqlite | orig | orig | 5 | 1.834 [1.740, 1.861] | — (single metric, pooled CV 1.2%) | — | 0 | pinned |
| sqlite | tsan | tsan | 5 | — | — (single metric, pooled CV 1.2%) | 1.83 [1.74, 1.86] | 57996 | pinned |
| sqlite | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.006 [0.992, 1.021] | — (single metric, pooled CV 1.2%) | 1.82 [1.74, 1.84] | 61931 | pinned |
| sqlite | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.987 [0.971, 1.019] | — (single metric, pooled CV 1.2%) | 1.86 [1.74, 1.88] | 61897 | pinned |
| sqlite | tsan-stmt | tsan-stmt | 5 | 0.986 [0.959, 0.996] | — (single metric, pooled CV 1.2%) | 1.86 [1.78, 1.90] | 57957 | pinned |
