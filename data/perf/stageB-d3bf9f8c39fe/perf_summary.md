# P5 summary — stageB-d3bf9f8c39fe

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; it is empty where every subtest is inside that bound. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| ffmpeg | orig | orig | 5 | 2.813 [2.723, 2.825] | — | — | 0 | pinned |
| ffmpeg | tsan | tsan | 5 | — | — | 2.81 [2.72, 2.82] | 514609 | pinned |
| ffmpeg | tsan-dom | tsan-dom | 5 | 1.004 [0.992, 1.010] | — | 2.80 [2.72, 2.82] | 490223 | pinned |
| ffmpeg | tsan-dom-ea-lo-st-swmr | AllOpt-peel | 5 | 1.001 [0.991, 1.008] | — | 2.81 [2.72, 2.82] | 474557 | pinned |
| ffmpeg | tsan-dom_peeling | tsan-dom_peeling | 5 | 1.007 [0.991, 1.011] | — | 2.79 [2.72, 2.82] | 560213 | pinned |
| ffmpeg | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.004 [0.992, 1.011] | — | 2.80 [2.72, 2.82] | 542684 | pinned |
| ffmpeg | tsan-ea | tsan-ea | 5 | 1.002 [0.991, 1.009] | — | 2.81 [2.72, 2.82] | 497410 | pinned |
| ffmpeg | tsan-lo | tsan-lo | 5 | 0.993 [0.983, 1.006] | — | 2.83 [2.74, 2.84] | 514609 | pinned |
| ffmpeg | tsan-sound | tsan-sound | 5 | 0.999 [0.989, 1.008] | — | 2.82 [2.73, 2.83] | 497410 | pinned |
| ffmpeg | tsan-st | tsan-st | 5 | 0.996 [0.986, 1.004] | — | 2.82 [2.74, 2.84] | 514609 | pinned |
| ffmpeg | tsan-stmt | tsan-stmt | 5 | 1.113 [1.097, 1.124] | — | 2.53 [2.45, 2.55] | 514493 | pinned |
| ffmpeg | tsan-swmr | tsan-swmr | 5 | 0.994 [0.985, 1.007] | — | 2.83 [2.73, 2.84] | 514609 | pinned |
| memcached | orig | orig | 5 | 2.828 [2.674, 3.021] | — | — | 0 | pinned |
| memcached | tsan | tsan | 5 | — | — | 2.83 [2.67, 3.02] | 6748 | pinned |
| memcached | tsan-dom | tsan-dom | 5 | 1.000 [0.919, 1.056] | — | 2.83 [2.66, 3.12] | 6508 | pinned |
| memcached | tsan-dom-ea-lo-st-swmr | AllOpt-peel | 5 | 0.998 [0.918, 1.047] | — | 2.83 [2.69, 3.13] | 6408 | pinned |
| memcached | tsan-dom_peeling | tsan-dom_peeling | 5 | 0.961 [0.936, 1.030] | — | 2.94 [2.73, 3.07] | 7270 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 0.972 [0.946, 1.042] | — | 2.91 [2.70, 3.04] | 7130 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr-wp | AllOpt+peel (WP summaries) | 5 | 0.986 [0.925, 1.080] | — | 2.87 [2.60, 3.10] | 6699 | pinned |
| memcached | tsan-ea | tsan-ea | 5 | 0.957 [0.934, 1.060] | — | 2.96 [2.65, 3.08] | 6653 | pinned |
| memcached | tsan-lo | tsan-lo | 5 | 0.967 [0.948, 1.073] | — | 2.92 [2.62, 3.03] | 6739 | pinned |
| memcached | tsan-sound | tsan-sound | 5 | 0.968 [0.943, 1.020] | — | 2.92 [2.76, 3.05] | 6643 | pinned |
| memcached | tsan-sound-tfn | tsan-sound-tfn | 5 | 0.972 [0.947, 1.054] | — | 2.91 [2.67, 3.03] | 6590 | pinned |
| memcached | tsan-sound-tfn-wp | tsan-sound-tfn-wp | 5 | 0.960 [0.944, 1.063] | — | 2.94 [2.64, 3.04] | 6227 | pinned |
| memcached | tsan-sound-wp | sound (WP summaries) | 5 | 0.969 [0.946, 1.061] | — | 2.92 [2.65, 3.04] | 6280 | pinned |
| memcached | tsan-st | tsan-st | 5 | 0.992 [0.939, 1.091] | — | 2.85 [2.58, 3.06] | 6747 | pinned |
| memcached | tsan-stmt | tsan-stmt | 5 | 0.974 [0.929, 1.068] | — | 2.90 [2.63, 3.09] | 6810 | pinned |
| memcached | tsan-swmr | tsan-swmr | 5 | 0.993 [0.980, 1.054] | — | 2.85 [2.67, 2.93] | 6748 | pinned |
| mysql | orig | orig | 5 | 10.836 [9.867, 11.728] | — | — | 0 | pinned |
| mysql | tsan | tsan | 5 | — | — | 10.84 [9.87, 11.73] | 602434 | pinned |
| mysql | tsan-dom | tsan-dom | 5 | 1.009 [0.933, 1.069] | — | 10.74 [9.95, 11.65] | 578658 | pinned |
| mysql | tsan-dom-ea-lo-st-swmr | AllOpt-peel | 5 | 1.022 [0.938, 1.082] | — | 10.61 [9.83, 11.55] | 574085 | pinned |
| mysql | tsan-dom_peeling | tsan-dom_peeling | 5 | 0.999 [0.923, 1.065] | — | 10.85 [9.98, 11.74] | 645512 | pinned |
| mysql | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.012 [0.954, 1.096] | — | 10.71 [9.67, 11.36] | 640355 | pinned |
| mysql | tsan-ea | tsan-ea | 5 | 1.034 [0.959, 1.080] | — | 10.48 [9.78, 11.35] | 597140 | pinned |
| mysql | tsan-lo | tsan-lo | 5 | 0.986 [0.903, 1.040] | — | 10.99 [10.23, 12.05] | 602434 | pinned |
| mysql | tsan-sound | tsan-sound | 5 | 1.021 [0.938, 1.078] | — | 10.62 [9.82, 11.55] | 597140 | pinned |
| mysql | tsan-st | tsan-st | 5 | 0.983 [0.896, 1.056] | — | 11.02 [10.05, 12.11] | 602434 | pinned |
| mysql | tsan-stmt | tsan-stmt | 5 | 0.983 [0.912, 1.053] | — | 11.02 [10.09, 11.90] | 602809 | pinned |
| mysql | tsan-swmr | tsan-swmr | 5 | 1.006 [0.917, 1.073] | — | 10.78 [9.90, 11.83] | 602434 | pinned |
| redis | orig | orig | 5 | 7.934 [7.747, 8.148] | 7.896 [7.708, 8.108] | — | 0 | pinned |
| redis | tsan | tsan | 5 | — | — | 7.93 [7.75, 8.15] | 37941 | pinned |
| redis | tsan-dom | tsan-dom | 5 | 1.020 [1.002, 1.045] | 1.016 [1.001, 1.043] | 7.78 [7.59, 7.93] | 37396 | pinned |
| redis | tsan-dom-ea-lo-st-swmr | AllOpt-peel | 5 | 1.010 [0.991, 1.033] | 1.007 [0.988, 1.030] | 7.85 [7.68, 8.04] | 37077 | pinned |
| redis | tsan-dom_peeling | tsan-dom_peeling | 5 | 1.017 [0.989, 1.035] | 1.014 [0.989, 1.034] | 7.80 [7.67, 8.03] | 43668 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.008 [0.994, 1.038] | 1.009 [0.994, 1.039] | 7.87 [7.64, 8.00] | 43292 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr-wp | AllOpt+peel (WP summaries) | 5 | 1.027 [1.008, 1.051] | 1.022 [1.007, 1.049] | 7.72 [7.55, 7.88] | 40692 | pinned |
| redis | tsan-ea | tsan-ea | 5 | 1.012 [0.988, 1.029] | 1.007 [0.988, 1.028] | 7.84 [7.71, 8.05] | 37608 | pinned |
| redis | tsan-lo | tsan-lo | 5 | 1.010 [0.989, 1.034] | 1.006 [0.988, 1.033] | 7.86 [7.67, 8.04] | 37941 | pinned |
| redis | tsan-sound | tsan-sound | 5 | 1.003 [0.984, 1.027] | 0.998 [0.982, 1.024] | 7.91 [7.73, 8.08] | 37608 | pinned |
| redis | tsan-sound-wp | sound (WP summaries) | 5 | 1.017 [0.994, 1.038] | 1.011 [0.990, 1.035] | 7.80 [7.64, 8.01] | 35372 | pinned |
| redis | tsan-st | tsan-st | 5 | 1.017 [0.991, 1.037] | 1.014 [0.990, 1.036] | 7.80 [7.65, 8.03] | 37941 | pinned |
| redis | tsan-stmt | tsan-stmt | 5 | 0.969 [0.950, 0.990] | 0.970 [0.951, 0.990] | 8.19 [7.99, 8.37] | 37882 | pinned |
| redis | tsan-swmr | tsan-swmr | 5 | 1.008 [0.993, 1.035] | 1.004 [0.990, 1.033] | 7.87 [7.67, 8.01] | 37941 | pinned |
| sqlite | orig | orig | 5 | 3.181 [2.937, 3.482] | 2.214 [2.136, 2.256] | — | 0 | pinned |
| sqlite | tsan | tsan | 5 | — | — | 3.18 [2.94, 3.48] | 57996 | pinned |
| sqlite | tsan-dom | tsan-dom | 5 | 0.978 [0.924, 1.126] | 1.001 [0.989, 1.012] | 3.25 [2.80, 3.49] | 57033 | pinned |
| sqlite | tsan-dom-ea-lo-st-swmr | AllOpt-peel | 5 | 1.036 [0.924, 1.110] | 1.003 [0.997, 1.012] | 3.07 [2.89, 3.47] | 56087 | pinned |
| sqlite | tsan-dom_peeling | tsan-dom_peeling | 5 | 0.978 [0.920, 1.050] | 1.000 [0.992, 1.010] | 3.25 [3.03, 3.51] | 62996 | pinned |
| sqlite | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 0.999 [0.921, 1.098] | 1.002 [0.994, 1.013] | 3.18 [2.93, 3.49] | 61931 | pinned |
| sqlite | tsan-dom_peeling-ea-lo-st-swmr-wp | AllOpt+peel (WP summaries) | 5 | 0.993 [0.923, 1.074] | 1.002 [0.969, 1.014] | 3.20 [2.98, 3.50] | 61827 | pinned |
| sqlite | tsan-ea | tsan-ea | 5 | 0.997 [0.948, 1.110] | 1.002 [0.993, 1.011] | 3.19 [2.88, 3.43] | 57025 | pinned |
| sqlite | tsan-lo | tsan-lo | 5 | 0.964 [0.899, 1.077] | 0.995 [0.988, 1.007] | 3.30 [2.97, 3.58] | 57996 | pinned |
| sqlite | tsan-sound | tsan-sound | 5 | 0.991 [0.921, 1.062] | 1.003 [0.996, 1.013] | 3.21 [2.98, 3.49] | 57025 | pinned |
| sqlite | tsan-sound-wp | sound (WP summaries) | 5 | 1.024 [0.941, 1.120] | 0.997 [0.983, 1.008] | 3.11 [2.85, 3.43] | 56890 | pinned |
| sqlite | tsan-st | tsan-st | 5 | 1.000 [0.920, 1.093] | 0.999 [0.988, 1.010] | 3.18 [2.93, 3.48] | 57996 | pinned |
| sqlite | tsan-stmt | tsan-stmt | 5 | 0.988 [0.942, 1.130] | 0.983 [0.978, 0.995] | 3.22 [2.85, 3.44] | 57957 | pinned |
| sqlite | tsan-swmr | tsan-swmr | 5 | 0.994 [0.930, 1.118] | 1.003 [0.996, 1.013] | 3.20 [2.83, 3.46] | 57996 | pinned |
