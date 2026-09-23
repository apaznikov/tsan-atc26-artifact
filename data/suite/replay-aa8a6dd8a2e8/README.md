# K = 5 report-key replay, compiler aa8a6dd8a2e8, 15 Sep 2026

The run `CLAIMS.md` section 1, third row (report keys), cites. `replay-output.txt` is the harness's own output, unedited.

    compiler        aa8a6dd8a2e8  -- the PREDECESSOR of the shipped f3deebfbab60, not the
                    shipped compiler itself. See "What this does and does not cover".
    tests           293 executable tests, replayed 5 times under each configuration
    configurations  12 (stock plus 11 compared against it)
    keys            harness/tools/preservation/tsan_reports.py
                    L1 = kind + both stacks' frames (function@file:line) + location
                    L2 = functions only
    date            15 Sep 2026

## Result

No L1 or L2 key differs on any test under any configuration: every per-configuration line
in the output reads `L2=0`, on both the racy and the no-report sides.

Four tests land in the `other` bucket. Their buckets, read from the output:

    ('racy',     'other:lost')  pthread_atfork_deadlock2.c   STC only.  THE ONLY LOST ENTRY.
    ('racy',     'other:new')   fd_location_closed.cpp       STC, AllOpt+peel
    ('racy',     'other:new')   race_on_barrier2.c           STC, DE
    ('noreport', 'other:new')   fork_atexit.cpp              9 of the 11 configurations

## What this does and does not cover

It was run on **aa8a6dd8a2e8**, not on the shipped **f3deebfbab60**. The two differ by
exactly three EA compile-time commits, and the evidence that those change no instrumentation
is: zero of 112 IR-corpus rows differ, all 17 shared application configurations have
identical site counts, and Redis's whole-program summaries are byte-identical between the
two compilers -- the same verdict for every function, not merely the same count. Identical
instrumentation implies identical reports, so the result carries; but it is carried by that
argument, not measured on the shipped compiler. No K = 5 replay against f3deebfbab60 exists.

## Scope of the lost entry

One test lost a report, under one configuration, and that test is a thread-leak diagnostic rather than
a data race.
