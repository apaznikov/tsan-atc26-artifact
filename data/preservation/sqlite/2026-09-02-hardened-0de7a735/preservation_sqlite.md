# Preservation summary: sqlite

Report kinds considered: data race

## Per-configuration counts (mean ± sample σ over runs)

| config | runs | reports/run | distinct L1/run | distinct L2/run | union L1 | union L2 | kinds |
|---|---|---|---|---|---|---|---|
| tsan | 10 | 2.2 ± 1.5 | 2.2 ± 1.5 | 1.1 ± 0.7 | 5 | 2 | data race:22 |
| tsan-dom_peeling-ea-lo-st-swmr | 10 | 1.8 ± 2.1 | 1.6 ± 1.6 | 0.9 ± 0.7 | 5 | 2 | data race:18 |
| tsan-sound | 10 | 1.8 ± 1.5 | 1.8 ± 1.5 | 1.1 ± 0.7 | 5 | 2 | data race:18 |

## tsan-dom_peeling-ea-lo-st-swmr vs tsan

- L1 (function@file:line): lost 0 of 5 baseline races, new 0; of the lost, 0 are still found at L2 (relocated).
- L2 (function only): lost 0 of 2, new 0.

## tsan-sound vs tsan

- L1 (function@file:line): lost 0 of 5 baseline races, new 0; of the lost, 0 are still found at L2 (relocated).
- L2 (function only): lost 0 of 2, new 0.

## All races (L1) with per-configuration detection frequency

| tsan | tsan-dom_peeling-ea-lo-st-swmr | tsan-sound | race |
|---|---|---|---|
| 4/10 | 3/10 | 5/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:68991 | write:walIndexRecover@sqlite3.c:67450 | mapped:test.db-shm+0x60` |
| 7/10 | 4/10 | 3/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68034 | mapped:test.db-shm+0x68` |
| 2/10 | 2/10 | 4/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x6c` |
| 6/10 | 6/10 | 5/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x70` |
| 3/10 | 1/10 | 1/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x74` |

