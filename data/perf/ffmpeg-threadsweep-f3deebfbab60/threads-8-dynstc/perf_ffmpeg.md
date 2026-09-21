# ffmpeg: performance (lower is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=00c09a4a6ca7 started=2026-09-21T14:49:27

| config | N | h264_libx264 median (mean ± σ, CV) | copy_passthrough median (mean ± σ, CV) | mjpeg median (mean ± σ, CV) | h265_libx265 median (mean ± σ, CV) |
|---|---|---|---|---|---|
| orig | 5 | 20.07 (20.21 ± 0.29, 1.5 %) | 0.13 (0.132 ± 0.0045, 3.4 %) | 3.49 (3.484 ± 0.076, 2.2 %) | 27.37 (27.2 ± 0.31, 1.2 %) |
| tsan | 5 | 27.01 (27.03 ± 0.47, 1.8 %) | 0.82 (0.828 ± 0.019, 2.3 %) | 18.63 (18.78 ± 0.28, 1.5 %) | 38.3 (38.33 ± 0.17, 0.4 %) |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 26.51 (26.67 ± 0.36, 1.4 %) | 0.51 (0.516 ± 0.0089, 1.7 %) | 15.32 (15.39 ± 0.15, 1.0 %) | 38.08 (38.31 ± 0.41, 1.1 %) |
| tsan-stmt | 5 | 26.55 (26.58 ± 0.23, 0.9 %) | 0.49 (0.5 ± 0.014, 2.8 %) | 18.89 (18.92 ± 0.29, 1.6 %) | 38.33 (38.55 ± 0.62, 1.6 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| orig | orig | 5 | 2.822 [2.755, 2.889] | — (all 4 subtests within 5%) | — | 0 | pinned | h264_libx264:1.35, copy_passthrough:6.31, mjpeg:5.34, h265_libx265:1.40 |
| tsan | tsan | 5 | — | — (all 4 subtests within 5%) | 2.82 [2.75, 2.89] | 507825 | pinned |  |
| tsan-dom_peeling-ea-lo-st-swmr-stmt | tsan-dom_peeling-ea-lo-st-swmr-stmt | 5 | 1.190 [1.167, 1.211] | — (all 4 subtests within 5%) | 2.37 [2.32, 2.43] | 535687 | pinned | h264_libx264:1.02, copy_passthrough:1.61, mjpeg:1.22, h265_libx265:1.01 |
| tsan-stmt | tsan-stmt | 5 | 1.138 [1.112, 1.161] | — (all 4 subtests within 5%) | 2.48 [2.43, 2.55] | 507709 | pinned | h264_libx264:1.02, copy_passthrough:1.67, mjpeg:0.99, h265_libx265:1.00 |
