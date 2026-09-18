# P5 summary — r2

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| memcached | orig | orig | 5 | 5.110 [4.485, 5.216] | — (single metric, pooled CV 5.1%) | — | — | pinned |
| memcached | tsan | tsan | 5 | — | — (single metric, pooled CV 5.1%) | 5.11 [4.48, 5.22] | — | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.006 [0.890, 1.161] | — (single metric, pooled CV 5.1%) | 5.08 [4.33, 5.22] | — | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.089 [0.875, 1.129] | — (single metric, pooled CV 5.1%) | 4.69 [4.46, 5.32] | — | pinned |
| redis | orig | orig | 5 | 7.961 [7.833, 8.115] | 7.963 [7.843, 8.125] | — | — | pinned |
| redis | tsan | tsan | 5 | — | — | 7.96 [7.83, 8.11] | — | pinned |
| redis | tsan-dom | tsan-dom | 5 | 1.000 [0.980, 1.020] | 1.006 [0.985, 1.025] | 7.96 [7.82, 8.13] | — | pinned |
| redis | tsan-dom-ea-lo-st-swmr | AllOpt-peel | 5 | 1.005 [0.983, 1.020] | 1.009 [0.988, 1.024] | 7.92 [7.82, 8.11] | — | pinned |
| redis | tsan-dom_peeling | tsan-dom_peeling | 5 | 1.001 [0.980, 1.016] | 1.002 [0.981, 1.018] | 7.96 [7.85, 8.13] | — | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.006 [0.990, 1.026] | 1.007 [0.991, 1.029] | 7.92 [7.78, 8.04] | — | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.974 [0.949, 0.988] | 0.974 [0.952, 0.989] | 8.18 [8.08, 8.39] | — | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr-wp | AllOpt+peel (WP summaries) | 5 | 1.004 [0.987, 1.023] | 1.006 [0.989, 1.024] | 7.93 [7.81, 8.06] | — | pinned |
| redis | tsan-ea | tsan-ea | 5 | 0.986 [0.967, 1.003] | 0.988 [0.969, 1.005] | 8.08 [7.96, 8.24] | — | pinned |
| redis | tsan-lo | tsan-lo | 5 | 0.985 [0.962, 1.001] | 0.986 [0.963, 1.003] | 8.08 [7.98, 8.29] | — | pinned |
| redis | tsan-sound-wp | sound (WP summaries) | 5 | 0.984 [0.962, 1.003] | 0.991 [0.968, 1.007] | 8.09 [7.96, 8.28] | — | pinned |
| redis | tsan-st | tsan-st | 5 | 0.989 [0.970, 1.010] | 0.991 [0.974, 1.013] | 8.05 [7.90, 8.21] | — | pinned |
| redis | tsan-stmt | tsan-stmt | 5 | 0.967 [0.948, 0.988] | 0.970 [0.953, 0.992] | 8.23 [8.08, 8.41] | — | pinned |
| redis | tsan-swmr | tsan-swmr | 5 | 0.987 [0.966, 1.003] | 0.987 [0.968, 1.004] | 8.07 [7.96, 8.26] | — | pinned |
| mysql | orig | orig | 5 | 8.772 [8.560, 9.368] | 9.017 [8.739, 9.425] | — | — | pinned |
| mysql | tsan | tsan | 5 | — | — | 8.77 [8.56, 9.37] | — | pinned |
| mysql | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.011 [0.978, 1.049] | 1.010 [0.989, 1.040] | 8.68 [8.43, 9.26] | — | pinned |
| mysql | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.992 [0.966, 1.023] | 0.989 [0.968, 1.008] | 8.84 [8.64, 9.39] | — | pinned |
