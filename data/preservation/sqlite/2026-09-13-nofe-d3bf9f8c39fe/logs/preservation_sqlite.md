# Preservation summary: sqlite

Report kinds considered: data race

## Per-configuration counts (mean ± sample σ over runs)

| config | runs | reports/run | distinct L1/run | distinct L2/run | union L1 | union L2 | union L3 | kinds |
|---|---|---|---|---|---|---|---|---|
| tsan | 10 | 2.5 ± 1.4 | 2.5 ± 1.4 | 1.1 ± 0.6 | 7 | 2 | 5 | data race:25 |
| tsan-sound | 10 | 2.5 ± 1.4 | 2.4 ± 1.3 | 1.1 ± 0.6 | 5 | 2 | 3 | data race:25 |
| tsan-sound-nofe | 10 | 2.2 ± 1.4 | 2.2 ± 1.4 | 0.9 ± 0.6 | 5 | 2 | 3 | data race:22 |

## tsan-sound vs tsan

- L1 (function@file:line): lost 2 of 7 baseline races, new 0; of the lost, 2 are still found at L2 (relocated).
- L2 (function only): lost 0 of 2, new 0.
- L3 (location + writer site, readers collapsed): lost 2 of 5, new 0; of the L1-lost, 0 are still found at L3.

### Locations (L3) reported by tsan in ≥1 run and by tsan-sound in 0 runs

| baseline runs | race location |
|---|---|
| 1/10 | `data race | write:walIndexRecover@sqlite3.c | mapped:test.db-shm` |
| 1/10 | `data race | write:walIndexRecover@sqlite3.c:67459 | mapped:test.db-shm` |

### Races reported by tsan in ≥1 run and by tsan-sound in 0 runs (L1)

| baseline runs | at L2 in cfg? | race |
|---|---|---|
| 1/10 | yes | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walIndexRecover@sqlite3.c | mapped:test.db-shm+0x68` |
| 1/10 | yes | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walIndexRecover@sqlite3.c:67459 | mapped:test.db-shm+0x70` |

## tsan-sound-nofe vs tsan

- L1 (function@file:line): lost 2 of 7 baseline races, new 0; of the lost, 2 are still found at L2 (relocated).
- L2 (function only): lost 0 of 2, new 0.
- L3 (location + writer site, readers collapsed): lost 2 of 5, new 0; of the L1-lost, 0 are still found at L3.

### Locations (L3) reported by tsan in ≥1 run and by tsan-sound-nofe in 0 runs

| baseline runs | race location |
|---|---|
| 1/10 | `data race | write:walIndexRecover@sqlite3.c | mapped:test.db-shm` |
| 1/10 | `data race | write:walIndexRecover@sqlite3.c:67459 | mapped:test.db-shm` |

### Races reported by tsan in ≥1 run and by tsan-sound-nofe in 0 runs (L1)

| baseline runs | at L2 in cfg? | race |
|---|---|---|
| 1/10 | yes | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walIndexRecover@sqlite3.c | mapped:test.db-shm+0x68` |
| 1/10 | yes | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walIndexRecover@sqlite3.c:67459 | mapped:test.db-shm+0x70` |

## All races (L1) with per-configuration detection frequency

| tsan | tsan-sound | tsan-sound-nofe | race |
|---|---|---|---|
| 3/10 | 2/10 | 1/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:68991 | write:walIndexRecover@sqlite3.c:67450 | mapped:test.db-shm+0x60` |
| 1/10 | 0/10 | 0/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walIndexRecover@sqlite3.c | mapped:test.db-shm+0x68` |
| 1/10 | 0/10 | 0/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walIndexRecover@sqlite3.c:67459 | mapped:test.db-shm+0x70` |
| 7/10 | 8/10 | 7/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68034 | mapped:test.db-shm+0x68` |
| 3/10 | 5/10 | 5/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x6c` |
| 8/10 | 6/10 | 8/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x70` |
| 2/10 | 3/10 | 1/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x74` |

