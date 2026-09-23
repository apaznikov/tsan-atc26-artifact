# What an N = 2 run would have read, from an N = 5 leg

The intervals in `PERFORMANCE.md` are N = 5; an evaluator's default is N = 2. When an N = 2 point falls outside an
interval the question is whether that is a disagreement or the spread of a two-run estimate — and it is
answerable from a leg already on disk, without measuring anything.

`harness/tools/perf/subset_spread.py` recomputes the headline statistic over every subset of a completed
leg's runs, using `aggregate.py`'s own geomean and ratio, so the numbers are the estimator the tables
print rather than an approximation.

## SQLite, AllOpt with peeling — the spread explains the OUT readings

    subset_spread.py data/perf/n2-spread-sqlite-n5-20260918 sqlite \
        tsan-dom_peeling-ea-lo-st-swmr --interval 0.942 1.061

    all 5 runs:       1.0408
    10 subsets of 2:  0.9767 0.9913 0.9968 1.0102 1.0172 1.0384 1.0563 1.0651 1.0880 1.1044
    min 0.9767   median 1.0278   max 1.1044
    outside [0.942, 1.061]: 3 of 10  (1.0651, 1.0880, 1.1044)

Three of ten two-run subsets of one clean leg exceed the shipped upper bound, while the five-run answer
sits inside it. So this row reads OUT for roughly a third of evaluators at N = 2 for reasons that have
nothing to do with their machine. (This leg is the source of the N = 5 SQLite row and is shipped here for
that purpose; it is not part of the campaign and no claim rests on it.)

## Redis, DynSTC — the spread does NOT explain it

    subset_spread.py data/perf/campaign-f3deebfbab60/primary redis tsan-stmt --interval 0.927 0.970

    all 5 runs:       0.9443
    10 subsets of 2:  0.9258 0.9319 0.9334 0.9359 0.9521 0.9536 0.9565 0.9602 0.9629 0.9646
    min 0.9258   median 0.9529   max 0.9646
    outside [0.927, 0.970]: 1 of 10  (0.9258)

Three N = 2 runs on the campaign's own host read 0.961, 0.968 and 0.984 — at or above the maximum the
campaign's own two-run subsets produce. The N = 2 spread has been measured and does not reach 0.984, so it
is not the cause; the between-session Redis effect documented in `docs/confounds.md` (byte-identical
binaries differing by 14 % in throughput six days apart) is large enough to move a 5.6 % ratio to 2-4 %.

## What this is not

The subsets share runs and come from one session, so this measures **within-session** variability only.
Between-session drift is additional and invisible here. Do not read the spread as a confidence interval,
and do not read "k of n subsets outside" as a probability: the subsets are not independent.
