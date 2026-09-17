#!/usr/bin/env python3
"""preservation_verdict.py — comparative LOST/UNDETERMINED/KEPT verdict on the evaluator's OWN runs.

WHY THIS EXISTS. The shipped claim was "the union of races over 10 runs is the set stock reports (5 sites)".
A reviewer asked whether that is guaranteed or whether they could be unlucky, and it is NOT guaranteed:
race detection is stochastic, so a site stock finds in 7 runs of 10 here may appear in 4 of theirs, or in
none, without anything being wrong with the compiler. A fixed expected set is therefore the wrong criterion
for someone else's machine. The five sites are OUR OBSERVATION; the criterion has to be comparative and
computed from the runs the evaluator actually got.

THE RULE, per site, with k_s stock's count and k_c the configuration's out of N runs:

  KEPT            k_c >= 1                     the configuration found it. Stock's frequency is irrelevant
                                               to that: finding it once demonstrates it can be found.
  LOST            k_c = 0 and k_s = N          stock always, the configuration never. The only failure,
                                               and the only shape detection noise cannot produce.
  UNDETERMINED    k_c = 0 and 0 < k_s < N      stock sometimes, the configuration never. More runs needed.
  ONLY-OPTIMIZED  k_c >= 1 and k_s = 0         the configuration reports a site stock never did. Not a
                                               loss; labelled rather than dropped, since the eviction
                                               effect can produce exactly this.

An earlier draft keyed UNDETERMINED on stock's frequency ALONE, so a site stock reported 8 times in 10 and
the configuration 7 times in 10 came back UNDETERMINED. That rule can never say KEPT on any workload whose
detection is schedule-dependent, and **a check that cannot certify anything is not conservative, it is
uninformative**. Stock's frequency matters only when the configuration reports nothing, where it is what
separates a loss from an unlucky schedule. (tsan-paper, 2026-09-16.)

Exit status: non-zero ONLY if some site is LOST. UNDETERMINED never fails the run — a criterion that
fails on noise would fail on a good compiler, and a reviewer cannot tell those apart from the exit code.
"""
import argparse, os, sys, importlib.util

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("tsan_reports", os.path.join(HERE, "tsan_reports.py"))
TR = importlib.util.module_from_spec(spec); sys.modules["tsan_reports"] = TR; spec.loader.exec_module(TR)

LEVELS = {"l1": "union_l1", "l2": "union_l2", "l3": "union_l3"}

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--results-dir", required=True, help="the runner's logs/ directory")
    ap.add_argument("--app")
    ap.add_argument("--baseline", default="tsan", help="the stock configuration (default: tsan)")
    ap.add_argument("--level", default="l3", choices=sorted(LEVELS),
                    help="matching level that gates the exit code (default l3: same location and writer, "
                         "which answers 'is the race on this location still found'); all three are printed")
    a = ap.parse_args()

    runs = TR.collect_runs(a.results_dir, a.app, None)
    by_cfg = {}
    for (_, cfg, _), rr in sorted(runs.items()):
        by_cfg.setdefault(cfg, []).append(rr)
    if a.baseline not in by_cfg:
        sys.exit(f"baseline {a.baseline!r} not among configurations: {sorted(by_cfg)}")
    summ = {cfg: TR.summarize_cfg(cfg, rs, None) for cfg, rs in by_cfg.items()}
    base = summ[a.baseline]
    others = [c for c in sorted(summ) if c != a.baseline]

    print(f"preservation verdict — baseline {a.baseline}, N={base.nruns} runs per configuration")
    print(f"gating level: {a.level.upper()}   (verdicts printed at all three)\n")

    any_lost = False; vacuous = False
    for lvl in ("l1", "l2", "l3"):
        bu = getattr(base, LEVELS[lvl])
        print(f"=== {lvl.upper()} ===")
        if not bu:
            print("  the baseline reported NO sites at this level. That is not a pass: a run in which stock")
            print("  finds nothing cannot show that anything was preserved. Check the workload and the build.\n")
            if lvl == a.level: vacuous = True        # fails, like a control that never fires
            continue
        hdr = f"  {'site':60s} {a.baseline:>8s}"
        for c in others: hdr += f" {c[:14]:>15s}"
        print(hdr + "   verdict")
        # every key ANY configuration reported, so ONLY-OPTIMIZED sites appear in the table rather than as
        # a footnote: a site stock never found is a result about the configuration, not a stray.
        allkeys = set(bu)
        for c in others: allkeys |= set(getattr(summ[c], LEVELS[lvl]))
        for key in sorted(allkeys, key=lambda k: (-bu.get(k, 0), k)):
            kb = bu.get(key, 0)
            row = f"  {key[:60]:60s} {kb:>4d}/{base.nruns:<3d}"
            verdicts = []
            for c in others:
                ko = getattr(summ[c], LEVELS[lvl]).get(key, 0)
                row += f" {ko:>6d}/{summ[c].nruns:<8d}"
                if ko >= 1:                        verdicts.append("KEPT" if kb >= 1 else "ONLY-OPTIMIZED")
                elif kb == base.nruns:             verdicts.append("LOST")
                else:                              verdicts.append("UNDETERMINED")
            # worst outcome across configurations decides the printed verdict
            v = ("LOST" if "LOST" in verdicts else
                 "UNDETERMINED" if "UNDETERMINED" in verdicts else
                 "ONLY-OPTIMIZED" if "ONLY-OPTIMIZED" in verdicts else "KEPT")
            if v == "LOST" and lvl == a.level: any_lost = True
            print(row + f"   {v}")
        print()

    # The two failure causes are reported separately. An earlier draft routed the vacuous baseline through
    # the LOST message, so a run in which stock found nothing at all was reported as a lost race — the same
    # class of misattribution as a watchdog reporting "low memory" for something that is not memory.
    if vacuous:
        print("RESULT: the baseline reported NOTHING at the gating level, so this run certifies nothing.")
        print("No site was LOST; there was no evidence either way. Check the workload, the build and that")
        print("reporting is enabled before reading any other row.")
        return 1
    if any_lost:
        print("RESULT: at least one site is LOST at the gating level — stock reported it in every run and the")
        print("configuration in none. That is the shape detection noise cannot produce.")
        return 1
    bu = getattr(base, LEVELS[a.level])
    und = 0
    for key, kb in bu.items():
        if any(getattr(summ[c], LEVELS[a.level]).get(key, 0) == 0 for c in others) and kb < base.nruns:
            und += 1
    print("RESULT: no site LOST.")
    if und:
        print(f"{und} site(s) UNDETERMINED at N={base.nruns}: no configuration reported them at all and stock")
        print("itself did not report them in every run, so this N cannot separate a loss from stock's own")
        print("detection noise. Raise --runs to narrow it.")
    return 0

sys.exit(main())
