# P5 summary — perf-memcached-20260922-142601

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| memcached | orig | orig | 5 | 3.675 [3.523, 3.821] | — (single metric, pooled CV 2.6%) | — | 0 | pinned |
| memcached | tsan | tsan | 5 | — | — (single metric, pooled CV 2.6%) | 3.68 [3.52, 3.82] | 6748 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.991 [0.930, 1.036] | — (single metric, pooled CV 2.6%) | 3.71 [3.49, 4.01] | 7183 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr-stmt-wp | AllOpt+peel+DynSTC (WP summaries) | 5 | 1.004 [0.950, 1.028] | — (single metric, pooled CV 2.6%) | 3.66 [3.51, 3.92] | 6743 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr-wp | AllOpt+peel (WP summaries) | 5 | 1.000 [0.935, 1.046] | — (single metric, pooled CV 2.6%) | 3.67 [3.45, 3.99] | 6699 | pinned |
