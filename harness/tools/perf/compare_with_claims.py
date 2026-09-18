#!/usr/bin/env python3
"""compare_with_claims.py — did your run reproduce ours?

    compare_with_claims.py CLAIMS.md results/perf-redis-20260918-120000 [more trees...]

For every configuration row the artifact claims, prints your value, our shipped interval, and a verdict.
Exits 0 when every JUDGED row is inside, 1 otherwise, 2 on a usage error.

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
         "tsan-st": "STC", "tsan-swmr": "SWMR", "tsan-dom": "DE", "tsan-dom_peeling": "DE + peeling"}

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

def run_facts(tree, app):
    """N, the effective thread count, and whether FFmpeg ran on the reference clip."""
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
    per_cfg = len({os.path.basename(os.path.dirname(os.path.dirname(m)))
                   for m in glob.glob(os.path.join(tree, app, "*", "run*", "meta.json"))}) or 1
    return max(1, n // per_cfg), threads, isref

def parse_table(tree, app):
    """{row_label: (point, lo, hi or None)} from the run's own perf_<app>.md summary table."""
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
        if cfg == "orig":
            out["stock vs native"] = (pt, iv)
        elif cfg in LABEL:
            out[LABEL[cfg]] = (pt, iv)
    return out

def main():
    if len(sys.argv) < 3:
        print(__doc__.strip()); return 2
    claims_path, trees = sys.argv[1], sys.argv[2:]
    root = os.path.dirname(os.path.abspath(claims_path))
    claims = claims_rows(claims_path)
    bad = judged = 0
    print(f"{'app':10} {'row':24} {'yours':>22}  {'ours (N=5)':22} verdict")
    print("-" * 100)
    for tree in trees:
        app = next((a for a in claims if f"perf-{a}-" in os.path.basename(tree.rstrip("/"))), None)
        if app is None:
            print(f"{os.path.basename(tree):10} {'-':24} {'':>22}  {'':22} cannot tell which application"); bad += 1; continue
        rows = parse_table(tree, app)
        if not rows:
            print(f"{app:10} {'-':24} {'':>22}  {'':22} NO TABLE (the leg produced none)"); bad += 1; continue
        n, threads, isref = run_facts(tree, app)
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
        why = None
        if threads and want and threads != want:
            why = f"not comparable: {threads} threads, ours {want}"
        elif want and not threads:
            why = "not judged: this run records no effective thread count"
        elif threads and not want:
            why = ("not judged: no shipped campaign data to compare the thread count with "
                   f"(looked in {os.path.join(root, 'data', 'perf')})")
        elif isref is False:
            why = "not comparable: not the reference clip"
        for row, ours in sorted(claims.get(app, {}).items()):
            if row not in rows:
                continue
            pt, iv = rows[row]
            yours = f"{pt:.3f} [{iv[0]:.3f}, {iv[1]:.3f}]" if iv else f"{pt:.3f} (N={n})"
            shipped = f"{ours[0]:.3f} [{ours[1]:.3f}, {ours[2]:.3f}]"
            if row == "stock vs native":
                v = "not judged (session drift is wider than this interval)"
            elif n < 2:
                v = "no verdict (N<2 is not a measurement)"
            elif why:
                v = why
            else:
                judged += 1
                inside = ours[1] <= pt <= ours[2]
                v = "IN " if inside else "OUT"
                if not inside:
                    bad += 1
                if ours[1] > 1.0 or ours[2] < 1.0:
                    same = (pt > 1.0) == (ours[0] > 1.0)
                    v += ", same side of 1.0" if same else ", WRONG SIDE OF 1.0"
                    if not same and inside:
                        bad += 1
            print(f"{app:10} {row:24} {yours:>22}  {shipped:22} {v}")
    print("-" * 100)
    if judged:
        print(f"{judged} rows judged, {bad} not inside.")
    else:
        # NOTHING JUDGED IS NOT A PASS, and this file said so in its own docstring while returning 0 for
        # it: "0 judged, 0 not inside" and "all judged, none outside" shared an exit code, so a run in
        # which every row was not-comparable reported PASS to evaluate.sh. The rule the file exists to
        # enforce, broken by the file. (Found by the three-agent audit, 2026-09-19.)
        print("NO ROWS COULD BE JUDGED — this is not a pass. Nothing above was compared with the shipped")
        print("intervals; read the reasons on each line (not comparable, no table, no verdict below N=2,")
        print("no shipped campaign data) and fix the cause before reading any number as reproduction.")
    return 1 if (bad or not judged) else 0

if __name__ == "__main__":
    sys.exit(main())
