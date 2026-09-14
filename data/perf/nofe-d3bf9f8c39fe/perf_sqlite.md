# sqlite: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-10T14:43:45

| config | N | walthread1 median (mean ± σ, CV) | walthread2 median (mean ± σ, CV) | dynamic_triggers median (mean ± σ, CV) | checkpoint_starvation_1 median (mean ± σ, CV) | checkpoint_starvation_2 median (mean ± σ, CV) | stress1 median (mean ± σ, CV) | stress2 median (mean ± σ, CV) |
|---|---|---|---|---|---|---|---|---|
| tsan-sound | 5 | 2724 (2703 ± 47, 1.8 %) | 6378 (6382 ± 64, 1.0 %) | 1.09e+05 (1.226e+05 ± 3.1e+04, 25.4 %) | 1.651e+05 (1.641e+05 ± 2.5e+03, 1.5 %) | 766 (766 ± 0, 0.0 %) | 1.017e+05 (1.008e+05 ± 1.2e+04, 11.5 %) | 2.948e+04 (2.989e+04 ± 1.4e+03, 4.5 %) |
| tsan-sound-nofe | 5 | 2841 (2835 ± 33, 1.1 %) | 6850 (6845 ± 46, 0.7 %) | 1.05e+05 (1.272e+05 ± 5.3e+04, 41.7 %) | 1.748e+05 (1.725e+05 ± 4.6e+03, 2.6 %) | 766 (766 ± 0, 0.0 %) | 1.205e+05 (1.306e+05 ± 2.8e+04, 21.4 %) | 3.215e+04 (3.232e+04 ± 1.9e+03, 5.9 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| tsan-sound | tsan-sound | 5 | — | — | — | — | pinned |  |
| tsan-sound-nofe | tsan-sound-nofe | 5 | — | — | — | — | pinned |  |
