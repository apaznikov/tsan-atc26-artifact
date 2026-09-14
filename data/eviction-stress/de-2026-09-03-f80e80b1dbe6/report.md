# DE eviction stress -- 2026-09-03T15:05:54+08:00

    compiler: /extra/alexey/builds/tsan-audit-f80e80b1dbe6/bin/clang (clang version 19.0.0git (https://github.com/focs-lab/llvm-project f80e80b1dbe61ad722ccf3b77fbb8de3e63b4de5))
    tsan                               flags: <none>
                                       tsan calls: a_body stores=2 burst_shared=1
    tsan-sound                         flags: -mllvm -tsan-use-escape-analysis-global -mllvm -tsan-use-lock-ownership -mllvm -tsan-use-single-threaded -mllvm -tsan-use-swmr
                                       tsan calls: a_body stores=2 burst_shared=1
    tsan-dom                           flags: -mllvm -tsan-use-dominance-analysis
                                       tsan calls: a_body stores=1 burst_shared=1
    tsan-dom_peeling-ea-lo-st-swmr     flags: -mllvm -tsan-use-dominance-analysis -mllvm -tsan-use-loop-peeling=true -mllvm -tsan-use-escape-analysis-global -mllvm -tsan-use-lock-ownership -mllvm -tsan-use-single-threaded -mllvm -tsan-use-swmr
                                       tsan calls: a_body stores=1 burst_shared=1

Columns: config, M (escaping burst length of the evicting thread), a_evicted (A's first record gone after the evicting store), race (reported).

## Sweep M = 0..15 (a_evicted / race per M)

| config | M=0 .. 15: a_evicted/race |
|---|---|
| tsan | 0/1 0/1 1/1 0/1 0/1 0/1 1/1 0/1 0/1 0/1 1/1 0/1 0/1 0/1 1/1 0/1 |
| tsan-sound | 0/1 0/1 1/1 0/1 0/1 0/1 1/1 0/1 0/1 0/1 1/1 0/1 0/1 0/1 1/1 0/1 |
| tsan-dom | 0/1 0/1 1/0 0/1 0/1 0/1 1/0 0/1 0/1 0/1 1/0 0/1 0/1 0/1 1/0 0/1 |
| tsan-dom_peeling-ea-lo-st-swmr | 0/1 0/1 1/0 0/1 0/1 0/1 1/0 0/1 0/1 0/1 1/0 0/1 0/1 0/1 1/0 0/1 |

## Random M in [0, 1023], 1000 runs per build (seed shared by all builds)

| config | detected (all runs) | A's record evicted between the stores | detected \| evicted | detected \| not evicted |
|---|---|---|---|---|
| tsan | 1000/1000 = 100.0 % [99.6, 100.0] | 252/1000 | 252/252 = 100.0 % | 748/748 = 100.0 % |
| tsan-sound | 1000/1000 = 100.0 % [99.6, 100.0] | 252/1000 | 252/252 = 100.0 % | 748/748 = 100.0 % |
| tsan-dom | 748/1000 = 74.8 % [72.0, 77.4] | 252/1000 | 0/252 = 0.0 % | 748/748 = 100.0 % |
| tsan-dom_peeling-ea-lo-st-swmr | 748/1000 = 74.8 % [72.0, 77.4] | 252/1000 | 0/252 = 0.0 % | 748/748 = 100.0 % |
