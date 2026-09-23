# P5 summary — perf-memcached-20260922-143926

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| memcached | orig | orig | 5 | 4.718 [4.584, 4.905] | — (single metric, pooled CV 2.5%) | — | 0 | pinned |
| memcached | tsan | tsan | 5 | — | — (single metric, pooled CV 2.5%) | 4.72 [4.58, 4.91] | 6748 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.008 [0.940, 1.055] | — (single metric, pooled CV 2.5%) | 4.68 [4.53, 5.00] | 7130 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.979 [0.949, 1.042] | — (single metric, pooled CV 2.5%) | 4.82 [4.59, 4.95] | 7183 | pinned |
| memcached | tsan-stmt | tsan-stmt | 5 | 1.008 [0.942, 1.081] | — (single metric, pooled CV 2.5%) | 4.68 [4.42, 4.99] | 6810 | pinned |
