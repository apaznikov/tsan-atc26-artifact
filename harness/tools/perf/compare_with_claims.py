#!/usr/bin/env python3
"""compare_with_claims.py — did your run reproduce ours?

    compare_with_claims.py CLAIMS.md results/perf-redis-20260918-120000 [more trees...]

For every configuration row the artifact claims, prints your value, our shipped interval, and a verdict.
Exits 0 when every JUDGED row is inside and every tree could be compared, 1 otherwise, 2 on a usage error.

WHAT IS AND IS NOT JUDGED, because a verdict on a row that cannot be compared is worse than no verdict:

  not judged      the stock-against-native ratio. Byte-identical binaries on this host differed by 14%
                  in throughput six days apart (docs/confounds.md), which is wider than the interval we
                  print for it, so an evaluator lands outside it routinely and it means nothing.
  not comparable  the run's workload differs from the campaign's -- a thread count other than ours, or
                  an FFmpeg clip that is not the reference one. A row that agrees at the wrong thread
                  count is worse than one that disagrees, because it looks like agreement.
  no verdict      fewer than two runs. N=1 is not a measurement and the artifact says so elsewhere.

THE EXPECTED THREAD COUNT IS READ FROM OUR SHIPPED DATA, never hardcoded here: a constant in this file
would rot the moment the campaign's parameters changed, and the shipped meta.json is the record.
"""
import glob, json, math, os, re, sys

def claims_rows(path):
    """{app: {row: (point, lo, hi)}} from CLAIMS.md's own tables, so the two cannot drift apart."""
    out, app, cols = {}, None, None
    for line in open(path, encoding="utf-8"):
        m = re.match(r"^### (\w+)", line)
        if m:
            app = m.group(1).lower(); out.setdefault(app, {}); cols = None
        if app is None:
            continue
        m = re.search(r"Stock ThreadSanitizer against native:\s*([\d.]+)x?\s*\[([\d.]+),\s*([\d.]+)\]", line)
        if m:
            out[app]["stock vs native"] = tuple(float(x) for x in m.groups())
        if line.startswith("| Configuration |"):
            cols = [c.strip() for c in line.strip().strip("|").split("|")]; continue
        if cols and line.startswith("|"):
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cells) != len(cols) or "All five runs [95%]" not in cols:
                continue
            m = re.search(r"([\d.]+)\s*\[([\d.]+),\s*([\d.]+)\]", cells[cols.index("All five runs [95%]")])
            if m:
                out[app][cells[0]] = tuple(float(x) for x in m.groups())
    return out

LABEL = {"tsan-dom_peeling-ea-lo-st-swmr": "AllOpt with peeling", "tsan-stmt": "DynSTC",
         "tsan-dom-ea-lo-st-swmr": "AllOpt without peeling", "tsan-ea": "EA", "tsan-lo": "LO",
         "tsan-st": "STC", "tsan-swmr": "SWMR", "tsan-dom": "DE", "tsan-dom_peeling": "DE + peeling",
         # The three rows that were silently never judged until 19 Sep 2026 (no label, so `continue`).
         "tsan-dom_peeling-ea-lo-st-swmr-stmt": "AllOpt with peeling and DynSTC",
         "tsan-dom_peeling-ea-lo-st-swmr-wp": "AllOpt with peeling, whole-program summaries",
         "tsan-sound-wp": "four sound analyses, whole-program summaries"}

def expected_threads(root, app):
    """Our campaign's thread count for this application, from the shipped data. None if not shipped."""
    for m in sorted(glob.glob(os.path.join(root, "data", "perf", "campaign-*", "primary", app, "*", "run*", "meta.json"))):
        try:
            v = json.load(open(m)).get("threads_setting")
        except Exception:
            continue
        if v not in (None, ""):
            return str(v)
    return None

def reference_input_sha(root, app):
    """The input hash our shipped campaign cells record for this application, from the data, never a constant."""
    for m in sorted(glob.glob(os.path.join(root, "data", "perf", "campaign-*", "primary", app, "*", "run*", "meta.json"))):
        try:
            v = json.load(open(m)).get("input_sha256")
        except Exception:
            continue
        if v:
            return v
    return None

def expected_shape(root):
    """Our campaign's processor-set SHAPE, from the shipped data. None if not shipped.

    Read from data/perf/campaign-*/shape.json rather than derived: the shape of a cpuset depends on the
    topology of the machine it ran on, so an evaluator computing the sibling structure of "4-27,60-83"
    would get THEIR machine's answer and not ours. Cells recorded from 2026-09-20 carry the two numbers
    themselves; the campaign's predate that, which is why the file exists."""
    for f in sorted(glob.glob(os.path.join(root, "data", "perf", "campaign-*", "shape.json"))):
        try:
            j = json.load(open(f))
            if j.get("n_physical_cores"):
                return j["n_physical_cores"], j.get("smt_pairs_complete"), j.get("cpuset")
        except Exception:
            continue
    return None

def run_cpuset(tree, app):
    for m in sorted(glob.glob(os.path.join(tree, app, "*", "run*", "meta.json"))):
        try:
            c = json.load(open(m)).get("cpuset")
        except Exception:
            continue
        if c: return c
    return None

def run_shape(tree, app):
    """The run's own shape, from its cells. None when the run predates the recording."""
    for m in sorted(glob.glob(os.path.join(tree, app, "*", "run*", "meta.json"))):
        try:
            j = json.load(open(m))
        except Exception:
            continue
        if j.get("n_physical_cores"):
            return j["n_physical_cores"], j.get("smt_pairs_complete")
    return None

def run_facts(tree, app, ref_sha=None):
    """N, the effective thread count, and whether FFmpeg ran on the reference clip: the recorded flag, or,
    where a run predates the flag (our own campaign's FFmpeg cells), its recorded input hash equal to the
    hash the shipped campaign records."""
    n, threads, isref = 0, None, None
    for m in sorted(glob.glob(os.path.join(tree, app, "*", "run*", "meta.json"))):
        try:
            j = json.load(open(m))
        except Exception:
            continue
        if j.get("rc") != 0 or j.get("disturbed"):
            continue
        n += 1
        if threads is None and j.get("threads_setting") not in (None, ""):
            threads = str(j["threads_setting"])
        if isref is None and j.get("input_is_reference") is not None:
            isref = bool(j["input_is_reference"])
        elif isref is None and ref_sha and j.get("input_sha256"):
            isref = (j["input_sha256"] == ref_sha)
    per_cfg = len({os.path.basename(os.path.dirname(os.path.dirname(m)))
                   for m in glob.glob(os.path.join(tree, app, "*", "run*", "meta.json"))}) or 1
    return max(1, n // per_cfg), threads, isref

def parse_table(tree, app):
    """{row_label: (point, interval or None, N of that row or None)} from the run's own perf_<app>.md summary table.
    N is the row's own (column 3): a tree-wide N derived from clean runs over configurations read one
    disturbed cell in one configuration as N = 1 for every row of the application (found 19 Sep 2026)."""
    p = os.path.join(tree, f"perf_{app}.md")
    if not os.path.exists(p):
        return None
    out = {}
    for line in open(p, encoding="utf-8"):
        if not line.startswith("| "):
            continue
        c = [x.strip() for x in line.strip().strip("|").split("|")]
        if len(c) < 8:
            continue
        cfg = c[0]
        m = re.match(r"([\d.]+)(?:\s*\[([\d.]+),\s*([\d.]+)\])?", c[3])
        if not m:
            continue
        pt = float(m.group(1))
        iv = (float(m.group(2)), float(m.group(3))) if m.group(2) else None
        mn = re.match(r"(\d+)$", c[2])
        nrow = int(mn.group(1)) if mn else None
        if cfg == "orig":
            out["stock vs native"] = (pt, iv, nrow)
        elif cfg in LABEL:
            out[LABEL[cfg]] = (pt, iv, nrow)
    return out

def main():
    if len(sys.argv) < 3:
        print(__doc__.strip()); return 2
    claims_path, trees = sys.argv[1], sys.argv[2:]
    root = os.path.dirname(os.path.abspath(claims_path))
    claims = claims_rows(claims_path)
    outside = judged = unjudged = 0
    print(f"{'app':10} {'row':24} {'yours':>22}  {'ours (N=5)':22} verdict")
    print("-" * 100)
    for tree in trees:
        app = next((a for a in claims if f"perf-{a}-" in os.path.basename(tree.rstrip("/"))), None)
        if app is None:
            print(f"{os.path.basename(tree):10} {'-':24} {'':>22}  {'':22} cannot tell which application"); unjudged += 1; continue
        rows = parse_table(tree, app)
        if not rows:
            print(f"{app:10} {'-':24} {'':>22}  {'':22} NO TABLE (the leg produced none)"); unjudged += 1; continue
        n, threads, isref = run_facts(tree, app, reference_input_sha(root, app))
        want = expected_threads(root, app)
        # A MISSING THREAD COUNT IS NOT A MATCHING ONE. Runs made before the harness recorded the
        # EFFECTIVE thread count wrote an empty field, and reading that as "comparable" is the same
        # mistake this whole file exists to prevent -- the absence and the pass sharing a channel. If
        # we know what ours was and the run does not say what its was, we decline to judge it.
        # FOUR COMBINATIONS, NOT TWO. `want` being absent means either "this application has no thread
        # knob" (redis and sqlite record nothing, and nothing is the right answer for both sides) or "the
        # shipped campaign data is missing", and those need opposite treatment. Collapsing them was the
        # same absence-as-a-match bug one level up: with no shipped data every row would have been judged
        # with no comparability check at all, silently.
        # SHAPE BEFORE THREADS. A set of the same SIZE but a different shape is a different machine --
        # 48 logical processors are 24 cores with both SMT siblings on our host and can be 48 separate
        # cores elsewhere, twice the compute with no sibling contention -- and comparing across that is
        # meaningless however well the thread counts agree. (2026-09-20.)
        # Graduated, because refusing every run made before the shape was recorded would discard our own
        # rehearsal evidence, which WAS measured on the campaign's set. Strongest basis available wins,
        # and the weaker one says so: a matching cpuset STRING is only evidence of a matching shape on the
        # same host, since the sibling structure of "4-27,60-83" is a property of the machine.
        # THE SHAPE DECISION IS ITS OWN CHAIN, NOT THE HEAD OF THIS ONE. Folding it in as leading `elif`s
        # meant the row-three case -- shape unrecorded, cpuset ours -- SATISFIED the chain and stopped it,
        # so the thread and clip checks below were never reached: FFmpeg rows on a REGENERATED clip were
        # judged IN/OUT although every cell said input_is_reference false. A guard that silently disables
        # the guards after it is worse than the bug it was added for. (Found by tsan-paper running the
        # vendored copy on real trees before committing, 2026-09-20.)
        ours_shape, mine_shape = expected_shape(root), run_shape(tree, app)
        why = None; basis = None
        if ours_shape and mine_shape and ours_shape[:2] != mine_shape:
            why = (f"not comparable: {mine_shape[0]} physical cores, {mine_shape[1]} full SMT pairs; "
                   f"ours {ours_shape[0]} and {ours_shape[1]}")
        elif ours_shape and not mine_shape:
            mine_cs = run_cpuset(tree, app)
            if mine_cs and ours_shape[2] and mine_cs == ours_shape[2]:
                basis = (f"shape not recorded (cells predate 2026-09-20); matched on cpuset {mine_cs}, "
                         "which is our shape only if this is the same host")
            else:
                why = (f"not judged: no processor-set shape recorded and cpuset {mine_cs or 'unknown'!s} "
                       f"is not ours ({ours_shape[2]})")
        # Every remaining condition is still evaluated when the shape did not already refuse the tree.
        if why is not None:
            pass
        elif threads and want and threads != want:
            why = f"not comparable: {threads} threads, ours {want}"
        elif want and not threads:
            why = "not judged: this run records no effective thread count"
        elif threads and not want:
            why = ("not judged: no shipped campaign data to compare the thread count with "
                   f"(looked in {os.path.join(root, 'data', 'perf')})")
        elif app == "ffmpeg" and isref is not True:
            # An absent flag is not the reference clip: the same absence-as-a-match shape as above.
            why = ("not comparable: not the reference clip" if isref is False
                   else "not judged: the run does not record whether its clip is the reference")
        # EVERY TREE MUST PRODUCE A LINE. If CLAIMS's column header or a row label drifts for ONE
        # application while the others parse, this loop simply does not execute for it: nothing is
        # printed, nothing is judged, and the summary still reports success on the other applications.
        # Silence for a tree the caller explicitly named is the same failure as silence overall, and the
        # all-or-nothing guard below does not catch it. (Audit, 2026-09-19.)
        printed = 0
        for row, ours in sorted(claims.get(app, {}).items()):
            if row not in rows:
                continue
            printed += 1
            pt, iv, nrow = rows[row]
            n_here = nrow or n
            yours = f"{pt:.3f} [{iv[0]:.3f}, {iv[1]:.3f}]" if iv else f"{pt:.3f} (N={n_here})"
            shipped = f"{ours[0]:.3f} [{ours[1]:.3f}, {ours[2]:.3f}]"
            if row == "stock vs native":
                v = "not judged (session drift is wider than this interval)"
            elif n_here < 2:
                v = "no verdict (N<2 is not a measurement)"
            elif why:
                v = why
            else:
                judged += 1
                if iv:
                    # The N = 5 rule of CLAIMS.md section 5: the intervals overlap, and both contain 1.0 or
                    # neither does. Until 19 Sep 2026 the point-in-interval rule was applied at every N, which
                    # failed an overlapping N = 5 interval whose point lay outside ours.
                    overlap = iv[0] <= ours[2] and ours[1] <= iv[1]
                    agree = (iv[0] <= 1.0 <= iv[1]) == (ours[1] <= 1.0 <= ours[2])
                    inside = overlap and agree
                    if inside:
                        v = "IN (intervals overlap)"
                    elif not overlap:
                        v = f"OUT: intervals do not overlap (gap {max(iv[0] - ours[2], ours[1] - iv[1]):.3f})"
                    else:
                        v = "OUT: one interval contains 1.0 and the other does not"
                else:
                    inside = ours[1] <= pt <= ours[2]
                    if inside:
                        v = "IN "
                    else:
                        # The distance, so a reader sees a thousandth for what it is without computing it.
                        v = f"OUT by {ours[1] - pt:.3f} below" if pt < ours[1] else f"OUT by {pt - ours[2]:.3f} above"
                if not inside:
                    outside += 1
                if ours[1] > 1.0 or ours[2] < 1.0:
                    same = (pt > 1.0) == (ours[0] > 1.0)
                    v += ", same side of 1.0" if same else ", WRONG SIDE OF 1.0"
                    if not same and inside:
                        outside += 1
            print(f"{app:10} {row:24} {yours:>22}  {shipped:22} {v}")
        if basis and printed:
            print(f"{'':10}   basis: {basis}")
        missing = [r for r in claims.get(app, {}) if r not in rows]
        if printed and missing:
            print(f"{app:10} {len(missing)} of {len(claims[app])} rows CLAIMS.md ships for this application were not produced by this run"
                  + (" (the default four-configuration subset)" if len(rows) <= 3 else "") + "; nothing is judged for them.")
        if not printed:
            cl = sorted(claims.get(app, {})) or ["(none parsed from CLAIMS.md)"]
            rn = sorted(rows) or ["(none parsed from the run's table)"]
            print(f"{app:10} {'-':24} {'':>22}  {'':22} TABLES COULD NOT BE MATCHED")
            print(f"{'':10}   CLAIMS.md offers: {', '.join(cl)}")
            print(f"{'':10}   the run offers:   {', '.join(rn)}")
            print(f"{'':10}   no row name appears on both sides, so nothing could be compared.")
            unjudged += 1
    print("-" * 100)
    if judged:
        # Two counts, not one: a judged row outside its interval and a tree that could not be compared at
        # all are different failures, and "2 not inside" once counted both (found by the reviewer
        # walkthrough, 19 Sep 2026).
        print(f"{judged} rows judged, {outside} outside their intervals"
              + (f"; {unjudged} tree(s) could not be compared at all (see above)." if unjudged else "."))
    else:
        # NOTHING JUDGED IS NOT A PASS, and this file said so in its own docstring while returning 0 for
        # it: "0 judged, 0 not inside" and "all judged, none outside" shared an exit code, so a run in
        # which every row was not-comparable reported PASS to evaluate.sh. The rule the file exists to
        # enforce, broken by the file. (Found by the three-agent audit, 2026-09-19.)
        print("NO ROWS COULD BE JUDGED — this is not a pass. Nothing above was compared with the shipped")
        print("intervals; read the reasons on each line (not comparable, no table, no verdict below N=2,")
        print("no shipped campaign data) and fix the cause before reading any number as reproduction.")
    return 1 if (outside or unjudged or not judged) else 0

if __name__ == "__main__":
    sys.exit(main())
