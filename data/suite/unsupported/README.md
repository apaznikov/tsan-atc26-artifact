# Unsupported count for the vendored TSan suite

`lit -q` never prints an Unsupported line, so the preservation suite's own logs cannot
establish how many of the 383 discovered tests actually ran. This is that one run, kept so
the executed count is checkable.

    lit-show-unsupported.log   llvm-lit --show-unsupported -j48, image tsan-atc26,
                               compiler f3deebfbab60, 2026-09-19 04:26, 60 s

    Total Discovered Tests: 383
      Unsupported      :  91   Darwin 47, libdispatch 37, top level 5, Linux 1, libcxx 1
      Passed           : 291
      Expectedly Failed:   1
      Failed           :   0

    executed = 383 - 91 = 292

## Correcting an earlier figure

CLAIMS row 22 said 298 executed, from 383 - 85. **The 85 was wrong.** It came from a run
filtered to `Darwin/|libdispatch/|libcxx/`, which is 47+37+1 = 85, and was then used as if
it were the total. Six further tests are unsupported through lit feature gates and lie
outside those three directories:

    Linux/clockwait_double_lock.c   debug_alloc_stack.cpp   pthread_mutex_clocklock.cpp
    shadow_evictions.c              signal_recursive.cpp    sunrpc.cpp

The correct figures for that image and lit configuration are 91 unsupported and 292 executed. The failure
count is unaffected: zero, in all 60 repeats of the 2026-09-17 run.

## After the glibc-detection fix of 2026-09-21

The vendored lit configuration did not detect glibc under Python 3.12 (`docs/nondeterministic-tests.md`), so
the 91 included two tests that require glibc 2.30 and excluded one that upstream marks unsupported from
glibc 2.38 on. With the fix (`tests/lit.common.cfg.py`, a tuple comparison in place of `distutils`):

    lit-show-unsupported-after-fix.log   the same command, 2026-09-21, image with the checkout's tests/ mounted

    Total Discovered Tests: 383
      Unsupported      :  90   the 91 above, plus getline_nohang.cpp, minus
                               pthread_mutex_clocklock.cpp and Linux/clockwait_double_lock.c
      executed = 383 - 90 = 293

Exactly three tests in the suite are gated on glibc, so 91 + 1 - 2 = 90 was predicted before it was
measured, and the measurement agreed.
