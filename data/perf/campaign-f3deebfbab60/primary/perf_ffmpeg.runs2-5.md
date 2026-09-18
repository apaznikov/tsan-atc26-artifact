# ffmpeg: performance (lower is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-16T22:02:32

| config | N | h264_libx264 median (mean ± σ, CV) | copy_passthrough median (mean ± σ, CV) | mjpeg median (mean ± σ, CV) | h265_libx265 median (mean ± σ, CV) |
|---|---|---|---|---|---|
| orig | 4 | 36.12 (36.12 ± 0.2, 0.6 %) | 0.14 (0.1425 ± 0.005, 3.5 %) | 3.51 (3.507 ± 0.056, 1.6 %) | 31.73 (31.72 ± 0.048, 0.2 %) |
| tsan | 4 | 45.31 (45.41 ± 0.3, 0.7 %) | 0.805 (0.8075 ± 0.017, 2.1 %) | 21.05 (20.97 ± 0.24, 1.1 %) | 43.05 (43.05 ± 0.18, 0.4 %) |
| tsan-dom | 4 | 45.06 (45.08 ± 0.13, 0.3 %) | 0.805 (0.805 ± 0.0058, 0.7 %) | 20.44 (20.52 ± 0.2, 1.0 %) | 43.02 (42.99 ± 0.076, 0.2 %) |
| tsan-dom-ea-lo-st-swmr | 4 | 45.01 (45.09 ± 0.41, 0.9 %) | 0.795 (0.795 ± 0.024, 3.0 %) | 20.3 (20.34 ± 0.12, 0.6 %) | 42.92 (42.92 ± 0.066, 0.2 %) |
| tsan-dom_peeling | 4 | 45.12 (45.15 ± 0.4, 0.9 %) | 0.79 (0.7925 ± 0.005, 0.6 %) | 20.49 (20.56 ± 0.25, 1.2 %) | 42.94 (42.95 ± 0.16, 0.4 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 4 | 45.16 (45.28 ± 0.41, 0.9 %) | 0.805 (0.805 ± 0.021, 2.6 %) | 20.48 (20.46 ± 0.18, 0.9 %) | 42.98 (42.95 ± 0.25, 0.6 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 4 | 45.32 (45.3 ± 0.16, 0.4 %) | 0.51 (0.51 ± 0.0082, 1.6 %) | 20.81 (20.89 ± 0.18, 0.8 %) | 42.87 (42.88 ± 0.14, 0.3 %) |
| tsan-ea | 4 | 45.61 (45.63 ± 0.5, 1.1 %) | 0.815 (0.8175 ± 0.017, 2.1 %) | 20.88 (20.98 ± 0.28, 1.3 %) | 43.02 (43.03 ± 0.092, 0.2 %) |
| tsan-lo | 4 | 45.35 (45.51 ± 0.5, 1.1 %) | 0.81 (0.81 ± 0.0082, 1.0 %) | 20.78 (20.89 ± 0.28, 1.4 %) | 42.81 (42.87 ± 0.16, 0.4 %) |
| tsan-st | 4 | 45.35 (45.46 ± 0.45, 1.0 %) | 0.81 (0.8125 ± 0.005, 0.6 %) | 20.85 (20.86 ± 0.11, 0.5 %) | 42.94 (42.91 ± 0.13, 0.3 %) |
| tsan-stmt | 4 | 45.25 (45.27 ± 0.17, 0.4 %) | 0.52 (0.52 ± 0.0082, 1.6 %) | 21.2 (21.16 ± 0.084, 0.4 %) | 42.96 (43.01 ± 0.22, 0.5 %) |
| tsan-swmr | 4 | 45.44 (45.47 ± 0.28, 0.6 %) | 0.795 (0.7975 ± 0.0096, 1.2 %) | 20.72 (20.78 ± 0.17, 0.8 %) | 42.84 (42.89 ± 0.17, 0.4 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 4 | 2.768 (N=4, no interval; compare with the shipped interval) | — (all 4 subtests within 5%) | — | — | pinned | h264_libx264:1.25, copy_passthrough:5.75, mjpeg:6.00, h265_libx265:1.36 |
| tsan | tsan | 4 | — | — (all 4 subtests within 5%) | 2.77 (N=4, no interval; compare with the shipped interval) | — | pinned |  |
| tsan-dom | tsan-dom | 4 | 1.009 (N=4, no interval; compare with the shipped interval) | — (all 4 subtests within 5%) | 2.74 (N=4, no interval; compare with the shipped interval) | — | pinned | h264_libx264:1.01, copy_passthrough:1.00, mjpeg:1.03, h265_libx265:1.00 |
| tsan-dom-ea-lo-st-swmr | AllOpt-peel | 4 | 1.015 (N=4, no interval; compare with the shipped interval) | — (all 4 subtests within 5%) | 2.73 (N=4, no interval; compare with the shipped interval) | — | pinned | h264_libx264:1.01, copy_passthrough:1.01, mjpeg:1.04, h265_libx265:1.00 |
| tsan-dom_peeling | tsan-dom_peeling | 4 | 1.013 (N=4, no interval; compare with the shipped interval) | — (all 4 subtests within 5%) | 2.73 (N=4, no interval; compare with the shipped interval) | — | pinned | h264_libx264:1.00, copy_passthrough:1.02, mjpeg:1.03, h265_libx265:1.00 |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 4 | 1.008 (N=4, no interval; compare with the shipped interval) | — (all 4 subtests within 5%) | 2.75 (N=4, no interval; compare with the shipped interval) | — | pinned | h264_libx264:1.00, copy_passthrough:1.00, mjpeg:1.03, h265_libx265:1.00 |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 4 | 1.125 (N=4, no interval; compare with the shipped interval) | — (all 4 subtests within 5%) | 2.46 (N=4, no interval; compare with the shipped interval) | — | pinned | h264_libx264:1.00, copy_passthrough:1.58, mjpeg:1.01, h265_libx265:1.00 |
| tsan-ea | tsan-ea | 4 | 0.997 (N=4, no interval; compare with the shipped interval) | — (all 4 subtests within 5%) | 2.77 (N=4, no interval; compare with the shipped interval) | — | pinned | h264_libx264:0.99, copy_passthrough:0.99, mjpeg:1.01, h265_libx265:1.00 |
| tsan-lo | tsan-lo | 4 | 1.003 (N=4, no interval; compare with the shipped interval) | — (all 4 subtests within 5%) | 2.76 (N=4, no interval; compare with the shipped interval) | — | pinned | h264_libx264:1.00, copy_passthrough:0.99, mjpeg:1.01, h265_libx265:1.01 |
| tsan-st | tsan-st | 4 | 1.001 (N=4, no interval; compare with the shipped interval) | — (all 4 subtests within 5%) | 2.76 (N=4, no interval; compare with the shipped interval) | — | pinned | h264_libx264:1.00, copy_passthrough:0.99, mjpeg:1.01, h265_libx265:1.00 |
| tsan-stmt | tsan-stmt | 4 | 1.114 (N=4, no interval; compare with the shipped interval) | — (all 4 subtests within 5%) | 2.48 (N=4, no interval; compare with the shipped interval) | — | pinned | h264_libx264:1.00, copy_passthrough:1.55, mjpeg:0.99, h265_libx265:1.00 |
| tsan-swmr | tsan-swmr | 4 | 1.008 (N=4, no interval; compare with the shipped interval) | — (all 4 subtests within 5%) | 2.75 (N=4, no interval; compare with the shipped interval) | — | pinned | h264_libx264:1.00, copy_passthrough:1.01, mjpeg:1.02, h265_libx265:1.00 |
