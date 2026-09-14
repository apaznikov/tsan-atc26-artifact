# P5 summary — yield-d98873cda906

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; it is empty where every subtest is inside that bound. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| ffmpeg | orig | orig | 5 | 2.804 [2.738, 2.840] | — | — | 0 | pinned |
| ffmpeg | tsan | tsan | 5 | — | — | 2.80 [2.74, 2.84] | 514609 | pinned |
| ffmpeg | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.000 [0.993, 1.011] | — | 2.80 [2.74, 2.83] | 541449 | pinned |
| ffmpeg | tsan-dom_peeling-ea-lo-st-swmr-yoff | tsan-dom_peeling-ea-lo-st-swmr-yoff | 5 | 1.003 [0.990, 1.014] | — | 2.80 [2.73, 2.83] | 542683 | pinned |
| ffmpeg | tsan-sound | tsan-sound | 5 | 0.996 [0.990, 1.010] | — | 2.82 [2.74, 2.84] | 497309 | pinned |
| ffmpeg | tsan-sound-yoff | tsan-sound-yoff | 5 | 0.996 [0.992, 1.008] | — | 2.81 [2.75, 2.84] | 497409 | pinned |
| ffmpeg | tsan-stmt | tsan-stmt | 5 | 1.114 [1.103, 1.124] | — | 2.52 [2.46, 2.55] | 514540 | pinned |
| ffmpeg | tsan-stmt-yoff | tsan-stmt-yoff | 5 | 1.105 [1.099, 1.119] | — | 2.54 [2.47, 2.56] | 514493 | pinned |
| ffmpeg | tsan-yoff | tsan-yoff | 5 | 0.991 [0.982, 1.002] | — | 2.83 [2.76, 2.86] | 514609 | pinned |
| memcached | orig | orig | 5 | 3.378 [3.271, 3.590] | — | — | 0 | pinned |
| memcached | tsan | tsan | 5 | — | — | 3.38 [3.27, 3.59] | 6748 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.012 [0.944, 1.059] | — | 3.34 [3.13, 3.75] | 7127 | pinned |
| memcached | tsan-dom_peeling-ea-lo-st-swmr-yoff | tsan-dom_peeling-ea-lo-st-swmr-yoff | 5 | 1.016 [0.978, 1.031] | — | 3.33 [3.22, 3.62] | 7130 | pinned |
| memcached | tsan-sound | tsan-sound | 5 | 1.005 [0.945, 1.026] | — | 3.36 [3.23, 3.75] | 6640 | pinned |
| memcached | tsan-sound-yoff | tsan-sound-yoff | 5 | 1.006 [0.970, 1.031] | — | 3.36 [3.22, 3.65] | 6643 | pinned |
| memcached | tsan-stmt | tsan-stmt | 5 | 0.998 [0.956, 1.008] | — | 3.39 [3.29, 3.70] | 6810 | pinned |
| memcached | tsan-stmt-yoff | tsan-stmt-yoff | 5 | 1.003 [0.943, 1.026] | — | 3.37 [3.23, 3.75] | 6810 | pinned |
| memcached | tsan-yoff | tsan-yoff | 5 | 1.019 [0.983, 1.034] | — | 3.31 [3.21, 3.60] | 6748 | pinned |
| redis | orig | orig | 5 | 7.993 [7.725, 8.068] | 7.855 [7.635, 7.950] | — | 0 | pinned |
| redis | tsan | tsan | 5 | — | — | 7.99 [7.73, 8.07] | 37941 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.001 [0.954, 1.010] | 1.006 [0.966, 1.019] | 7.98 [7.82, 8.27] | 43242 | pinned |
| redis | tsan-dom_peeling-ea-lo-st-swmr-yoff | tsan-dom_peeling-ea-lo-st-swmr-yoff | 5 | 1.011 [0.981, 1.024] | 1.011 [0.991, 1.027] | 7.91 [7.72, 8.03] | 43291 | pinned |
| redis | tsan-sound | tsan-sound | 5 | 0.995 [0.968, 1.013] | 0.993 [0.976, 1.015] | 8.03 [7.80, 8.14] | 37604 | pinned |
| redis | tsan-sound-yoff | tsan-sound-yoff | 5 | 0.998 [0.970, 1.013] | 0.997 [0.978, 1.015] | 8.01 [7.80, 8.13] | 37607 | pinned |
| redis | tsan-stmt | tsan-stmt | 5 | 0.976 [0.945, 0.987] | 0.979 [0.955, 0.993] | 8.19 [8.01, 8.35] | 37878 | pinned |
| redis | tsan-stmt-yoff | tsan-stmt-yoff | 5 | 0.971 [0.942, 0.982] | 0.974 [0.954, 0.988] | 8.23 [8.04, 8.38] | 37882 | pinned |
| redis | tsan-yoff | tsan-yoff | 5 | 1.000 [0.975, 1.016] | 1.004 [0.985, 1.022] | 7.99 [7.78, 8.10] | 37941 | pinned |
| sqlite | orig | orig | 5 | 2.772 [2.540, 3.052] | 2.230 [2.161, 2.310] | — | 0 | pinned |
| sqlite | tsan | tsan | 5 | — | — | 2.77 [2.54, 3.05] | 57996 | pinned |
| sqlite | tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 0.989 [0.918, 1.101] | 1.002 [0.976, 1.024] | 2.80 [2.53, 3.04] | 61872 | pinned |
| sqlite | tsan-dom_peeling-ea-lo-st-swmr-yoff | tsan-dom_peeling-ea-lo-st-swmr-yoff | 5 | 0.991 [0.908, 1.057] | 0.986 [0.964, 1.012] | 2.80 [2.63, 3.09] | 61931 | pinned |
| sqlite | tsan-sound | tsan-sound | 5 | 0.961 [0.905, 1.046] | 0.983 [0.958, 1.018] | 2.88 [2.66, 3.09] | 57006 | pinned |
| sqlite | tsan-sound-yoff | tsan-sound-yoff | 5 | 1.008 [0.907, 1.083] | 0.996 [0.963, 1.023] | 2.75 [2.56, 3.08] | 57025 | pinned |
| sqlite | tsan-stmt | tsan-stmt | 5 | 1.012 [0.921, 1.087] | 0.980 [0.952, 1.010] | 2.74 [2.56, 3.04] | 57961 | pinned |
| sqlite | tsan-stmt-yoff | tsan-stmt-yoff | 5 | 1.004 [0.911, 1.075] | 0.972 [0.947, 1.002] | 2.76 [2.57, 3.05] | 57957 | pinned |
| sqlite | tsan-yoff | tsan-yoff | 5 | 1.015 [0.934, 1.095] | 1.004 [0.978, 1.034] | 2.73 [2.54, 3.01] | 57996 | pinned |
