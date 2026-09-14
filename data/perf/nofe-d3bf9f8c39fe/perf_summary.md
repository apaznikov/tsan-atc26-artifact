# P5 summary — nofe-d3bf9f8c39fe

SU = speedup vs stock TSan, SD = slowdown vs native; geometric mean over the app's tests on per-test medians of N undisturbed runs; [95 % bootstrap interval]. **SU stable** is the same speedup over the subtests whose stock-TSan baseline CV is at most 5 %, the set chosen once from the baseline and applied to every configuration alike; it is empty where every subtest is inside that bound. Read SU as the headline and SU stable as what the data can resolve; the per-app file names the excluded subtests and their baseline CV.

| app | config | label | N | SU | SU stable | SD | static sites | modes |
|---|---|---|---|---|---|---|---|---|
| ffmpeg | tsan-sound | tsan-sound | 5 | — | — | — | — | pinned |
| ffmpeg | tsan-sound-nofe | tsan-sound-nofe | 5 | — | — | — | — | pinned |
| memcached | tsan-sound | tsan-sound | 5 | — | — | — | — | pinned |
| memcached | tsan-sound-nofe | tsan-sound-nofe | 5 | — | — | — | — | pinned |
| mysql | tsan-sound | tsan-sound | 5 | — | — | — | — | pinned |
| mysql | tsan-sound-nofe | tsan-sound-nofe | 5 | — | — | — | — | pinned |
| redis | tsan-sound | tsan-sound | 5 | — | — | — | — | pinned |
| redis | tsan-sound-nofe | tsan-sound-nofe | 5 | — | — | — | — | pinned |
| sqlite | tsan-sound | tsan-sound | 5 | — | — | — | — | pinned |
| sqlite | tsan-sound-nofe | tsan-sound-nofe | 5 | — | — | — | — | pinned |
