# The minimal example, and how to extend it

`scripts/10-minimal-example.sh` compiles each file here twice, once with stock ThreadSanitizer and once with
the analysis its comment names, counts the calls to `__tsan_read*`/`__tsan_write*` in each binary, and prints
what the analysis removed. It then builds `race.c` under stock and under all analyses and shows that the race
is reported either way. The comment at the top of each file says why the accesses it removes cannot race.

To add a case of your own: put the program in this directory, add one line to the `CASES` array at the top of
`scripts/10-minimal-example.sh` in the form `NAME  file.c  §section  -mllvm -tsan-use-<analysis>`, then run
the script. A case is only evidence if the removal it shows cannot happen without the
analysis: keep the flags minimal, and check that the stock build instruments the access you expect by reading
the two counts the script prints rather than the difference alone. `tests/ir/` holds the same idea at the IR
level: each fixed shape has a negative test
that must keep the instrumentation and fails on the commit before the fix, and a positive control that must
still remove it. `scripts/11-soundness-shapes.sh` runs them with a check that refuses a removal test that would
pass with the analysis switched off.
