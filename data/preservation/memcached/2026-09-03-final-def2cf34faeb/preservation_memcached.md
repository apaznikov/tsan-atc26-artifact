# Preservation summary: memcached

Report kinds considered: data race

## Per-configuration counts (mean ± sample σ over runs)

| config | runs | reports/run | distinct L1/run | distinct L2/run | union L1 | union L2 | union L3 | kinds |
|---|---|---|---|---|---|---|---|---|
| tsan | 30 | 11.6 ± 5.7 | 10.5 ± 5.6 | 9.8 ± 3.4 | 34 | 21 | 27 | data race:347 |
| tsan-all | 30 | 15.8 ± 8.0 | 10.8 ± 8.0 | 9.4 ± 3.3 | 51 | 24 | 43 | data race:474 |
| tsan-sound | 10 | 9.7 ± 2.3 | 8.7 ± 2.3 | 8.7 ± 2.3 | 17 | 17 | 11 | data race:97 |

## tsan-all vs tsan

- L1 (function@file:line): lost 1 of 34 baseline races, new 18; of the lost, 1 are still found at L2 (relocated).
- L2 (function only): lost 0 of 21, new 3.
- L3 (location + writer site, readers collapsed): lost 1 of 27, new 17; of the L1-lost, 0 are still found at L3.

### Locations (L3) reported by tsan in ≥1 run and by tsan-all in 0 runs

| baseline runs | race location |
|---|---|
| 1/30 | `data race | write:conn_new@memcached.c:694 | write:conn_new@memcached.c:694 | heap:conn_new` |

### Races reported by tsan in ≥1 run and by tsan-all in 0 runs (L1)

| baseline runs | at L2 in cfg? | race |
|---|---|---|
| 1/30 | yes | `data race | write:conn_new@memcached.c:694 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |

### Races reported by tsan-all but never by tsan (L1)

| cfg runs | at L2 in baseline? | race |
|---|---|---|
| 1/30 | **no** | `data race | read:conn_new@memcached.c:653 | write:conn_new@memcached.c:691 | heap:conn_init@memcached.c:488` |
| 1/30 | **no** | `data race | read:conn_new@memcached.c:761 | write:clock_handler@memcached.c | global:current_time` |
| 1/30 | yes | `data race | write:conn_new@memcached.c | write:conn_new@memcached.c:656 | heap:conn_new@memcached.c:656` |
| 1/30 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |
| 1/30 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:695 | heap:conn_new@memcached.c:656` |
| 1/30 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:708 | heap:conn_new@memcached.c:656` |
| 1/30 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:749 | heap:conn_new@memcached.c:656` |
| 1/30 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:750 | heap:conn_new@memcached.c:656` |
| 1/30 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:751 | heap:conn_new@memcached.c:656` |
| 1/30 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:752 | heap:conn_new@memcached.c:656` |
| 1/30 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:757 | heap:conn_new@memcached.c:656` |
| 1/30 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:761 | heap:conn_new@memcached.c:656` |
| 1/30 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:764 | heap:conn_new@memcached.c:656` |
| 1/30 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |
| 1/30 | **no** | `data race | write:conn_new@memcached.c:753 | write:rbuf_alloc@memcached.c:432 | heap:conn_new@memcached.c:656` |
| 2/30 | yes | `data race | write:conn_new@memcached.c:766 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 1/30 | yes | `data race | write:conn_new@memcached.c:768 | write:conn_new@memcached.c:768 | heap:conn_new@memcached.c:656` |
| 1/30 | yes | `data race | write:conn_new@memcached.c:820 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |

## tsan-sound vs tsan

- L1 (function@file:line): lost 17 of 34 baseline races, new 0; of the lost, 0 are still found at L2 (relocated).
- L2 (function only): lost 4 of 21, new 0.
- L3 (location + writer site, readers collapsed): lost 16 of 27, new 0; of the L1-lost, 1 are still found at L3.

### Locations (L3) reported by tsan in ≥1 run and by tsan-sound in 0 runs

| baseline runs | race location |
|---|---|
| 2/30 | `data race | write:conn_new@memcached.c | write:conn_new@memcached.c | heap:conn_new` |
| 1/30 | `data race | write:conn_new@memcached.c:694 | write:conn_new@memcached.c:694 | heap:conn_new` |
| 2/30 | `data race | write:conn_new@memcached.c:695 | write:conn_new@memcached.c:695 | heap:conn_new` |
| 2/30 | `data race | write:conn_new@memcached.c:696 | write:conn_new@memcached.c:696 | heap:conn_new` |
| 2/30 | `data race | write:conn_new@memcached.c:708 | write:conn_new@memcached.c:708 | heap:conn_new` |
| 2/30 | `data race | write:conn_new@memcached.c:750 | write:conn_new@memcached.c:750 | heap:conn_new` |
| 2/30 | `data race | write:conn_new@memcached.c:751 | write:reset_cmd_handler@memcached.c:1452 | heap:conn_new` |
| 2/30 | `data race | write:conn_new@memcached.c:754 | write:conn_new@memcached.c:754 | heap:conn_new` |
| 1/30 | `data race | write:conn_new@memcached.c:757 | write:conn_new@memcached.c:757 | heap:conn_new` |
| 1/30 | `data race | write:conn_new@memcached.c:761 | write:conn_new@memcached.c:761 | heap:conn_new` |
| 2/30 | `data race | write:conn_new@memcached.c:764 | write:conn_new@memcached.c:764 | heap:conn_new` |
| 1/30 | `data race | write:conn_new@memcached.c:784 | write:conn_new@memcached.c:784 | heap:conn_new` |
| 2/30 | `data race | write:conn_new@memcached.c:785 | write:conn_new@memcached.c:785 | heap:conn_new` |
| 2/30 | `data race | write:conn_new@memcached.c:786 | write:conn_new@memcached.c:786 | heap:conn_new` |
| 2/30 | `data race | write:conn_new@memcached.c:808 | write:conn_new@memcached.c:808 | heap:conn_new` |
| 2/30 | `data race | write:conn_new@memcached.c:820 | heap:conn_new` |

### Races reported by tsan in ≥1 run and by tsan-sound in 0 runs (L1)

| baseline runs | at L2 in cfg? | race |
|---|---|---|
| 2/30 | **no** | `data race | read:reset_cmd_handler@memcached.c:1454 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 2/30 | **no** | `data race | read:update_event@memcached.c:2562 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |
| 2/30 | **no** | `data race | write:conn_new@memcached.c | write:conn_new@memcached.c | heap:conn_new@memcached.c:656` |
| 1/30 | **no** | `data race | write:conn_new@memcached.c:694 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |
| 2/30 | **no** | `data race | write:conn_new@memcached.c:695 | write:conn_new@memcached.c:695 | heap:conn_new@memcached.c:656` |
| 2/30 | **no** | `data race | write:conn_new@memcached.c:696 | write:conn_new@memcached.c:696 | heap:conn_new@memcached.c:656` |
| 2/30 | **no** | `data race | write:conn_new@memcached.c:708 | write:conn_new@memcached.c:708 | heap:conn_new@memcached.c:656` |
| 2/30 | **no** | `data race | write:conn_new@memcached.c:750 | write:conn_new@memcached.c:750 | heap:conn_new@memcached.c:656` |
| 2/30 | **no** | `data race | write:conn_new@memcached.c:751 | write:reset_cmd_handler@memcached.c:1452 | heap:conn_new@memcached.c:656` |
| 2/30 | **no** | `data race | write:conn_new@memcached.c:754 | write:conn_new@memcached.c:754 | heap:conn_new@memcached.c:656` |
| 1/30 | **no** | `data race | write:conn_new@memcached.c:757 | write:conn_new@memcached.c:757 | heap:conn_new@memcached.c:656` |
| 1/30 | **no** | `data race | write:conn_new@memcached.c:761 | write:conn_new@memcached.c:761 | heap:conn_new@memcached.c:656` |
| 2/30 | **no** | `data race | write:conn_new@memcached.c:764 | write:conn_new@memcached.c:764 | heap:conn_new@memcached.c:656` |
| 1/30 | **no** | `data race | write:conn_new@memcached.c:784 | write:conn_new@memcached.c:784 | heap:conn_new@memcached.c:656` |
| 2/30 | **no** | `data race | write:conn_new@memcached.c:785 | write:conn_new@memcached.c:785 | heap:conn_new@memcached.c:656` |
| 2/30 | **no** | `data race | write:conn_new@memcached.c:786 | write:conn_new@memcached.c:786 | heap:conn_new@memcached.c:656` |
| 2/30 | **no** | `data race | write:conn_new@memcached.c:808 | write:conn_new@memcached.c:808 | heap:conn_new@memcached.c:656` |

## All races (L1) with per-configuration detection frequency

| tsan | tsan-all | tsan-sound | race |
|---|---|---|---|
| 30/30 | 30/30 | 10/10 | `data race | read:clock_handler@memcached.c:4009 | write:do_item_link@items.c:499 | global:stats_state` |
| 30/30 | 30/30 | 10/10 | `data race | read:clock_handler@memcached.c:4009 | write:do_item_unlink@items.c:519 | global:stats_state` |
| 0/30 | 1/30 | 0/10 | `data race | read:conn_new@memcached.c:653 | write:conn_new@memcached.c:691 | heap:conn_init@memcached.c:488` |
| 7/30 | 5/30 | 1/10 | `data race | read:conn_new@memcached.c:753 | write:rbuf_release@memcached.c:417 | heap:conn_new@memcached.c:656` |
| 0/30 | 1/30 | 0/10 | `data race | read:conn_new@memcached.c:761 | write:clock_handler@memcached.c | global:current_time` |
| 6/30 | 3/30 | 1/10 | `data race | read:conn_release_items@memcached.c:840 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 30/30 | 30/30 | 10/10 | `data race | read:do_item_link@items.c:495 | write:clock_handler@memcached.c | global:current_time` |
| 6/30 | 5/30 | 1/10 | `data race | read:drive_machine@memcached.c:3162 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |
| 24/30 | 23/30 | 8/10 | `data race | read:item_crawler_thread@crawler.c:570 | write:do_item_unlink@items.c:516 | heap:memory_allocate@slabs.c:615` |
| 30/30 | 30/30 | 10/10 | `data race | read:item_remove@thread.c:921 | write:do_item_unlink@items.c:516 | heap:memory_allocate@slabs.c:615` |
| 2/30 | 3/30 | 1/10 | `data race | read:lru_maintainer_juggle@items.c:1426 | write:clock_handler@memcached.c | global:current_time` |
| 30/30 | 30/30 | 10/10 | `data race | read:lru_maintainer_thread@items.c:1671 | write:clock_handler@memcached.c | global:current_time` |
| 30/30 | 30/30 | 10/10 | `data race | read:lru_pull_tail@items.c:1137 | write:do_item_unlink@items.c:516 | heap:memory_allocate@slabs.c:615` |
| 3/30 | 6/30 | 1/10 | `data race | read:lru_pull_tail@items.c:1207 | write:clock_handler@memcached.c | global:current_time` |
| 2/30 | 2/30 | 0/10 | `data race | read:reset_cmd_handler@memcached.c:1454 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 30/30 | 30/30 | 10/10 | `data race | read:try_read_command_ascii@proto_text.c:493 | write:clock_handler@memcached.c | global:current_time` |
| 7/30 | 3/30 | 1/10 | `data race | read:try_read_network@memcached.c:2530 | write:conn_new@memcached.c:784 | heap:conn_new@memcached.c:656` |
| 2/30 | 1/30 | 0/10 | `data race | read:update_event@memcached.c:2562 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |
| 7/30 | 5/30 | 1/10 | `data race | write:conn_close@memcached.c:933 | write:conn_new@memcached.c:752 | heap:conn_new@memcached.c:656` |
| 2/30 | 2/30 | 0/10 | `data race | write:conn_new@memcached.c | write:conn_new@memcached.c | heap:conn_new@memcached.c:656` |
| 0/30 | 1/30 | 0/10 | `data race | write:conn_new@memcached.c | write:conn_new@memcached.c:656 | heap:conn_new@memcached.c:656` |
| 0/30 | 1/30 | 0/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |
| 0/30 | 1/30 | 0/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:695 | heap:conn_new@memcached.c:656` |
| 0/30 | 1/30 | 0/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:708 | heap:conn_new@memcached.c:656` |
| 0/30 | 1/30 | 0/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:749 | heap:conn_new@memcached.c:656` |
| 0/30 | 1/30 | 0/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:750 | heap:conn_new@memcached.c:656` |
| 0/30 | 1/30 | 0/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:751 | heap:conn_new@memcached.c:656` |
| 0/30 | 1/30 | 0/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:752 | heap:conn_new@memcached.c:656` |
| 0/30 | 1/30 | 0/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:757 | heap:conn_new@memcached.c:656` |
| 0/30 | 1/30 | 0/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:761 | heap:conn_new@memcached.c:656` |
| 0/30 | 1/30 | 0/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:764 | heap:conn_new@memcached.c:656` |
| 0/30 | 1/30 | 0/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |
| 1/30 | 0/30 | 0/10 | `data race | write:conn_new@memcached.c:694 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |
| 2/30 | 2/30 | 0/10 | `data race | write:conn_new@memcached.c:695 | write:conn_new@memcached.c:695 | heap:conn_new@memcached.c:656` |
| 2/30 | 2/30 | 0/10 | `data race | write:conn_new@memcached.c:696 | write:conn_new@memcached.c:696 | heap:conn_new@memcached.c:656` |
| 2/30 | 2/30 | 0/10 | `data race | write:conn_new@memcached.c:708 | write:conn_new@memcached.c:708 | heap:conn_new@memcached.c:656` |
| 7/30 | 5/30 | 1/10 | `data race | write:conn_new@memcached.c:749 | write:conn_set_state@memcached.c:1011 | heap:conn_new@memcached.c:656` |
| 2/30 | 2/30 | 0/10 | `data race | write:conn_new@memcached.c:750 | write:conn_new@memcached.c:750 | heap:conn_new@memcached.c:656` |
| 2/30 | 2/30 | 0/10 | `data race | write:conn_new@memcached.c:751 | write:reset_cmd_handler@memcached.c:1452 | heap:conn_new@memcached.c:656` |
| 0/30 | 1/30 | 0/10 | `data race | write:conn_new@memcached.c:753 | write:rbuf_alloc@memcached.c:432 | heap:conn_new@memcached.c:656` |
| 7/30 | 5/30 | 1/10 | `data race | write:conn_new@memcached.c:753 | write:rbuf_release@memcached.c:417 | heap:conn_new@memcached.c:656` |
| 2/30 | 2/30 | 0/10 | `data race | write:conn_new@memcached.c:754 | write:conn_new@memcached.c:754 | heap:conn_new@memcached.c:656` |
| 1/30 | 2/30 | 0/10 | `data race | write:conn_new@memcached.c:757 | write:conn_new@memcached.c:757 | heap:conn_new@memcached.c:656` |
| 1/30 | 2/30 | 0/10 | `data race | write:conn_new@memcached.c:761 | write:conn_new@memcached.c:761 | heap:conn_new@memcached.c:656` |
| 2/30 | 2/30 | 0/10 | `data race | write:conn_new@memcached.c:764 | write:conn_new@memcached.c:764 | heap:conn_new@memcached.c:656` |
| 0/30 | 2/30 | 0/10 | `data race | write:conn_new@memcached.c:766 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 0/30 | 1/30 | 0/10 | `data race | write:conn_new@memcached.c:768 | write:conn_new@memcached.c:768 | heap:conn_new@memcached.c:656` |
| 1/30 | 2/30 | 0/10 | `data race | write:conn_new@memcached.c:784 | write:conn_new@memcached.c:784 | heap:conn_new@memcached.c:656` |
| 2/30 | 2/30 | 0/10 | `data race | write:conn_new@memcached.c:785 | write:conn_new@memcached.c:785 | heap:conn_new@memcached.c:656` |
| 2/30 | 2/30 | 0/10 | `data race | write:conn_new@memcached.c:786 | write:conn_new@memcached.c:786 | heap:conn_new@memcached.c:656` |
| 2/30 | 2/30 | 0/10 | `data race | write:conn_new@memcached.c:808 | write:conn_new@memcached.c:808 | heap:conn_new@memcached.c:656` |
| 0/30 | 1/30 | 0/10 | `data race | write:conn_new@memcached.c:820 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |

