# Preservation summary: sqlite

Report kinds considered: data race

## Per-configuration counts (mean ± sample σ over runs)

| config | runs | reports/run | distinct L1/run | distinct L2/run | union L1 | union L2 | kinds |
|---|---|---|---|---|---|---|---|
| tsan | 10 | 2.9 ± 1.4 | 2.7 ± 1.2 | 1.4 ± 0.7 | 5 | 2 | data race:29 |
| tsan-dom_peeling-ea-lo-st-swmr | 10 | 0.1 ± 0.3 | 0.1 ± 0.3 | 0.1 ± 0.3 | 1 | 1 | data race:1 |

## tsan-dom_peeling-ea-lo-st-swmr vs tsan

- L1 (function@file:line): lost 4 of 5 baseline races, new 0; of the lost, 0 are still found at L2 (relocated).
- L2 (function only): lost 1 of 2, new 0.

### Races reported by tsan in ≥1 run and by tsan-dom_peeling-ea-lo-st-swmr in 0 runs (L1)

| baseline runs | at L2 in cfg? | race |
|---|---|---|
| 9/10 | **no** | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68034 | mapped:test.db-shm+0x68` |
| 2/10 | **no** | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x6c` |
| 9/10 | **no** | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x70` |
| 2/10 | **no** | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x74` |

## All races (L1) with per-configuration detection frequency

| tsan | tsan-dom_peeling-ea-lo-st-swmr | race |
|---|---|---|
| 5/10 | 1/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:68991 | write:walIndexRecover@sqlite3.c:67450 | mapped:test.db-shm+0x60` |
| 9/10 | 0/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68034 | mapped:test.db-shm+0x68` |
| 2/10 | 0/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x6c` |
| 9/10 | 0/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x70` |
| 2/10 | 0/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x74` |

