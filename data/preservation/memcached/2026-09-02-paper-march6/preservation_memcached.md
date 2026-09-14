# Preservation summary: memcached

Report kinds considered: data race

## Per-configuration counts (mean ± sample σ over runs)

| config | runs | reports/run | distinct L1/run | distinct L2/run | union L1 | union L2 | kinds |
|---|---|---|---|---|---|---|---|
| tsan | 10 | 11.8 ± 3.6 | 10.8 ± 3.6 | 10.8 ± 3.6 | 17 | 17 | data race:118 |
| tsan-all | 10 | 14.5 ± 8.3 | 9.4 ± 8.0 | 7.8 ± 3.0 | 37 | 21 | data race:145 |

## tsan-all vs tsan

- L1 (function@file:line): lost 1 of 17 baseline races, new 21; of the lost, 0 are still found at L2 (relocated).
- L2 (function only): lost 1 of 17, new 5.

### Races reported by tsan in ≥1 run and by tsan-all in 0 runs (L1)

| baseline runs | at L2 in cfg? | race |
|---|---|---|
| 3/10 | **no** | `data race | read:conn_release_items@memcached.c:840 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |

### Races reported by tsan-all but never by tsan (L1)

| cfg runs | at L2 in baseline? | race |
|---|---|---|
| 1/10 | yes | `data race | read:drive_machine@memcached.c:3421 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | read:lru_pull_tail@items.c:1207 | write:clock_handler@memcached.c | global:current_time` |
| 1/10 | **no** | `data race | read:reset_cmd_handler@memcached.c:1454 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | read:update_event@memcached.c:2562 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c | write:conn_new@memcached.c | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:695 | write:conn_new@memcached.c:695 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:696 | write:conn_new@memcached.c:696 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:708 | write:conn_new@memcached.c:708 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:750 | write:conn_new@memcached.c:750 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:751 | write:reset_cmd_handler@memcached.c:1452 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:754 | write:conn_new@memcached.c:754 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:757 | write:conn_new@memcached.c:757 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:758 | write:conn_new@memcached.c:758 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:761 | write:conn_new@memcached.c:761 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:764 | write:conn_new@memcached.c:764 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:766 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:784 | write:conn_new@memcached.c:784 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:785 | write:conn_new@memcached.c:785 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:786 | write:conn_new@memcached.c:786 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:808 | write:conn_new@memcached.c:808 | heap:conn_new@memcached.c:656` |
| 1/10 | **no** | `data race | write:conn_new@memcached.c:820 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |

### Detection-frequency changes (both found it; Fisher exact p < 0.05)

| tsan | tsan-all | p | race |
|---|---|---|---|
| 10/10 | 1/10 | 0.000119 | `data race | read:clock_handler@memcached.c:4009 | write:do_item_link@items.c:499 | global:stats_state` |
| 10/10 | 1/10 | 0.000119 | `data race | read:clock_handler@memcached.c:4009 | write:do_item_unlink@items.c:519 | global:stats_state` |

## All races (L1) with per-configuration detection frequency

| tsan | tsan-all | race |
|---|---|---|
| 10/10 | 1/10 | `data race | read:clock_handler@memcached.c:4009 | write:do_item_link@items.c:499 | global:stats_state` |
| 10/10 | 1/10 | `data race | read:clock_handler@memcached.c:4009 | write:do_item_unlink@items.c:519 | global:stats_state` |
| 3/10 | 1/10 | `data race | read:conn_new@memcached.c:753 | write:rbuf_release@memcached.c:417 | heap:conn_new@memcached.c:656` |
| 8/10 | 10/10 | `data race | read:conn_new@memcached.c:761 | write:clock_handler@memcached.c | global:current_time` |
| 3/10 | 0/10 | `data race | read:conn_release_items@memcached.c:840 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 10/10 | 9/10 | `data race | read:do_item_link@items.c:495 | write:clock_handler@memcached.c | global:current_time` |
| 3/10 | 1/10 | `data race | read:drive_machine@memcached.c:3162 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | read:drive_machine@memcached.c:3421 | write:conn_new@memcached.c:694 | heap:conn_new@memcached.c:656` |
| 7/10 | 8/10 | `data race | read:item_crawler_thread@crawler.c:570 | write:do_item_unlink@items.c:516 | heap:memory_allocate@slabs.c:615` |
| 10/10 | 10/10 | `data race | read:item_remove@thread.c:921 | write:do_item_unlink@items.c:516 | heap:memory_allocate@slabs.c:615` |
| 3/10 | 1/10 | `data race | read:lru_maintainer_juggle@items.c:1426 | write:clock_handler@memcached.c | global:current_time` |
| 9/10 | 8/10 | `data race | read:lru_maintainer_thread@items.c:1671 | write:clock_handler@memcached.c | global:current_time` |
| 10/10 | 10/10 | `data race | read:lru_pull_tail@items.c:1137 | write:do_item_unlink@items.c:516 | heap:memory_allocate@slabs.c:615` |
| 0/10 | 1/10 | `data race | read:lru_pull_tail@items.c:1207 | write:clock_handler@memcached.c | global:current_time` |
| 0/10 | 1/10 | `data race | read:reset_cmd_handler@memcached.c:1454 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 10/10 | 9/10 | `data race | read:try_read_command_ascii@proto_text.c:493 | write:clock_handler@memcached.c | global:current_time` |
| 3/10 | 1/10 | `data race | read:try_read_network@memcached.c:2530 | write:conn_new@memcached.c:784 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | read:update_event@memcached.c:2562 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |
| 3/10 | 1/10 | `data race | write:conn_close@memcached.c:933 | write:conn_new@memcached.c:752 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c | write:conn_new@memcached.c | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c:695 | write:conn_new@memcached.c:695 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c:696 | write:conn_new@memcached.c:696 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c:708 | write:conn_new@memcached.c:708 | heap:conn_new@memcached.c:656` |
| 3/10 | 1/10 | `data race | write:conn_new@memcached.c:749 | write:conn_set_state@memcached.c:1011 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c:750 | write:conn_new@memcached.c:750 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c:751 | write:reset_cmd_handler@memcached.c:1452 | heap:conn_new@memcached.c:656` |
| 3/10 | 1/10 | `data race | write:conn_new@memcached.c:753 | write:rbuf_release@memcached.c:417 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c:754 | write:conn_new@memcached.c:754 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c:757 | write:conn_new@memcached.c:757 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c:758 | write:conn_new@memcached.c:758 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c:761 | write:conn_new@memcached.c:761 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c:764 | write:conn_new@memcached.c:764 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c:766 | write:conn_new@memcached.c:766 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c:784 | write:conn_new@memcached.c:784 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c:785 | write:conn_new@memcached.c:785 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c:786 | write:conn_new@memcached.c:786 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c:808 | write:conn_new@memcached.c:808 | heap:conn_new@memcached.c:656` |
| 0/10 | 1/10 | `data race | write:conn_new@memcached.c:820 | write:conn_new@memcached.c:820 | heap:conn_new@memcached.c:656` |

