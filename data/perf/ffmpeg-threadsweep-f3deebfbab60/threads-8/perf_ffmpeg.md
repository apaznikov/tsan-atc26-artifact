# ffmpeg: performance (lower is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-18T18:04:06

| config | N | h264_libx264 median (mean ± σ, CV) | copy_passthrough median (mean ± σ, CV) | mjpeg median (mean ± σ, CV) | h265_libx265 median (mean ± σ, CV) |
|---|---|---|---|---|---|
| orig | 5 | 20.77 (20.79 ± 0.069, 0.3 %) | 0.14 (0.14 ± 0, 0.0 %) | 3.56 (3.548 ± 0.03, 0.9 %) | 30.11 (30.06 ± 0.14, 0.5 %) |
| tsan | 5 | 27.22 (27.29 ± 0.16, 0.6 %) | 0.82 (0.816 ± 0.0055, 0.7 %) | 17.49 (17.46 ± 0.061, 0.3 %) | 40.23 (40.22 ± 0.14, 0.3 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 27.22 (27.22 ± 0.15, 0.5 %) | 0.8 (0.804 ± 0.0055, 0.7 %) | 13.99 (14 ± 0.15, 1.1 %) | 40.35 (40.3 ± 0.12, 0.3 %) |
| tsan-stmt | 5 | 27.39 (27.5 ± 0.37, 1.3 %) | 0.52 (0.526 ± 0.022, 4.2 %) | 17.69 (17.72 ± 0.19, 1.1 %) | 40.23 (40.24 ± 0.13, 0.3 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 2.664 [2.648, 2.681] | — (all 4 subtests within 5%) | — | — | pinned | h264_libx264:1.31, copy_passthrough:5.86, mjpeg:4.91, h265_libx265:1.34 |
| tsan | tsan | 5 | — | — (all 4 subtests within 5%) | 2.66 [2.65, 2.68] | — | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.063 [1.052, 1.069] | — (all 4 subtests within 5%) | 2.51 [2.49, 2.53] | — | pinned | h264_libx264:1.00, copy_passthrough:1.02, mjpeg:1.25, h265_libx265:1.00 |
| tsan-stmt | tsan-stmt | 5 | 1.116 [1.087, 1.130] | — (all 4 subtests within 5%) | 2.39 [2.36, 2.45] | — | pinned | h264_libx264:0.99, copy_passthrough:1.58, mjpeg:0.99, h265_libx265:1.00 |
