# ffmpeg: performance (lower is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-10T13:12:53

| config | N | h264_libx264 median (mean ± σ, CV) | copy_passthrough median (mean ± σ, CV) | mjpeg median (mean ± σ, CV) | h265_libx265 median (mean ± σ, CV) |
|---|---|---|---|---|---|
| tsan-sound | 5 | 46.67 (46.37 ± 0.92, 2.0 %) | 0.76 (0.774 ± 0.038, 5.0 %) | 27.43 (27.46 ± 0.96, 3.5 %) | 54.82 (54.95 ± 0.82, 1.5 %) |
| tsan-sound-nofe | 5 | 47.5 (47.58 ± 2.3, 4.9 %) | 0.71 (0.738 ± 0.041, 5.5 %) | 25.81 (25.75 ± 0.87, 3.4 %) | 54.77 (54.64 ± 0.32, 0.6 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| tsan-sound | tsan-sound | 5 | — | — | — | — | pinned |  |
| tsan-sound-nofe | tsan-sound-nofe | 5 | — | — | — | — | pinned |  |
