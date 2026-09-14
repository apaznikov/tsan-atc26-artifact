# redis: performance (higher is better per test)

Session: mode=pinned cpuset=4-27,60-83 governor=powersave no_turbo=0 host=focs-server started=2026-09-10T12:58:33

| config | N | PING_INLINE median (mean ± σ, CV) | PING_MBULK median (mean ± σ, CV) | SET median (mean ± σ, CV) | GET median (mean ± σ, CV) | INCR median (mean ± σ, CV) | RPUSH median (mean ± σ, CV) | LPOP median (mean ± σ, CV) | RPOP median (mean ± σ, CV) | SADD median (mean ± σ, CV) | HSET median (mean ± σ, CV) | SPOP median (mean ± σ, CV) | ZADD median (mean ± σ, CV) | ZPOPMIN median (mean ± σ, CV) | LPUSH median (mean ± σ, CV) | LRANGE_100 median (mean ± σ, CV) | LRANGE_300 median (mean ± σ, CV) | LRANGE_500 median (mean ± σ, CV) | LRANGE_600 median (mean ± σ, CV) | MSET median (mean ± σ, CV) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| tsan-sound | 5 | 4.632e+05 (4.611e+05 ± 2.7e+04, 5.8 %) | 7.239e+05 (7.186e+05 ± 3.1e+04, 4.3 %) | 3.075e+05 (3.075e+05 ± 9.2e+03, 3.0 %) | 3.927e+05 (3.94e+05 ± 1.1e+04, 2.8 %) | 3.896e+05 (3.888e+05 ± 6.4e+03, 1.6 %) | 2.436e+05 (2.461e+05 ± 5.3e+03, 2.1 %) | 2.231e+05 (2.233e+05 ± 4.2e+03, 1.9 %) | 4.715e+05 (4.657e+05 ± 1.7e+04, 3.6 %) | 3.312e+05 (3.346e+05 ± 1.5e+04, 4.5 %) | 2.643e+05 (2.615e+05 ± 6.4e+03, 2.5 %) | 4.892e+05 (4.905e+05 ± 1.1e+04, 2.2 %) | 2.728e+05 (2.711e+05 ± 5.8e+03, 2.1 %) | 4.948e+05 (4.965e+05 ± 2e+04, 3.9 %) | 2.078e+05 (2.08e+05 ± 3e+03, 1.4 %) | 2.465e+04 (2.41e+04 ± 1.2e+03, 5.0 %) | 8333 (8226 ± 1.9e+02, 2.4 %) | 5059 (5027 ± 1e+02, 2.0 %) | 4232 (4218 ± 75, 1.8 %) | 5.768e+04 (5.669e+04 ± 3.1e+03, 5.5 %) |
| tsan-sound-nofe | 5 | 5.665e+05 (5.579e+05 ± 2.1e+04, 3.7 %) | 8.715e+05 (8.445e+05 ± 5e+04, 5.9 %) | 3.94e+05 (3.912e+05 ± 5.1e+03, 1.3 %) | 4.931e+05 (4.906e+05 ± 1.9e+04, 3.9 %) | 4.972e+05 (4.783e+05 ± 3.1e+04, 6.5 %) | 3.005e+05 (2.957e+05 ± 1.3e+04, 4.3 %) | 2.657e+05 (2.62e+05 ± 1.5e+04, 5.6 %) | 5.479e+05 (5.503e+05 ± 4.3e+03, 0.8 %) | 4.06e+05 (4.075e+05 ± 2.2e+04, 5.4 %) | 3.271e+05 (3.074e+05 ± 5e+04, 16.3 %) | 5.83e+05 (5.755e+05 ± 6.9e+04, 12.1 %) | 3.221e+05 (3.192e+05 ± 2.5e+04, 7.8 %) | 5.962e+05 (6.03e+05 ± 3.4e+04, 5.7 %) | 2.539e+05 (2.513e+05 ± 5.5e+03, 2.2 %) | 3.053e+04 (3.071e+04 ± 8.4e+02, 2.7 %) | 1.065e+04 (1.049e+04 ± 2.9e+02, 2.7 %) | 6442 (6452 ± 54, 0.8 %) | 5343 (5347 ± 1e+02, 1.9 %) | 7.461e+04 (7.357e+04 ± 2.5e+03, 3.4 %) |

## Speedup vs stock TSan (SU) and slowdown vs native (SD), on medians; geometric mean over tests; 95 % bootstrap interval

| config | label | N | SU geomean [95 %] | SU stable [95 %] | SD geomean [95 %] | static sites | modes | per-test SU |
|---|---|---|---|---|---|---|---|---|
| tsan-sound | tsan-sound | 5 | — | — | — | — | pinned |  |
| tsan-sound-nofe | tsan-sound-nofe | 5 | — | — | — | — | pinned |  |
