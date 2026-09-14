# Symmetric DE eviction stress -- 2026-09-03T15:22:40+08:00

    compiler: /extra/alexey/builds/tsan-audit-f80e80b1dbe6/bin/clang (clang version 19.0.0git (https://github.com/focs-lab/llvm-project f80e80b1dbe61ad722ccf3b77fbb8de3e63b4de5))
    tsan                               flags: <none>
                                       tsan calls: a_body stores=3 burst_shared=1
    tsan-sound                         flags: -mllvm -tsan-use-escape-analysis-global -mllvm -tsan-use-lock-ownership -mllvm -tsan-use-single-threaded -mllvm -tsan-use-swmr
                                       tsan calls: a_body stores=3 burst_shared=1
    tsan-dom                           flags: -mllvm -tsan-use-dominance-analysis
                                       tsan calls: a_body stores=2 burst_shared=1
    tsan-dom_peeling-ea-lo-st-swmr     flags: -mllvm -tsan-use-dominance-analysis -mllvm -tsan-use-loop-peeling=true -mllvm -tsan-use-escape-analysis-global -mllvm -tsan-use-lock-ownership -mllvm -tsan-use-single-threaded -mllvm -tsan-use-swmr
                                       tsan calls: a_body stores=2 burst_shared=1

Cells: A/C present after F4's store . after A's second store . after B's y store | races A-B C-B

## Sweep M = 0..15 (A's burst 0, B's burst 0)

| config | M=0 .. 15 |
|---|---|
| tsan | 11.11.00\|01 11.11.00\|01 01.11.00\|01 10.10.10\|10 11.11.00\|01 11.11.00\|01 01.11.00\|01 10.10.10\|10 11.11.00\|01 11.11.00\|01 01.11.00\|01 10.10.10\|10 11.11.00\|01 11.11.00\|01 01.11.00\|01 10.10.10\|10 |
| tsan-sound | 11.11.00\|01 11.11.00\|01 01.11.00\|01 10.10.10\|10 11.11.00\|01 11.11.00\|01 01.11.00\|01 10.10.10\|10 11.11.00\|01 11.11.00\|01 01.11.00\|01 10.10.10\|10 11.11.00\|01 11.11.00\|01 01.11.00\|01 10.10.10\|10 |
| tsan-dom | 11.11.00\|01 11.11.00\|01 01.01.00\|01 10.10.10\|10 11.11.00\|01 11.11.00\|01 01.01.00\|01 10.10.10\|10 11.11.00\|01 11.11.00\|01 01.01.00\|01 10.10.10\|10 11.11.00\|01 11.11.00\|01 01.01.00\|01 10.10.10\|10 |
| tsan-dom_peeling-ea-lo-st-swmr | 11.11.00\|01 11.11.00\|01 01.01.00\|01 10.10.10\|10 11.11.00\|01 11.11.00\|01 01.01.00\|01 10.10.10\|10 11.11.00\|01 11.11.00\|01 01.01.00\|01 10.10.10\|10 11.11.00\|01 11.11.00\|01 01.01.00\|01 10.10.10\|10 |

## Sweep of A's burst MA = 0..15 at M = 2 (A's record evicted by F4), B's burst 1

| config | MA=0 .. 15 |
|---|---|
| tsan | 01.11.00\|01 01.11.00\|01 01.10.10\|10 01.11.00\|01 01.11.00\|01 01.11.00\|01 01.10.10\|10 01.11.00\|01 01.11.00\|01 01.11.00\|01 01.10.10\|10 01.11.00\|01 01.11.00\|01 01.11.00\|01 01.10.10\|10 01.11.00\|01 |
| tsan-sound | 01.11.00\|01 01.11.00\|01 01.11.00\|01 01.10.10\|10 01.11.00\|01 01.11.00\|01 01.11.00\|01 01.10.10\|10 01.11.00\|01 01.11.00\|01 01.11.00\|01 01.10.10\|10 01.11.00\|01 01.11.00\|01 01.11.00\|01 01.10.10\|10 |
| tsan-dom | 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 |
| tsan-dom_peeling-ea-lo-st-swmr | 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 01.01.00\|01 |

## Random (M, MA, MB) in [0, 1023]^3, 1000 runs per build (same sequence for all builds)

| config | races/run (mean) | A–B reported | C–B reported | (i) A's record evicted by F4 | A–B given (i) | C–B given (i) | (ii) C's record evicted by A's 2nd store | C–B given (ii) | C evicted by F4 | C–B given that |
|---|---|---|---|---|---|---|---|---|---|---|
| tsan | 910/1000 = 0.91 | 228/1000 = 22.8 % [20.3, 25.5] | 682/1000 = 68.2 % [65.2, 71.0] | 236/1000 | 54/236 = 22.9 % | 165/236 = 69.9 % | 71/1000 | 0/71 = 0.0 % | 247/1000 | 0/247 = 0.0 % |
| tsan-sound | 922/1000 = 0.92 | 226/1000 = 22.6 % [20.1, 25.3] | 696/1000 = 69.6 % [66.7, 72.4] | 236/1000 | 41/236 = 17.4 % | 179/236 = 75.8 % | 57/1000 | 0/57 = 0.0 % | 247/1000 | 0/247 = 0.0 % |
| tsan-dom | 927/1000 = 0.93 | 174/1000 = 17.4 % [15.2, 19.9] | 753/1000 = 75.3 % [72.5, 77.9] | 236/1000 | 0/236 = 0.0 % | 236/236 = 100.0 % | 0/1000 | n/a | 247/1000 | 0/247 = 0.0 % |
| tsan-dom_peeling-ea-lo-st-swmr | 938/1000 = 0.94 | 185/1000 = 18.5 % [16.2, 21.0] | 753/1000 = 75.3 % [72.5, 77.9] | 236/1000 | 0/236 = 0.0 % | 236/236 = 100.0 % | 0/1000 | n/a | 247/1000 | 0/247 = 0.0 % |
