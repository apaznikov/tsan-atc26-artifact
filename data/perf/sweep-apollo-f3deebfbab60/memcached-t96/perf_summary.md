# P5 summary — perf-memcached-20260922-103501

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| memcached | orig | orig | 5 | 5.231 [4.946, 5.781] | — (single metric, pooled CV 2.7%) | — | 0 | pinned |
| memcached | tsan | tsan | 5 | — | — (single metric, pooled CV 2.7%) | 5.23 [4.95, 5.78] | 6748 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 0.995 [0.930, 1.076] | — (single metric, pooled CV 2.7%) | 5.26 [5.02, 5.69] | 7130 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.027 [0.960, 1.118] | — (single metric, pooled CV 2.7%) | 5.09 [4.83, 5.52] | 7183 | pinned |
| memcached | tsan-stmt | tsan-stmt | 5 | 1.005 [0.925, 1.080] | — (single metric, pooled CV 2.7%) | 5.21 [5.00, 5.73] | 6810 | pinned |
