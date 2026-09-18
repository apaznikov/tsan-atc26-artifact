#!/usr/bin/env python3
"""cpu_snapshot.py <cpuset> — busy jiffies inside and outside the cpuset, plus the two CPU counts.

Prints "inside_busy outside_busy n_inside n_outside".  Busy = all /proc/stat fields except idle and iowait.
The benchmark is pinned to the cpuset, so nothing of ours ever runs outside it: the busy time on the outside
CPUs is foreign by construction and is the disturbance signal, independent of how well we account for our own
processes (a server started outside the timed region, a benchmark that daemonises, ...).
"""
import sys

def expand(s):
    out = set()
    for part in s.split(","):
        if "-" in part:
            a, b = part.split("-"); out.update(range(int(a), int(b) + 1))
        elif part:
            out.add(int(part))
    return out

inside = expand(sys.argv[1])
# AN EMPTY CPUSET IS "UNPINNED", NOT "EVERY CPU IS FOREIGN". With no pinned set the benchmark runs
# everywhere, so there is no region where nothing of ours can run and no foreign signal to read. Treating
# the empty set literally put every CPU on the outside, and the outside busy share then measured OUR OWN
# workload: on a machine small enough for the benchmark to fill it, every run exceeded the threshold, was
# re-run once, failed again, and the leg produced no data after paying twice for it. Everything inside and
# nothing outside is what docs/confounds.md already describes -- outside_busy_share null, gate_checked
# false -- and it is what the downstream `if n_outside > 0` tests were written for.
ALL_INSIDE = not sys.argv[1].strip()
# CPUs deliberately given to our own background work (a long compile parked off the benchmark set) are
# neither "ours" for this run nor foreign disturbance: excluded from both sides so the outside busy share
# keeps measuring other people's load.  Source: $P5_IGNORE_CPUS, else the file "ignore_cpus" next to this
# script, else nothing.
import os
ig = os.environ.get("P5_IGNORE_CPUS")
if ig is None:
    f = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ignore_cpus")
    # Comments and blank lines are stripped, so the shipped file can explain itself and still default to
    # EMPTY. It used to ship this lab's reserved processors (52-55,108-111) as the default, which on an
    # evaluator's machine silently removed eight processors from the disturbance accounting -- the gate
    # quietly not watching part of the machine it was asked to watch. (Audit, 2026-09-19.)
    ig = ""
    if os.path.exists(f):
        ig = ",".join(l.split("#", 1)[0].strip() for l in open(f) if l.split("#", 1)[0].strip())
ignored = expand(ig) if ig else set()
inside -= ignored
bi = bo = ni = no = 0
for line in open("/proc/stat"):
    f = line.split()
    if not f[0].startswith("cpu") or f[0] == "cpu":
        continue
    n = int(f[0][3:]); v = [int(x) for x in f[1:]]
    busy = v[0] + v[1] + v[2] + sum(v[5:])          # user+nice+system+irq+softirq+steal+guest*; skip idle, iowait
    if n in ignored: continue
    if ALL_INSIDE or n in inside: bi += busy; ni += 1
    else: bo += busy; no += 1
print(bi, bo, ni, no)
