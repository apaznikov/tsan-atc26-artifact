# P5 summary — perf-memcached-20260922-090654

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| memcached | orig | orig | 5 | 4.036 [3.685, 4.429] | — (single metric, pooled CV 2.9%) | — | 0 | pinned |
| memcached | tsan | tsan | 5 | — | — (single metric, pooled CV 2.9%) | 4.04 [3.69, 4.43] | 6748 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.005 [0.960, 1.037] | — (single metric, pooled CV 2.9%) | 4.02 [3.72, 4.41] | 7130 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.997 [0.947, 1.038] | — (single metric, pooled CV 2.9%) | 4.05 [3.72, 4.47] | 7183 | pinned |
| memcached | tsan-stmt | tsan-stmt | 5 | 1.019 [0.976, 1.043] | — (single metric, pooled CV 2.9%) | 3.96 [3.70, 4.34] | 6810 | pinned |
