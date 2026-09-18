# ffmpeg: performance (lower is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-18T17:30:07

| config | N | h264_libx264 median (mean ± σ, CV) | copy_passthrough median (mean ± σ, CV) | mjpeg median (mean ± σ, CV) | h265_libx265 median (mean ± σ, CV) |
|---|---|---|---|---|---|
| orig | 5 | 36.37 (36.47 ± 0.33, 0.9 %) | 0.14 (0.14 ± 0, 0.0 %) | 3.52 (3.52 ± 0.016, 0.4 %) | 31.72 (31.73 ± 0.12, 0.4 %) |
| tsan | 5 | 45.6 (45.7 ± 0.34, 0.7 %) | 0.82 (0.818 ± 0.013, 1.6 %) | 21.03 (21.02 ± 0.078, 0.4 %) | 43.18 (43.41 ± 0.41, 0.9 %) |
| tsan-dom_peeling-ea-lo-st-swmr | 5 | 45.64 (45.73 ± 0.35, 0.8 %) | 0.8 (0.802 ± 0.0084, 1.0 %) | 20.79 (20.78 ± 0.15, 0.7 %) | 43.04 (43.06 ± 0.057, 0.1 %) |
| tsan-stmt | 5 | 45.86 (45.87 ± 0.2, 0.4 %) | 0.52 (0.522 ± 0.013, 2.5 %) | 21.49 (21.55 ± 0.21, 1.0 %) | 43.22 (43.15 ± 0.21, 0.5 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 2.780 [2.753, 2.807] | — (all 4 subtests within 5%) | — | — | pinned | h264_libx264:1.25, copy_passthrough:5.86, mjpeg:5.97, h265_libx265:1.36 |
| tsan | tsan | 5 | — | — (all 4 subtests within 5%) | 2.78 [2.75, 2.81] | — | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr | AllOpt+peel | 5 | 1.010 [0.999, 1.021] | — (all 4 subtests within 5%) | 2.75 [2.73, 2.77] | — | pinned | h264_libx264:1.00, copy_passthrough:1.02, mjpeg:1.01, h265_libx265:1.00 |
| tsan-stmt | tsan-stmt | 5 | 1.113 [1.096, 1.128] | — (all 4 subtests within 5%) | 2.50 [2.47, 2.53] | — | pinned | h264_libx264:0.99, copy_passthrough:1.58, mjpeg:0.98, h265_libx265:1.00 |
