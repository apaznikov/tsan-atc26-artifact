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

The correct figures are 91 unsupported and 292 executed. The failure count is unaffected:
zero, in all 60 repeats of the 2026-09-17 run.
