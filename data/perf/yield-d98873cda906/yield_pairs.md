# Yield stage: each configuration against its own yield-off build

Ratio > 1 means the yield changes are faster. `stable subtests` restricts to the subtests whose pooled run-to-run CV, taken across every configuration of the application, is at most 5 %; it is blank where the filter keeps everything or would keep fewer than half.

| app | configuration | N on / off | yield on vs off [95 %] | stable subtests [95 %] | sites on / off |
|---|---|---|---|---|---|
| memcached | tsan | 5 / 5 | 0.981 [0.967, 1.017] | — | 6748 / 6748 |
| memcached | AllOpt+peel | 5 / 5 | 0.996 [0.929, 1.068] | — | 7127 / 7130 |
| memcached | tsan-sound | 5 / 5 | 1.000 [0.929, 1.042] | — | 6640 / 6643 |
| memcached | tsan-stmt | 5 / 5 | 0.995 [0.945, 1.054] | — | 6810 / 6810 |
| redis | tsan | 5 / 5 | 1.000 [0.985, 1.025] | 0.996 [0.979, 1.016] | 37941 / 37941 |
| redis | AllOpt+peel | 5 / 5 | 0.991 [0.951, 1.008] | 0.995 [0.959, 1.010] | 43242 / 43291 |
| redis | tsan-sound | 5 / 5 | 0.998 [0.977, 1.020] | 0.996 [0.980, 1.018] | 37604 / 37607 |
| redis | tsan-stmt | 5 / 5 | 1.005 [0.984, 1.024] | 1.005 [0.984, 1.024] | 37878 / 37882 |
| sqlite | tsan | 5 / 5 | 0.985 [0.915, 1.072] | 0.996 [0.968, 1.022] | 57996 / 57996 |
| sqlite | AllOpt+peel | 5 / 5 | 0.999 [0.953, 1.105] | 1.016 [0.993, 1.030] | 61872 / 61931 |
| sqlite | tsan-sound | 5 / 5 | 0.954 [0.914, 1.050] | 0.987 [0.963, 1.026] | 57006 / 57025 |
| sqlite | tsan-stmt | 5 / 5 | 1.008 [0.931, 1.081] | 1.008 [0.976, 1.036] | 57961 / 57957 |
| ffmpeg | tsan | 5 / 5 | 1.009 [0.998, 1.019] | — | 514609 / 514609 |
| ffmpeg | AllOpt+peel | 5 / 5 | 0.997 [0.989, 1.010] | — | 541449 / 542683 |
| ffmpeg | tsan-sound | 5 / 5 | 1.000 [0.992, 1.008] | — | 497309 / 497409 |
| ffmpeg | tsan-stmt | 5 / 5 | 1.008 [0.996, 1.012] | — | 514540 / 514493 |
