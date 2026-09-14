# Preservation summary: sqlite

Report kinds considered: data race

## Per-configuration counts (mean ± sample σ over runs)

| config | runs | reports/run | distinct L1/run | distinct L2/run | union L1 | union L2 | union L3 | kinds |
|---|---|---|---|---|---|---|---|---|
| tsan | 10 | 4.6 ± 0.5 | 4.6 ± 0.5 | 1.7 ± 0.5 | 6 | 3 | 4 | data race:46 |
| tsan-dom_peeling-ea-lo-st-swmr | 10 | 4.4 ± 1.3 | 4.1 ± 0.6 | 1.2 ± 0.4 | 5 | 2 | 3 | data race:44 |
| tsan-sound | 10 | 4.1 ± 0.6 | 4.1 ± 0.6 | 1.2 ± 0.4 | 5 | 2 | 3 | data race:41 |

## tsan-dom_peeling-ea-lo-st-swmr vs tsan

- L1 (function@file:line): lost 1 of 6 baseline races, new 0; of the lost, 0 are still found at L2 (relocated).
- L2 (function only): lost 1 of 3, new 0.
- L3 (location + writer site, readers collapsed): lost 1 of 4, new 0; of the L1-lost, 0 are still found at L3.

### Locations (L3) reported by tsan in ≥1 run and by tsan-dom_peeling-ea-lo-st-swmr in 0 runs

| baseline runs | race location |
|---|---|
| 1/10 | `data race | write:sqlite3BtreeSchema@sqlite3.c:82865 | heap:sqlite3MemMalloc` |

### Races reported by tsan in ≥1 run and by tsan-dom_peeling-ea-lo-st-swmr in 0 runs (L1)

| baseline runs | at L2 in cfg? | race |
|---|---|---|
| 1/10 | **no** | `data race | read:sqlite3BtreeSchema@sqlite3.c | write:sqlite3BtreeSchema@sqlite3.c:82865 | heap:sqlite3MemMalloc@sqlite3.c:27279` |

## tsan-sound vs tsan

- L1 (function@file:line): lost 1 of 6 baseline races, new 0; of the lost, 0 are still found at L2 (relocated).
- L2 (function only): lost 1 of 3, new 0.
- L3 (location + writer site, readers collapsed): lost 1 of 4, new 0; of the L1-lost, 0 are still found at L3.

### Locations (L3) reported by tsan in ≥1 run and by tsan-sound in 0 runs

| baseline runs | race location |
|---|---|
| 1/10 | `data race | write:sqlite3BtreeSchema@sqlite3.c:82865 | heap:sqlite3MemMalloc` |

### Races reported by tsan in ≥1 run and by tsan-sound in 0 runs (L1)

| baseline runs | at L2 in cfg? | race |
|---|---|---|
| 1/10 | **no** | `data race | read:sqlite3BtreeSchema@sqlite3.c | write:sqlite3BtreeSchema@sqlite3.c:82865 | heap:sqlite3MemMalloc@sqlite3.c:27279` |

## All races (L1) with per-configuration detection frequency

| tsan | tsan-dom_peeling-ea-lo-st-swmr | tsan-sound | race |
|---|---|---|---|
| 6/10 | 2/10 | 2/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:68991 | write:walIndexRecover@sqlite3.c:67450 | mapped:test.db-shm+0x60` |
| 10/10 | 10/10 | 10/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68034 | mapped:test.db-shm+0x68` |
| 10/10 | 10/10 | 10/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x6c` |
| 10/10 | 10/10 | 10/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x70` |
| 9/10 | 9/10 | 9/10 | `data race | atomic read:walTryBeginRead@sqlite3.c:69040 | write:walRestartHdr@sqlite3.c:68035 | mapped:test.db-shm+0x74` |
| 1/10 | 0/10 | 0/10 | `data race | read:sqlite3BtreeSchema@sqlite3.c | write:sqlite3BtreeSchema@sqlite3.c:82865 | heap:sqlite3MemMalloc@sqlite3.c:27279` |

