# Preservation summary: sqlite

Report kinds considered: data race

## Per-configuration counts (mean ± sample σ over runs)

| config | runs | reports/run | distinct L1/run | distinct L2/run | union L1 | union L2 | union L3 | kinds |
|---|---|---|---|---|---|---|---|---|
| tsan | 10 | 4.3 ± 1.1 | 3.9 ± 0.6 | 1.3 ± 0.5 | 5 | 2 | 3 | data race:43 |
| tsan-dom_peeling-ea-lo-st-swmr | 10 | 4.3 ± 0.8 | 4.2 ± 0.6 | 1.4 ± 0.5 | 5 | 2 | 3 | data race:43 |
| tsan-sound | 10 | 4.7 ± 1.3 | 4.3 ± 0.8 | 1.5 ± 0.5 | 5 | 2 | 3 | data race:47 |

## tsan-dom_peeling-ea-lo-st-swmr vs tsan

- L1 (function@file:line): lost 0 of 5 baseline races, new 0; of the lost, 0 are still found at L2 (relocated).
- L2 (function only): lost 0 of 2, new 0.
- L3 (location + writer site, readers collapsed): lost 0 of 3, new 0; of the L1-lost, 0 are still found at L3.

## tsan-sound vs tsan

- L1 (function@file:line): lost 0 of 5 baseline races, new 0; of the lost, 0 are still found at L2 (relocated).
- L2 (function only): lost 0 of 2, new 0.
- L3 (location + writer site, readers collapsed): lost 0 of 3, new 0; of the L1-lost, 0 are still found at L3.

## All races (L1) with per-configuration detection frequency

| tsan | tsan-dom_peeling-ea-lo-st-swmr | tsan-sound | race |
|---|---|---|---|
| 3/10 | 4/10 | 5/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:68991 | write:walIndexRecover@sqlite3.c:67450 | mapped:test.db-shm+0x60` |
| 10/10 | 10/10 | 10/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68034 | mapped:test.db-shm+0x68` |
| 10/10 | 10/10 | 10/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x6c` |
| 10/10 | 10/10 | 10/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x70` |
| 6/10 | 8/10 | 8/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x74` |

