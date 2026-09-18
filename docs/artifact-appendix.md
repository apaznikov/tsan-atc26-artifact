# Artifact Appendix

Draft for the two-page appendix submitted with the paper. Numbers here are the ones in `CLAIMS.md`
and nowhere else; when a leg completes, both change together.

## Abstract

The artifact contains the modified LLVM/ThreadSanitizer compiler the paper describes, as a patch
series over a pinned upstream commit; the test suites and audit ledger for its five static analyses;
the benchmark harness for five applications; every run we recorded, with the conditions each was
taken under; and one script per experiment. A container builds the compiler from the patch series and
asserts that the reconstructed source tree hashes to ours, so the compiler an evaluator gets is the
compiler we measured, checked rather than asserted.

## Scope

Supported by the artifact:

- **Race detection is preserved.** No configuration loses a race that unmodified ThreadSanitizer
  reports, over ThreadSanitizer's own regression suite in 12 configurations and over the
  applications' own races.
- **The analyses are sound on 23 code shapes** in which an optimized build could have failed to
  report a race; each has a test that fails on the commit before its fix, and a control proving the
  test can tell a removal from an absence.
- **Static instrumentation removed**, per application and configuration, exactly reproducible.
- **Compile-time cost**, including the case the paper's largest application turns on.
- **Runtime performance**, as a table with confidence intervals, reproducible in direction on
  comparable hardware.

Not supported, and stated in `CLAIMS.md` as not claimed: Chromium (a checkout exceeds a terabyte and
our only build predates the shipped compiler), and any number from before the campaign of
15-17 September 2026.

## Contents, hosting and requirements

`https://github.com/apaznikov/tsan-atc26-artifact`, and archived with a DOI for the final version.
About 100 MB: the compiler is 29 patch files, and the recorded runs are text.

Any x86-64 Linux host with Docker, 8 processors and 20 GB of disk runs everything deterministic. The
container build fetches upstream LLVM with a shallow clone and compiles it: measured with `--no-cache`,
14m52s at the derived default of 25 jobs on our host and 24m38s at 8 jobs (mostly a fixed serial head:
clone, patches, configure and the runtime stage do not scale with jobs). The performance experiments need at least 32 processors and a machine doing
nothing else; ours was an Intel Xeon w9-3495X, 56 cores and 112 threads, 250 GB, Ubuntu 24.04, with
benchmarks pinned to 48 processors.

## Set-up and basic test

```
git clone https://github.com/apaznikov/tsan-atc26-artifact.git && cd tsan-atc26-artifact
./scripts/00-prereqs.sh
./docker/build.sh
./docker/run.sh scripts/10-minimal-example.sh
```

The basic test compiles one small program per analysis, prints how many instrumentation calls each
analysis removed and why those accesses cannot race, then compiles and runs a program with a real
race and shows that both the stock and the fully optimized build still report it. About twenty minutes,
including the container build at 25 jobs.

## Evaluation workflow

One command runs every deterministic check and prints a verdict per step, stopping at the first
failure and reporting a step whose prerequisite is absent as a skip rather than a pass:

```
./docker/run.sh scripts/01-functional.sh
```

It covers: the basic test; the 23 shapes against 62 IR tests with their vacuity control; the shipped
compiler's equivalence to the one the measurements were taken on, over 112 corpus rows, with a
control showing the comparison can separate configurations; the provenance of every shipped run; the
regression suite in 12 configurations, preceded by a self-test that requires the harness to detect
deliberately lost races; and the regeneration of every table in the paper from the recorded runs.
About 1 h 45 min on 32 processors (measured on an evaluator's machine, 18 Sep 2026: 103 minutes,
most of it the regression suite in 12 configurations); longer on eight.

Performance is separate and needs the hardware above. At the defaults (four configurations, two
runs each, a point estimate per row) it is about two hours for Redis, memcached, FFmpeg and SQLite
together; everything at fourteen configurations is about 14 hours; our own five-run setting, which
produces the confidence intervals in `CLAIMS.md`, is a variable away and 2.5 times longer:

```
./docker/run.sh scripts/40-perf.sh <redis|memcached|sqlite|ffmpeg|mysql>
```

Each row is claimed only where both run ranges of its interval agree, and a row whose interval
contains 1.0 is reported as no measurable change rather than as an absence of effect. What makes the
numbers vary, and by how much, is in `docs/confounds.md`; it includes the conditions we could not
explain and did not hide.

## Notes

Three things an evaluator should know before reading a result as a failure. Docker's default seccomp
profile refuses the system call ThreadSanitizer uses to disable address-space randomization, so the
container must be started through `docker/run.sh`. Three tests of the regression suite are
non-deterministic under unmodified ThreadSanitizer as well, and are named in
`docs/nondeterministic-tests.md`. And the preservation suite must not be run on one processor: tests
that pass by reporting nothing can pass for want of an interleaving, and the suite livelocks on a
spin-wait test confined to a single core.
