# P5 summary — perf-memcached-20260922-185704

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| memcached | orig | orig | 5 | 4.530 [4.239, 4.755] | — (single metric, pooled CV 2.0%) | — | 0 | pinned |
| memcached | tsan | tsan | 5 | — | — (single metric, pooled CV 2.0%) | 4.53 [4.24, 4.75] | 6748 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.021 [0.935, 1.054] | — (single metric, pooled CV 2.0%) | 4.44 [4.30, 4.76] | 7130 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.018 [0.953, 1.063] | — (single metric, pooled CV 2.0%) | 4.45 [4.26, 4.67] | 7183 | pinned |
| memcached | tsan-stmt | tsan-stmt | 5 | 1.012 [0.958, 1.053] | — (single metric, pooled CV 2.0%) | 4.48 [4.30, 4.65] | 6810 | pinned |
