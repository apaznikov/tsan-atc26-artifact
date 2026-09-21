# P5 summary — perf-memcached-20260921-162538

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| memcached | orig | orig | 5 | 3.680 [3.541, 3.774] | — (single metric, pooled CV 2.6%) | — | 0 | pinned |
| memcached | tsan | tsan | 5 | — | — (single metric, pooled CV 2.6%) | 3.68 [3.54, 3.77] | 6748 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.033 [0.945, 1.068] | — (single metric, pooled CV 2.6%) | 3.56 [3.49, 3.79] | 7130 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr-nofe | tsan-dom_peeling-ea-lo-st-swmr-nofe | 5 | 1.019 [0.925, 1.058] | — (single metric, pooled CV 2.6%) | 3.61 [3.52, 3.87] | 7130 | pinned |
| memcached | tsan-nofe | tsan-nofe | 5 | 1.000 [0.914, 1.040] | — (single metric, pooled CV 2.6%) | 3.68 [3.59, 3.92] | 6748 | pinned |
