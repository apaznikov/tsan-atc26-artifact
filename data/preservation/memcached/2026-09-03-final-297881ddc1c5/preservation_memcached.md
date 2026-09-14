# Preservation summary: memcached

Report kinds considered: data race

## Per-configuration counts (mean ± sample σ over runs)

| config | runs | reports/run | distinct L1/run | distinct L2/run | union L1 | union L2 | union L3 | kinds |
|---|---|---|---|---|---|---|---|---|
| tsan | 10 | 15.4 ± 7.0 | 14.3 ± 7.0 | 12.9 ± 3.8 | 35 | 20 | 27 | data race:154 |
| tsan-all | 10 | 17.5 ± 9.3 | 12.4 ± 9.1 | 10.3 ± 4.6 | 31 | 20 | 25 | data race:175 |
| tsan-old | 10 | 9.7 ± 2.3 | 8.7 ± 2.3 | 8.7 ± 2.3 | 16 | 16 | 11 | data race:97 |
| tsan-sound | 10 | 17.5 ± 10.9 | 16.5 ± 10.9 | 12.4 ± 4.5 | 50 | 24 | 42 | data race:175 |

## tsan-all vs tsan

- L1 (function@file:line): lost 7 of 35 baseline races, new 3; of the lost, 5 are still found at L2 (relocated).
- L2 (function only): lost 2 of 20, new 2.
- L3 (location + writer site, readers collapsed): lost 4 of 27, new 2; of the L1-lost, 3 are still found at L3.

### Locations (L3) reported by tsan in ≥1 run and by tsan-all in 0 runs

| baseline runs | race location |
|---|---|
| 1/10 | `data race | write:conn_new@memcached.c:757 | write:conn_new@memcached.c:757 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:761 | write:conn_new@memcached.c:761 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:766 | write:conn_new@memcached.c:766 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:820 | write:conn_new@memcached.c:820 | heap:conn_new` |

### Races reported by tsan in ≥1 run and by tsan-all in 0 runs (L1)

| baseline runs | at L2 in cfg? | race |
|---|---|---|
| 10/10 | **no** | `data race | read:conn_new@memcached.c:761 | write:clock_handler@memcached.c | global:current_time` |
| 1/10 | yes | `data race | read:drive_machine@memcached.c:3421 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |
| 2/10 | **no** | `data race | read:lru_pull_tail@items.c:1207 | write:clock_handler@memcached.c | global:current_time` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:757 | write:conn_new@memcached.c:757 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:761 | write:conn_new@memcached.c:761 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:766 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:820 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |

### Races reported by tsan-all but never by tsan (L1)

| cfg runs | at L2 in baseline? | race |
|---|---|---|
| 2/10 | **no** | `data race | read:reset_cmd_handler@memcached.c:1454 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 2/10 | **no** | `data race | read:update_event@memcached.c:2562 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |
| 2/10 | yes | `data race | write:conn_new@memcached.c:758 | write:conn_new@memcached.c:758 | heap:conn_new@memcached.c:656` |

## tsan-old vs tsan

- L1 (function@file:line): lost 19 of 35 baseline races, new 0; of the lost, 1 are still found at L2 (relocated).
- L2 (function only): lost 4 of 20, new 0.
- L3 (location + writer site, readers collapsed): lost 16 of 27, new 0; of the L1-lost, 3 are still found at L3.

### Locations (L3) reported by tsan in ≥1 run and by tsan-old in 0 runs

| baseline runs | race location |
|---|---|
| 1/10 | `data race | write:conn_new@memcached.c | write:conn_new@memcached.c | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:695 | write:conn_new@memcached.c:695 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:696 | write:conn_new@memcached.c:696 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:708 | write:conn_new@memcached.c:708 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:750 | write:conn_new@memcached.c:750 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:751 | write:reset_cmd_handler@memcached.c:1452 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:754 | write:conn_new@memcached.c:754 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:757 | write:conn_new@memcached.c:757 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:761 | write:conn_new@memcached.c:761 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:764 | write:conn_new@memcached.c:764 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:766 | write:conn_new@memcached.c:766 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:784 | write:conn_new@memcached.c:784 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:785 | write:conn_new@memcached.c:785 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:786 | write:conn_new@memcached.c:786 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:808 | write:conn_new@memcached.c:808 | heap:conn_new` |
| 1/10 | `data race | write:conn_new@memcached.c:820 | write:conn_new@memcached.c:820 | heap:conn_new` |

### Races reported by tsan in ≥1 run and by tsan-old in 0 runs (L1)

| baseline runs | at L2 in cfg? | race |
|---|---|---|
| 10/10 | **no** | `data race | read:conn_new@memcached.c:761 | write:clock_handler@memcached.c | global:current_time` |
| 1/10 | yes | `data race | read:drive_machine@memcached.c:3421 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |
| 2/10 | **no** | `data race | read:lru_pull_tail@items.c:1207 | write:clock_handler@memcached.c | global:current_time` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c | write:conn_new@memcached.c | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:695 | write:conn_new@memcached.c:695 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:696 | write:conn_new@memcached.c:696 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:708 | write:conn_new@memcached.c:708 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:750 | write:conn_new@memcached.c:750 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:751 | write:reset_cmd_handler@memcached.c:1452 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:754 | write:conn_new@memcached.c:754 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:757 | write:conn_new@memcached.c:757 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:761 | write:conn_new@memcached.c:761 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:764 | write:conn_new@memcached.c:764 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:766 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:784 | write:conn_new@memcached.c:784 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:785 | write:conn_new@memcached.c:785 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:786 | write:conn_new@memcached.c:786 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:808 | write:conn_new@memcached.c:808 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:820 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |

## tsan-sound vs tsan

- L1 (function@file:line): lost 2 of 35 baseline races, new 17; of the lost, 2 are still found at L2 (relocated).
- L2 (function only): lost 0 of 20, new 4.
- L3 (location + writer site, readers collapsed): lost 1 of 27, new 16; of the L1-lost, 1 are still found at L3.

### Locations (L3) reported by tsan in ≥1 run and by tsan-sound in 0 runs

| baseline runs | race location |
|---|---|
| 1/10 | `data race | write:conn_new@memcached.c:820 | write:conn_new@memcached.c:820 | heap:conn_new` |

### Races reported by tsan in ≥1 run and by tsan-sound in 0 runs (L1)

| baseline runs | at L2 in cfg? | race |
|---|---|---|
| 1/10 | yes | `data race | read:drive_machine@memcached.c:3421 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:820 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |

### Races reported by tsan-sound but never by tsan (L1)

| cfg runs | at L2 in baseline? | race |
|---|---|---|
| 1/10 | **no** | `data race | read:conn_new@memcached.c:653 | write:conn_new@memcached.c:691 | heap:conn_init@memcached.c:488` |
| 1/10 | **no** | `data race | read:reset_cmd_handler@memcached.c:1454 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 2/10 | **no** | `data race | read:update_event@memcached.c:2562 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c | write:conn_new@memcached.c:656 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:695 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:708 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:749 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:750 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:751 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:752 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:761 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:764 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:753 | write:rbuf_alloc@memcached.c:432 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:758 | write:conn_new@memcached.c:758 | heap:conn_new@memcached.c:656` |
| 1/10 | yes | `data race | write:conn_new@memcached.c:768 | write:conn_new@memcached.c:768 | heap:conn_new@memcached.c:656` |

## All races (L1) with per-configuration detection frequency

| tsan | tsan-all | tsan-old | tsan-sound | race |
|---|---|---|---|---|
| 10/10 | 10/10 | 10/10 | 10/10 | `data race | read:clock_handler@memcached.c:4009 | write:do_item_link@items.c:499 | global:stats_state` |
| 10/10 | 10/10 | 10/10 | 10/10 | `data race | read:clock_handler@memcached.c:4009 | write:do_item_unlink@items.c:519 | global:stats_state` |
| 0/10 | 0/10 | 0/10 | 1/10 | `data race | read:conn_new@memcached.c:653 | write:conn_new@memcached.c:691 | heap:conn_init@memcached.c:488` |
| 5/10 | 2/10 | 1/10 | 4/10 | `data race | read:conn_new@memcached.c:753 | write:rbuf_release@memcached.c:417 | heap:conn_new@memcached.c:656` |
| 10/10 | 0/10 | 0/10 | 10/10 | `data race | read:conn_new@memcached.c:761 | write:clock_handler@memcached.c | global:current_time` |
| 4/10 | 1/10 | 1/10 | 1/10 | `data race | read:conn_release_items@memcached.c:840 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 10/10 | 10/10 | 10/10 | 10/10 | `data race | read:do_item_link@items.c:495 | write:clock_handler@memcached.c | global:current_time` |
| 4/10 | 2/10 | 1/10 | 3/10 | `data race | read:drive_machine@memcached.c:3162 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |
| 1/10 | 0/10 | 0/10 | 0/10 | `data race | read:drive_machine@memcached.c:3421 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |
| 10/10 | 9/10 | 9/10 | 8/10 | `data race | read:item_crawler_thread@crawler.c:570 | write:do_item_unlink@items.c:516 | heap:memory_allocate@slabs.c:615` |
| 10/10 | 10/10 | 10/10 | 10/10 | `data race | read:item_remove@thread.c:921 | write:do_item_unlink@items.c:516 | heap:memory_allocate@slabs.c:615` |
| 2/10 | 3/10 | 1/10 | 1/10 | `data race | read:lru_maintainer_juggle@items.c:1426 | write:clock_handler@memcached.c | global:current_time` |
| 10/10 | 10/10 | 10/10 | 10/10 | `data race | read:lru_maintainer_thread@items.c:1671 | write:clock_handler@memcached.c | global:current_time` |
| 10/10 | 10/10 | 10/10 | 10/10 | `data race | read:lru_pull_tail@items.c:1137 | write:do_item_unlink@items.c:516 | heap:memory_allocate@slabs.c:615` |
| 2/10 | 0/10 | 0/10 | 1/10 | `data race | read:lru_pull_tail@items.c:1207 | write:clock_handler@memcached.c | global:current_time` |
| 0/10 | 2/10 | 0/10 | 1/10 | `data race | read:reset_cmd_handler@memcached.c:1454 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 10/10 | 10/10 | 10/10 | 10/10 | `data race | read:try_read_command_ascii@proto_text.c:493 | write:clock_handler@memcached.c | global:current_time` |
| 4/10 | 2/10 | 1/10 | 3/10 | `data race | read:try_read_network@memcached.c:2530 | write:conn_new@memcached.c:784 | heap:conn_new@memcached.c:656` |
| 0/10 | 2/10 | 0/10 | 2/10 | `data race | read:update_event@memcached.c:2562 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |
| 5/10 | 2/10 | 1/10 | 4/10 | `data race | write:conn_close@memcached.c:933 | write:conn_new@memcached.c:752 | heap:conn_new@memcached.c:656` |
| 1/10 | 2/10 | 0/10 | 2/10 | `data race | write:conn_new@memcached.c | write:conn_new@memcached.c | heap:conn_new@memcached.c:656` |
| 0/10 | 0/10 | 0/10 | 1/10 | `data race | write:conn_new@memcached.c | write:conn_new@memcached.c:656 | heap:conn_new@memcached.c:656` |
| 0/10 | 0/10 | 0/10 | 1/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |
| 0/10 | 0/10 | 0/10 | 1/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:695 | heap:conn_new@memcached.c:656` |
| 0/10 | 0/10 | 0/10 | 1/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:708 | heap:conn_new@memcached.c:656` |
| 0/10 | 0/10 | 0/10 | 1/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:749 | heap:conn_new@memcached.c:656` |
| 0/10 | 0/10 | 0/10 | 1/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:750 | heap:conn_new@memcached.c:656` |
| 0/10 | 0/10 | 0/10 | 1/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:751 | heap:conn_new@memcached.c:656` |
| 0/10 | 0/10 | 0/10 | 1/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:752 | heap:conn_new@memcached.c:656` |
| 0/10 | 0/10 | 0/10 | 1/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:761 | heap:conn_new@memcached.c:656` |
| 0/10 | 0/10 | 0/10 | 1/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:764 | heap:conn_new@memcached.c:656` |
| 0/10 | 0/10 | 0/10 | 1/10 | `data race | write:conn_new@memcached.c:656 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |
| 1/10 | 2/10 | 0/10 | 2/10 | `data race | write:conn_new@memcached.c:695 | write:conn_new@memcached.c:695 | heap:conn_new@memcached.c:656` |
| 1/10 | 2/10 | 0/10 | 3/10 | `data race | write:conn_new@memcached.c:696 | write:conn_new@memcached.c:696 | heap:conn_new@memcached.c:656` |
| 1/10 | 2/10 | 0/10 | 2/10 | `data race | write:conn_new@memcached.c:708 | write:conn_new@memcached.c:708 | heap:conn_new@memcached.c:656` |
| 5/10 | 2/10 | 1/10 | 4/10 | `data race | write:conn_new@memcached.c:749 | write:conn_set_state@memcached.c:1011 | heap:conn_new@memcached.c:656` |
| 1/10 | 2/10 | 0/10 | 2/10 | `data race | write:conn_new@memcached.c:750 | write:conn_new@memcached.c:750 | heap:conn_new@memcached.c:656` |
| 1/10 | 2/10 | 0/10 | 3/10 | `data race | write:conn_new@memcached.c:751 | write:reset_cmd_handler@memcached.c:1452 | heap:conn_new@memcached.c:656` |
| 0/10 | 0/10 | 0/10 | 1/10 | `data race | write:conn_new@memcached.c:753 | write:rbuf_alloc@memcached.c:432 | heap:conn_new@memcached.c:656` |
| 5/10 | 2/10 | 1/10 | 4/10 | `data race | write:conn_new@memcached.c:753 | write:rbuf_release@memcached.c:417 | heap:conn_new@memcached.c:656` |
| 1/10 | 2/10 | 0/10 | 3/10 | `data race | write:conn_new@memcached.c:754 | write:conn_new@memcached.c:754 | heap:conn_new@memcached.c:656` |
| 1/10 | 0/10 | 0/10 | 2/10 | `data race | write:conn_new@memcached.c:757 | write:conn_new@memcached.c:757 | heap:conn_new@memcached.c:656` |
| 0/10 | 2/10 | 0/10 | 1/10 | `data race | write:conn_new@memcached.c:758 | write:conn_new@memcached.c:758 | heap:conn_new@memcached.c:656` |
| 1/10 | 0/10 | 0/10 | 1/10 | `data race | write:conn_new@memcached.c:761 | write:conn_new@memcached.c:761 | heap:conn_new@memcached.c:656` |
| 1/10 | 2/10 | 0/10 | 2/10 | `data race | write:conn_new@memcached.c:764 | write:conn_new@memcached.c:764 | heap:conn_new@memcached.c:656` |
| 1/10 | 0/10 | 0/10 | 2/10 | `data race | write:conn_new@memcached.c:766 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 0/10 | 0/10 | 0/10 | 1/10 | `data race | write:conn_new@memcached.c:768 | write:conn_new@memcached.c:768 | heap:conn_new@memcached.c:656` |
| 1/10 | 1/10 | 0/10 | 1/10 | `data race | write:conn_new@memcached.c:784 | write:conn_new@memcached.c:784 | heap:conn_new@memcached.c:656` |
| 1/10 | 2/10 | 0/10 | 3/10 | `data race | write:conn_new@memcached.c:785 | write:conn_new@memcached.c:785 | heap:conn_new@memcached.c:656` |
| 1/10 | 2/10 | 0/10 | 3/10 | `data race | write:conn_new@memcached.c:786 | write:conn_new@memcached.c:786 | heap:conn_new@memcached.c:656` |
| 1/10 | 2/10 | 0/10 | 3/10 | `data race | write:conn_new@memcached.c:808 | write:conn_new@memcached.c:808 | heap:conn_new@memcached.c:656` |
| 1/10 | 0/10 | 0/10 | 0/10 | `data race | write:conn_new@memcached.c:820 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |

