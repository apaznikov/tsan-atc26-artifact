# Our own evaluator-style runs

`CLAIMS.md` section 5 states the criterion and the condition under which a row is compared. This file is the
record behind it: every time we ran the artifact the way an evaluator runs it, on two machines, between 17 and
22 September 2026, with what each run judged. It supports no claim of its own; it exists so that a reviewer
whose own run lands a row outside its interval can see the spread we saw ourselves.

**What the default mode measured when we ran it as an evaluator would** (17-18 Sep 2026, the pushed
checkout in the container, the campaign's own 48 processors (4-27,60-83) pinned, N = 2, four configurations, nothing else on the machine;
those runs are not shipped, the figures are what the scripts printed; the Redis rows are from the run of
17 Sep 14:15, memcached and FFmpeg from the run of 17 Sep 23:07, which followed the thread-count and
shared-memory fixes and carried `input_is_reference: true`, SQLite from the run of 18 Sep 11:47):
the functional check 52 s; Redis 15 min; memcached 28 min at the rule's 48 server threads; FFmpeg 25 min
on the reference clip with all four codecs; SQLite 68 min. Seven of the eight configuration rows landed
inside our interval, both rows whose interval excludes 1.0 on the same side, and one row landed outside:

| Application | Row | Evaluator's point (N = 2) | Shipped interval (N = 5) | Verdict |
|---|---|---|---|---|
| Redis | AllOpt with peeling | 1.004 | 1.000 [0.983, 1.026] | inside |
| Redis | DynSTC | 0.968 | 0.944 [0.927, 0.970] | inside, below 1.0 like ours |
| memcached | AllOpt with peeling | 0.991 | 1.019 [0.951, 1.079] | inside |
| memcached | DynSTC | 0.983 | 0.986 [0.944, 1.063] | inside |
| FFmpeg | AllOpt with peeling | 1.017 | 1.006 [0.990, 1.024] | inside |
| FFmpeg | DynSTC | 1.127 | 1.113 [1.099, 1.129] | inside, above 1.0 like ours |
| SQLite | AllOpt with peeling | 1.078 | 1.023 [0.942, 1.061] | **outside** at N = 2, by 0.017; at N = 5, 1.041 [0.943, 1.129]: intervals overlap, inside |
| SQLite | DynSTC | 0.984 | 0.995 [0.928, 1.082] | inside; at N = 5, 1.035 [0.912, 1.111], inside |

The stock-against-native ratios of the same runs, reported and not judged, since the drift condition
governs them: Redis 8.26 against 8.01 [7.83, 8.21]; memcached 3.66 against 3.20 [2.97, 3.40] (4.66 before
the thread-count defect was fixed, so the fix closed three quarters of the gap and the rest is the size of
the documented session drift); FFmpeg 2.99 against 2.76 [2.70, 2.80]. The SQLite row that failed the
criterion at N = 2 was reported as a failure of the criterion, which was fixed before the run, and then
decided by the N = 5 run of the same leg (18 Sep, 20 cells, none disturbed): 1.041 [0.943, 1.129] against
the shipped 1.023 [0.942, 1.061], intervals overlapping and both containing 1.0, so the N = 2 point was
noise on SQLite's headline column, which this file describes above as heterogeneous (in the N = 2 run
`stress1` varied by 23 per cent between its two runs). At N = 5 the resolvable-subtest column, the
comparable one, also exists: AllOpt with peeling 1.004 [0.984, 1.032] against the shipped 0.998
[0.975, 1.013], overlapping and both containing 1.0; DynSTC 0.980 [0.945, 1.003] against the shipped
0.980 [0.966, 0.999], the same point estimate, with one nuance stated rather than rounded away: the
shipped interval excludes 1.0 by 0.001 and the evaluator's contains it by 0.003, which by the letter of
the N = 5 criterion is a mismatch and by the numbers is a knife-edge on a bound of 0.999 with identical
points. Both numbers are given so a reader sees the 0.001. A second run of the whole tier from a fresh clone on
the same set, 20 Sep 2026 (2 h 56 min: the correctness set 37 min on the 48 pinned processors, Redis 15,
memcached 27, FFmpeg 24, SQLite 73 minutes; no cell disturbed, outside busy share at most 0.014), put five
of six judged rows inside (Redis 1.015 and 0.961, the latter on the same side of 1.0; memcached 0.982 and
0.977; SQLite DynSTC 0.989) and the SQLite AllOpt row outside again at N = 2, 1.076 by 0.015, the same row
at nearly the same value as on 18 Sep, which the N = 5 run above decided; FFmpeg was not comparable there
because the reference clip is not yet downloadable and the run regenerated it. A third run the same night,
the performance subset alone from another fresh clone on the same set, every cell recording its shape (24
cores, 24 complete SMT pairs; 2 h 23 min; no cell disturbed), put four of six inside (memcached 1.017 and
0.958, Redis AllOpt 1.023, SQLite DynSTC 1.029) and two outside: SQLite AllOpt 1.063 by 0.002 and Redis DynSTC
0.984 by 0.014, on the same side of 1.0. A fourth run on 22 Sep 2026, from a fresh clone of the tree submitted,
with the 16-thread FFmpeg default and the reference clip from the release, pinned to the campaign's set, 2 h 39 min
in all (the correctness set 31 min; Redis 15, memcached 27, FFmpeg 21, SQLite 66 minutes; no cell retired): nine
rows judged, eight inside, FFmpeg's three rows at 16 threads 1.068, 1.130 and 1.186 against 1.067, 1.133 and 1.187,
and Redis DynSTC 0.979 outside by 0.009 on the same side of 1.0. That row is worth reading across every run: on
this host 0.968 (17 Sep), 0.961 and 0.984 (20 Sep) and 0.979 (22 Sep), two inside and two outside by 0.014 and
0.009; on the second host 0.971 and 0.977 (19 and 20 Sep, rows the comparator does not judge there). Every
independent observation lies between 0.961 and 0.984 against the campaign's own point of 0.944 and upper bound of
0.970, all on the cost side of 1.0: the sign and the 2 to 4 per cent band reproduce on both hosts and in every run,
and the shipped interval, one session's N = 5, is narrower than the spread between sessions. That is what an
evaluator who lands at 0.975 should read, a documented pattern and not a failure, and why an outside row is a
question and not a verdict. The two are different cases, and both are derivable from shipped data
with `harness/tools/perf/subset_spread.py`, which recomputes the headline statistic over every two-run subset
of an N = 5 leg through the aggregator's own estimator. SQLite AllOpt: over the ten two-run subsets of the
N = 5 leg of 18 Sep (shipped as `data/perf/n2-spread-sqlite-n5-20260918`, claimed for nothing) the point
ranges from 0.977 to 1.104 with median 1.028 around the leg's 1.041, and 3 of the 10 exceed the shipped bound
of 1.061; so this row reads outside for about a third of evaluators at N = 2 for reasons unrelated to their
machine (the subsets share runs, so this is within-session spread, not a probability), and our three N = 2
readings of 1.078, 1.076 and 1.063 are that spread. Redis DynSTC: the campaign's own ten two-run subsets range
from 0.926 to 0.965 (1 of 10 outside), and our three N = 2 readings of 0.968, 0.961 and 0.984 sit at or above
that maximum, so they are not the N = 2 spread: the cost of DynSTC on Redis is 2 to 4 per cent on this host
now against the campaign's 5.6, the size of change the documented between-session Redis drift (14 per cent in
the stock baseline six days apart) produces in a ratio, with the sign kept in every run. The table is generated from this
file's own interval tables and each run's `perf_<app>.md`, not transcribed, by
`harness/tools/perf/compare_with_claims.py`, which ships and is the last step of `evaluate.sh reproduced`:
one line per configuration row (the evaluator's point or interval, the shipped interval, inside or outside,
the same-side test where the shipped interval excludes 1.0), "not judged" for the stock-against-native
ratio and for a run that records no thread count, "not comparable" for a run on a non-reference clip or a
different thread count, and a count of rows judged; its exit status is 0 only when every judged row is
inside, and its silence is never a pass.

On other hardware the criterion does not apply, and a full run there says what travels. An AMD EPYC
9115 host (2 sockets of 16 cores with 2 threads each, 64 logical processors) ran the whole
`evaluate.sh reproduced` tier twice from fresh clones, on 19 and 20 Sep 2026, both times pinned to 0-47 by
the rule `evaluate.sh` had until 20 Sep (the first 48 processors the daemon grants), which on that host is
all 32 physical cores, 16 of them with both SMT threads and 16 with one: a shape the campaign (24 cores with
both threads of each) never used. N = 2, no cell disturbed, the runs not shipped. Their cells carry no
session record (the harness's session writer read an Intel-only sysfs file and failed silently there, fixed
19 Sep); the set and the pinned mode come from every cell's own `meta.json`. Judged by the comparator of
those days; since 20 Sep the tool declines a tree whose set records no shape and whose cpuset is not ours,
so it would not judge these rows today:

| Application | Row | 19 Sep (N = 2) | 20 Sep (N = 2) | Shipped interval (N = 5) | Verdict on those days |
|---|---|---|---|---|---|
| Redis | AllOpt with peeling | 1.001 | 1.018 | 1.000 [0.983, 1.026] | inside, inside |
| Redis | DynSTC | 0.971 | 0.977 | 0.944 [0.927, 0.970] | outside by 0.001 and by 0.007, both on the same side of 1.0 |
| memcached | AllOpt with peeling | 1.059 | 1.104 | 1.019 [0.951, 1.079] | inside; outside by 0.025 |
| memcached | DynSTC | 0.942 | 1.162 | 0.986 [0.944, 1.063] | outside by 0.002 below; outside by 0.099 above |
| SQLite | AllOpt with peeling | 0.944 | 1.016 | 1.023 [0.942, 1.061] | inside, inside |
| SQLite | DynSTC | 0.968 | 0.959 | 0.995 [0.928, 1.082] | inside, inside |
| FFmpeg | both rows | 0.999, 1.115 | 1.008, 1.130 | | not comparable: the clip was regenerated there |

What travels: the sign of the Redis DynSTC row on both days (below 1.0 by 2.9 and 2.3 per cent, against the
campaign's 5.6), and SQLite's "no measurable change". What does not: memcached, whose swing from 0.942 to
1.162 in a day is not the compiler. On that host every instrumented memcached run lands in one of two modes,
about 200 s (1.40 to 1.46 million operations per second) or about 230 s (1.20 to 1.25 million): on 19 Sep
stock drew one of each, AllOpt with peeling two fast, DynSTC two slow; on 20 Sep stock two slow, AllOpt one of
each, DynSTC two fast. At N = 2 a ratio there is which mode each pair drew. This is the bimodality
`docs/confounds.md` records for memcached on the earlier campaign on our host, absent from the shipped
campaign (1 to 3 per cent per configuration at N = 5) and present on this host's 32-core set; whether the
shape or the host produces it is what a run on that host's sibling-paired set (0-23,32-55, the set
`evaluate.sh` chooses there since 20 Sep) will say. The refusals are the machinery working rather than a
gap: FFmpeg is declined because that host regenerated the clip, and every stock-against-native ratio
(memcached 4.56 and 4.85 on the two days against our 3.20 [2.97, 3.40]) is reported and not judged because
the drift condition governs it. The SQLite AllOpt row was 0.909 and outside on that host's run of 18 Sep,
then 0.944 and 1.016 and inside, which is the size of the N = 2 variation on that column and the reason the
criterion asks for five runs before it is strict. Wall time there on 20 Sep: 2 h 48 min for the whole tier
(the correctness set 30 min on 64 processors; Redis 13, memcached 36, FFmpeg 20, SQLite 69 minutes).

The same host, the same night, on the campaign's shape: `evaluate.sh` now chooses the first 24 complete SMT
pairs, which there is 0-23,32-55 (24 cores with both threads, every cell recording it), and the whole tier ran
again from a fresh clone (2 h 49 min). The comparator judged six rows: memcached inside on both (1.016 and
0.983), Redis inside on both (0.986; DynSTC 0.939, on the same side of 1.0, a cost of 6.1 per cent against the
campaign's 5.6), SQLite outside on both (AllOpt 0.913 by 0.029 below, DynSTC 1.123 by 0.041 above). Two things
follow. The memcached two-mode behaviour above was the shape, not the host: on the paired set all eight
instrumented runs landed in the fast mode (194 to 207 s, 1.37 to 1.49 million operations per second) and both
rows fell inside, where on the 32-core set the pairs had split between the modes on two days running. And
SQLite's headline column is wide on that host at N = 2 in either direction (0.909, 0.944, 1.016 and 0.913 for
AllOpt over four runs; 0.851, 0.968, 0.959 and 1.123 for DynSTC), wider than on ours, so on that host the row
is one that only an N = 5 run can decide; the resolvable-subtest column, which the shipped tables carry, is
the one to read there.

Eight of nine inside on this host, three of nine on the second. What the second host's outside rows are is the
next paragraph, and the reading rule they establish is this: when several judged rows of one application fall
outside on the same side in one run, suspect the shared denominator before the configurations. The check is each
configuration's own slowdown against native, the column the table already prints, and native being unchanged is
what tells a moved baseline from a slower machine. A ratio of cell wall times is not that check and is not quoted:
it weights an application's subtests by their duration where the headline weights them equally, and on Redis it
reads 4.07 where the table reads 8.01.

The same host again on 22 Sep 2026, the tree of the day (`8e63965`, the 16-thread FFmpeg default, the release
clip), the set chosen by the script (0-23,32-55, the campaign's shape), no cell retired, 2 h 39 min: nine rows
judged, three inside and six outside (the table above). Which side moved, read in the headline estimator from
that run's own summary table, slowdown against native: stock ThreadSanitizer 8.54 on 20 Sep and 9.59 on 22 Sep,
DynSTC 9.09 and 9.00, AllOpt with peeling 8.66 and 8.55. Stock is the only configuration that moved, by 12.3 per
cent, and the four printed ratios follow from those six numbers exactly (8.54/9.09 = 0.939, 9.59/9.00 = 1.066,
8.54/8.66 = 0.986, 9.59/8.55 = 1.121). So both of that host's outside Redis rows are one baseline event rather than
two configuration effects, and DynSTC took the same time on both nights; the static instrumentation counts are
identical across every run on that host and equal to ours (37 922 sites under stock, 37 863 under DynSTC), so the
same program was measured. FFmpeg's two AllOpt rows
2 to 3 points below theirs on the same side of 1.0 (1.024 against [1.050, 1.079]; 1.155 against [1.171, 1.201]);
Redis 10 points above on both (AllOpt with peeling 1.121; DynSTC 1.066, on the gain side, where the same host
and set read 0.939 two days earlier); SQLite 4 to 5 points above (1.113 and 1.122, where the same host read
0.913 and 1.123 two days earlier). So on that host an N = 2 point on Redis or SQLite moves by ten to twenty
points between days, in either direction, and the Redis DynSTC row has now been on both sides of 1.0 there;
what holds across every run on both hosts is FFmpeg's DynSTC gain (1.11 to 1.13 everywhere) and memcached's
rows. The intervals in this file describe our host; a second machine of the same shape is judged by the tool,
as this one was, and what its outside rows mean is this paragraph, not a verdict on the compiler.
