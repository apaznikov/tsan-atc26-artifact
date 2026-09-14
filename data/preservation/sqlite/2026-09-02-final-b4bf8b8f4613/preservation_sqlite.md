# Preservation summary: sqlite

Report kinds considered: data race

## Per-configuration counts (mean ± sample σ over runs)

| config | runs | reports/run | distinct L1/run | distinct L2/run | union L1 | union L2 | union L3 | kinds |
|---|---|---|---|---|---|---|---|---|
| tsan | 10 | 4.7 ± 1.1 | 4.4 ± 0.7 | 1.7 ± 0.5 | 5 | 2 | 3 | data race:47 |
| tsan-dom_peeling-ea-lo-st-swmr | 10 | 4.8 ± 0.8 | 4.4 ± 0.5 | 1.4 ± 0.5 | 6 | 2 | 4 | data race:48 |
| tsan-sound | 10 | 4.7 ± 0.8 | 4.3 ± 0.5 | 1.3 ± 0.5 | 5 | 2 | 3 | data race:47 |

## tsan-dom_peeling-ea-lo-st-swmr vs tsan

- L1 (function@file:line): lost 0 of 5 baseline races, new 1; of the lost, 0 are still found at L2 (relocated).
- L2 (function only): lost 0 of 2, new 0.
- L3 (location + writer site, readers collapsed): lost 0 of 3, new 1; of the L1-lost, 0 are still found at L3.

### Races reported by tsan-dom_peeling-ea-lo-st-swmr but never by tsan (L1)

| cfg runs | at L2 in baseline? | race |
|---|---|---|
| 1/10 | yes | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walIndexRecover@sqlite3.c:67459 | mapped:test.db-shm+0x74` |

## tsan-sound vs tsan

- L1 (function@file:line): lost 0 of 5 baseline races, new 0; of the lost, 0 are still found at L2 (relocated).
- L2 (function only): lost 0 of 2, new 0.
- L3 (location + writer site, readers collapsed): lost 0 of 3, new 0; of the L1-lost, 0 are still found at L3.

## All races (L1) with per-configuration detection frequency

| tsan | tsan-dom_peeling-ea-lo-st-swmr | tsan-sound | race |
|---|---|---|---|
| 7/10 | 3/10 | 3/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:68991 | write:walIndexRecover@sqlite3.c:67450 | mapped:test.db-shm+0x60` |
| 0/10 | 1/10 | 0/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walIndexRecover@sqlite3.c:67459 | mapped:test.db-shm+0x74` |
| 10/10 | 10/10 | 10/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68034 | mapped:test.db-shm+0x68` |
| 10/10 | 10/10 | 10/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x6c` |
| 10/10 | 10/10 | 10/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x70` |
| 7/10 | 10/10 | 10/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x74` |

