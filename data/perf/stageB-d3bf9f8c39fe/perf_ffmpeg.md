# ffmpeg: performance (lower is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-08T08:56:45

| config | N | h264_libx264 median (mean ± σ, CV) | copy_passthrough median (mean ± σ, CV) | mjpeg median (mean ± σ, CV) | h265_libx265 median (mean ± σ, CV) |
|---|---|---|---|---|---|
| orig | 5 | 34.45 (34.5 ± 0.15, 0.4 %) | 0.12 (0.124 ± 0.0055, 4.4 %) | 3.53 (3.556 ± 0.057, 1.6 %) | 39.06 (39.1 ± 0.08, 0.2 %) |
| tsan | 5 | 42.49 (42.58 ± 0.23, 0.6 %) | 0.69 (0.684 ± 0.0089, 1.3 %) | 23.53 (23.53 ± 0.2, 0.9 %) | 51.71 (51.71 ± 0.1, 0.2 %) |
| tsan-dom | 5 | 42.45 (42.52 ± 0.15, 0.4 %) | 0.69 (0.69 ± 0.0071, 1.0 %) | 23.22 (23.26 ± 0.17, 0.7 %) | 51.71 (51.67 ± 0.098, 0.2 %) |
| tsan-dom-ea-lo-st-swmr | 5 | 42.36 (42.4 ± 0.21, 0.5 %) | 0.7 (0.696 ± 0.0055, 0.8 %) | 23.24 (23.23 ± 0.038, 0.2 %) | 51.63 (51.64 ± 0.14, 0.3 %) |
| tsan-dom_peeling | 5 | 42.41 (42.5 ± 0.25, 0.6 %) | 0.68 (0.686 ± 0.0089, 1.3 %) | 23.27 (23.35 ± 0.25, 1.1 %) | 51.67 (51.67 ± 0.061, 0.1 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 42.37 (42.46 ± 0.22, 0.5 %) | 0.69 (0.69 ± 0.0071, 1.0 %) | 23.2 (23.26 ± 0.16, 0.7 %) | 51.68 (51.64 ± 0.13, 0.3 %) |
| tsan-ea | 5 | 42.47 (42.42 ± 0.097, 0.2 %) | 0.68 (0.682 ± 0.0045, 0.7 %) | 23.69 (23.68 ± 0.22, 0.9 %) | 51.63 (51.62 ± 0.12, 0.2 %) |
| tsan-lo | 5 | 42.44 (42.49 ± 0.16, 0.4 %) | 0.71 (0.702 ± 0.013, 1.9 %) | 23.57 (23.62 ± 0.14, 0.6 %) | 51.66 (51.71 ± 0.091, 0.2 %) |
| tsan-sound | 5 | 42.37 (42.49 ± 0.23, 0.5 %) | 0.69 (0.688 ± 0.0045, 0.7 %) | 23.75 (23.61 ± 0.28, 1.2 %) | 51.59 (51.59 ± 0.08, 0.2 %) |
| tsan-st | 5 | 42.47 (42.52 ± 0.13, 0.3 %) | 0.7 (0.7 ± 0.0071, 1.0 %) | 23.52 (23.45 ± 0.12, 0.5 %) | 51.74 (51.73 ± 0.11, 0.2 %) |
| tsan-stmt | 5 | 42.45 (42.49 ± 0.21, 0.5 %) | 0.44 (0.438 ± 0.0084, 1.9 %) | 24.02 (24.11 ± 0.3, 1.2 %) | 51.75 (51.75 ± 0.019, 0.0 %) |
| tsan-swmr | 5 | 42.5 (42.52 ± 0.18, 0.4 %) | 0.7 (0.692 ± 0.011, 1.6 %) | 23.68 (23.67 ± 0.2, 0.8 %) | 51.83 (51.78 ± 0.2, 0.4 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 2.813 [2.723, 2.825] | — | — | 0 | pinned | h264_libx264:1.23, copy_passthrough:5.75, mjpeg:6.67, h265_libx265:1.32 |
| tsan | tsan | 5 | — | — | 2.81 [2.72, 2.82] | 514609 | pinned |  |
| tsan-dom | tsan-dom | 5 | 1.004 [0.992, 1.010] | — | 2.80 [2.72, 2.82] | 490223 | pinned | h264_libx264:1.00, copy_passthrough:1.00, mjpeg:1.01, h265_libx265:1.00 |
| tsan-dom-ea-lo-st-swmr | AllOpt-peel | 5 | 1.001 [0.991, 1.008] | — | 2.81 [2.72, 2.82] | 474557 | pinned | h264_libx264:1.00, copy_passthrough:0.99, mjpeg:1.01, h265_libx265:1.00 |
| tsan-dom_peeling | tsan-dom_peeling | 5 | 1.007 [0.991, 1.011] | — | 2.79 [2.72, 2.82] | 560213 | pinned | h264_libx264:1.00, copy_passthrough:1.01, mjpeg:1.01, h265_libx265:1.00 |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.004 [0.992, 1.011] | — | 2.80 [2.72, 2.82] | 542684 | pinned | h264_libx264:1.00, copy_passthrough:1.00, mjpeg:1.01, h265_libx265:1.00 |
| tsan-ea | tsan-ea | 5 | 1.002 [0.991, 1.009] | — | 2.81 [2.72, 2.82] | 497410 | pinned | h264_libx264:1.00, copy_passthrough:1.01, mjpeg:0.99, h265_libx265:1.00 |
| tsan-lo | tsan-lo | 5 | 0.993 [0.983, 1.006] | — | 2.83 [2.74, 2.84] | 514609 | pinned | h264_libx264:1.00, copy_passthrough:0.97, mjpeg:1.00, h265_libx265:1.00 |
| tsan-sound | tsan-sound | 5 | 0.999 [0.989, 1.008] | — | 2.82 [2.73, 2.83] | 497410 | pinned | h264_libx264:1.00, copy_passthrough:1.00, mjpeg:0.99, h265_libx265:1.00 |
| tsan-st | tsan-st | 5 | 0.996 [0.986, 1.004] | — | 2.82 [2.74, 2.84] | 514609 | pinned | h264_libx264:1.00, copy_passthrough:0.99, mjpeg:1.00, h265_libx265:1.00 |
| tsan-stmt | tsan-stmt | 5 | 1.113 [1.097, 1.124] | — | 2.53 [2.45, 2.55] | 514493 | pinned | h264_libx264:1.00, copy_passthrough:1.57, mjpeg:0.98, h265_libx265:1.00 |
| tsan-swmr | tsan-swmr | 5 | 0.994 [0.985, 1.007] | — | 2.83 [2.73, 2.84] | 514609 | pinned | h264_libx264:1.00, copy_passthrough:0.99, mjpeg:0.99, h265_libx265:1.00 |
