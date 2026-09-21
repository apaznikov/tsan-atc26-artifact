# ffmpeg: performance (lower is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=40ec0d95cd9e started=2026-09-21T13:58:31

| config | N | h264_libx264 median (mean ± σ, CV) | copy_passthrough median (mean ± σ, CV) | mjpeg median (mean ± σ, CV) | h265_libx265 median (mean ± σ, CV) |
|---|---|---|---|---|---|
| orig | 5 | 12.34 (12.37 ± 0.11, 0.9 %) | 0.13 (0.132 ± 0.0045, 3.4 %) | 3.41 (3.404 ± 0.068, 2.0 %) | 24.94 (25.05 ± 0.24, 1.0 %) |
| tsan | 5 | 17.7 (17.68 ± 0.098, 0.6 %) | 0.82 (0.818 ± 0.016, 2.0 %) | 18.16 (18.23 ± 0.13, 0.7 %) | 35.77 (35.78 ± 0.14, 0.4 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 17.57 (17.6 ± 0.15, 0.9 %) | 0.81 (0.808 ± 0.015, 1.8 %) | 14.37 (14.4 ± 0.14, 1.0 %) | 35.63 (35.67 ± 0.29, 0.8 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 17.71 (17.68 ± 0.18, 1.0 %) | 0.51 (0.51 ± 0.0071, 1.4 %) | 14.72 (14.73 ± 0.11, 0.8 %) | 35.76 (35.78 ± 0.21, 0.6 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt-nofe | 5 | 17.62 (17.62 ± 0.13, 0.8 %) | 0.5 (0.492 ± 0.011, 2.2 %) | 14.54 (14.55 ± 0.15, 1.0 %) | 35.53 (35.64 ± 0.24, 0.7 %) |
| tsan-nofe | 5 | 17.5 (17.47 ± 0.15, 0.9 %) | 0.79 (0.786 ± 0.011, 1.5 %) | 17.92 (18.02 ± 0.21, 1.2 %) | 35.66 (35.64 ± 0.15, 0.4 %) |
| tsan-stmt | 5 | 17.74 (17.69 ± 0.16, 0.9 %) | 0.49 (0.492 ± 0.0084, 1.7 %) | 18.44 (18.51 ± 0.17, 0.9 %) | 35.71 (35.71 ± 0.18, 0.5 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 2.883 [2.799, 2.916] | — (all 4 subtests within 5%) | — | 0 | pinned | h264_libx264:1.43, copy_passthrough:6.31, mjpeg:5.33, h265_libx265:1.43 |
| tsan | tsan | 5 | — | — (all 4 subtests within 5%) | 2.88 [2.80, 2.92] | 507825 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.067 [1.050, 1.079] | — (all 4 subtests within 5%) | 2.70 [2.63, 2.74] | 535690 | pinned | h264_libx264:1.01, copy_passthrough:1.01, mjpeg:1.26, h265_libx265:1.00 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.187 [1.171, 1.201] | — (all 4 subtests within 5%) | 2.43 [2.36, 2.46] | 535687 | pinned | h264_libx264:1.00, copy_passthrough:1.61, mjpeg:1.23, h265_libx265:1.00 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt-nofe | tsan-dom_peeling-ea-lo-st-swmr-stmt-nofe | 5 | 1.200 [1.185, 1.221] | — (all 4 subtests within 5%) | 2.40 [2.32, 2.43] | 535631 | pinned | h264_libx264:1.00, copy_passthrough:1.64, mjpeg:1.25, h265_libx265:1.01 |
| tsan-nofe | tsan-nofe | 5 | 1.016 [1.002, 1.029] | — (all 4 subtests within 5%) | 2.84 [2.75, 2.87] | 507823 | pinned | h264_libx264:1.01, copy_passthrough:1.04, mjpeg:1.01, h265_libx265:1.00 |
| tsan-stmt | tsan-stmt | 5 | 1.133 [1.114, 1.146] | — (all 4 subtests within 5%) | 2.55 [2.48, 2.58] | 507709 | pinned | h264_libx264:1.00, copy_passthrough:1.67, mjpeg:0.98, h265_libx265:1.00 |
