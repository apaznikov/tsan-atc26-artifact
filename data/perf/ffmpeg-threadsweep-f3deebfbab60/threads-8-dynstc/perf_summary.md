# P5 summary — perf-ffmpeg-20260921-144526

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| ffmpeg | orig | orig | 5 | 2.822 [2.755, 2.889] | — (all 4 subtests within 5%) | — | 0 | pinned |
| ffmpeg | tsan | tsan | 5 | — | — (all 4 subtests within 5%) | 2.82 [2.75, 2.89] | 507825 | pinned |
| ffmpeg | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.190 [1.167, 1.211] | — (all 4 subtests within 5%) | 2.37 [2.32, 2.43] | 535687 | pinned |
| ffmpeg | tsan-stmt | tsan-stmt | 5 | 1.138 [1.112, 1.161] | — (all 4 subtests within 5%) | 2.48 [2.43, 2.55] | 507709 | pinned |
