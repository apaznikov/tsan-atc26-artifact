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

## Why the repository is small

The compiler is not here as a binary and there is no copy of LLVM. There are 29 patches over the
upstream LLVM commit `c609043dd009`, which is text. The container fetches upstream itself with a
shallow clone, applies the patches, checks that the reconstructed source tree hashes to ours, and
builds the compiler inside itself. The recorded runs are text too, logs and JSON, so 112 MB of data
packs into a few megabytes of git history.

## The environment we used

Intel Xeon w9-3495X, 56 cores and 112 threads, 250 GB RAM, Ubuntu 24.04, kernel 6.8.0-40-generic.
Performance runs are pinned to 48 processors, one measurement at a time. Nothing here needs that
machine: the container runs anywhere, and the deterministic experiments give identical results on
any x86-64 Linux host. The performance experiments need at least 32 cores to be meaningful, and
`docs/confounds.md` says what varies and why.

## Getting started: one command

```
./evaluate.sh --quick            # about 20 minutes: prerequisites, the image, the minimal example,
                                 # the correctness set without the regression suite, the tables
./evaluate.sh                    # the same with the full correctness set: about 2 hours (Functional)
./evaluate.sh reproduced         # plus the performance subset: about 4 hours on 32+ idle processors
./evaluate.sh everything         # plus MySQL and all fourteen configurations: about 14 hours
./evaluate.sh reproduced --plan  # print the steps and their expected times, run nothing
```

Where the results are: `results/evaluate-<tier>-<stamp>.log` holds every step's full output;
each performance run writes `results/perf-<app>-<stamp>/perf_<app>.md` (the table for that
application, one row per configuration, with the point estimate or the interval) and
`perf_summary.md`; the correctness steps write their own directories under `results/` (the
preservation suite's `report.txt` and `manifest.txt`, the soundness shapes' lit logs). The
performance tiers end with `harness/tools/perf/compare_with_claims.py`, which prints one line per
configuration row against the interval `CLAIMS.md` ships for it (inside or outside, not judged, not
comparable) and a count of rows judged; read that count first, since a row it cannot judge is reported,
never passed, and its silence is never a pass. On a machine with 48 or more processors the performance tier pins the first 48 unless
`ART_CPUSET` says which; on a smaller one it runs unpinned and says so.

`evaluate.sh` runs the scripts below in the documented order, prints one line per step with its time,
writes the full log under `results/`, and ends with one verdict: PASS, INCOMPLETE (a check whose
prerequisite is absent here was skipped, which is neither a pass nor a failure) or FAIL with the step
that stopped it. The tiers are separate because the correctness set runs anywhere in two hours while
the performance set needs a quiet 32-processor machine for four to fourteen hours, and the badges are
awarded separately. The same steps, one at a time:

```
./scripts/00-prereqs.sh          # says what is missing, changes nothing; on the host only Docker matters
./docker/build.sh                # builds the image, including the compiler
./docker/run.sh scripts/10-minimal-example.sh
```

On the host, Docker is the only requirement. `00-prereqs.sh` run on the host reports the compiler,
`llvm-lit` and the benchmark clients as missing: that is expected, they live inside the container and
`docker/build.sh` builds them, and nothing is to be installed for them. Run it again inside the container
(`./docker/run.sh scripts/00-prereqs.sh`) and it passes.

Start the container through `docker/run.sh`. It does two things a hand-written `docker run` will
not: it passes `--security-opt seccomp=unconfined`, because the ThreadSanitizer runtime re-executes
programs with address-space randomization off and Docker's default seccomp profile refuses that call,
so without the flag every instrumented program dies with a segmentation fault; and it computes the
build parallelism on the host from the memory the Docker daemon actually has, a cap that is invisible
from inside the container and that an unbounded build does not fail against but thrashes
(`docs/troubleshooting.md`).

The minimal example compiles one small program per analysis, shows which instrumentation each
analysis removes and why, then compiles and runs a program with a real race to show the race is
still reported. It needs no special hardware. The container build, if you have not run it before, takes about
15 minutes at the default job count on a machine like ours and about 25 minutes at 8 jobs (both measured
with `--no-cache` on 18 Sep 2026: 14m52s at 25 jobs, 24m38s at 8); the example itself is a few minutes. The two build times are
not a scaling curve: three times fewer jobs cost 1.7 times the wall time, because the apt install, the
shallow clone, the patch series, the CMake configure and the runtime stage are a fixed serial head that
the job count does not touch.

## The correctness set: one command, no performance

For the Functional badge, and for anyone who wants to know the artifact does what it says without
spending a day on measurements:

```
./docker/run.sh scripts/01-functional.sh            # 31 min on 64 processors, 1 h 45 min on 32, longer on 8
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
its negative control) and 298 tests of ThreadSanitizer's own regression suite vendored from
compiler-rt (278 in `tests/tsan` and 20 more in `tests/tsan/Linux`), run in each of 12 configurations.
The suite discovers 383 and `lit` marks 85 unsupported on Linux before anything is compiled.

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
| `40-perf.sh` | the performance table, one application at a time | default (4 configurations, N = 2), measured: Redis 13-15 min, memcached 28-36, FFmpeg 20-25, SQLite 65-68; MySQL about 3.4 h; everything at N = 2 about 14 h with builds; `ART_RUNS=5` for intervals, 2.5x longer | 32 cores |
| `50-eviction-stress.sh` | the bounded-shadow experiments | 1 h | 4 cores |
| `13-verify-image.sh` | the image an evaluator built is the compiler we measured: version, stamp, self-containedness, and the reconstructed tree hash from the build log | 10 min | any |
| `90-tables.sh` | regenerates every table, from your runs or from ours | 1 min | any |

The whole artifact, every script at its defaults, is about 14 hours on 48 processors; the reviewer's
subset of the performance table, four configurations on the four cheaper applications, is about two
hours. Our own campaign used five runs per configuration and took 43 hours; that setting is one
variable away (`ART_RUNS=5`) and `CLAIMS.md` says what each mode can and cannot conclude.

Every performance-side script also has a smoke mode, `ART_SMOKE=1`: one run, short workloads, reduced
test lists, output marked NOT A MEASUREMENT. It answers one question, whether the pipeline runs end to end
on your machine, and nothing about the numbers. The preservation smoke (`31-preservation-apps.sh`) attempts
no verdict at that scale: a single short run cannot show a race site that stock itself reports in only
two or three of ten paper-scale runs, so the script prints that no verdict was attempted and exits on the
plumbing alone; the positive control that refuses to certify a run in which stock found nothing applies
unchanged at the paper scale.

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
| `scripts/11-soundness-shapes.sh` | Does the compiler still instrument every access the audit says it must? | Re-runs each test with its `-tsan-*` flags stripped. A test claiming a removal must then fail; one asserting instrumentation stays is expected to pass either way. Currently 50 removal tests, 11 controls, 0 vacuous; the 62nd, `ipa-summary-external.ll`, is a multi-step test with no FileCheck pipe, which the vacuity tool reports as skipped because it cannot strip a flag from it. |
| `scripts/12-compiler-equivalence.sh` | Does this compiler instrument the IR corpus exactly as the campaign compiler did? | Checks the reference table can separate the configurations at all (24 of 28 modules do), and reports the provenance stamp separately -- the corpus alone cannot identify the commit. |
| `scripts/30-preservation-suite.sh` | Does any configuration lose a race stock reports? | `--self-test` runs a detector with load/store instrumentation switched off and requires the harness to report the losses. A suite that reports nothing looks identical whether races are preserved or the harness is blind. |

```
./docker/run.sh scripts/11-soundness-shapes.sh
./docker/run.sh scripts/12-compiler-equivalence.sh
./docker/run.sh scripts/30-preservation-suite.sh --self-test    # first, always
./docker/run.sh scripts/30-preservation-suite.sh 5              # then the real matrix
```

## What this artifact does not contain

Chromium performance. It is documented in `docs/chromium.md`, with our recorded data, the exact
configuration and the reason: a Chromium checkout is over a terabyte and our only build predates the
compiler shipped here. It is not claimed in `CLAIMS.md`.

MySQL is claimed, and its table ships with the recorded runs, but it is the expensive row: about
3.4 hours of runs at the default settings on top of four builds, which is why it is not part of the
two-hour reviewer's subset and why `CLAIMS.md` says so beside the row rather than leaving it to be
discovered.

## If something does not work

`docs/troubleshooting.md` lists the failures we have seen, including the ones that look like our
bugs and are not: ThreadSanitizer's own reports on the benchmarks, the tests that are
non-deterministic under stock ThreadSanitizer as well, and the message the container prints when
the host has fewer cores than an experiment assumes.
