# ffmpeg: performance (lower is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-18T18:30:08

| config | N | h264_libx264 median (mean ± σ, CV) | copy_passthrough median (mean ± σ, CV) | mjpeg median (mean ± σ, CV) | h265_libx265 median (mean ± σ, CV) |
|---|---|---|---|---|---|
| orig | 5 | 12.85 (12.83 ± 0.034, 0.3 %) | 0.14 (0.138 ± 0.0045, 3.2 %) | 3.56 (3.548 ± 0.036, 1.0 %) | 28.06 (28.11 ± 0.11, 0.4 %) |
| tsan | 5 | 18.09 (18.14 ± 0.13, 0.7 %) | 0.8 (0.806 ± 0.0089, 1.1 %) | 17.53 (17.55 ± 0.032, 0.2 %) | 37.82 (37.86 ± 0.093, 0.2 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 17.91 (17.95 ± 0.12, 0.7 %) | 0.8 (0.802 ± 0.013, 1.6 %) | 13.8 (13.85 ± 0.11, 0.8 %) | 37.79 (37.8 ± 0.16, 0.4 %) |
| tsan-stmt | 5 | 18.07 (18.1 ± 0.11, 0.6 %) | 0.51 (0.516 ± 0.0089, 1.7 %) | 17.85 (17.83 ± 0.087, 0.5 %) | 37.91 (37.89 ± 0.17, 0.4 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 2.703 [2.696, 2.777] | — (all 4 subtests within 5%) | — | — | pinned | h264_libx264:1.41, copy_passthrough:5.71, mjpeg:4.92, h265_libx265:1.35 |
| tsan | tsan | 5 | — | — (all 4 subtests within 5%) | 2.70 [2.70, 2.78] | — | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.065 [1.055, 1.076] | — (all 4 subtests within 5%) | 2.54 [2.52, 2.61] | — | pinned | h264_libx264:1.01, copy_passthrough:1.00, mjpeg:1.27, h265_libx265:1.00 |
| tsan-stmt | tsan-stmt | 5 | 1.114 [1.102, 1.125] | — (all 4 subtests within 5%) | 2.43 [2.42, 2.50] | — | pinned | h264_libx264:1.00, copy_passthrough:1.57, mjpeg:0.98, h265_libx265:1.00 |
