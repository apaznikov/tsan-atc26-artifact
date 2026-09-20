# Artifact: Instrumentation Optimization for Practical Dynamic Race Detection

*Русская версия: [README.ru.md](README.ru.md).*

This artifact accompanies the ATC '26 paper *Instrumentation Optimization for Practical
Dynamic Race Detection*. It contains the modified LLVM/ThreadSanitizer compiler the paper
describes, the analyses' test suites and audit ledger, the benchmark harness, the data we
recorded, and one script per experiment.

## Start here

```
git clone https://github.com/apaznikov/tsan-atc26-artifact.git && cd tsan-atc26-artifact
./evaluate.sh check          # does it all run here? 5 minutes, plus the image build the first time (15-25 min). Not a badge.
./evaluate.sh functional     # the Functional badge: the full correctness set, about 2 hours (31 min on 64 processors, 1 h 45 min on 32, 2 h on 8)
./evaluate.sh reproduced     # the Reproduced badge: the whole functional tier, then the performance subset; about 3 hours on 48 idle processors
./evaluate.sh                # prints the tiers and their steps, runs nothing
```

Each tier contains the one before it: `reproduced` runs the whole `functional` tier first, so one command per
badge is the whole job. Docker is the only thing to install. Each command prints one line per step with its time, shows what the
step said, and ends with one verdict line and a sentence saying what it established:

- **PASS** on the Functional tier means: the container built our compiler from the patch series (the build log
  shows the reconstructed source tree hashing to ours, and the image's clang carries our commit) and it emits
  the same instrumentation as the compiler we measured on; every analysis removes what it claims and a real
  race is still reported; the 23 lost-race shapes stay instrumented; ThreadSanitizer's regression suite loses
  no race in any of the 12 configurations; every shipped run carries its provenance; and every table follows
  from the shipped runs. It says nothing about speed.
- **INCOMPLETE** means nothing failed but a check could not be made here (its prerequisite is absent) and
  the log names it. Neither a pass nor a failure.
- **FAIL** names the step that stopped it; `docs/troubleshooting.md` lists the failures we know.
- The **Reproduced** tier ends with a table: one line per configuration row of your run against the
  interval `CLAIMS.md` ships for it, marked IN, OUT (with the distance), not judged, or not comparable,
  then "N rows judged". What counts as reproduced, what an OUT row can mean, and the five-run re-check for
  it are in `CLAIMS.md`, section 5, under "Match criterion". FFmpeg's two rows come back "not comparable"
  unless `ART_FFMPEG_CLIP_URL` names the reference clip (`docs/ffmpeg-input.md`); the run itself is valid.

What the end of a run looks like, from our own runs. No graphs: the verdict and the numbers are the deliverable,
and the per-application tables with every subtest are in `results/perf-<app>-<stamp>/perf_<app>.md`.

```
evaluate.sh: PASS  (tier check, 0h1m; full log in results/evaluate-check-20260919-144059.log)
Every step ran and passed: the image is our compiler built from the patch series, each analysis removes what it
claims and the race is still reported, and the shipped tables follow from the shipped runs. This is the check,
not the Functional badge: the regression suite (no configuration loses a race) runs in ./evaluate.sh functional.
```

```
evaluate.sh: PASS  (tier functional, 1h57m; full log in results/evaluate-functional-20260919-055431.log)
Every step ran and passed: the image is our compiler built from the patch series, the analyses, the regression
suite and the shipped tables (what each step established is CLAIMS.md sections 1 to 4). This tier says nothing
about speed.
```

The Reproduced tier ends with the comparison. This one is from a 64-processor AMD host (the run `CLAIMS.md`
section 5 quotes), with the stock-against-native lines and the "rows not produced by this run" lines left out;
FFmpeg is not compared there because that host regenerated the clip:

```
app        row                                       yours  ours (N=5)             verdict
----------------------------------------------------------------------------------------------------
ffmpeg     AllOpt with peeling                 0.999 (N=2)  1.006 [0.990, 1.024]   not comparable: not the reference clip
ffmpeg     DynSTC                              1.115 (N=2)  1.113 [1.099, 1.129]   not comparable: not the reference clip
memcached  AllOpt with peeling                 1.059 (N=2)  1.019 [0.951, 1.079]   IN
memcached  DynSTC                              0.942 (N=2)  0.986 [0.944, 1.063]   OUT by 0.002 below
redis      AllOpt with peeling                 1.001 (N=2)  1.000 [0.983, 1.026]   IN
redis      DynSTC                              0.971 (N=2)  0.944 [0.927, 0.970]   OUT by 0.001 above, same side of 1.0
sqlite     AllOpt with peeling                 0.944 (N=2)  1.023 [0.942, 1.061]   IN
sqlite     DynSTC                              0.968 (N=2)  0.995 [0.928, 1.082]   IN
----------------------------------------------------------------------------------------------------
6 rows judged, 2 outside their intervals.
evaluate.sh: PASS on every step, COMPARISON NOT CLEAN  (tier reproduced, 4h6m; full log in results/evaluate-reproduced-20260919-010131.log)
```

The tables name configurations as the harness does:

| Name | Meaning |
|---|---|
| `orig` | native build, no ThreadSanitizer |
| `tsan` | stock ThreadSanitizer; every configuration row is a ratio against it, above 1.0 = faster than stock |
| `tsan-st`, `tsan-swmr`, `tsan-lo`, `tsan-ea`, `tsan-dom` | one analysis each: single-threaded context (STC), single-writer multiple-reader (SWMR), lock ownership (LO), escape analysis (EA), dominance-based elimination (DE) |
| `tsan-dom_peeling` | DE with loop peeling |
| `tsan-dom-ea-lo-st-swmr` | AllOpt without peeling: all five analyses |
| `tsan-dom_peeling-ea-lo-st-swmr` | **AllOpt with peeling**, the paper's AllOpt |
| `tsan-stmt` | **DynSTC**, the dynamic single-threaded-context transformation |
| `tsan-dom_peeling-ea-lo-st-swmr-stmt` | AllOpt with peeling plus DynSTC |
| `tsan-sound-wp`, `tsan-dom_peeling-ea-lo-st-swmr-wp` | the four analyses STC, SWMR, LO and EA (without DE), and AllOpt with peeling, each with whole-program summaries |

`CLAIMS.md` is the contract: every claim the paper makes, the script that produces it, and what counts
as a match. Nothing outside that file is claimed here. Read it once the quick tier has passed.

> Status: prepared for the artifact submission of 22 September 2026. Every claim in `CLAIMS.md` is measured
> on the shipped compiler, all five applications included; nothing is pending. The "Paper" column of each
> performance table is the submitted manuscript's figure, kept so that the change is visible; the
> camera-ready reports the numbers in `CLAIMS.md`.

## What is in here

| Path | What it is | Where it appears in the paper |
|---|---|---|
| `compiler/` | The compiler as a patch series over a pinned upstream LLVM commit, plus `TSanAnalysesAudit.md`, the per-function ledger of contracts, verdicts and covering tests | Sections 4 to 7 |
| `docker/` | The container recipe that builds and installs that compiler | Section 8.1 |
| `scripts/` | One script per experiment, numbered in the order a reader would run them | Section 8 |
| `data/` | Every run we recorded: per-run metadata with compiler stamp, binary hash, processor set, governor and load, plus the aggregates | Section 8 |
| `docs/` | The method document, the known confounds, and the one experiment (Chromium) that is documented rather than runnable here | Section 8, appendices |

Third-party code is unmodified except where noted in `THIRD-PARTY.md`, which also records the
licence of every vendored component.

## Why the repository is small

The compiler is not here as a binary and there is no copy of LLVM. There are 29 patches over the
upstream LLVM commit `c609043dd009`, which is text. The container fetches upstream itself with a
shallow clone, applies the patches, checks that the reconstructed source tree hashes to ours, and
builds the compiler inside itself. The recorded runs are text too, logs and JSON, so about 140 MB of data
packs into a few megabytes of git history.

## The environment we used

Intel Xeon w9-3495X, 56 cores and 112 threads, 250 GB RAM, Ubuntu 24.04, kernel 6.8.0-40-generic.
Performance runs are pinned to 24 physical cores with both SMT threads of each (48 logical processors, CPUs 4-27
and 60-83), one measurement at a time. Nothing here needs that
machine: the container runs anywhere, and the deterministic experiments give identical results on
any x86-64 Linux host. The performance experiments run on any processor count; the comparison with our intervals is made with
the campaign's shape pinned, 24 physical cores with both SMT threads (48 logical processors; memcached's thread
count follows the logical count): with fewer, the run is unpinned,
memcached's rows are reported with their thread count and not compared, and the other rows are judged. `docs/confounds.md`
says what varies and why. The minimum for the correctness set is 8 processors (the regression suite refuses
fewer), 16 GB of memory (`ART_MEMORY=16g` caps the container so that the derived job count respects it) and
20 GB of disk; the performance set needs up to 100 GB of disk with MySQL.

## Getting started, in detail

`./evaluate.sh everything` is `reproduced` at all fourteen configurations, plus MySQL (about 14 hours). On a
checkout where `./evaluate.sh functional` already ended in PASS, `./evaluate.sh reproduced --performance-only`
runs the performance subset alone (about 2 h 20 min); `./evaluate.sh <tier> --plan` prints a tier's steps and
their expected times without running anything.
Nothing asks a question: a tier starts when named, after printing what to know about it (`--plan` lists the
steps without starting anything). `--rebuild` builds the image again from nothing (15-25 min).
The build asserts that the patch series reproduces our source tree and stamps the measured tree hash into the
image, where every tier checks it; an image built from a checkout older than 20 Sep 2026 has no such stamp,
and a tier run against it is INCOMPLETE until `--rebuild`. On a machine that never had the image, the first
command builds it and this never arises.

Where the results are: `results/evaluate-<tier>-<stamp>.log` holds every step's full output;
each performance run writes `results/perf-<app>-<stamp>/perf_<app>.md` (the table for that
application, one row per configuration, with the point estimate or the interval) and
`perf_summary.md`; the correctness steps write their own directories under `results/` (the
preservation suite's `report.txt` and `manifest.txt`, the soundness shapes' lit logs). The
performance tiers end with `harness/tools/perf/compare_with_claims.py`, which prints one line per
configuration row against the interval `CLAIMS.md` ships for it (inside or outside, not judged, not
comparable) and a count of rows judged; read that count first, since a row it cannot judge is reported,
never passed, and its silence is never a pass. On a machine with 48 or more processors the performance tier pins the campaign's shape from the processors
the Docker daemon grants to containers, the first 24 complete SMT sibling pairs, and prints the set (on a
machine without 24 such pairs, the first 48 granted, printed as a different shape) unless `ART_CPUSET` says
which; on a smaller one it runs unpinned and says so.

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

Start the container through `docker/run.sh`. It does four things a hand-written `docker run` will
not: it passes `--security-opt seccomp=unconfined`, because the ThreadSanitizer runtime re-executes
programs with address-space randomization off and Docker's default seccomp profile refuses that call,
so without the flag every instrumented program dies with a segmentation fault; it runs the container as
your own user, because memcached refuses to start as root and its benchmark then measures a client
talking to nothing (and root-owned results cannot be deleted without sudo); it gives `/dev/shm` 1 GB,
because two of FFmpeg's four codecs write outputs larger than Docker's 64 MB default and the row would
silently measure two codecs instead of four; and it computes the build parallelism on the host from the
memory the Docker daemon actually has, a cap that is invisible from inside the container and that an
unbounded build does not fail against but thrashes (`docs/troubleshooting.md`). It also forwards every
knob in `env.sh` into the container.

The minimal example compiles one small program per analysis, shows which instrumentation each
analysis removes and why, then compiles and runs a program with a real race to show the race is
still reported. It needs no special hardware. On our image it prints, per analysis, stock/enabled/removed
counts of 8/6/2 (STC), 56/8/48 (SWMR), 6/4/2 (LO), 21/1/20 (EA) and 9/8/1 (DE), then `data race reported`
under stock and under AllOpt; the step fails if stock shows no instrumentation, if any analysis removed
nothing, or if the race goes unreported (the exact counts include a little libc glue and are what our image
prints, not the criterion). The container build, if you have not run it before, takes about
15 minutes at the default job count on a machine like ours and about 25 minutes at 8 jobs (both measured
with `--no-cache` on 18 Sep 2026: 14m52s at 25 jobs, 24m38s at 8); the example itself is a few minutes. The two build times are
not a scaling curve: three times fewer jobs cost 1.7 times the wall time, because the apt install, the
shallow clone, the patch series, the CMake configure and the runtime stage are a fixed serial head that
the job count does not touch.

## The correctness set: one command, no performance

For the Functional badge, and for anyone who wants to know the artifact does what it says without
spending a day on measurements:

```
./docker/run.sh scripts/01-functional.sh            # 31 min on 64 processors, 1 h 45 min on 32, 2 h on 8
./docker/run.sh scripts/01-functional.sh --quick    # about 5 minutes, without the regression suite
```

It runs the deterministic checks in order and prints one verdict per step: the minimal example, the
23 lost-race shapes with their vacuity control, the compiler's equivalence to the one we measured on,
the provenance of the shipped runs, the image's identity (`13-verify-image.sh`, on the host, from the build log), the identity of the two copies of the table code, the self-test of the
rule that decides a lost race, the ThreadSanitizer regression suite in 12 configurations preceded by its
self-test, and the regeneration of every table from the shipped data (`--quick` omits the two
regression-suite steps and its verdict says so). It stops at the
first failure, because each later step assumes the compiler is the one the earlier steps identified.
A step whose prerequisite is absent is reported as SKIP and the set is declared incomplete: a skipped
check is one not made, and it counts as neither a pass nor a failure.

The correctness tests themselves are 62 IR tests of our own (`tests/ir`: 50 removal tests and 11 negative
controls covering the 23 lost-race shapes, plus one multi-step summary test) and ThreadSanitizer's own regression suite vendored from compiler-rt under
`tests/tsan`, run in each of 12 configurations. `lit` discovers 383 tests there and marks 91
unsupported on this platform before anything is compiled, so 292 execute; our own run of them ships as
`data/suite/`, with the command to re-derive each count. One test, `getline_nohang.cpp`, stalls to its
two-minute timeout in many repeats under stock as well as under every configuration; a pause of a couple of
minutes during the suite is that test, not a hang (on our 8-processor run it stalled 40 of 60 repeats, most of
the two hours); it should be skipped on this glibc and is not, a lit
configuration defect explained in `docs/nondeterministic-tests.md`, to be fixed after the submission.

## Running the experiments

Each measurement script prints what it will do, roughly how long it takes and how much disk it needs, then
does it; the quick checks print only their verdicts.
Running one twice is safe: results are written to a new directory per run and the tables are
regenerated from whichever runs you point them at.

| Script | What it checks | Time | Hardware |
|---|---|---|---|
| `10-minimal-example.sh` | the analyses do what Sections 4 to 6 say | under a minute | any |
| `11-soundness-shapes.sh` | 23 fixed lost-race shapes, each against its negative test | 2 min | any |
| `12-compiler-equivalence.sh` | the shipped compiler emits the instrumentation our measurements were taken on | 3 min | any |
| `20-static-counts.sh` | static instrumentation per application and configuration, counted on the binaries `40-perf.sh` built | 5 min | any |
| `21-compile-time.sh <app>` | compile-time overhead, three clean builds per configuration | 20 min to 3 h per application (MySQL 5 to 10 h) | 8 cores |
| `30-preservation-suite.sh` | 12 configurations over ThreadSanitizer's regression suite, pass or fail per test (the report-level comparison is recorded, not re-run; `CLAIMS.md` section 1) | 1 h 40 min on 32 processors, 25 min on 64, about 3 h on 8 | 8 cores |
| `31-preservation-apps.sh <app> 10` | races reported on the applications, against stock; N = 10 runs for a verdict (the default N = 2 prints the per-site frequencies without one) | 1.5 to 3 h per application | 16 cores |
| `40-perf.sh <app>` | the performance table, one application at a time | default (4 configurations, N = 2), measured: Redis 13-15 min, memcached 28-36, FFmpeg 20-25, SQLite 65-68; MySQL about 3.4 h; everything at N = 2 about 14 h with builds; `ART_RUNS=5` for intervals, twice as long | 32 cores |
| `50-eviction-stress.sh` | the bounded-shadow experiments | 15 min to 1 h | any |
| `13-verify-image.sh` | the image an evaluator built is the compiler we measured: version, stamp, self-containedness, and the reconstructed tree hash from the build log | about 35 min (a minute with `--static`); runs on the host, it starts its own container | any |
| `90-tables.sh` | regenerates every table, from your runs or from ours | 1 min | any |

Everything, every application at all fourteen configurations, is about 14 hours on 48 processors; the reviewer's
subset of the performance table, four configurations on the four cheaper applications, is about two
hours. Our own campaign used five runs per configuration and took 32 hours of measurement after about 7 hours
of builds; that setting is one variable away (`ART_RUNS=5`, twice the default's time) and `CLAIMS.md` says
what each mode can and cannot conclude.

Every performance-side script also has a smoke mode, `ART_SMOKE=1`: one run, short workloads, reduced
test lists, output marked NOT A MEASUREMENT. It answers one question, whether the pipeline runs end to end
on your machine, and nothing about the numbers. The preservation smoke (`31-preservation-apps.sh`) attempts
no verdict at that scale: a single short run cannot show a race site that stock itself reports in only
two or three of ten paper-scale runs, so the script prints that no verdict was attempted and exits on the
plumbing alone; the positive control that refuses to certify a run in which stock found nothing applies
unchanged at the paper scale.

`90-tables.sh` works without running anything else: run with no argument, it re-derives every table
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

These are the invocations `evaluate.sh` runs inside the correctness set; after a PASS there is nothing to
repeat.

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
