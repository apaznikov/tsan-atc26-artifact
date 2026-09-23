# Artifact: Instrumentation Optimization for Practical Dynamic Race Detection

*Русская версия: [README.ru.md](README.ru.md).*

This is the artifact for the ATC '26 paper *Instrumentation Optimization for Practical Dynamic Race
Detection*. It contains the modified LLVM/ThreadSanitizer compiler the paper describes, its test suites and
audit ledger, the benchmark harness, every run we recorded, and one script per experiment.

`CLAIMS.md` is the contract: each claim the paper makes, the script that produces it, and what counts as a
match. Nothing outside that file is claimed here.

## What you need

Docker on an x86-64 Linux host, with your user in the `docker` group. Engine 24 or later should do — every
option the artifact passes is older than that — and what we have actually run it on is 28.5 and 29.1;
`docker/run.sh` sets the container's file-descriptor limit itself, because those two versions default it
differently. Nothing else is installed on the host: the compiler, `llvm-lit` and the benchmark clients
live inside the image, which the first command builds in 15 to 25 minutes.

| For | Processors | Memory | Disk |
|---|---|---|---|
| the correctness set | 8 | 16 GB | 20 GB |
| performance, compared with our intervals | 48 logical, being 24 physical cores with both SMT threads, and otherwise idle | 16 GB | 20 GB |
| performance including MySQL | the same | 16 GB | 100 GB |

We measured on an Intel Xeon w9-3495X (56 cores, 112 threads), 250 GB, Ubuntu 24.04, kernel 6.8.0-40-generic,
with 24 cores and both SMT threads of each pinned, and repeated the whole evaluation on an AMD EPYC 9115
(32 cores, 64 threads). On fewer processors, or on a set of another shape, every step still runs and the
performance rows are reported rather than judged; `CLAIMS.md` section 5 says why.

The network is used twice: while the image builds (Ubuntu packages and a shallow clone of upstream LLVM) and
for FFmpeg's input clip, 78 MB from this repository's GitHub release. The other application sources ship in
`third-party/sources/` and are checked against pinned sha256 digests; MySQL's 421 MB archive is fetched only
by the `everything` tier.

## Run it

```
git clone https://github.com/apaznikov/tsan-atc26-artifact.git && cd tsan-atc26-artifact
./evaluate.sh check          # does this machine work at all? about 2 minutes, plus the image build
./evaluate.sh functional     # Functional badge: the correctness set. 23 min on 64 processors, 48 min on 8
./evaluate.sh reproduced     # Reproduced badge: the above, then the performance subset. About 3 hours
```

Each tier contains the one before it, so one command is the whole job for a badge. `./evaluate.sh` with no
tier lists them and runs nothing; `<tier> --plan` prints a tier's steps and their expected times; `--rebuild`
builds the image again from nothing; `everything` adds MySQL and all fourteen configurations, about 14 hours.
Nothing asks a question once a tier starts.

## What you get

Every step prints its own result, and the run ends with one verdict line:

- **PASS** — every step did what it claims. On the performance tiers it also means every judged row lies
  inside the interval `CLAIMS.md` ships for it.
- **PASS on every step, COMPARISON NOT CLEAN** — the steps passed and a judged row lies outside its interval.
  `CLAIMS.md` section 5, "Match criterion", says what that can mean and how to re-check it.
- **PASS on every step; COMPARISON NOT APPLICABLE ON THIS MACHINE** (exit status 3) — the steps passed and no
  row could be compared, because this machine's processor-set shape, thread count or FFmpeg input is not the
  one the intervals describe. The run is valid and its ratios are printed beside ours, unjudged.
- **INCOMPLETE** — nothing failed, but a check could not be made here; the log names it.
- **FAIL** — the step that stopped it is named, and `docs/troubleshooting.md` lists the failures we have seen.

Results land in `results/`: `evaluate-<tier>-<stamp>.log` is the whole run, `perf-<app>-<stamp>/perf_<app>.md`
is one application's table with every configuration and subtest, and the performance tiers end with the
comparison against `CLAIMS.md`. This is one of our own runs, on the machine and processor set the intervals
describe, with the rows that are not compared left out:

```
app        row                                       yours  ours (N=5)             verdict
----------------------------------------------------------------------------------------------------
ffmpeg     AllOpt with peeling                 1.068 (N=2)  1.067 [1.050, 1.079]   IN , same side of 1.0
ffmpeg     AllOpt with peeling and DynSTC      1.186 (N=2)  1.187 [1.171, 1.201]   IN , same side of 1.0
ffmpeg     DynSTC                              1.130 (N=2)  1.133 [1.114, 1.146]   IN , same side of 1.0
memcached  AllOpt with peeling                 1.038 (N=2)  1.019 [0.951, 1.079]   IN
memcached  DynSTC                              0.974 (N=2)  0.986 [0.944, 1.063]   IN
redis      AllOpt with peeling                 1.005 (N=2)  1.000 [0.983, 1.026]   IN
redis      DynSTC                              0.979 (N=2)  0.944 [0.927, 0.970]   OUT by 0.009 above, same side of 1.0
sqlite     AllOpt with peeling                 1.032 (N=2)  1.023 [0.942, 1.061]   IN
sqlite     DynSTC                              0.930 (N=2)  0.995 [0.928, 1.082]   IN
----------------------------------------------------------------------------------------------------
9 rows judged, 1 outside their intervals.
evaluate.sh: PASS on every step, COMPARISON NOT CLEAN  (tier reproduced, 2h39m)
```

A reviewer's run is N = 2, a point compared against our N = 5 interval; our own campaign is N = 5 with 95 %
bootstrap intervals. The Redis row above is 0.009 outside on the same side of 1.0, which is the between-session
drift `CLAIMS.md` states with every Redis row.

## What is claimed

The camera-ready's performance section was re-measured with the compiler released here, which carries 23
soundness fixes made while preparing the artifact and still finds every race stock ThreadSanitizer finds. What
the campaign establishes: DynSTC changes performance measurably (FFmpeg +11 % at the paper's four threads,
Redis −5.6 %), and at 16 threads the full sound bundle with DynSTC reaches +19 % on FFmpeg; every other
configuration lies within its interval of stock ThreadSanitizer, and 2 to 8 per cent of the static
instrumentation is removed. The submitted paper's figures, measured before those fixes, stay in `CLAIMS.md`'s
"Paper" column beside ours. `CLAIMS.md` section 7 lists what this artifact does not support, Chromium and the
ReX comparison among them.

## What is in here

| Path | What it is | In the paper |
|---|---|---|
| `compiler/` | the compiler as 29 patches over a pinned upstream LLVM commit, plus the per-function audit ledger of contracts, verdicts and covering tests | sections 4 to 7 |
| `docker/` | the container recipe that applies those patches, checks the reconstructed source tree against its hash, and builds the compiler | section 8.1 |
| `scripts/` | one script per experiment, numbered in the order a reader would run them | section 8 |
| `harness/` | the benchmark harness: build, run, aggregate, compare | section 8 |
| `data/` | every run we recorded, each with its compiler stamp, binary hash, processor set, governor and load, plus the aggregates | section 8 |
| `tests/` | the IR suite for the analyses and the vendored ThreadSanitizer regression suite | sections 4 to 7 |
| `docs/` | the method, the known confounds, the experiment that is documented rather than runnable here, and the artifact appendix | section 8, appendices |

Third-party code is unmodified except where `THIRD-PARTY.md` says otherwise; that file also records each
component's licence, and `third-party/SOURCES.md` its origin and digest.

## What the artifact does to your machine

Everything runs in a container started by `docker/run.sh`, which writes only under `results/` and `build/` of
the checkout. Inside that container the benchmark scripts start and stop servers **by name** — `memcached`,
`redis-server`, `mysqld` — which is why they must be run through `docker/run.sh` and not directly on a host
that runs those services. Nothing else on the machine is touched, nothing is installed outside the image, and
the artifact contains no destructive or malicious code.

Two container options are worth knowing: `--security-opt seccomp=unconfined`, because ThreadSanitizer
re-executes every program with ASLR off and Docker's default profile refuses that system call, and
`--shm-size=1g`, because FFmpeg's workload writes each codec's output to `/dev/shm` and two of the four
outputs exceed Docker's 64 MB default.

## Running one experiment at a time

Each script prints what it will do, how long it takes and how much disk it needs, then does it. Running one
twice is safe: every run writes a new directory, and the tables are regenerated from whichever runs you name.

| Script | What it checks | Time |
|---|---|---|
| `10-minimal-example.sh` | one small program per analysis: what the analysis removes, and that a real race is still reported (`scripts/minimal/README.md` says how to add a case of your own) | under a minute |
| `11-soundness-shapes.sh` | 23 fixed lost-race shapes, each against its negative control | 2 min |
| `12-compiler-equivalence.sh` | the image's compiler emits the instrumentation our measurements were taken on | 3 min |
| `20-static-counts.sh` | static instrumentation per application and configuration | 5 min |
| `21-compile-time.sh <app>` | compile-time overhead, three clean builds per configuration | 20 min to 3 h (MySQL 5 to 10 h) |
| `30-preservation-suite.sh` | ThreadSanitizer's regression suite in 12 configurations: no configuration may lose a race | 25 min on 64 processors, 1 h 30 min on 32, 3 h on 8 |
| `31-preservation-apps.sh <app> 10` | races reported on an application against stock, N = 10 for a verdict | 1.5 to 3 h |
| `40-perf.sh <app>` | the performance table for one application | Redis 15 min, memcached 30, FFmpeg 25, SQLite 1 h, MySQL 3.5 h |
| `50-eviction-stress.sh` | the bounded-shadow experiments | 15 min to 1 h |
| `90-tables.sh` | regenerates the performance tables, the results ledger and the eviction tables from recorded runs | 1 min |
| `91-verify-provenance.sh` | every recorded run against its own metadata: one compiler, one processor set, one mode per leg, and the campaign's compiler hash where a claim rests on it | 2 min |
| `92-figures.sh` | the paper's presentation: one bar chart per application, our campaign with its intervals, and your own run's points beside it when you name a results directory | 1 min |

`90-tables.sh` needs nothing else to have run: with no argument it re-derives those tables from the data we
ship, which is the fastest way to check that our tables follow from our runs. Every performance script also
takes `ART_SMOKE=1`: one short run, output marked NOT A MEASUREMENT, which answers only whether the pipeline
works on your machine. `env.sh` holds every knob, `ART_RUNS=5` among them.

## If something does not work

`docs/troubleshooting.md` lists the failures we have seen, including the ones that look like our bugs and are
not: a test that waits out a two-minute timeout under stock ThreadSanitizer, a build killed for memory when
Docker's job count exceeds its memory cap, an image built before the source-tree stamp existed. `docs/confounds.md`
says what makes a performance number move on a machine that is not ours.

## Licence

The artifact's own code, documents and data are under the MIT licence (`LICENSE`). Vendored third-party
components keep their own licences, recorded in `THIRD-PARTY.md`; the LLVM patches are under Apache-2.0 with
the LLVM exception, as upstream.
