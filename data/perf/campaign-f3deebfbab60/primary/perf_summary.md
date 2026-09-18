# P5 summary — primary

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| memcached | orig | orig | 5 | 3.203 [2.972, 3.400] | — (single metric, pooled CV 2.4%) | — | — | pinned |
| memcached | tsan | tsan | 5 | — | — (single metric, pooled CV 2.4%) | 3.20 [2.97, 3.40] | — | pinned |
| memcached | tsan-dom | tsan-dom | 5 | 0.986 [0.935, 1.085] | — (single metric, pooled CV 2.4%) | 3.25 [2.98, 3.35] | — | pinned |
| memcached | tsan-dom-ea-lo-st-swmr | AllOpt-peel | 5 | 0.986 [0.940, 1.078] | — (single metric, pooled CV 2.4%) | 3.25 [3.00, 3.33] | — | pinned |
| memcached | tsan-dom_peeling | tsan-dom_peeling | 5 | 0.990 [0.934, 1.077] | — (single metric, pooled CV 2.4%) | 3.24 [3.00, 3.35] | — | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.019 [0.951, 1.079] | — (single metric, pooled CV 2.4%) | 3.14 [2.99, 3.29] | — | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.003 [0.961, 1.099] | — (single metric, pooled CV 2.4%) | 3.19 [2.94, 3.26] | — | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr-wp | AllOpt+peel (WP summaries) | 5 | 1.023 [0.961, 1.112] | — (single metric, pooled CV 2.4%) | 3.13 [2.90, 3.26] | — | pinned |
| memcached | tsan-ea | tsan-ea | 5 | 0.989 [0.933, 1.064] | — (single metric, pooled CV 2.4%) | 3.24 [3.03, 3.35] | — | pinned |
| memcached | tsan-lo | tsan-lo | 5 | 1.003 [0.946, 1.090] | — (single metric, pooled CV 2.4%) | 3.19 [2.96, 3.31] | — | pinned |
| memcached | tsan-sound-wp | sound (WP summaries) | 5 | 1.005 [0.947, 1.089] | — (single metric, pooled CV 2.4%) | 3.19 [2.97, 3.30] | — | pinned |
| memcached | tsan-st | tsan-st | 5 | 1.016 [0.948, 1.082] | — (single metric, pooled CV 2.4%) | 3.15 [2.98, 3.30] | — | pinned |
| memcached | tsan-stmt | tsan-stmt | 5 | 0.986 [0.944, 1.063] | — (single metric, pooled CV 2.4%) | 3.25 [3.04, 3.31] | — | pinned |
| memcached | tsan-swmr | tsan-swmr | 5 | 1.020 [0.932, 1.089] | — (single metric, pooled CV 2.4%) | 3.14 [2.96, 3.36] | — | pinned |
| redis | orig | orig | 5 | 8.007 [7.826, 8.211] | 7.846 [7.709, 8.066] | — | — | pinned |
| redis | tsan | tsan | 5 | — | — | 8.01 [7.83, 8.21] | — | pinned |
| redis | tsan-dom | tsan-dom | 5 | 0.992 [0.970, 1.015] | 0.992 [0.972, 1.017] | 8.08 [7.89, 8.27] | — | pinned |
| redis | tsan-dom-ea-lo-st-swmr | AllOpt-peel | 5 | 0.989 [0.975, 1.015] | 0.984 [0.968, 1.011] | 8.10 [7.89, 8.23] | — | pinned |
| redis | tsan-dom_peeling | tsan-dom_peeling | 5 | 0.996 [0.977, 1.024] | 0.990 [0.971, 1.021] | 8.04 [7.82, 8.22] | — | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.000 [0.983, 1.026] | 0.994 [0.978, 1.024] | 8.01 [7.80, 8.18] | — | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.958 [0.944, 0.985] | 0.951 [0.940, 0.981] | 8.36 [8.13, 8.51] | — | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr-wp | AllOpt+peel (WP summaries) | 5 | 0.998 [0.980, 1.027] | 0.997 [0.976, 1.023] | 8.02 [7.80, 8.20] | — | pinned |
| redis | tsan-ea | tsan-ea | 5 | 0.994 [0.974, 1.019] | 0.991 [0.972, 1.019] | 8.06 [7.85, 8.26] | — | pinned |
| redis | tsan-lo | tsan-lo | 5 | 0.981 [0.967, 1.010] | 0.981 [0.969, 1.009] | 8.16 [7.93, 8.31] | — | pinned |
| redis | tsan-sound-wp | sound (WP summaries) | 5 | 0.996 [0.971, 1.017] | 0.994 [0.968, 1.015] | 8.04 [7.87, 8.28] | — | pinned |
| redis | tsan-st | tsan-st | 5 | 0.980 [0.962, 1.003] | 0.978 [0.959, 1.002] | 8.17 [7.98, 8.35] | — | pinned |
| redis | tsan-stmt | tsan-stmt | 5 | 0.944 [0.927, 0.970] | 0.939 [0.922, 0.963] | 8.48 [8.26, 8.67] | — | pinned |
| redis | tsan-swmr | tsan-swmr | 5 | 0.988 [0.971, 1.015] | 0.982 [0.970, 1.014] | 8.11 [7.90, 8.29] | — | pinned |
| sqlite | orig | orig | 5 | 2.963 [2.785, 3.278] | 2.677 [2.639, 2.743] | — | — | pinned |
| sqlite | tsan | tsan | 5 | — | — | 2.96 [2.79, 3.28] | — | pinned |
| sqlite | tsan-dom | tsan-dom | 5 | 1.003 [0.947, 1.071] | 1.002 [0.985, 1.018] | 2.95 [2.76, 3.27] | — | pinned |
| sqlite | tsan-dom-ea-lo-st-swmr | AllOpt-peel | 5 | 1.020 [0.947, 1.076] | 1.002 [0.985, 1.027] | 2.91 [2.74, 3.25] | — | pinned |
| sqlite | tsan-dom_peeling | tsan-dom_peeling | 5 | 1.006 [0.958, 1.088] | 0.999 [0.990, 1.020] | 2.94 [2.71, 3.22] | — | pinned |
| sqlite | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.023 [0.942, 1.061] | 0.998 [0.975, 1.013] | 2.90 [2.77, 3.27] | — | pinned |
| sqlite | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 0.994 [0.938, 1.087] | 0.987 [0.967, 1.005] | 2.98 [2.72, 3.28] | — | pinned |
| sqlite | tsan-dom_peeling-ea-lo-st-swmr-wp | AllOpt+peel (WP summaries) | 5 | 1.049 [0.988, 1.113] | 0.998 [0.984, 1.017] | 2.82 [2.66, 3.11] | — | pinned |
| sqlite | tsan-ea | tsan-ea | 5 | 1.016 [0.962, 1.100] | 1.003 [0.987, 1.017] | 2.91 [2.68, 3.20] | — | pinned |
| sqlite | tsan-lo | tsan-lo | 5 | 0.990 [0.931, 1.048] | 0.994 [0.968, 1.010] | 2.99 [2.83, 3.31] | — | pinned |
| sqlite | tsan-sound-wp | sound (WP summaries) | 5 | 1.013 [0.942, 1.099] | 0.999 [0.978, 1.015] | 2.93 [2.68, 3.26] | — | pinned |
| sqlite | tsan-st | tsan-st | 5 | 1.016 [0.940, 1.079] | 0.997 [0.972, 1.014] | 2.92 [2.74, 3.28] | — | pinned |
| sqlite | tsan-stmt | tsan-stmt | 5 | 0.995 [0.928, 1.082] | 0.980 [0.966, 0.999] | 2.98 [2.74, 3.30] | — | pinned |
| sqlite | tsan-swmr | tsan-swmr | 5 | 1.006 [0.940, 1.089] | 0.995 [0.959, 1.009] | 2.94 [2.73, 3.27] | — | pinned |
| mysql | orig | orig | 5 | 9.699 [9.293, 10.082] | 9.609 [9.270, 9.970] | — | — | pinned |
| mysql | tsan | tsan | 5 | — | — | 9.70 [9.29, 10.08] | — | pinned |
| mysql | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.042 [0.985, 1.062] | 1.027 [0.991, 1.052] | 9.31 [9.07, 9.89] | — | pinned |
| mysql | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.018 [0.967, 1.037] | 1.000 [0.964, 1.023] | 9.52 [9.26, 10.05] | — | pinned |
| ffmpeg | orig | orig | 5 | 2.759 [2.700, 2.803] | — (all 4 subtests within 5%) | — | — | pinned |
| ffmpeg | tsan | tsan | 5 | — | — (all 4 subtests within 5%) | 2.76 [2.70, 2.80] | — | pinned |
| ffmpeg | tsan-dom | tsan-dom | 5 | 1.006 [0.996, 1.020] | — (all 4 subtests within 5%) | 2.74 [2.68, 2.77] | — | pinned |
| ffmpeg | tsan-dom-ea-lo-st-swmr | AllOpt-peel | 5 | 1.012 [0.996, 1.029] | — (all 4 subtests within 5%) | 2.73 [2.66, 2.77] | — | pinned |
| ffmpeg | tsan-dom_peeling | tsan-dom_peeling | 5 | 1.010 [0.994, 1.023] | — (all 4 subtests within 5%) | 2.73 [2.68, 2.78] | — | pinned |
| ffmpeg | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.006 [0.990, 1.024] | — (all 4 subtests within 5%) | 2.74 [2.68, 2.79] | — | pinned |
| ffmpeg | tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.123 [1.112, 1.142] | — (all 4 subtests within 5%) | 2.46 [2.40, 2.48] | — | pinned |
| ffmpeg | tsan-ea | tsan-ea | 5 | 0.996 [0.980, 1.011] | — (all 4 subtests within 5%) | 2.77 [2.71, 2.82] | — | pinned |
| ffmpeg | tsan-lo | tsan-lo | 5 | 1.001 [0.962, 1.013] | — (all 4 subtests within 5%) | 2.76 [2.70, 2.87] | — | pinned |
| ffmpeg | tsan-st | tsan-st | 5 | 1.000 [0.976, 1.011] | — (all 4 subtests within 5%) | 2.76 [2.71, 2.83] | — | pinned |
| ffmpeg | tsan-stmt | tsan-stmt | 5 | 1.113 [1.099, 1.129] | — (all 4 subtests within 5%) | 2.48 [2.43, 2.52] | — | pinned |
| ffmpeg | tsan-swmr | tsan-swmr | 5 | 1.004 [0.992, 1.019] | — (all 4 subtests within 5%) | 2.75 [2.69, 2.78] | — | pinned |
