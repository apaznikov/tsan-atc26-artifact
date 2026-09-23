# Artifact: Instrumentation Optimization for Practical Dynamic Race Detection

This is the artifact for the ATC '26 paper *Instrumentation Optimization for Practical Dynamic Race
Detection*. It contains the modified LLVM/ThreadSanitizer compiler the paper describes, its test suites, the benchmark
harness, the runs every claim rests on, and one script per experiment.

It is submitted for the **Available** and **Functional** badges. Its performance harness and the runs of its
performance campaign (`data/perf/`) ship with it and are not submitted for evaluation.

`CLAIMS.md` is the contract: each claim the paper makes, the script that produces it, and what counts as a
match. Nothing outside that file is claimed here.

## What you need

Docker on an x86-64 Linux host, with your user in the `docker` group. Engine 24 or later should do (every
option the artifact passes is older than that); we have run it on 28.5 and 29.1. Nothing else is installed
on the host: the compiler, `llvm-lit` and the benchmark clients live inside the image, which the first
command builds in 15 to 25 minutes.

| For | Processors | Memory | Disk |
|---|---|---|---|
| the correctness set | 8 | 16 GB | 20 GB |
| performance (optional, not submitted for evaluation), comparable with the campaign's runs | 48 logical, being 24 physical cores with both SMT threads, and otherwise idle | 16 GB | 20 GB |
| performance including MySQL (optional) | the same | 16 GB | 100 GB |

We measured on an Intel Xeon w9-3495X (56 cores, 112 threads), 250 GB, Ubuntu 24.04, kernel 6.8.0-40-generic,
with 24 cores and both SMT threads of each pinned, and repeated the correctness set and the default N = 2
performance runs on an AMD EPYC 9115 (32 cores, 64 threads; `docs/evaluator-runs.md`). On fewer processors, or
on a set of another shape, every step still runs.

The network is used twice: while the image builds (Ubuntu packages and a shallow clone of upstream LLVM) and
for FFmpeg's input clip, 78 MB from this repository's GitHub release. The other application sources ship in
`third-party/sources/` and are checked against pinned sha256 digests; MySQL's 421 MB archive is fetched only
by the `everything` tier.

## Run it

```
git clone https://github.com/apaznikov/tsan-atc26-artifact.git && cd tsan-atc26-artifact
./evaluate.sh check          # does this machine work at all? about 2 minutes, plus 15-25 min to build the image the first time
./evaluate.sh functional     # Functional badge: the correctness set. 23 min on 64 processors, 48 min on 8
./evaluate.sh reproduced     # optional: the above, then the performance measurements. About 3 hours (2 h 38 min here)
```

Each tier contains the one before it, so run the one for your badge and not the others after it: chaining them repeats the correctness set each time. `./evaluate.sh` with no
tier lists them and runs nothing; `<tier> --plan` prints a tier's steps and their expected times; `--rebuild`
builds the image again from nothing; `everything` adds MySQL and all fourteen configurations, about 14 hours.
Nothing asks a question once a tier starts.

## What you get

Every step prints its own result, and the run ends with one verdict line:

- **PASS**: every step did what it claims.
- **INCOMPLETE**: nothing failed, but a check could not be made here; the log names it.
- **FAIL**: the step that stopped it is named, and `docs/troubleshooting.md` lists the failures we have seen.

The optional performance tier ends with the tables of its own runs and judges nothing.

Results land in `results/`: `evaluate-<tier>-<stamp>.log` is the whole run. This is the end of a Functional run
from a fresh clone on our 112-thread host (23 Sep 2026, image build included), trimmed to its per-step verdicts:

```
PASS  10-minimal-example.sh
PASS  11-soundness-shapes.sh
PASS  12-compiler-equivalence.sh
PASS  91-verify-provenance.sh
PASS  14-tool-copies.sh
PASS  15-verdict-rules.sh
PASS  30-preservation-suite.sh --self-test
PASS  30-preservation-suite.sh 5
PASS  90-tables.sh

The correctness set passed, in full.
evaluate.sh: PASS  (tier functional, 42m47s; full log in results/evaluate-functional-20260923-065547.log)
```

## What is claimed

The camera-ready paper describes the compiler released here, which carries 23 soundness fixes made while
preparing the artifact. The Functional claims, each with its script and match criterion in `CLAIMS.md`:

- **Race detection is preserved.** No race is lost on ThreadSanitizer's regression suite in any of twelve
  configurations. On SQLite and memcached at N = 10, no race is lost at the level of the racing location (L3);
  one memcached report moves to another reader of the same location (`CLAIMS.md` section 1).
- **The analyses are sound on 23 code shapes** in which an optimized build could fail to report a race, each
  pinned by a test that fails on the commit before its fix (section 2, with the assumptions the argument
  rests on).
- **Instrumentation counts**: static instrumentation sites per application and configuration, and a compiler
  built from the patch series that emits the same instrumentation as the measured compiler on 112 corpus rows
  (section 3).
- **Compile time**: the script that measures the analyses' overhead, and its criterion (section 4).
- **Bounded shadow state**: how ThreadSanitizer's four shadow slots per granule interact with the optimized
  builds (section 6).

The performance campaign's runs ship in `data/perf/` and are not submitted for evaluation.
`CLAIMS.md` section 7 lists what this artifact does not support, Chromium and the ReX comparison among them.

## What is in here

| Path | What it is | In the paper |
|---|---|---|
| `compiler/` | the compiler as 28 patches over a pinned upstream LLVM commit | the analyses, redundancy elimination, transformations and LLVM integration |
| `docker/` | the container recipe that applies those patches, checks the reconstructed source tree against its hash, and builds the compiler | the evaluation's setup |
| `scripts/` | one script per experiment, numbered in the order a reader would run them | the evaluation |
| `harness/` | the benchmark harness: build, run, aggregate | the evaluation |
| `data/` | the runs every claim rests on, each with its compiler stamp, binary hash, processor set, governor and load, plus the aggregates | the evaluation |
| `tests/` | the IR suite for the analyses and the vendored ThreadSanitizer regression suite | the analyses; race-detection preservation |
| `docs/` | the method, the known confounds, the experiment that is documented rather than runnable here, and the artifact appendix | the evaluation, appendices |

Third-party code is unmodified except where `THIRD-PARTY.md` says otherwise; that file also records each
component's licence, and `third-party/SOURCES.md` its origin and digest.

## What the artifact does to your machine

Everything runs in a container started by `docker/run.sh`, which writes only under `results/` and `build/` of
the checkout. Inside that container the benchmark scripts start and stop servers **by name** (`memcached`,
`redis-server`, `mysqld`), which is why they must be run through `docker/run.sh` and not directly on a host
that runs those services. Nothing else on the machine is touched, nothing is installed outside the image, and
the artifact contains no destructive or malicious code.

Three container options are worth knowing: `--security-opt seccomp=unconfined`, because ThreadSanitizer
re-executes every program with ASLR off and Docker's default profile refuses that system call;
`--shm-size=1g`, because FFmpeg's workload writes each codec's output to `/dev/shm` and two of the four
outputs exceed Docker's 64 MB default; and a fixed open-files limit, because Docker versions default it
differently.

## Running one experiment at a time

Each script prints what it will do, how long it takes and how much disk it needs, then does it. Running one
twice is safe: every run writes a new directory, and the tables are regenerated from whichever runs you name.

| Script | What it checks | Time |
|---|---|---|
| `10-minimal-example.sh` | one small program per analysis: what the analysis removes, and that a real race is still reported (`scripts/minimal/README.md` says how to add a case of your own) | under a minute |
| `11-soundness-shapes.sh` | the 23 fixed lost-race shapes: the 62 IR tests, and a control that every removal test fails without its analysis | 2 min |
| `12-compiler-equivalence.sh` | the image's compiler emits the instrumentation our measurements were taken on | 3 min |
| `20-static-counts.sh` | static instrumentation per application and configuration | 5 min |
| `21-compile-time.sh <app>` | compile-time overhead, three clean builds per configuration | 20 min to 3 h; MySQL twelve builds of 5 to 8 min each at 56 jobs, longer on fewer processors |
| `30-preservation-suite.sh` | ThreadSanitizer's regression suite in 12 configurations: no configuration may lose a race | most of the functional tier: 23 min on 64 processors, 48 min on 8 |
| `31-preservation-apps.sh <app> 10` | races reported on an application against stock, N = 10 for a verdict | 1.5 to 3 h |
| `40-perf.sh <app>` | the performance table for one application (optional) | Redis 15 min, memcached 30, FFmpeg 25, SQLite 70, MySQL 3.5 h |
| `50-eviction-stress.sh` | the bounded-shadow experiments | 15 min to 1 h |
| `90-tables.sh` | regenerates the performance tables and the eviction tables from recorded runs | 1 min |
| `91-verify-provenance.sh` | every recorded run against its own metadata: one compiler, one processor set, one mode per leg, and the campaign's compiler hash where a claim rests on it | 2 min |
| `92-figures.sh` | one bar chart per application, our campaign with its intervals, and your own run's points beside it when you name a results directory | 1 min |

`90-tables.sh` needs nothing else to have run: with no argument it re-derives those tables from the data we
ship, which is the fastest way to check that our tables follow from our runs. Every performance script also
takes `ART_SMOKE=1`: one run, no warm-up, output marked NOT A MEASUREMENT, answering only whether the
pipeline works on your machine. It shortens the workload only for memcached and MySQL; **SQLite runs its whole
suite and costs about what its measurement costs** (`docs/campaign-parameters.md`, "Smoke mode"). Smoke Redis
or memcached to test the pipeline. `env.sh` holds every knob, `ART_RUNS=5` among them.

## If something does not work

`docs/troubleshooting.md` lists the failures we have seen, including the ones that look like our bugs and are
not: a compiler build stalled or killed by Docker's memory cap, a test binary that spins in `close()` under a
huge open-files limit, an image build interrupted in `apt-get`, a smoke run of SQLite that is not short.
`docs/confounds.md` says what makes a performance number move on a machine that is not ours.

## Licence

The artifact's own code, documents and data are under the MIT licence (`LICENSE`). Vendored third-party
components keep their own licences, recorded in `THIRD-PARTY.md`; the LLVM patches are under Apache-2.0 with
the LLVM exception, as upstream.
