# Preservation suite, shipped compiler, 2026-09-17

The run on the shipped compiler before the lit glibc-detection fix, mentioned in `CLAIMS.md` section 1,
first row. Exported so its numbers can be checked rather than taken.

    compiler   tsan-line-f3deebfbab60 (stamp f3deebfbab602f4e05289e0acbde0efd06b8058c)
    started    2026-09-17 15:50:05 +08   finished 17:32:26 +08
    directory  named 20260917-075005 because the container clock is UTC; 07:50Z = 15:50+08
    K          5 repeats x 12 configurations = 60
    jobs       ART_JOBS=64
    cpuset     0-3,28-59,84-111 (64 processors, off the benchmark set 4-27,60-83)
    lit        per-test timeout 600 s (this run predates the 120 s default)

## What is here

    report.txt          the verdict as the script printed it
    failures.tsv        every harvested row: configuration, repeat, KIND, test
    lit-logs/           all 60 lit logs, one per (configuration, repeat)
    configurations.txt  the 12 configurations and their flags
    ran.txt             the configurations that actually ran

## Checking the cited numbers

    failures: 0        awk -F'\t' '$3=="fail"' failures.tsv | wc -l
    timeouts: 48/60    awk -F'\t' '$3=="timeout"' failures.tsv | wc -l
    per configuration  awk -F'\t' '{print $1}' failures.tsv | sort | uniq -c
                       stock 5, EA 5, SWMR 5, STC 4, DE+peel 4, sound 4,
                       AllOpt+peel 4, AllOpt+peel+DynSTC 4, AllOpt-peel+DynSTC 4,
                       LO 3, DE 3, AllOpt-peel 3
    discovered: 383    grep -m1 'Total Discovered' lit-logs/lit-stock-1.log

Every one of the 48 is getline_nohang.cpp and every one is kind=timeout, so none reaches
the lost-race rule, which requires kind=fail. That test should not have been running at all:
upstream marks it unsupported from glibc 2.38 on, and it ran because the lit configuration
of that date did not detect glibc (the run after the fix ships beside this one). See
docs/nondeterministic-tests.md.

The executed count (292 = 383 - 91 unsupported) is NOT derivable from these logs: lit -q
does not print an Unsupported line. It is established separately in ../unsupported/.
