# memcached: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-10T14:09:48

| config | N | ops_sec median (mean ± σ, CV) |
|---|---|---|
| tsan-sound | 5 | 1.509e+06 (1.532e+06 ± 7.3e+04, 4.8 %) |
| tsan-sound-nofe | 5 | 1.549e+06 (1.545e+06 ± 4.9e+04, 3.2 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| tsan-sound | tsan-sound | 5 | — | — | — | — | pinned |  |
| tsan-sound-nofe | tsan-sound-nofe | 5 | — | — | — | — | pinned |  |
