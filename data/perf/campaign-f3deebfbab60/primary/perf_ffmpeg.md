# ffmpeg: performance (lower is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-16T22:02:32

| config | N | h264_libx264 median (mean ± σ, CV) | copy_passthrough median (mean ± σ, CV) | mjpeg median (mean ± σ, CV) | h265_libx265 median (mean ± σ, CV) |
|---|---|---|---|---|---|
| orig | 5 | 36.22 (36.21 ± 0.25, 0.7 %) | 0.14 (0.142 ± 0.0045, 3.1 %) | 3.53 (3.524 ± 0.061, 1.7 %) | 31.74 (31.73 ± 0.044, 0.1 %) |
| tsan | 5 | 45.42 (45.5 ± 0.33, 0.7 %) | 0.8 (0.806 ± 0.015, 1.9 %) | 21.04 (20.98 ± 0.21, 1.0 %) | 43.06 (43.18 ± 0.34, 0.8 %) |
| tsan-dom | 5 | 45.13 (45.19 ± 0.27, 0.6 %) | 0.81 (0.806 ± 0.0055, 0.7 %) | 20.46 (20.59 ± 0.23, 1.1 %) | 43.04 (43.02 ± 0.09, 0.2 %) |
| tsan-dom-ea-lo-st-swmr | 5 | 45.06 (45.26 ± 0.51, 1.1 %) | 0.8 (0.796 ± 0.021, 2.6 %) | 20.3 (20.44 ± 0.24, 1.2 %) | 42.96 (42.93 ± 0.061, 0.1 %) |
| tsan-dom_peeling | 5 | 45.32 (45.28 ± 0.45, 1.0 %) | 0.79 (0.798 ± 0.013, 1.6 %) | 20.56 (20.65 ± 0.29, 1.4 %) | 43.02 (43.07 ± 0.3, 0.7 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 45.27 (45.45 ± 0.53, 1.2 %) | 0.81 (0.81 ± 0.021, 2.6 %) | 20.48 (20.51 ± 0.2, 1.0 %) | 42.86 (42.92 ± 0.22, 0.5 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 45.29 (45.3 ± 0.14, 0.3 %) | 0.51 (0.508 ± 0.0084, 1.6 %) | 20.84 (20.91 ± 0.16, 0.8 %) | 42.97 (42.92 ± 0.16, 0.4 %) |
| tsan-ea | 5 | 45.82 (45.85 ± 0.65, 1.4 %) | 0.81 (0.814 ± 0.017, 2.1 %) | 20.9 (21.02 ± 0.26, 1.3 %) | 43.04 (43.06 ± 0.11, 0.3 %) |
| tsan-lo | 5 | 45.53 (45.52 ± 0.44, 1.0 %) | 0.81 (0.828 ± 0.041, 4.9 %) | 20.8 (21.11 ± 0.55, 2.6 %) | 42.82 (43.06 ± 0.46, 1.1 %) |
| tsan-st | 5 | 45.4 (46 ± 1.3, 2.8 %) | 0.81 (0.816 ± 0.0089, 1.1 %) | 20.86 (21 ± 0.31, 1.5 %) | 42.99 (42.99 ± 0.22, 0.5 %) |
| tsan-stmt | 5 | 45.27 (45.42 ± 0.35, 0.8 %) | 0.52 (0.52 ± 0.0071, 1.4 %) | 21.21 (21.27 ± 0.25, 1.2 %) | 42.98 (43.05 ± 0.21, 0.5 %) |
| tsan-swmr | 5 | 45.58 (45.58 ± 0.35, 0.8 %) | 0.8 (0.798 ± 0.0084, 1.0 %) | 20.77 (20.84 ± 0.2, 0.9 %) | 42.85 (42.96 ± 0.22, 0.5 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 2.759 [2.700, 2.803] | — (all 4 subtests within 5%) | — | — | pinned | h264_libx264:1.25, copy_passthrough:5.71, mjpeg:5.96, h265_libx265:1.36 |
| tsan | tsan | 5 | — | — (all 4 subtests within 5%) | 2.76 [2.70, 2.80] | — | pinned |  |
| tsan-dom | tsan-dom | 5 | 1.006 [0.996, 1.020] | — (all 4 subtests within 5%) | 2.74 [2.68, 2.77] | — | pinned | h264_libx264:1.01, copy_passthrough:0.99, mjpeg:1.03, h265_libx265:1.00 |
| tsan-dom-ea-lo-st-swmr | AllOpt-peel | 5 | 1.012 [0.996, 1.029] | — (all 4 subtests within 5%) | 2.73 [2.66, 2.77] | — | pinned | h264_libx264:1.01, copy_passthrough:1.00, mjpeg:1.04, h265_libx265:1.00 |
| tsan-dom_peeling | tsan-dom_peeling | 5 | 1.010 [0.994, 1.023] | — (all 4 subtests within 5%) | 2.73 [2.68, 2.78] | — | pinned | h264_libx264:1.00, copy_passthrough:1.01, mjpeg:1.02, h265_libx265:1.00 |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.006 [0.990, 1.024] | — (all 4 subtests within 5%) | 2.74 [2.68, 2.79] | — | pinned | h264_libx264:1.00, copy_passthrough:0.99, mjpeg:1.03, h265_libx265:1.00 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.123 [1.112, 1.142] | — (all 4 subtests within 5%) | 2.46 [2.40, 2.48] | — | pinned | h264_libx264:1.00, copy_passthrough:1.57, mjpeg:1.01, h265_libx265:1.00 |
| tsan-ea | tsan-ea | 5 | 0.996 [0.980, 1.011] | — (all 4 subtests within 5%) | 2.77 [2.71, 2.82] | — | pinned | h264_libx264:0.99, copy_passthrough:0.99, mjpeg:1.01, h265_libx265:1.00 |
| tsan-lo | tsan-lo | 5 | 1.001 [0.962, 1.013] | — (all 4 subtests within 5%) | 2.76 [2.70, 2.87] | — | pinned | h264_libx264:1.00, copy_passthrough:0.99, mjpeg:1.01, h265_libx265:1.01 |
| tsan-st | tsan-st | 5 | 1.000 [0.976, 1.011] | — (all 4 subtests within 5%) | 2.76 [2.71, 2.83] | — | pinned | h264_libx264:1.00, copy_passthrough:0.99, mjpeg:1.01, h265_libx265:1.00 |
| tsan-stmt | tsan-stmt | 5 | 1.113 [1.099, 1.129] | — (all 4 subtests within 5%) | 2.48 [2.43, 2.52] | — | pinned | h264_libx264:1.00, copy_passthrough:1.54, mjpeg:0.99, h265_libx265:1.00 |
| tsan-swmr | tsan-swmr | 5 | 1.004 [0.992, 1.019] | — (all 4 subtests within 5%) | 2.75 [2.69, 2.78] | — | pinned | h264_libx264:1.00, copy_passthrough:1.00, mjpeg:1.01, h265_libx265:1.00 |
