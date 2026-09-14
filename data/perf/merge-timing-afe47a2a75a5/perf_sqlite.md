# sqlite: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-11T17:01:01

| config | N | walthread1 median (mean ± σ, CV) | walthread2 median (mean ± σ, CV) | dynamic_triggers median (mean ± σ, CV) | checkpoint_starvation_1 median (mean ± σ, CV) | checkpoint_starvation_2 median (mean ± σ, CV) | stress1 median (mean ± σ, CV) | stress2 median (mean ± σ, CV) |
|---|---|---|---|---|---|---|---|---|
| tsan-sound | 5 | 2772 (2726 ± 1.1e+02, 4.1 %) | 6821 (6777 ± 1.5e+02, 2.2 %) | 1.314e+05 (1.347e+05 ± 1.6e+04, 12.0 %) | 1.82e+05 (1.803e+05 ± 6.9e+03, 3.8 %) | 766 (766 ± 0, 0.0 %) | 1.144e+05 (1.154e+05 ± 1.2e+04, 10.2 %) | 3.256e+04 (3.21e+04 ± 8.5e+02, 2.7 %) |
| tsan-sound-nomerge | 5 | 2794 (2786 ± 29, 1.1 %) | 6720 (6710 ± 19, 0.3 %) | 1.188e+05 (1.191e+05 ± 1.3e+04, 10.6 %) | 1.656e+05 (1.656e+05 ± 7.8e+03, 4.7 %) | 766 (766 ± 0, 0.0 %) | 1.135e+05 (1.139e+05 ± 1.9e+04, 16.2 %) | 3.184e+04 (3.124e+04 ± 1.5e+03, 4.8 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| tsan-sound | tsan-sound | 5 | — | — | — | 52573 | pinned |  |
| tsan-sound-nomerge | tsan-sound-nomerge | 5 | — | — | — | 57025 | pinned |  |
