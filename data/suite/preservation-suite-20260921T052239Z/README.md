# The preservation suite on the shipped compiler, after the glibc-detection fix (2026-09-21)

The run `CLAIMS.md` section 1, first row, cites. Same command and image as `../preservation-suite-20260917T075005Z`
(compiler f3deebfbab60, 12 configurations, K = 5, 60 repeats, per-test timeout 120 s), made on this
host with the checkout's `tests/` mounted over the image's copy, so `tests/lit.common.cfg.py` carries
the fix: glibc is detected without `distutils`, `getline_nohang.cpp` is unsupported on the image's
glibc 2.39 as upstream marks it, and the two tests requiring glibc 2.30 run. 25 lit jobs on the 104
processors the Docker daemon granted (`manifest.txt`); the whole correctness set took 30 min 22 s.

    lit-logs/lit-<config>-<k>.log   lit -q output per configuration and repeat (failures only)
    failures.tsv                    every failure or timeout: EMPTY (0 rows)
    report.txt                      the harness's always-fail / ever-fail table: 0 and 0 everywhere
    ran.txt, configurations.txt     the twelve configurations, in the order run
    manifest.txt                    every result-changing knob, the effective processor set, the stamp

Re-derive:

    discovered: 383    grep -m1 'Total Discovered' lit-logs/lit-stock-1.log
    failures:     0    wc -l < failures.tsv
    timeouts:     0    grep -l 'Timed Out' lit-logs/*.log | wc -l
    unsupported: 90    ../unsupported/lit-show-unsupported-after-fix.log (lit -q prints no such line)
    executed:   293    383 - 90; passed 292 and expectedly failed 1, from the same log

The same suite on a 64-processor AMD host the same day: 0 failures, 0 timeouts, 22 min 33 s.
Beside the 17 Sep run (91 unsupported, 292 executed, 48 of 60 repeats stalled on a test that should
not have been running) this is the record after the fix; `docs/nondeterministic-tests.md` explains
the difference, which is exactly the three glibc-gated tests.
