# P5 summary — perf-memcached-20260922-153509

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| memcached | orig | orig | 5 | 5.179 [4.581, 5.614] | — (single metric, pooled CV 5.3%) | — | 0 | pinned |
| memcached | tsan | tsan | 5 | — | — (single metric, pooled CV 5.3%) | 5.18 [4.58, 5.61] | 6748 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.063 [0.864, 1.200] | — (single metric, pooled CV 5.3%) | 4.87 [4.55, 5.45] | 7130 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.980 [0.848, 1.117] | — (single metric, pooled CV 5.3%) | 5.28 [4.88, 5.56] | 7183 | pinned |
| memcached | tsan-stmt | tsan-stmt | 5 | 0.974 [0.837, 1.144] | — (single metric, pooled CV 5.3%) | 5.32 [4.77, 5.63] | 6810 | pinned |
