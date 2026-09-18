# P5 summary — threads-4

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| ffmpeg | orig | orig | 5 | 2.780 [2.753, 2.807] | — (all 4 subtests within 5%) | — | — | pinned |
| ffmpeg | tsan | tsan | 5 | — | — (all 4 subtests within 5%) | 2.78 [2.75, 2.81] | — | pinned |
| ffmpeg | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.010 [0.999, 1.021] | — (all 4 subtests within 5%) | 2.75 [2.73, 2.77] | — | pinned |
| ffmpeg | tsan-stmt | tsan-stmt | 5 | 1.113 [1.096, 1.128] | — (all 4 subtests within 5%) | 2.50 [2.47, 2.53] | — | pinned |
