# Artifact Appendix

The artifact's abstract, scope, requirements and evaluation workflow. Numbers here are the ones in
`CLAIMS.md` and nowhere else.

## Abstract

The artifact contains the modified LLVM/ThreadSanitizer compiler the paper describes, as a patch
series over a pinned upstream commit; the test suites for its five static analyses;
the benchmark harness for five applications; the runs every claim rests on, with the conditions each was
taken under; and one script per experiment. A container builds the compiler from the patch series,
asserts that the reconstructed source tree hashes to ours, and checks that the compiler emits the same
instrumentation as the measured compiler on 112 corpus rows (`scripts/12-compiler-equivalence.sh`).

## Scope

The artifact is submitted for the Available and Functional badges. Supported by the artifact:

- **Race detection is preserved.** No race is lost on ThreadSanitizer's regression suite in twelve
  configurations. On SQLite and memcached at N = 10, under stock, the sound bundle and AllOpt with peeling,
  no race is lost at the level of the racing location (L3); one memcached report moves to another reader of
  the same location (`CLAIMS.md` section 1).
- **The analyses are sound on 23 code shapes** in which an optimized build could have failed to
  report a race; each has a test that fails on the commit before its fix. The 62 IR tests also run with the
  analysis flags stripped, where each of the 50 that assert a removal must fail; 11 assert only that
  instrumentation stays, and one multi-step test is not re-run.
- **Static instrumentation**, per application and configuration, exactly reproducible, from a compiler that
  emits the measured compiler's instrumentation on 112 corpus rows.
- **Compile-time cost**: the script and the criterion (same order of magnitude as stock); the shipped control
  is memcached, whose build is too short to resolve the effect; MySQL's run is the evaluator's option
  (twelve builds of 5 to 8 minutes each at 56 jobs).
- **Bounded shadow state**: the occupied-granule experiment, which a script re-runs, and the two-race
  experiment, recorded (`CLAIMS.md` section 6).

The performance campaign's runs ship in `data/perf/` and are not submitted for evaluation.

Not supported, and stated in `CLAIMS.md` section 7: the submitted version's static-reduction figures, executed
instrumentation per unit of work, memory overhead, the ReX comparison and the access-trace oracle, Chromium,
and loop peeling in isolation. The report-key replay and the bounded-shadow results are claimed on the earlier
compilers they name (`CLAIMS.md` sections 1 and 6).

## Which version of the paper the artifact describes

The camera-ready.

## Contents, hosting and requirements

`https://github.com/apaznikov/tsan-atc26-artifact`, under the MIT licence (`LICENSE`; vendored third-party code
under its own licences, `THIRD-PARTY.md`), and archived on Zenodo with a DOI when evaluation finishes.
About 133 MB of tracked files: 96 MB of recorded runs in plain text and 32 MB of application source
archives; the compiler itself is 28 patch files.

Any x86-64 Linux host with Docker, 8 processors, 16 GB of memory and 20 GB of disk runs everything
deterministic. The container build fetches upstream LLVM with a shallow clone and compiles it: measured with
`--no-cache`, 14m52s at the derived default of 25 jobs on our host and 24m38s at 8 jobs (mostly a fixed
serial head: clone, patches, configure and the runtime stage do not scale with jobs). The optional performance
experiments run on any processor count, are comparable with the campaign's runs only with 48 processors
pinned, and need a machine doing nothing else; ours was an Intel Xeon w9-3495X, 56 cores and 112 threads, 250 GB, Ubuntu
24.04, with benchmarks pinned to 24 physical cores with both SMT threads of each (48 logical processors).

## Set-up and basic test

```
git clone https://github.com/apaznikov/tsan-atc26-artifact.git && cd tsan-atc26-artifact
./evaluate.sh check          # prerequisites, the image, the minimal example, the quick correctness set
```

The basic test compiles one small program per analysis, prints how many instrumentation calls each
analysis removed and why those accesses cannot race, then compiles and runs a program with a real
race and shows that both the stock and the fully optimized build still report it. About two minutes once
the image exists; about twenty minutes including the first container build at 25 jobs.

## Evaluation workflow

One command runs every deterministic check and prints a verdict per step, stopping at the first
failure and reporting a step whose prerequisite is absent as a skip rather than a pass:

```
./evaluate.sh functional     # the full correctness set; ./evaluate.sh reproduced runs it and then the performance subset
                             # (--performance-only skips the correctness set on a checkout where it already passed)
```

It covers: the basic test; the 23 shapes against 62 IR tests with their vacuity control; the shipped
compiler's equivalence to the one the measurements were taken on, over 112 corpus rows, with a
control showing the comparison can separate configurations; the provenance of every shipped run; the
regression suite in 12 configurations, preceded by a self-test that requires the harness to detect
deliberately lost races; and the regeneration of the performance tables from the recorded runs, each
compared with the shipped copy byte for byte. Measured: 23 minutes on a 64-processor
host, 30 minutes on ours and 48 minutes pinned to 8 processors with 16 GB, most of it the regression suite.

Performance is optional, not submitted for evaluation, and needs the hardware above. At the defaults (four configurations, five on FFmpeg, two
runs each, a point estimate per row) it is about 2 h 30 min for Redis, memcached, FFmpeg and SQLite
together, and the whole Reproduced tier about 3 hours (2 h 38 min on our host); everything at fourteen
configurations is about 11 hours of runs, 14 with the builds; our own five-run setting, which produces the
campaign's confidence intervals, is a variable away and twice as long:

```
./docker/run.sh scripts/40-perf.sh <redis|memcached|sqlite|ffmpeg|mysql>
```

Each row is claimed only where the runs-2-5 point lies inside the all-five interval, and a row whose interval
contains 1.0 is reported as no measurable change rather than as an absence of effect. What makes the
numbers vary, and by how much, is in `docs/confounds.md`.

## Notes

Three things an evaluator should know before reading a result as a failure. Docker's default seccomp
profile refuses the system call ThreadSanitizer uses to disable address-space randomization, so the
container must be started through `docker/run.sh`. Three tests of the regression suite are
non-deterministic under unmodified ThreadSanitizer as well, and are named in
`docs/nondeterministic-tests.md`. And the preservation suite must not be run on one processor: tests
that pass by reporting nothing can pass for want of an interleaving, and the suite livelocks on a
spin-wait test confined to a single core.
