# P5 summary — perf-ffmpeg-20260921-135106

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| ffmpeg | orig | orig | 5 | 2.883 [2.799, 2.916] | — (all 4 subtests within 5%) | — | 0 | pinned |
| ffmpeg | tsan | tsan | 5 | — | — (all 4 subtests within 5%) | 2.88 [2.80, 2.92] | 507825 | pinned |
| ffmpeg | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.067 [1.050, 1.079] | — (all 4 subtests within 5%) | 2.70 [2.63, 2.74] | 535690 | pinned |
| ffmpeg | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.187 [1.171, 1.201] | — (all 4 subtests within 5%) | 2.43 [2.36, 2.46] | 535687 | pinned |
| ffmpeg | tsan-dom_peeling-ea-lo-st-swmr-stmt-nofe | tsan-dom_peeling-ea-lo-st-swmr-stmt-nofe | 5 | 1.200 [1.185, 1.221] | — (all 4 subtests within 5%) | 2.40 [2.32, 2.43] | 535631 | pinned |
| ffmpeg | tsan-nofe | tsan-nofe | 5 | 1.016 [1.002, 1.029] | — (all 4 subtests within 5%) | 2.84 [2.75, 2.87] | 507823 | pinned |
| ffmpeg | tsan-stmt | tsan-stmt | 5 | 1.133 [1.114, 1.146] | — (all 4 subtests within 5%) | 2.55 [2.48, 2.58] | 507709 | pinned |
