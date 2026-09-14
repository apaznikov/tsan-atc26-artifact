# Preservation summary: ffmpeg

Report kinds considered: data race

## Per-configuration counts (mean ± sample σ over runs)

| config | runs | reports/run | distinct L1/run | distinct L2/run | union L1 | union L2 | kinds |
|---|---|---|---|---|---|---|---|
| tsan | 10 | 0.0 ± 0.0 | 0.0 ± 0.0 | 0.0 ± 0.0 | 0 | 0 |  |
| tsan-dom_peeling-ea-lo-st-swmr | 10 | 0.0 ± 0.0 | 0.0 ± 0.0 | 0.0 ± 0.0 | 0 | 0 |  |

## tsan-dom_peeling-ea-lo-st-swmr vs tsan

- L1 (function@file:line): lost 0 of 0 baseline races, new 0; of the lost, 0 are still found at L2 (relocated).
- L2 (function only): lost 0 of 0, new 0.

## All races (L1) with per-configuration detection frequency

| tsan | tsan-dom_peeling-ea-lo-st-swmr | race |
|---|---|---|

