# P5 summary — perf-memcached-20260922-171336

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| memcached | orig | orig | 5 | 5.603 [5.394, 6.426] | — (single metric, pooled CV 5.6%) | — | 0 | pinned |
| memcached | tsan | tsan | 5 | — | — (single metric, pooled CV 5.6%) | 5.60 [5.39, 6.43] | 6748 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 0.996 [0.891, 1.180] | — (single metric, pooled CV 5.6%) | 5.62 [5.35, 6.17] | 7130 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.006 [0.884, 1.189] | — (single metric, pooled CV 5.6%) | 5.57 [5.31, 6.22] | 7183 | pinned |
| memcached | tsan-stmt | tsan-stmt | 5 | 0.900 [0.842, 1.170] | — (single metric, pooled CV 5.6%) | 6.23 [5.39, 6.53] | 6810 | pinned |
