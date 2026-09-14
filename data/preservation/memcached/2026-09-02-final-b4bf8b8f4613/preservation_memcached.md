# Preservation summary: memcached

Report kinds considered: data race

## Per-configuration counts (mean ± sample σ over runs)

| config | runs | reports/run | distinct L1/run | distinct L2/run | union L1 | union L2 | union L3 | kinds |
|---|---|---|---|---|---|---|---|---|
| tsan | 10 | 9.7 ± 2.3 | 8.7 ± 2.3 | 8.7 ± 2.3 | 16 | 16 | 11 | data race:97 |
| tsan-all | 10 | 11.1 ± 2.1 | 6.1 ± 2.1 | 6.1 ± 2.1 | 13 | 13 | 11 | data race:111 |
| tsan-sound | 10 | 7.2 ± 2.1 | 6.2 ± 2.1 | 6.2 ± 2.1 | 13 | 13 | 11 | data race:72 |

## tsan-all vs tsan

- L1 (function@file:line): lost 4 of 16 baseline races, new 1; of the lost, 0 are still found at L2 (relocated).
- L2 (function only): lost 4 of 16, new 1.
- L3 (location + writer site, readers collapsed): lost 0 of 11, new 0; of the L1-lost, 4 are still found at L3.

### Races reported by tsan in ≥1 run and by tsan-all in 0 runs (L1)

| baseline runs | at L2 in cfg? | race |
|---|---|---|
| 10/10 | **no** | `data race | read:do_item_link@items.c:495 | write:clock_handler@memcached.c | global:current_time` |
| 1/10 | **no** | `data race | read:lru_maintainer_juggle@items.c:1426 | write:clock_handler@memcached.c | global:current_time` |
| 10/10 | **no** | `data race | read:lru_maintainer_thread@items.c:1671 | write:clock_handler@memcached.c | global:current_time` |
| 10/10 | **no** | `data race | read:try_read_command_ascii@proto_text.c:493 | write:clock_handler@memcached.c | global:current_time` |

### Races reported by tsan-all but never by tsan (L1)

| cfg runs | at L2 in baseline? | race |
|---|---|---|
| 10/10 | **no** | `data race | read:conn_new@memcached.c:761 | write:clock_handler@memcached.c | global:current_time` |

## tsan-sound vs tsan

- L1 (function@file:line): lost 4 of 16 baseline races, new 1; of the lost, 0 are still found at L2 (relocated).
- L2 (function only): lost 4 of 16, new 1.
- L3 (location + writer site, readers collapsed): lost 0 of 11, new 0; of the L1-lost, 4 are still found at L3.

### Races reported by tsan in ≥1 run and by tsan-sound in 0 runs (L1)

| baseline runs | at L2 in cfg? | race |
|---|---|---|
| 10/10 | **no** | `data race | read:do_item_link@items.c:495 | write:clock_handler@memcached.c | global:current_time` |
| 1/10 | **no** | `data race | read:lru_maintainer_juggle@items.c:1426 | write:clock_handler@memcached.c | global:current_time` |
| 10/10 | **no** | `data race | read:lru_maintainer_thread@items.c:1671 | write:clock_handler@memcached.c | global:current_time` |
| 10/10 | **no** | `data race | read:try_read_command_ascii@proto_text.c:493 | write:clock_handler@memcached.c | global:current_time` |

### Races reported by tsan-sound but never by tsan (L1)

| cfg runs | at L2 in baseline? | race |
|---|---|---|
| 10/10 | **no** | `data race | read:conn_new@memcached.c:761 | write:clock_handler@memcached.c | global:current_time` |

## All races (L1) with per-configuration detection frequency

| tsan | tsan-all | tsan-sound | race |
|---|---|---|---|
| 10/10 | 10/10 | 10/10 | `data race | read:clock_handler@memcached.c:4009 | write:do_item_link@items.c:499 | global:stats_state` |
| 10/10 | 10/10 | 10/10 | `data race | read:clock_handler@memcached.c:4009 | write:do_item_unlink@items.c:519 | global:stats_state` |
| 1/10 | 1/10 | 1/10 | `data race | read:conn_new@memcached.c:753 | write:rbuf_release@memcached.c:417 | heap:conn_new@memcached.c:656` |
| 0/10 | 10/10 | 10/10 | `data race | read:conn_new@memcached.c:761 | write:clock_handler@memcached.c | global:current_time` |
| 1/10 | 1/10 | 1/10 | `data race | read:conn_release_items@memcached.c:840 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 10/10 | 0/10 | 0/10 | `data race | read:do_item_link@items.c:495 | write:clock_handler@memcached.c | global:current_time` |
| 1/10 | 1/10 | 1/10 | `data race | read:drive_machine@memcached.c:3162 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |
| 9/10 | 4/10 | 5/10 | `data race | read:item_crawler_thread@crawler.c:570 | write:do_item_unlink@items.c:516 | heap:memory_allocate@slabs.c:615` |
| 10/10 | 10/10 | 10/10 | `data race | read:item_remove@thread.c:921 | write:do_item_unlink@items.c:516 | heap:memory_allocate@slabs.c:615` |
| 1/10 | 0/10 | 0/10 | `data race | read:lru_maintainer_juggle@items.c:1426 | write:clock_handler@memcached.c | global:current_time` |
| 10/10 | 0/10 | 0/10 | `data race | read:lru_maintainer_thread@items.c:1671 | write:clock_handler@memcached.c | global:current_time` |
| 10/10 | 10/10 | 10/10 | `data race | read:lru_pull_tail@items.c:1137 | write:do_item_unlink@items.c:516 | heap:memory_allocate@slabs.c:615` |
| 10/10 | 0/10 | 0/10 | `data race | read:try_read_command_ascii@proto_text.c:493 | write:clock_handler@memcached.c | global:current_time` |
| 1/10 | 1/10 | 1/10 | `data race | read:try_read_network@memcached.c:2530 | write:conn_new@memcached.c:784 | heap:conn_new@memcached.c:656` |
| 1/10 | 1/10 | 1/10 | `data race | write:conn_close@memcached.c:933 | write:conn_new@memcached.c:752 | heap:conn_new@memcached.c:656` |
| 1/10 | 1/10 | 1/10 | `data race | write:conn_new@memcached.c:749 | write:conn_set_state@memcached.c:1011 | heap:conn_new@memcached.c:656` |
| 1/10 | 1/10 | 1/10 | `data race | write:conn_new@memcached.c:753 | write:rbuf_release@memcached.c:417 | heap:conn_new@memcached.c:656` |

