# P5 summary — perf-mysql-20260922-034705

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; where there is no restricted column the cell says why in brackets, because the two reasons are opposite: all subtests being within the bound is the best case for a row, and too few being within it to restrict is the worst, and one unannotated mark for both invites reading the worst as the best. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| mysql | orig | orig | 5 | 9.898 [9.314, 10.430] | 9.813 [9.345, 10.215] | — | 0 | pinned |
| mysql | tsan | tsan | 5 | — | — | 9.90 [9.31, 10.43] | 602434 | pinned |
| mysql | tsan-dom_peeling-ea-lo-st-swmr-nofe | tsan-dom_peeling-ea-lo-st-swmr-nofe | 5 | 1.090 [1.057, 1.157] | 1.138 [1.092, 1.173] | 9.08 [8.41, 9.47] | 636981 | pinned |
| mysql | tsan-nofe | tsan-nofe | 5 | 1.094 [1.068, 1.154] | 1.124 [1.095, 1.170] | 9.04 [8.44, 9.37] | 600722 | pinned |
