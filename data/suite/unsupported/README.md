# Unsupported count for the vendored TSan suite

**383 discovered, 90 unsupported, 293 executed** (`lit-show-unsupported-after-fix.log`). That is what
`CLAIMS.md` states and what the suite runs.

`lit -q` never prints an Unsupported line, so the preservation suite's own logs cannot establish how many of
the 383 discovered tests ran; the two runs here establish it.

    lit-show-unsupported.log             llvm-lit --show-unsupported -j48, image tsan-atc26,
                                         compiler f3deebfbab60, before the glibc-detection fix

    Total Discovered Tests: 383
      Unsupported      :  91   Darwin 47, libdispatch 37, top level 5, Linux 1, libcxx 1
      Passed           : 291
      Expectedly Failed:   1
      Failed           :   0

    executed = 383 - 91 = 292

Besides the 85 tests under `Darwin/`, `libdispatch/` and `libcxx/`, six tests are unsupported through lit
feature gates:

    Linux/clockwait_double_lock.c   debug_alloc_stack.cpp   pthread_mutex_clocklock.cpp
    shadow_evictions.c              signal_recursive.cpp    sunrpc.cpp

## After the glibc-detection fix

The vendored lit configuration did not detect glibc under Python 3.12 (`docs/nondeterministic-tests.md`), so
the 91 included two tests that require glibc 2.30 and excluded one that upstream marks unsupported from
glibc 2.38 on. With the fix (`tests/lit.common.cfg.py`, a tuple comparison in place of `distutils`):

    lit-show-unsupported-after-fix.log   the same command, image with the checkout's tests/ mounted

    Total Discovered Tests: 383
      Unsupported      :  90   the 91 above, plus getline_nohang.cpp, minus
                               pthread_mutex_clocklock.cpp and Linux/clockwait_double_lock.c
      executed = 383 - 90 = 293

Exactly three tests in the suite are gated on glibc, so 91 + 1 - 2 = 90, as measured.
