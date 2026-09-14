# ffmpeg: performance (lower is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-09T09:06:05

| config | N | h264_libx264 median (mean ± σ, CV) | copy_passthrough median (mean ± σ, CV) | mjpeg median (mean ± σ, CV) | h265_libx265 median (mean ± σ, CV) |
|---|---|---|---|---|---|
| orig | 5 | 36.97 (37.07 ± 0.18, 0.5 %) | 0.13 (0.134 ± 0.0055, 4.1 %) | 3.85 (3.832 ± 0.056, 1.5 %) | 40.9 (40.84 ± 0.13, 0.3 %) |
| tsan | 5 | 45.42 (45.46 ± 0.21, 0.5 %) | 0.74 (0.744 ± 0.011, 1.5 %) | 25.56 (25.59 ± 0.076, 0.3 %) | 54.45 (54.44 ± 0.086, 0.2 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 45.43 (45.53 ± 0.2, 0.4 %) | 0.74 (0.742 ± 0.0084, 1.1 %) | 25.5 (25.51 ± 0.12, 0.5 %) | 54.46 (54.42 ± 0.12, 0.2 %) |
| tsan-dom_peeling-ea-lo-st-swmr-yoff | 5 | 45.43 (45.41 ± 0.15, 0.3 %) | 0.74 (0.746 ± 0.015, 2.0 %) | 25.22 (25.24 ± 0.087, 0.3 %) | 54.48 (54.45 ± 0.15, 0.3 %) |
| tsan-sound | 5 | 45.6 (45.54 ± 0.22, 0.5 %) | 0.75 (0.746 ± 0.011, 1.5 %) | 25.46 (25.47 ± 0.088, 0.3 %) | 54.64 (54.62 ± 0.091, 0.2 %) |
| tsan-sound-yoff | 5 | 45.49 (45.52 ± 0.21, 0.5 %) | 0.75 (0.746 ± 0.0055, 0.7 %) | 25.53 (25.52 ± 0.029, 0.1 %) | 54.54 (54.49 ± 0.15, 0.3 %) |
| tsan-stmt | 5 | 45.42 (45.6 ± 0.34, 0.7 %) | 0.47 (0.47 ± 0, 0.0 %) | 26.13 (26.28 ± 0.32, 1.2 %) | 54.49 (54.53 ± 0.067, 0.1 %) |
| tsan-stmt-yoff | 5 | 45.82 (45.77 ± 0.31, 0.7 %) | 0.48 (0.478 ± 0.0045, 0.9 %) | 26.18 (26.21 ± 0.096, 0.4 %) | 54.58 (54.55 ± 0.16, 0.3 %) |
| tsan-yoff | 5 | 45.6 (45.64 ± 0.18, 0.4 %) | 0.76 (0.76 ± 0.012, 1.6 %) | 25.68 (25.7 ± 0.1, 0.4 %) | 54.52 (54.51 ± 0.05, 0.1 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 2.804 [2.738, 2.840] | — | — | 0 | pinned | h264_libx264:1.23, copy_passthrough:5.69, mjpeg:6.64, h265_libx265:1.33 |
| tsan | tsan | 5 | — | — | 2.80 [2.74, 2.84] | 514609 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.000 [0.993, 1.011] | — | 2.80 [2.74, 2.83] | 541449 | pinned | h264_libx264:1.00, copy_passthrough:1.00, mjpeg:1.00, h265_libx265:1.00 |
| tsan-dom_peeling-ea-lo-st-swmr-yoff | tsan-dom_peeling-ea-lo-st-swmr-yoff | 5 | 1.003 [0.990, 1.014] | — | 2.80 [2.73, 2.83] | 542683 | pinned | h264_libx264:1.00, copy_passthrough:1.00, mjpeg:1.01, h265_libx265:1.00 |
| tsan-sound | tsan-sound | 5 | 0.996 [0.990, 1.010] | — | 2.82 [2.74, 2.84] | 497309 | pinned | h264_libx264:1.00, copy_passthrough:0.99, mjpeg:1.00, h265_libx265:1.00 |
| tsan-sound-yoff | tsan-sound-yoff | 5 | 0.996 [0.992, 1.008] | — | 2.81 [2.75, 2.84] | 497409 | pinned | h264_libx264:1.00, copy_passthrough:0.99, mjpeg:1.00, h265_libx265:1.00 |
| tsan-stmt | tsan-stmt | 5 | 1.114 [1.103, 1.124] | — | 2.52 [2.46, 2.55] | 514540 | pinned | h264_libx264:1.00, copy_passthrough:1.57, mjpeg:0.98, h265_libx265:1.00 |
| tsan-stmt-yoff | tsan-stmt-yoff | 5 | 1.105 [1.099, 1.119] | — | 2.54 [2.47, 2.56] | 514493 | pinned | h264_libx264:0.99, copy_passthrough:1.54, mjpeg:0.98, h265_libx265:1.00 |
| tsan-yoff | tsan-yoff | 5 | 0.991 [0.982, 1.002] | — | 2.83 [2.76, 2.86] | 514609 | pinned | h264_libx264:1.00, copy_passthrough:0.97, mjpeg:1.00, h265_libx265:1.00 |
