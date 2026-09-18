# ffmpeg: performance (lower is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-18T16:39:34

| config | N | h264_libx264 median (mean ± σ, CV) | copy_passthrough median (mean ± σ, CV) | mjpeg median (mean ± σ, CV) | h265_libx265 median (mean ± σ, CV) |
|---|---|---|---|---|---|
| orig | 5 | 56.57 (56.59 ± 0.1, 0.2 %) | 0.14 (0.14 ± 0, 0.0 %) | 5.41 (5.414 ± 0.055, 1.0 %) | 39.21 (39.17 ± 0.16, 0.4 %) |
| tsan | 5 | 71.93 (71.98 ± 0.12, 0.2 %) | 0.81 (0.806 ± 0.0089, 1.1 %) | 38.44 (38.85 ± 0.81, 2.1 %) | 55.76 (55.76 ± 0.21, 0.4 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 72.15 (72.09 ± 0.17, 0.2 %) | 0.8 (0.798 ± 0.0045, 0.6 %) | 38.01 (37.86 ± 0.27, 0.7 %) | 55.81 (55.78 ± 0.083, 0.1 %) |
| tsan-stmt | 5 | 72.23 (72.38 ± 0.55, 0.8 %) | 0.52 (0.518 ± 0.0084, 1.6 %) | 38.85 (39.09 ± 0.52, 1.3 %) | 55.76 (55.75 ± 0.075, 0.1 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 2.936 [2.907, 2.977] | — (all 4 subtests within 5%) | — | — | pinned | h264_libx264:1.27, copy_passthrough:5.79, mjpeg:7.11, h265_libx265:1.42 |
| tsan | tsan | 5 | — | — (all 4 subtests within 5%) | 2.94 [2.91, 2.98] | — | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.005 [0.998, 1.021] | — (all 4 subtests within 5%) | 2.92 [2.90, 2.93] | — | pinned | h264_libx264:1.00, copy_passthrough:1.01, mjpeg:1.01, h265_libx265:1.00 |
| tsan-stmt | tsan-stmt | 5 | 1.113 [1.098, 1.131] | — (all 4 subtests within 5%) | 2.64 [2.61, 2.67] | — | pinned | h264_libx264:1.00, copy_passthrough:1.56, mjpeg:0.99, h265_libx265:1.00 |
