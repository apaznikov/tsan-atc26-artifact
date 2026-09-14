# mysql: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-10T15:31:16

| config | N | oltp_read_only median (mean ± σ, CV) | oltp_read_write median (mean ± σ, CV) | oltp_write_only median (mean ± σ, CV) | select_random_points median (mean ± σ, CV) | select_random_ranges median (mean ± σ, CV) |
|---|---|---|---|---|---|---|
| tsan-sound | 5 | 1.28e+05 (1.286e+05 ± 7.4e+03, 5.7 %) | 1.219e+05 (1.247e+05 ± 7.1e+03, 5.7 %) | 1.434e+05 (1.414e+05 ± 3.4e+03, 2.4 %) | 5.403e+04 (5.441e+04 ± 9.7e+02, 1.8 %) | 1.077e+05 (1.08e+05 ± 1.4e+03, 1.3 %) |
| tsan-sound-nofe | 5 | 1.311e+05 (1.322e+05 ± 9e+03, 6.8 %) | 1.304e+05 (1.335e+05 ± 7.6e+03, 5.7 %) | 1.726e+05 (1.714e+05 ± 3e+03, 1.8 %) | 7.012e+04 (6.969e+04 ± 1.7e+03, 2.5 %) | 1.192e+05 (1.19e+05 ± 4.6e+03, 3.8 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| tsan-sound | tsan-sound | 5 | — | — | — | — | pinned |  |
| tsan-sound-nofe | tsan-sound-nofe | 5 | — | — | — | — | pinned |  |
