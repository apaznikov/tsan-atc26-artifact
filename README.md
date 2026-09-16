# Artifact: Instrumentation Optimization for Practical Dynamic Race Detection

*Русская версия: [README.ru.md](README.ru.md).*

This artifact accompanies the USENIX ATC '26 paper *Instrumentation Optimization for Practical
Dynamic Race Detection*. It contains the modified LLVM/ThreadSanitizer compiler the paper
describes, the analyses' test suites and audit ledger, the benchmark harness, the data we
recorded, and one script per experiment.

Start with `CLAIMS.md`. It lists every claim the paper makes, the script that produces it, and
what counts as a match. Nothing outside that file is claimed here.

> Status: this artifact is being prepared for submission on 22 September 2026. The performance rows
> of `CLAIMS.md` are filled per application as the measurement campaign completes; an application
> not listed there is not yet claimed. The deterministic part is complete.

## What is in here

| Path | What it is | Where it appears in the paper |
|---|---|---|
| `compiler/` | The compiler as a patch series over a pinned upstream LLVM commit, plus `TSanAnalysesAudit.md`, the per-function ledger of contracts, verdicts and covering tests | Sections 4 to 7 |
| `docker/` | The container recipe that builds and installs that compiler | Section 8.1 |
| `scripts/` | One script per experiment, numbered in the order a reader would run them | Section 8 |
| `data/` | Every run we recorded: per-run metadata with compiler stamp, binary hash, processor set, governor and load, plus the aggregates | Section 8 |
| `docs/` | The method document, the known confounds, and the two experiments that are documented rather than runnable here | Section 8, appendices |

Third-party code is unmodified except where noted in `THIRD-PARTY.md`, which also records the
licence of every vendored component.

## The environment we used

Intel Xeon w9-3495X, 56 cores and 112 threads, 250 GB RAM, Ubuntu 24.04, kernel 6.8.0-40-generic.
Performance runs are pinned to 48 processors, one measurement at a time. Nothing here needs that
machine: the container runs anywhere, and the deterministic experiments give identical results on
any x86-64 Linux host. The performance experiments need at least 32 cores to be meaningful, and
`docs/confounds.md` says what varies and why.

## Getting started: ten minutes

```
./scripts/00-prereqs.sh          # says what is missing, changes nothing
./docker/build.sh                # builds the image, including the compiler
./docker/run.sh scripts/10-minimal-example.sh
```

Start the container through `docker/run.sh`, or pass `--security-opt seccomp=unconfined` to your
own `docker run`: the ThreadSanitizer runtime re-executes programs with address-space randomization
off, and Docker's default seccomp profile refuses that call, so without the flag every instrumented
program dies with a segmentation fault (`docs/troubleshooting.md`).

The minimal example compiles one small program per analysis, shows which instrumentation each
analysis removes and why, then compiles and runs a program with a real race to show the race is
still reported. It needs no special hardware and finishes in about ten minutes, most of which is
the container build if you have not run it before.

## The correctness set: one command, no performance

For the Functional badge, and for anyone who wants to know the artifact does what it says without
spending a day on measurements:

```
./docker/run.sh scripts/01-functional.sh            # about 40 minutes on 8 processors
./docker/run.sh scripts/01-functional.sh --quick    # about 5 minutes, without the regression suite
```

It runs the deterministic checks in order and prints one verdict per step: the minimal example, the
23 lost-race shapes with their vacuity control, the compiler's equivalence to the one we measured on,
the provenance of the shipped runs, the ThreadSanitizer regression suite in 12 configurations
preceded by its self-test, and the regeneration of every table from the shipped data. It stops at the
first failure, because each later step assumes the compiler is the one the earlier steps identified.
A step whose prerequisite is absent is reported as SKIP and the set is declared incomplete: a skipped
check is one not made, and it counts as neither a pass nor a failure.

The correctness tests themselves are 62 IR tests of our own (`tests/ir`, one per lost-race shape with
its negative control) and 278 tests of ThreadSanitizer's own regression suite vendored from
compiler-rt (`tests/tsan`), run in each of 12 configurations.

## Running the experiments

Each script prints what it will do, how long it takes and how much disk it needs, then does it.
Running one twice is safe: results are written to a new directory per run and the tables are
regenerated from whichever runs you point them at.

| Script | What it checks | Time | Hardware |
|---|---|---|---|
| `10-minimal-example.sh` | the analyses do what Sections 4 to 6 say | 10 min | any |
| `11-soundness-shapes.sh` | 23 fixed lost-race shapes, each against its negative test | 20 min | any |
| `12-compiler-equivalence.sh` | the shipped compiler emits the instrumentation our measurements were taken on | 30 min | any |
| `20-static-counts.sh` | static instrumentation per application and configuration | 2 h | 8 cores |
| `21-compile-time.sh` | compile-time overhead | 1 h | 8 cores |
| `30-preservation-suite.sh` | 12 configurations over ThreadSanitizer's regression suite, with a report-level diff | 2 h | 8 cores |
| `31-preservation-apps.sh` | races reported on the applications, against stock | 3 h | 16 cores |
| `40-perf.sh` | the performance table | 1 day | 32 cores |
| `50-eviction-stress.sh` | the bounded-shadow experiments | 1 h | 4 cores |
| `90-tables.sh` | regenerates every table, from your runs or from ours | 1 min | any |

`90-tables.sh` works without running anything else: pointed at `data/`, it re-derives every table
in the paper from the runs we recorded. That is the fastest way to check that our tables follow
from our data.

### The three checks that make a clean result mean something

Every claim in this artifact is a negative -- instrumentation removed, races still found --
and a broken check produces negatives for free. Each of these scripts therefore carries a
control that must fire, and each refuses to run beside another `llvm-lit` (concurrent lit
runs share `Output/` and fail for reasons that are not the compiler's):

| Script | What it answers | The control that makes it evidence |
|---|---|---|
| `scripts/11-soundness-shapes.sh` | Does the compiler still instrument every access the audit says it must? | Re-runs each test with its `-tsan-*` flags stripped. A test claiming a removal must then fail; one asserting instrumentation stays is expected to pass either way. Currently 50 removal tests, 11 controls, 0 vacuous. |
| `scripts/12-compiler-equivalence.sh` | Does this compiler instrument the IR corpus exactly as the campaign compiler did? | Checks the reference table can separate the configurations at all (24 of 28 modules do), and reports the provenance stamp separately -- the corpus alone cannot identify the commit. |
| `scripts/30-preservation-suite.sh` | Does any configuration lose a race stock reports? | `--self-test` runs a detector with load/store instrumentation switched off and requires the harness to report the losses. A suite that reports nothing looks identical whether races are preserved or the harness is blind. |

```
./docker/run.sh scripts/11-soundness-shapes.sh
./docker/run.sh scripts/12-compiler-equivalence.sh
./docker/run.sh scripts/30-preservation-suite.sh --self-test    # first, always
./docker/run.sh scripts/30-preservation-suite.sh 5              # then the real matrix
```

## What this artifact does not contain

Chromium and MySQL performance. Both are documented in `docs/`, with our recorded data, the exact
configuration and the reasons: a Chromium checkout is over a terabyte and our only build predates
the compiler shipped here, and a full MySQL run takes about seven hours on top of an hour of
build. Neither is claimed in `CLAIMS.md`.

## If something does not work

`docs/troubleshooting.md` lists the failures we have seen, including the ones that look like our
bugs and are not: ThreadSanitizer's own reports on the benchmarks, the tests that are
non-deterministic under stock ThreadSanitizer as well, and the message the container prints when
the host has fewer cores than an experiment assumes.
