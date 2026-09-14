# P4 eviction stress -- 2026-09-02T09:14:45+08:00

    compiler: /extra/alexey/llvm-project-paper/llvm/build/bin/clang (clang version 19.0.0git (/home/alexey/dev/llvm-project-focs-lab e90a3fc410043575326f83373d018d39f505b8de))
    tsan-st                            flags: -mllvm -tsan-use-single-threaded
                                       tsan calls: burst_local=2 burst_shared=2 stores-to-g=3
    tsan-sound                         flags: -mllvm -tsan-use-escape-analysis-global -mllvm -tsan-use-lock-ownership -mllvm -tsan-use-single-threaded -mllvm -tsan-use-swmr
                                       tsan calls: burst_local=0 burst_shared=1 stores-to-g=3
    tsan-dom_peeling-ea-lo-st-swmr     flags: -mllvm -tsan-use-dominance-analysis -mllvm -tsan-use-loop-peeling=true -mllvm -tsan-use-escape-analysis-global -mllvm -tsan-use-lock-ownership -mllvm -tsan-use-single-threaded -mllvm -tsan-use-swmr
                                       tsan calls: burst_local=0 burst_shared=2 stores-to-g=3
    tsan-ea                            flags: -mllvm -tsan-use-escape-analysis-global
                                       tsan calls: burst_local=0 burst_shared=2 stores-to-g=3
    tsan                               flags: <none>
                                       tsan calls: burst_local=2 burst_shared=2 stores-to-g=3

Runtime: ThreadSanitizer: data race (pid=2204709) TSAN_OPTIONS="exitcode=0 report_bugs=1"

## Deterministic sweep: burst length 0..15, 3 runs per value

Each character is one burst length (0..15): 1 = race reported in all 3 runs, 0 = in none, ? = mixed.

| config | local (N writes to a private heap buffer) | shared (M writes to an escaping buffer) |
|---|---|---|
| tsan | `1110111011101110` | `1011101110111011` |
| tsan-dom_peeling-ea-lo-st-swmr | `1111111111111111` | `1101110111011101` |
| tsan-ea | `1111111111111111` | `1011101110111011` |
| tsan-sound | `1111111111111111` | `1101110111011101` |
| tsan-st | `1110111011101110` | `1011101110111011` |

## Randomised burst lengths: 1000 runs per cell, N and M uniform in [0, 1023] (seed 20260902, same sequence for every build)

Detection rate of the planted race (95% Wilson interval).  A traced burst makes F4's trace position
depend on the burst length, so the victim cell is uniform over the 4 cells and A's record survives
with probability 3/4; an elided burst makes the position a per-binary constant and the outcome fixed.

| config | local: N private writes | shared: M escaping writes | mixed: N private + M escaping |
|---|---|---|---|
| tsan | 754/1000 = 75.4% [72.6, 78.0] | 742/1000 = 74.2% [71.4, 76.8] | 747/1000 = 74.7% [71.9, 77.3] |
| tsan-dom_peeling-ea-lo-st-swmr | 1000/1000 = 100.0% [99.6, 100.0] | 739/1000 = 73.9% [71.1, 76.5] | 765/1000 = 76.5% [73.8, 79.0] |
| tsan-ea | 1000/1000 = 100.0% [99.6, 100.0] | 742/1000 = 74.2% [71.4, 76.8] | 736/1000 = 73.6% [70.8, 76.2] |
| tsan-sound | 1000/1000 = 100.0% [99.6, 100.0] | 739/1000 = 73.9% [71.1, 76.5] | 765/1000 = 76.5% [73.8, 79.0] |
| tsan-st | 754/1000 = 75.4% [72.6, 78.0] | 742/1000 = 74.2% [71.4, 76.8] | 747/1000 = 74.7% [71.9, 77.3] |

## Fixed escaping prefix M, random private burst N (200 runs per cell, first 200 pairs of the sequence)

| config | M=0 | M=1 | M=2 | M=3 |
|---|---|---|---|---|
| tsan | 157/200 | 149/200 | 152/200 | 143/200 |
| tsan-dom_peeling-ea-lo-st-swmr | 200/200 | 200/200 | 200/200 | 0/200 |
| tsan-ea | 200/200 | 200/200 | 0/200 | 200/200 |
| tsan-sound | 200/200 | 200/200 | 200/200 | 0/200 |
| tsan-st | 157/200 | 149/200 | 152/200 | 143/200 |

Per-run outcomes: random.<config>.<mode>.txt, prefix.<config>.m<M>.txt (columns: config, N[, mode[, M]], detected).
