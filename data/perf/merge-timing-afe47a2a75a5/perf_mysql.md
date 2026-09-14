# mysql: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-11T18:04:00

| config | N | oltp_read_only median (mean ± σ, CV) | oltp_read_write median (mean ± σ, CV) | oltp_write_only median (mean ± σ, CV) | select_random_points median (mean ± σ, CV) | select_random_ranges median (mean ± σ, CV) |
|---|---|---|---|---|---|---|
| tsan-sound | 5 | 1.275e+05 (1.308e+05 ± 9.3e+03, 7.1 %) | 1.24e+05 (1.306e+05 ± 1e+04, 7.6 %) | 1.455e+05 (1.457e+05 ± 2.6e+03, 1.8 %) | 5.604e+04 (5.636e+04 ± 8.3e+02, 1.5 %) | 1.096e+05 (1.072e+05 ± 6.7e+03, 6.3 %) |
| tsan-sound-nomerge | 5 | 1.337e+05 (1.335e+05 ± 4.8e+03, 3.6 %) | 1.229e+05 (1.236e+05 ± 6.1e+03, 4.9 %) | 1.468e+05 (1.447e+05 ± 3.4e+03, 2.3 %) | 5.702e+04 (5.773e+04 ± 2.4e+03, 4.1 %) | 1.083e+05 (1.086e+05 ± 3.9e+03, 3.6 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| tsan-sound | tsan-sound | 5 | — | — | — | 588059 | pinned |  |
| tsan-sound-nomerge | tsan-sound-nomerge | 5 | — | — | — | 597140 | pinned |  |
