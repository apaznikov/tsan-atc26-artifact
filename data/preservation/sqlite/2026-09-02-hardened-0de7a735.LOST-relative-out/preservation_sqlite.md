== sqlite ==
  tsan                             runs=10 reports/run=     0.0 ± 0.0 distinctL1/run=   0.0 ± 0.0 unionL1=  0 unionL2=  0
  tsan-dom_peeling-ea-lo-st-swmr   runs=10 reports/run=     0.0 ± 0.0 distinctL1/run=   0.0 ± 0.0 unionL1=  0 unionL2=  0
  tsan-sound                       runs=10 reports/run=     0.0 ± 0.0 distinctL1/run=   0.0 ± 0.0 unionL1=  0 unionL2=  0
  tsan-dom_peeling-ea-lo-st-swmr vs tsan: lost L1=0 (relocated=0) new L1=0 | lost L2=0 new L2=0
  tsan-sound vs tsan: lost L1=0 (relocated=0) new L1=0 | lost L2=0 new L2=0
  -> results/sqlite/2026-09-02-hardened-0de7a735/preservation_sqlite.md
 0 of 0, new 0.

## tsan-sound vs tsan

- L1 (function@file:line): lost 0 of 0 baseline races, new 0; of the lost, 0 are still found at L2 (relocated).
- L2 (function only): lost 0 of 0, new 0.

## All races (L1) with per-configuration detection frequency

| tsan | tsan-dom_peeling-ea-lo-st-swmr | tsan-sound | race |
|---|---|---|---|

