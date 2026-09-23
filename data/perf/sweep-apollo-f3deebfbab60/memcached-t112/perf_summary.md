# P5 summary — perf-memcached-20260922-123345

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| memcached | orig | orig | 5 | 5.976 [5.700, 6.396] | — (single metric, pooled CV 2.4%) | — | 0 | pinned |
| memcached | tsan | tsan | 5 | — | — (single metric, pooled CV 2.4%) | 5.98 [5.70, 6.40] | 6748 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.023 [0.959, 1.077] | — (single metric, pooled CV 2.4%) | 5.84 [5.58, 6.33] | 7130 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.035 [1.014, 1.085] | — (single metric, pooled CV 2.4%) | 5.77 [5.54, 5.98] | 7183 | pinned |
| memcached | tsan-stmt | tsan-stmt | 5 | 1.019 [0.945, 1.071] | — (single metric, pooled CV 2.4%) | 5.87 [5.61, 6.42] | 6810 | pinned |
