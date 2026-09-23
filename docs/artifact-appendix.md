# Artifact Appendix

The artifact's abstract, scope, requirements and evaluation workflow. Numbers here are the ones in
`CLAIMS.md` and nowhere else.

## Abstract

The artifact contains the modified LLVM/ThreadSanitizer compiler the paper describes, as a patch
series over a pinned upstream commit; the test suites and audit ledger for its five static analyses;
the benchmark harness for five applications; the runs every claim rests on, with the conditions each was
taken under; and one script per experiment. A container builds the compiler from the patch series and
asserts that the reconstructed source tree hashes to ours, so the compiler an evaluator gets is the
compiler we measured.

## Scope

Supported by the artifact:

- **Race detection is preserved.** No configuration loses a race that unmodified ThreadSanitizer
  reports, over ThreadSanitizer's own regression suite in 12 configurations, and over the races of
  SQLite and memcached at N = 10 under stock, the sound bundle and AllOpt with peeling.
- **The analyses are sound on 23 code shapes** in which an optimized build could have failed to
  report a race; each has a test that fails on the commit before its fix, and a control proving the
  test can tell a removal from an absence.
- **Static instrumentation**, per application and configuration, exactly reproducible.
- **Compile-time cost**: the script and the criterion (same order of magnitude as stock); the shipped control
  is memcached, whose build is too short to resolve the effect; MySQL's run is the evaluator's option
  (twelve builds of 5 to 8 minutes each at 56 jobs).
- **Runtime performance**, as a table with confidence intervals. On the shipped compiler DynSTC has two
  directional effects on the campaign's host, FFmpeg above stock and Redis below. FFmpeg's gain also appeared
  on a second host of the same processor-set shape; Redis's cost did not (`CLAIMS.md` section 5). At 16
  threads, FFmpeg's default in the artifact, AllOpt with peeling is also above stock (1.067 [1.050, 1.079])
  and AllOpt with peeling and DynSTC reaches +19 % (1.187 [1.171, 1.201]); every other configuration's
  interval contains 1.0, no measurable change from stock ThreadSanitizer.

Not supported, and stated in `CLAIMS.md` as not claimed: Chromium (a checkout exceeds a terabyte and
our only build predates the shipped compiler), and any performance number from before the campaign of
15-17 September 2026 (the report-key replay and the bounded-shadow results are claimed on the earlier
compilers they name, `CLAIMS.md` sections 1 and 6).

## Which version of the paper the artifact reproduces

The camera-ready. Its performance section was re-measured with the compiler released here, which carries 23
soundness fixes made while preparing the artifact and still finds every race stock ThreadSanitizer finds
(`CLAIMS.md`, section 1); the campaign in section 5, N = 5 with 95 % intervals, is what the Reproduced tier
compares against. The submitted version's figures, measured before those fixes, stay in that file's "Paper"
column beside ours.

What the campaign establishes: DynSTC changes performance measurably, a gain of 11 % on FFmpeg at the paper's
four threads and a cost of 5.6 % on Redis. FFmpeg's gain holds at 2, 4, 8 and 16 encoder threads, every
interval excluding 1.0, and on the second host at 1.115. Redis's cost holds at four client counts on the
campaign's host, 50 through 512, every interval excluding 1.0, and does not reproduce on the second host,
where the same configuration reads 0.985, 1.035, 1.008 and 0.971 across those counts. At 16 threads, which
the thread sweep chose after the campaign and which the artifact uses by default, AllOpt with peeling and
DynSTC reaches 18.7 % on FFmpeg and AllOpt with peeling alone 6.7 %. Every other configuration's interval
contains 1.0. Statically, AllOpt without peeling removes 2 to 8 % of the instrumentation, and AllOpt with
peeling carries 5 to 14 % more than stock, because peeling duplicates loop bodies.

## Contents, hosting and requirements

`https://github.com/apaznikov/tsan-atc26-artifact`, under the MIT licence (`LICENSE`; vendored third-party code
under its own licences, `THIRD-PARTY.md`), and archived on Zenodo with a DOI when evaluation finishes.
About 133 MB of tracked files: 96 MB of recorded runs in plain text and 32 MB of application source
archives; the compiler itself is 28 patch files.

Any x86-64 Linux host with Docker, 8 processors, 16 GB of memory and 20 GB of disk runs everything
deterministic. The container build fetches upstream LLVM with a shallow clone and compiles it: measured with
`--no-cache`, 14m52s at the derived default of 25 jobs on our host and 24m38s at 8 jobs (mostly a fixed
serial head: clone, patches, configure and the runtime stage do not scale with jobs). The performance
experiments run on any processor count, are compared with our intervals only with 48 processors pinned, and
need a machine doing nothing else; ours was an Intel Xeon w9-3495X, 56 cores and 112 threads, 250 GB, Ubuntu
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
deliberately lost races; and the regeneration of the performance tables and the results ledger from the
recorded runs, each compared with the shipped copy byte for byte. Measured: 23 minutes on a 64-processor
host, 30 minutes on ours and 48 minutes pinned to 8 processors with 16 GB, most of it the regression suite.

Performance is separate and needs the hardware above. At the defaults (four configurations, five on FFmpeg, two
runs each, a point estimate per row) it is about 2 h 30 min for Redis, memcached, FFmpeg and SQLite
together, and the whole Reproduced tier about 3 hours (2 h 38 min on our host); everything at fourteen
configurations is about 11 hours of runs, 14 with the builds; our own five-run setting, which produces the
confidence intervals in `CLAIMS.md`, is a variable away and twice as long:

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
