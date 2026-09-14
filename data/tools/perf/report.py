#!/usr/bin/env python3
"""report.py <out.html> [--lang en|ru] — the P5 campaign's results report, from the measured data.

Every figure and every table cell is computed here from the results trees, never transcribed, so the report
cannot drift from what was measured. The statistics come from aggregate.py itself (same geomean, same ratio
direction, same bootstrap with the same seed), so a number here that disagreed with perf_summary.md would be a
bug in one of them rather than two defensible answers.

    python3 report.py /tmp/report.html
    python3 report.py /tmp/otchet.html --lang ru
"""
import os, sys, json, csv, math, glob, re, importlib.util, statistics as st
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("agg", os.path.join(HERE, "aggregate.py"))
A = importlib.util.module_from_spec(spec); sys.modules["agg"] = A; spec.loader.exec_module(A)

STAGEB = os.path.join(HERE, "results", "stageB-d3bf9f8c39fe")
YIELD  = os.path.join(HERE, "results", "yield-d98873cda906")
STAGEA = os.path.join(HERE, "results", "2026-09-04-729521af8965")
APPS   = ["memcached", "redis", "sqlite", "ffmpeg", "mysql"]
SERIES = {"memcached": "mc", "redis": "rd", "sqlite": "sq", "ffmpeg": "ff", "mysql": "my"}

# Figure and table wording, per language. The prose lives in TEMPLATES at the bottom; only the strings that
# are drawn into an SVG or a table header need to be reachable from the building code, and they live here so
# a translation never has to touch the code that computes a number.
LANG = "en"
STR = {
    "en": dict(
        ax_speedup="speedup against stock TSan", ax_speedup_short="speedup",
        grp_app="{app}   ({n} configurations, N = {N})",
        note_forest="filled = interval excludes 1.0; hollow tone = crosses it",
        ax_reach="memory-access sites removed against stock TSan (%)",
        grp_dynstc="dynamic single-threading, per application",
        grp_repl="FFmpeg, dynamic single-threading against stock TSan",
        sfx_resolvable_subtests="  (resolvable subtests)", sfx_resolvable="  (resolvable)",
        stage_a="  · Stage A", stage_b="  · Stage B",
        repl_b="Stage B compiler  d3bf9f8c39fe",
        repl_yon="yield compiler  d98873cda906, changes on",
        repl_yoff="yield compiler  d98873cda906, changes off",
        flag_mc=" ⚠ memtier short-iteration artefact", flag_ff=" ⚠ thread-count setting",
        band_row="{lo:.2f} – {hi:.2f}   (n = {n})",
        th_app="application", th_cfg="configuration", th_n="N", th_su="speedup [95 %]",
        th_basis="basis", th_stable="resolvable subtests", th_reach="sites removed",
        th_native="native against stock TSan", th_band="outside-CPU busy share", th_runs="runs",
        th_reldur="median relative duration", th_ypair="yield on against off [95 %]",
        th_ydelta="static delta",
        basis_all="all tests", basis_stable="resolvable subtests",
        u_pp=" pp", u_pct=" %", u_x="×",
        aria_forest="Speedup with 95% intervals, by application", aria_bars="bar chart",
        page_title="TSan Optimisation Re-measurement", aria_scatter="{x} against {y}",
    ),
    "ru": dict(
        ax_speedup="ускорение относительно штатного TSan", ax_speedup_short="ускорение",
        grp_app="{app}   ({n} конфигураций, N = {N})",
        note_forest="залитая точка — интервал не пересекает 1.0; полая — пересекает",
        ax_reach="удалено точек доступа к памяти относительно штатного TSan (%)",
        grp_dynstc="динамическое определение однопоточности, по приложениям",
        grp_repl="FFmpeg, динамическая однопоточность относительно штатного TSan",
        sfx_resolvable_subtests="  (разрешимые подтесты)", sfx_resolvable="  (разрешимые)",
        stage_a="  · этап A", stage_b="  · этап B",
        repl_b="компилятор этапа B  d3bf9f8c39fe",
        repl_yon="компилятор yield  d98873cda906, изменения включены",
        repl_yoff="компилятор yield  d98873cda906, изменения выключены",
        flag_mc=" ⚠ артефакт коротких итераций memtier", flag_ff=" ⚠ настройка числа потоков",
        band_row="{lo:.2f} – {hi:.2f}   (n = {n})",
        th_app="приложение", th_cfg="конфигурация", th_n="N", th_su="ускорение [95 %]",
        th_basis="основа", th_stable="разрешимые подтесты", th_reach="удалено точек",
        th_native="без инструментации относительно штатного TSan",
        th_band="загрузка CPU вне закреплённого набора", th_runs="запусков",
        th_reldur="медианная относительная длительность", th_ypair="yield вкл. против выкл. [95 %]",
        th_ydelta="разница по точкам",
        basis_all="все тесты", basis_stable="разрешимые подтесты",
        u_pp=" п.п.", u_pct=" %", u_x="×",
        aria_forest="Ускорение с 95 % интервалами, по приложениям", aria_bars="столбчатая диаграмма",
        page_title="Переизмерение оптимизаций TSan", aria_scatter="{x} — {y}",
    ),
}

def T(key, **kw):
    s = STR[LANG][key]
    return s.format(**kw) if kw else s

# ---------------------------------------------------------------- data

def load_tree(root, apps):
    """{app: per_cfg} from perf_<app>.json, in aggregate.py's own shape."""
    out = {}
    for app in apps:
        p = os.path.join(root, f"perf_{app}.json")
        if os.path.exists(p):
            out[app] = json.load(open(p))
    return out

def tests_of(per_cfg, base="tsan"):
    src = per_cfg.get(base) or next(iter(per_cfg.values()))
    return [t for t in src["runs"] if not t.startswith("_")]

def rows_for(per_cfg, app, base="tsan"):
    """Every configuration's speedup against stock TSan, with the interval, exactly as aggregate.py computes
    it. Returns (cfg, label, n, su, lo, hi, su_stable_or_None, lo_s, hi_s)."""
    hib = A.PARSERS[app][1]
    bt = per_cfg.get(base)
    if not bt:
        return []
    tests = tests_of(per_cfg, base)
    stable = A.stable_tests(per_cfg, tests)
    out = []
    for cfg, info in per_cfg.items():
        if cfg in (base, "orig") or "STALE" in cfg:      # STALE-* is the quarantined stale-binary artefact
            continue
        shared = [t for t in tests if t in info["runs"] and t in bt["runs"]]
        if not shared:
            continue
        rs = {t: A.ratio(st.median(info["runs"][t]), st.median(bt["runs"][t]), hib) for t in shared}
        lo, hi = A.bootstrap_geomean_ratio(info["runs"], bt["runs"], hib)
        s = sl = sh = None
        if stable:
            rss = {t: v for t, v in rs.items() if t in stable}
            if rss:
                s = A.geomean(rss.values())
                sl, sh = A.bootstrap_geomean_ratio(info["runs"], bt["runs"], hib, only=stable)
        out.append((cfg, A.label(cfg), info["n"], A.geomean(rs.values()), lo, hi, s, sl, sh))
    out.sort(key=lambda r: r[3])
    return out

def native_ratio(per_cfg, app):
    """orig against stock TSan: what instrumentation costs."""
    hib = A.PARSERS[app][1]
    o, t = per_cfg.get("orig"), per_cfg.get("tsan")
    if not (o and t):
        return None
    tests = [x for x in tests_of(per_cfg) if x in o["runs"]]
    rs = [A.ratio(st.median(o["runs"][x]), st.median(t["runs"][x]), hib) for x in tests]
    lo, hi = A.bootstrap_geomean_ratio(o["runs"], t["runs"], hib)
    return (A.geomean(rs), lo, hi)

def reach(statics, app, cfg):
    """Percent of memory-access sites removed against stock. Negative where loop peeling adds sites."""
    b = statics.get((app, "tsan")); c = statics.get((app, cfg))
    if not (b and c):
        return None
    bs = int(b["memory_access_sites"]); cs = int(c["memory_access_sites"])
    return 100.0 * (bs - cs) / bs if bs else None

def yield_pairs(trees, statics):
    """<config> against <config>-yoff inside the one compiler."""
    out = []
    for app in ["memcached", "redis", "sqlite", "ffmpeg"]:
        per_cfg = trees.get(app)
        if not per_cfg:
            continue
        hib = A.PARSERS[app][1]
        tests = tests_of(per_cfg)
        stable = A.stable_tests(per_cfg, tests)
        for cfg in sorted(per_cfg):
            off = cfg + "-yoff"
            if cfg in ("orig",) or cfg.endswith("-yoff") or off not in per_cfg:
                continue
            on_r, off_r = per_cfg[cfg]["runs"], per_cfg[off]["runs"]
            shared = [t for t in tests if t in on_r and t in off_r]
            if not shared:
                continue
            rs = {t: A.ratio(st.median(on_r[t]), st.median(off_r[t]), hib) for t in shared}
            lo, hi = A.bootstrap_geomean_ratio(on_r, off_r, hib)
            s = sl = sh = None
            if stable:
                rss = {t: v for t, v in rs.items() if t in stable}
                if rss:
                    s = A.geomean(rss.values()); sl, sh = A.bootstrap_geomean_ratio(on_r, off_r, hib, only=stable)
            son = statics.get((app, cfg), {}).get("memory_access_sites")
            sof = statics.get((app, off), {}).get("memory_access_sites")
            d = None
            if son and sof and int(sof):
                d = 100.0 * (int(son) - int(sof)) / int(sof)
            out.append((app, cfg, A.label(cfg), A.geomean(rs.values()), lo, hi, s, sl, sh, d))
    return out

def interference_bands(root):
    """Relative run duration against the busy share of the CPUs outside the pinned set."""
    rows = []
    for app in APPS:
        for cdir in sorted(glob.glob(f"{root}/{app}/*")):
            if not os.path.isdir(cdir):
                continue
            recs = []
            for d in sorted(glob.glob(cdir + "/run[0-9]*")):
                if not re.fullmatch(r"run\d+", os.path.basename(d)):
                    continue
                f = d + "/meta.json"
                if not os.path.isfile(f):
                    continue
                try:
                    m = json.load(open(f))
                except Exception:
                    continue
                if m.get("rc") != 0 or not m.get("seconds"):
                    continue
                recs.append((m["seconds"], m.get("outside_busy_share") or 0.0))
            if len(recs) < 4:
                continue
            med = st.median([r[0] for r in recs])
            for s, o in recs:
                rows.append((s / med, o))
    bands = [(0, 0.02), (0.02, 0.05), (0.05, 0.10), (0.10, 0.20), (0.20, 1.01)]
    out = []
    for lo, hi in bands:
        sub = [r for r in rows if lo <= r[1] < hi]
        if sub:
            out.append((lo, hi, len(sub), st.median([r[0] for r in sub])))
    xs = [r[1] for r in rows]; ys = [r[0] for r in rows]
    n = len(xs); mx = sum(xs) / n; my = sum(ys) / n
    sxy = sum((a - mx) * (b - my) for a, b in zip(xs, ys))
    sxx = sum((a - mx) ** 2 for a in xs); syy = sum((b - my) ** 2 for b in ys)
    r = sxy / math.sqrt(sxx * syy) if sxx and syy else float("nan")
    return out, r, n

def run_counts(root):
    good = len([p for p in glob.glob(f"{root}/*/*/run*/meta.json") if re.fullmatch(r"run\d+", os.path.basename(os.path.dirname(p)))])
    retired = len([d for d in glob.glob(f"{root}/*/*/run*") if os.path.isdir(d) and not re.fullmatch(r"run\d+", os.path.basename(d))])
    return good, retired

def clock_summary(root):
    p = os.path.join(root, "clock-samples2.csv")
    if not os.path.exists(p):
        return None
    rows = [r for r in csv.DictReader(open(p)) if r["n_busy"].isdigit()]
    busy = sorted(int(r["busy_median_khz"]) for r in rows if int(r["n_busy"]) >= 8)
    if not busy:
        return None
    hours = (int(rows[-1]["epoch"]) - int(rows[0]["epoch"])) / 3600
    return dict(n=len(busy), hours=hours, p10=busy[len(busy) // 10] / 1000,
                med=st.median(busy) / 1000, p90=busy[9 * len(busy) // 10] / 1000)

# ---------------------------------------------------------------- svg

def esc(s):
    return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

def fmt(v, n=3):
    return "—" if v is None else f"{v:.{n}f}"

def svg(w, h, title, body, cls="fig"):
    return (f'<figure class="{cls}"><svg viewBox="0 0 {w} {h}" width="100%" height="auto" '
            f'role="img" aria-label="{esc(title)}"><title>{esc(title)}</title>{body}</svg>')

def axis_x(x0, x1, y, lo, hi, ticks, fmtf=lambda v: f"{v:g}", label=None):
    """One horizontal scale: rule, ticks, and a label under each tick naming a value the scale reaches."""
    sx = lambda v: x0 + (v - lo) / (hi - lo) * (x1 - x0)
    o = [f'<line x1="{x0}" y1="{y}" x2="{x1}" y2="{y}" stroke="currentColor" stroke-width="1" opacity=".35"/>']
    for t in ticks:
        X = sx(t)
        o.append(f'<line x1="{X:.1f}" y1="{y}" x2="{X:.1f}" y2="{y+4}" stroke="currentColor" opacity=".35"/>')
        o.append(f'<text x="{X:.1f}" y="{y+16}" class="tick" text-anchor="middle">{esc(fmtf(t))}</text>')
    if label:
        o.append(f'<text x="{(x0+x1)/2:.1f}" y="{y+32}" class="axlabel" text-anchor="middle">{esc(label)}</text>')
    return "".join(o), sx

def forest(groups, lo, hi, ticks, labw=252, plotw=560, rowh=17, gaph=27, note=None):
    """Dot-and-interval rows grouped by application. `groups` = [(name, [(label, point, lo, hi, mark)])]."""
    rows = sum(len(g[1]) for g in groups)
    h = 34 + rows * rowh + len(groups) * gaph + 44
    w = labw + plotw + 60
    x0, x1 = labw, labw + plotw
    body, sx = axis_x(x0, x1, h - 40, lo, hi, ticks, lambda v: f"{v:g}", T("ax_speedup"))
    o = [body]
    one = sx(1.0)
    o.append(f'<line x1="{one:.1f}" y1="20" x2="{one:.1f}" y2="{h-40}" stroke="currentColor" '
             f'stroke-width="1" opacity=".45" stroke-dasharray="3 3"/>')
    y = 34
    for name, items in groups:
        o.append(f'<text x="0" y="{y}" class="grp">{esc(name)}</text>')
        y += gaph - rowh
        for lab, p, l, hh, mark in items:
            cls = "hit" if mark else "null"
            o.append(f'<text x="{labw-12}" y="{y+4}" class="rowlab" text-anchor="end">{esc(lab)}</text>')
            L, H, P = sx(max(l, lo)), sx(min(hh, hi)), sx(p)
            o.append(f'<line x1="{L:.1f}" y1="{y}" x2="{H:.1f}" y2="{y}" class="ci {cls}" stroke-width="1.5"/>')
            o.append(f'<circle cx="{P:.1f}" cy="{y}" r="3.1" class="pt {cls}"/>')
            y += rowh
        y += rowh
    if note:
        o.append(f'<text x="0" y="{h-6}" class="tick">{esc(note)}</text>')
    return svg(w, h, T("aria_forest"), "".join(o))

def scatter(points, xlo, xhi, ylo, yhi, xticks, yticks, xlabel, ylabel, w=900, h=420):
    """points = [(x, y, ylo, yhi, series, label)]"""
    x0, x1, y0, y1 = 74, w - 24, 28, h - 58
    sy = lambda v: y1 - (v - ylo) / (yhi - ylo) * (y1 - y0)
    body, sx = axis_x(x0, x1, y1, xlo, xhi, xticks, lambda v: f"{v:+g}", xlabel)
    o = [body]
    for t in yticks:
        Y = sy(t)
        o.append(f'<line x1="{x0}" y1="{Y:.1f}" x2="{x1}" y2="{Y:.1f}" stroke="currentColor" opacity=".12"/>')
        o.append(f'<text x="{x0-8}" y="{Y+4:.1f}" class="tick" text-anchor="end">{t:g}</text>')
    o.append(f'<text transform="translate(16,{(y0+y1)/2:.0f}) rotate(-90)" class="axlabel" text-anchor="middle">{esc(ylabel)}</text>')
    Y1 = sy(1.0)
    o.append(f'<line x1="{x0}" y1="{Y1:.1f}" x2="{x1}" y2="{Y1:.1f}" stroke="currentColor" opacity=".45" stroke-dasharray="3 3"/>')
    X0 = sx(0.0)
    o.append(f'<line x1="{X0:.1f}" y1="{y0}" x2="{X0:.1f}" y2="{y1}" stroke="currentColor" opacity=".2"/>')
    for x, y, l, hgh, s, lab in points:
        X, Y = sx(x), sy(y)
        o.append(f'<line x1="{X:.1f}" y1="{sy(max(l,ylo)):.1f}" x2="{X:.1f}" y2="{sy(min(hgh,yhi)):.1f}" '
                 f'class="s-{s}" stroke-width="1.2" opacity=".55"/>')
        o.append(f'<circle cx="{X:.1f}" cy="{Y:.1f}" r="3.4" class="d-{s}"><title>{esc(lab)}</title></circle>')
    return svg(w, h, T("aria_scatter", x=xlabel, y=ylabel), "".join(o))

def bars(items, vmax, w=900, rowh=30, unit="", fmtv=lambda v: f"{v:.2f}"):
    """items = [(label, value, series)] — horizontal bars, value printed at the end of each."""
    h = len(items) * rowh + 22
    x0, x1 = 132, w - 96
    o = []
    for i, (lab, v, s) in enumerate(items):
        y = 18 + i * rowh
        L = x0 + (v / vmax) * (x1 - x0)
        o.append(f'<text x="{x0-12}" y="{y+5}" class="rowlab" text-anchor="end">{esc(lab)}</text>')
        o.append(f'<rect x="{x0}" y="{y-8}" width="{max(L-x0,1):.1f}" height="16" rx="2" class="d-{s}" opacity=".8"/>')
        o.append(f'<text x="{L+8:.1f}" y="{y+5}" class="barval">{esc(fmtv(v))}{esc(unit)}</text>')
    return svg(w, h, T("aria_bars"), "".join(o))

# ---------------------------------------------------------------- html pieces

def table(headers, rows, cls="data"):
    th = "".join(f"<th>{esc(x)}</th>" for x in headers)
    tr = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in rows)
    return f'<div class="scroll"><table class="{cls}"><thead><tr>{th}</tr></thead><tbody>{tr}</tbody></table></div>'

def ci(p, l, h, n=3):
    if p is None:
        return "—"
    return f'<span class="num">{p:.{n}f}</span> <span class="ivl">[{l:.{n}f}, {h:.{n}f}]</span>'

# ---------------------------------------------------------------- build

def main():
    global LANG
    argv = sys.argv[1:]
    if "--lang" in argv:
        i = argv.index("--lang"); LANG = argv[i + 1]; del argv[i:i + 2]
    if LANG not in TEMPLATES:
        sys.exit(f"report.py: no template for language {LANG!r}; have {sorted(TEMPLATES)}")
    out_path = argv[0] if argv else "report.html"
    B = load_tree(STAGEB, APPS)
    Y = load_tree(YIELD, ["memcached", "redis", "sqlite", "ffmpeg"])
    Astage = load_tree(STAGEA, APPS)
    sB = A.static_counts(STAGEB); sY = A.static_counts(YIELD)

    brows = {app: rows_for(B[app], app) for app in APPS if app in B}
    natives = {app: native_ratio(B[app], app) for app in APPS if app in B}
    ypairs = yield_pairs(Y, sY)
    bands, rcorr, nruns = interference_bands(STAGEB)
    good_b, ret_b = run_counts(STAGEB); good_y, ret_y = run_counts(YIELD)
    clock = clock_summary(STAGEB)

    total_rows = sum(len(v) for v in brows.values())
    hits = [(app, r) for app in brows for r in brows[app]
            if (r[4] > 1.0 or r[5] < 1.0) or (r[6] is not None and (r[7] > 1.0 or r[8] < 1.0))]

    # ---- figure 1: the headline forest
    groups = []
    for app in APPS:
        if app not in brows:
            continue
        items = []
        for cfg, lab, n, su, lo, hi, s, sl, sh in brows[app]:
            mark = (lo > 1.0 or hi < 1.0)
            items.append((lab, su, lo, hi, mark))
        groups.append((T("grp_app", app=app, n=len(items), N=B[app]["tsan"]["n"]), items))
    fig1 = forest(groups, 0.86, 1.18, [0.9, 0.95, 1.0, 1.05, 1.1, 1.15],
                  note=T("note_forest"))

    # ---- figure 2: reach against speedup
    pts = []
    for app in APPS:
        for cfg, lab, n, su, lo, hi, s, sl, sh in brows.get(app, []):
            rc = reach(sB, app, cfg)
            if rc is None:
                continue
            pts.append((rc, su, lo, hi, SERIES[app], f"{app} {lab}: reach {rc:+.1f}%, SU {su:.3f}"))
    rmin = min(p[0] for p in pts); rmax = max(p[0] for p in pts)
    fig2 = scatter(pts, -16, 9, 0.88, 1.18, [-15, -10, -5, 0, 5], [0.9, 0.95, 1.0, 1.05, 1.1, 1.15],
                   T("ax_reach"), T("ax_speedup_short"))

    # ---- figure 3: DynSTC
    dyn = []
    for app in APPS:
        for cfg, lab, n, su, lo, hi, s, sl, sh in brows.get(app, []):
            if cfg != "tsan-stmt":
                continue
            use_stable = app == "sqlite" and s is not None
            v, l, h = (s, sl, sh) if use_stable else (su, lo, hi)
            dyn.append((app + (T("sfx_resolvable_subtests") if use_stable else ""), v, l, h, l > 1.0 or h < 1.0))
    dyn.sort(key=lambda r: -r[1])
    fig3 = forest([(T("grp_dynstc"), dyn)], 0.90, 1.16,
                  [0.95, 1.0, 1.05, 1.1, 1.15], labw=244, rowh=22, gaph=30)

    # ---- figure 5: the yield pairs
    yg = defaultdict(list)
    for app, cfg, lab, p, lo, hi, s, sl, sh, d in ypairs:
        v, l, h = (s, sl, sh) if (app == "sqlite" and s is not None) else (p, lo, hi)
        yg[app].append((lab + (T("sfx_resolvable") if app == "sqlite" and s is not None else ""),
                        v, l, h, l > 1.0 or h < 1.0))
    fig5 = forest([(f"{a}", yg[a]) for a in ["memcached", "redis", "sqlite", "ffmpeg"] if yg[a]],
                  0.90, 1.10, [0.925, 0.95, 0.975, 1.0, 1.025, 1.05, 1.075], labw=244)

    # ---- figure 6: cross-compiler replication of the FFmpeg DynSTC gain
    rep = []
    fb = [r for r in brows["ffmpeg"] if r[0] == "tsan-stmt"][0]
    rep.append((T("repl_b"), fb[3], fb[4], fb[5], True))
    yf = Y.get("ffmpeg", {})
    if yf:
        hib = A.PARSERS["ffmpeg"][1]; t = tests_of(yf)
        for cfg, name in (("tsan-stmt", T("repl_yon")), ("tsan-stmt-yoff", T("repl_yoff"))):
            rs = [A.ratio(st.median(yf[cfg]["runs"][x]), st.median(yf["tsan"]["runs"][x]), hib) for x in t]
            lo, hi = A.bootstrap_geomean_ratio(yf[cfg]["runs"], yf["tsan"]["runs"], hib)
            rep.append((name, A.geomean(rs), lo, hi, True))
    fig6 = forest([(T("grp_repl"), rep)], 1.05, 1.16,
                  [1.06, 1.08, 1.10, 1.12, 1.14], labw=300, rowh=24, gaph=30)

    # ---- figure 4: what the data can resolve
    res = []
    for app in APPS:
        rs = brows.get(app, [])
        if not rs:
            continue
        widths = sorted((h - l) * 100 for _, _, _, _, l, h, _, _, _ in rs)
        res.append((app, widths[len(widths) // 2], SERIES[app]))
    res.sort(key=lambda r: r[1])
    fig4 = bars(res, max(r[1] for r in res) * 1.18, unit=T("u_pp"), fmtv=lambda v: f"{v:.1f}")

    # ---- figure 7: Stage A context
    arows = {app: rows_for(Astage[app], app) for app in APPS if app in Astage}
    shared_cfgs = ["tsan-sound", "tsan-dom-ea-lo-st-swmr", "tsan-dom_peeling-ea-lo-st-swmr",
                   "tsan-dom_peeling-ea-lo-st-swmr-wp"]
    ag = []
    FLAG = {"memcached": T("flag_mc"), "ffmpeg": T("flag_ff")}
    for app in APPS:
        items = []
        for cfg in shared_cfgs:
            a = next((r for r in arows.get(app, []) if r[0] == cfg), None)
            b = next((r for r in brows.get(app, []) if r[0] == cfg), None)
            if a:
                items.append((A.label(cfg) + T("stage_a"), a[3], a[4], a[5], False))
            if b:
                items.append((A.label(cfg) + T("stage_b"), b[3], b[4], b[5], True))
        if items:
            ag.append((app + FLAG.get(app, ""), items))
    fig7 = forest(ag, 0.62, 1.20, [0.7, 0.8, 0.9, 1.0, 1.1], labw=286, rowh=15, gaph=26)

    # ---- figure 8: interference
    bitems = [(T("band_row", lo=lo, hi=hi, n=n), (m - 1) * 100, "mc" if m < 1.02 else "rd") for lo, hi, n, m in bands]
    fig8 = bars(bitems, max(0.5, max(abs(b[1]) for b in bitems) * 1.25), unit=T("u_pct"),
                fmtv=lambda v: f"{v:+.1f}")

    # ---- context bars
    natbars = sorted(((app, natives[app][0], SERIES[app]) for app in natives if natives[app]),
                     key=lambda r: r[1])
    fig0 = bars(natbars, max(r[1] for r in natbars) * 1.14, unit=T("u_x"))

    # ---- appendix A tables
    appA = []
    for app in APPS:
        for cfg, lab, n, su, lo, hi, s, sl, sh in sorted(brows.get(app, []), key=lambda r: r[0]):
            rc = reach(sB, app, cfg)
            appA.append([app, f'<code>{esc(cfg)}</code>', str(n), ci(su, lo, hi),
                         ci(s, sl, sh) if s is not None else "—",
                         f"{rc:+.1f}%" if rc is not None else "—"])
    appY = [[app, f'<code>{esc(cfg)}</code>', ci(p, lo, hi),
             ci(s, sl, sh) if s is not None else "—", f"{d:+.2f}%" if d is not None else "—"]
            for app, cfg, lab, p, lo, hi, s, sl, sh, d in ypairs]

    # ---- prose numbers
    nat = {a: natives[a][0] for a in natives}
    hit_rows = sorted(hits, key=lambda x: -abs(x[1][3] - 1))
    hit_tbl = []
    for app, r in hit_rows:
        cfg, lab, n, su, lo, hi, s, sl, sh = r
        stable_only = not (lo > 1.0 or hi < 1.0)
        hit_tbl.append([app, f'<code>{esc(lab)}</code>',
                        ci(s, sl, sh) if stable_only else ci(su, lo, hi),
                        T("basis_stable") if stable_only else T("basis_all")])

    H = SHELL.format(title=T("page_title")) + TEMPLATES[LANG].format(
        fig0=fig0, fig1=fig1, fig2=fig2, fig3=fig3, fig4=fig4, fig5=fig5, fig6=fig6, fig7=fig7, fig8=fig8,
        n_rows=total_rows, n_hits=len(hits), n_null=total_rows - len(hits),
        good_b=good_b, ret_b=ret_b, good_y=good_y, ret_y=ret_y,
        hit_table=table([T("th_app"), T("th_cfg"), T("th_su"), T("th_basis")], hit_tbl),
        nat_table=table([T("th_app"), T("th_native")],
                        [[a, ci(*natives[a], 2)] for a in APPS if natives.get(a)]),
        band_table=table([T("th_band"), T("th_runs"), T("th_reldur")],
                         [[f"{lo:.2f} – {hi:.2f}", str(n), f"{m:.4f}"] for lo, hi, n, m in bands]),
        yield_table=table([T("th_app"), T("th_cfg"), T("th_ypair"), T("th_stable"), T("th_ydelta")], appY),
        appA_table=table([T("th_app"), T("th_cfg"), T("th_n"), T("th_su"), T("th_stable"), T("th_reach")], appA),
        rcorr=f"{rcorr:.2f}", nruns=nruns,
        reach_min=f"{rmin:+.1f}", reach_max=f"{rmax:+.1f}",
        clock_n=clock["n"], clock_h=f"{clock['hours']:.1f}", clock_p10=f"{clock['p10']:.0f}",
        clock_med=f"{clock['med']:.0f}", clock_p90=f"{clock['p90']:.0f}",
        widest=f"{max(r[1] for r in res):.0f}", tightest=f"{min(r[1] for r in res):.1f}",
        widest_app=max(res, key=lambda r: r[1])[0], tightest_app=min(res, key=lambda r: r[1])[0],
    )
    open(out_path, "w").write(H)
    print(f"wrote {out_path}  ({len(H)//1024} KB)")
    print(f"  Stage B: {total_rows} configuration rows, {good_b} clean runs, {ret_b} retired")
    print(f"  conclusive rows: {len(hits)}")
    for app, r in hit_rows:
        print(f"    {app:10s} {r[1]:34s} {r[3]:.3f} [{r[4]:.3f}, {r[5]:.3f}]"
              + (f"   stable {r[6]:.3f} [{r[7]:.3f}, {r[8]:.3f}]" if r[6] is not None else ""))
    print(f"  yield pairs: {len(ypairs)}, none conclusive: "
          f"{all(not (l > 1.0 or h < 1.0) for _, _, _, _, l, h, _, _, _, _ in ypairs)}")


# The shell (fonts, title, tokens, CSS) is language-independent; only the prose below it is translated,
# so a style fix can never land in one language and not the other.
SHELL = r"""<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Spectral:ital,wght@0,400;0,600;1,400&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500&display=swap">
<title>{title}</title>
<style>
:root {{
  --paper:#F5F7F8; --raise:#FFFFFF; --ink:#12171C; --muted:#61707A; --rule:#D9E1E5;
  --accent:#0E6E7D; --warm:#A9501E;
  --mc:#0E6E7D; --rd:#A9501E; --sq:#3F6C8E; --ff:#5E7A4A; --my:#7A5C7E;
  --shadow:0 1px 2px rgba(18,23,28,.06), 0 8px 24px -16px rgba(18,23,28,.28);
}}
@media (prefers-color-scheme: dark) {{
  :root:not([data-theme="light"]) {{
    --paper:#0E1417; --raise:#141C21; --ink:#E4EBEF; --muted:#8A9AA4; --rule:#233038;
    --accent:#46B6C6; --warm:#DE9260;
    --mc:#46B6C6; --rd:#DE9260; --sq:#7FA6C7; --ff:#96B87C; --my:#B79ABB;
    --shadow:0 1px 2px rgba(0,0,0,.4), 0 8px 24px -16px rgba(0,0,0,.7);
  }}
}}
:root[data-theme="dark"] {{
  --paper:#0E1417; --raise:#141C21; --ink:#E4EBEF; --muted:#8A9AA4; --rule:#233038;
  --accent:#46B6C6; --warm:#DE9260;
  --mc:#46B6C6; --rd:#DE9260; --sq:#7FA6C7; --ff:#96B87C; --my:#B79ABB;
  --shadow:0 1px 2px rgba(0,0,0,.4), 0 8px 24px -16px rgba(0,0,0,.7);
}}
* {{ box-sizing:border-box; }}
body {{
  background:var(--paper); color:var(--ink);
  font-family:"IBM Plex Sans", system-ui, -apple-system, "Segoe UI", sans-serif;
  font-size:16px; line-height:1.62; margin:0;
  -webkit-font-smoothing:antialiased;
}}
.wrap {{ max-width:1000px; margin:0 auto; padding:56px 28px 96px; }}
.col {{ max-width:68ch; }}
h1, h2, h3 {{ font-family:Spectral, Georgia, serif; font-weight:600; text-wrap:balance; letter-spacing:-.01em; }}
h1 {{ font-size:2.45rem; line-height:1.14; margin:0 0 .5rem; }}
h2 {{ font-size:1.6rem; line-height:1.24; margin:0 0 .35rem; }}
h3 {{ font-size:1.12rem; margin:2.2rem 0 .5rem; }}
p {{ margin:0 0 1.05rem; }}
a {{ color:var(--accent); }}
code, .num, .ivl, .tick, .rowlab, .barval, .mono {{ font-family:"IBM Plex Mono", ui-monospace, monospace; }}
code {{ font-size:.88em; background:color-mix(in srgb, var(--accent) 9%, transparent); padding:.08em .34em; border-radius:3px; }}
.eyebrow {{
  font-family:"IBM Plex Mono", monospace; font-size:.735rem; letter-spacing:.12em;
  text-transform:uppercase; color:var(--muted); margin:0 0 .55rem;
}}
header.title {{ border-bottom:1px solid var(--rule); padding-bottom:30px; margin-bottom:38px; }}
.lede {{ font-family:Spectral, Georgia, serif; font-size:1.24rem; line-height:1.55; color:var(--ink); max-width:64ch; }}
.meta {{ display:flex; flex-wrap:wrap; gap:10px 26px; margin-top:22px; font-size:.85rem; color:var(--muted); }}
.meta b {{ font-family:"IBM Plex Mono", monospace; font-weight:500; color:var(--ink); }}
section {{ margin:0 0 58px; }}
section > .col > p:last-child {{ margin-bottom:0; }}
.fig {{ margin:26px 0 0; }}
figure {{ margin:26px 0; }}
figcaption {{ font-size:.845rem; color:var(--muted); margin-top:10px; max-width:76ch; line-height:1.5; }}
.src {{ font-family:"IBM Plex Mono", monospace; font-size:.78rem; opacity:.8; display:block; margin-top:3px; }}
svg text {{ fill:currentColor; }}
.tick {{ font-size:10.5px; fill:var(--muted); }}
.axlabel {{ font-size:11.5px; fill:var(--muted); letter-spacing:.03em; }}
.grp {{ font-size:12.5px; font-weight:600; font-family:"IBM Plex Sans", sans-serif; fill:var(--ink); }}
.rowlab {{ font-size:11px; fill:var(--muted); }}
.barval {{ font-size:11.5px; fill:var(--ink); }}
.ci.null {{ stroke:var(--muted); opacity:.55; }}
.pt.null {{ fill:var(--paper); stroke:var(--muted); stroke-width:1.3; }}
.ci.hit {{ stroke:var(--accent); opacity:.95; }}
.pt.hit {{ fill:var(--accent); stroke:none; }}
.d-mc {{ fill:var(--mc); }} .d-rd {{ fill:var(--rd); }} .d-sq {{ fill:var(--sq); }}
.d-ff {{ fill:var(--ff); }} .d-my {{ fill:var(--my); }}
.s-mc {{ stroke:var(--mc); }} .s-rd {{ stroke:var(--rd); }} .s-sq {{ stroke:var(--sq); }}
.s-ff {{ stroke:var(--ff); }} .s-my {{ stroke:var(--my); }}
.scroll {{ overflow-x:auto; margin:18px 0; }}
table.data {{ border-collapse:collapse; font-size:.855rem; width:100%; font-variant-numeric:tabular-nums; }}
table.data th {{
  text-align:left; font-family:"IBM Plex Mono", monospace; font-weight:500; font-size:.74rem;
  letter-spacing:.07em; text-transform:uppercase; color:var(--muted);
  border-bottom:1px solid var(--rule); padding:0 16px 7px 0; white-space:nowrap;
}}
table.data td {{ padding:6px 16px 6px 0; border-bottom:1px solid color-mix(in srgb, var(--rule) 55%, transparent); vertical-align:baseline; }}
table.data tr:last-child td {{ border-bottom:none; }}
.num {{ font-weight:500; }}
.ivl {{ color:var(--muted); font-size:.92em; }}
.callout {{
  background:var(--raise); border:1px solid var(--rule); border-radius:6px;
  padding:20px 24px; margin:26px 0; box-shadow:var(--shadow);
}}
.callout p:last-child {{ margin-bottom:0; }}
.callout .eyebrow {{ color:var(--accent); }}
.legend {{ display:flex; flex-wrap:wrap; gap:8px 22px; font-size:.8rem; color:var(--muted); margin:14px 0 0; }}
.legend span {{ display:inline-flex; align-items:center; gap:7px; }}
.dot {{ width:9px; height:9px; border-radius:50%; display:inline-block; }}
hr.major {{ border:none; border-top:1px solid var(--rule); margin:70px 0 44px; }}
.appendix {{ opacity:.97; }}
.appendix h2 {{ color:var(--muted); }}
@media (max-width:720px) {{ .wrap {{ padding:34px 18px 64px; }} h1 {{ font-size:1.9rem; }} }}
@media (prefers-reduced-motion:reduce) {{ * {{ animation:none !important; transition:none !important; }} }}
</style>
"""

TEMPLATES = {}

TEMPLATES["en"] = r"""
<div class="wrap">

<header class="title">
  <p class="eyebrow">P5 · performance re-measurement · 2026-09-09</p>
  <h1>What the instrumentation optimisations are worth</h1>
  <p class="lede">Five applications and {n_rows} configurations re-measured on the hardened compiler. {n_hits}
  rows separate from stock ThreadSanitizer; {n_null} do not. The one substantial effect is not an optimisation
  at all — it is a workload-shape bet that pays on one application and costs on two others.</p>
  <div class="meta">
    <span>Stage B compiler <b>tsan-perf-d3bf9f8c39fe</b></span>
    <span>Yield A/B <b>tsan-yield-d98873cda906</b></span>
    <span><b>N = 5</b> per row</span>
    <span>pinned to <b>4-27,60-83</b></span>
    <span><b>{good_b} + {good_y}</b> clean runs</span>
  </div>
</header>

<section>
  <div class="col">
    <p class="eyebrow">what was measured</p>
    <h2>The campaign</h2>
    <p>Stage B measured every configuration of the paper's set on <code>tsan-perf-d3bf9f8c39fe</code>, the
    performance branch with the P3 eviction counters compiled out, so both sides of every ratio share a
    runtime and the slowdown figures are sound. Five repetitions per row, one measurement at a time under a
    machine-wide job lock, pinned to 24 physical cores and their SMT siblings, run-major so that a
    configuration and its baseline are drawn from adjacent minutes.</p>
    <p>{good_b} clean runs entered the tables and {ret_b} were retired and re-run. A second stage then measured
    the yield branch's seven changes as A/B pairs inside a single compiler: {good_y} further runs, {ret_y}
    retired.</p>
  </div>
  {fig0}
  {nat_table}
  <figcaption>What ThreadSanitizer costs before any optimisation: native against stock instrumented, geometric
  mean over each application's tests.
  <span class="src">tools/perf/results/stageB-d3bf9f8c39fe/perf_&lt;app&gt;.json · N = 5</span></figcaption></figure>
</section>

<section>
  <div class="col">
    <p class="eyebrow">the result · {n_hits} of {n_rows} rows</p>
    <h2>Almost nothing separates from stock</h2>
    <p>Each row below is one configuration's speedup against stock ThreadSanitizer, with its 95 % bootstrap
    interval. The dashed rule is parity. A row whose interval crosses that rule has not been shown to differ
    from stock at all.</p>
  </div>
  {fig1}
  <div class="legend">
    <span><span class="dot" style="background:var(--accent)"></span> interval excludes parity</span>
    <span><span class="dot" style="background:var(--muted);opacity:.55"></span> interval crosses parity</span>
  </div>
  <figcaption>{n_rows} configurations across five applications; {n_null} intervals cross 1.0. Every single
  analysis, both AllOpt bundles, whole-program summaries, user-vouched thread-free names and loop peeling are
  among the rows that cross.
  <span class="src">tools/perf/results/stageB-d3bf9f8c39fe · geometric mean over tests, 2000-sample bootstrap</span></figcaption></figure>

  <div class="col">
    <h3>The rows that do separate</h3>
  </div>
  {hit_table}
  <div class="col">
    <p>Two of these are genuine but small gains on Redis, worth two to three percent. The other three are the
    same lever, dynamic single-threading, pointing in different directions on different applications.</p>
  </div>
</section>

<section>
  <div class="col">
    <p class="eyebrow">why · reach {reach_min}% to {reach_max}%</p>
    <h2>There is almost nothing left to remove</h2>
    <p>The analyses were hardened after the paper was submitted, and on this compiler their reach is small.
    Across every configuration and application, instrumentation removed against stock ranges from
    {reach_min}&thinsp;% to {reach_max}&thinsp;% — the negative end is loop peeling, which <em>adds</em> sites.
    Speedup is flat across that whole range.</p>
  </div>
  {fig2}
  <div class="legend">
    <span><span class="dot" style="background:var(--mc)"></span> memcached</span>
    <span><span class="dot" style="background:var(--rd)"></span> redis</span>
    <span><span class="dot" style="background:var(--sq)"></span> sqlite</span>
    <span><span class="dot" style="background:var(--ff)"></span> ffmpeg</span>
    <span><span class="dot" style="background:var(--my)"></span> mysql</span>
  </div>
  <figcaption>Sites removed against measured speedup, one point per configuration, whiskers are the 95 %
  interval. Removing eight percent of instrumentation buys nothing measurable, and neither does adding seven.
  <span class="src">static-counts.csv · objdump memory-access site counts</span></figcaption></figure>
</section>

<section>
  <div class="col">
    <p class="eyebrow">the one real effect</p>
    <h2>Dynamic single-threading, in both directions</h2>
    <p>DynSTC replaces a memory-access callback with a guarded one: load the active thread count, skip the
    callback while it is one. An application with genuinely single-threaded phases gets the skip; one that is
    never single-threaded pays the load and gets nothing. It changes the static site count by well under one
    percent everywhere, so the entire effect is at run time.</p>
  </div>
  {fig3}
  <figcaption>The same configuration on five applications. FFmpeg gains eleven percent; Redis and SQLite lose
  two to three; memcached and MySQL cannot resolve it.
  <span class="src">tools/perf/results/stageB-d3bf9f8c39fe · SQLite over its resolvable subtests</span></figcaption></figure>

  <div class="callout col">
    <p class="eyebrow">mechanism</p>
    <p><b>Redis is never single-threaded.</b> <code>main</code> calls <code>bioInit</code> during startup,
    before the first client connects, and that spawns the background I/O threads. The count is above one from
    before the benchmark begins until the server exits, so every guard is a pure add.</p>
    <p><b>SQLite is multi-threaded wherever the time goes.</b> <code>threadtest3</code> launches its workers
    per subtest and joins them at the end of it, so the windows where the count returns to one are the gaps
    between subtests, not the timed bodies.</p>
    <p><b>FFmpeg is single-threaded in phases.</b> Demux, parse and container setup run on one thread, and the
    codec worker pool exists only around the encode.</p>
    <p>The FFmpeg half is inferred from the workload's structure rather than from a counter; the Redis and
    SQLite halves are read from the sources.</p>
  </div>

  <div class="col">
    <h3>The gain reproduces on a second compiler</h3>
    <p>A single application showing an eleven percent gain where nothing else moves is exactly the shape a
    measurement artefact takes. It was measured again, unplanned, on a separately built compiler with a
    different base as part of the yield stage.</p>
  </div>
  {fig6}
  <figcaption>Three independent settings across two compilers, near-identical magnitude, no interval touching
  parity. Native against stock also agrees across the two builds on this workload, 2.80× and 2.81×.
  <span class="src">stageB-d3bf9f8c39fe and yield-d98873cda906 · FFmpeg, N = 5 each</span></figcaption></figure>
</section>

<section>
  <div class="col">
    <p class="eyebrow">yield branch · 16 pairs</p>
    <h2>The yield changes add nothing</h2>
    <p>The yield branch's seven changes each sit behind a compiler switch that defaults on, so each row could
    be measured against its own switched-off build inside one compiler. Both halves share a base, a source
    tree and a build recipe, which isolates the seven changes from the branch they sit on — a comparison
    against the Stage B compiler would have mixed the two.</p>
  </div>
  {fig5}
  <figcaption>Sixteen pairs; not one interval excludes parity. The tightest bound is FFmpeg's sound pair at
  1.000 [0.992, 1.008], so on the application that resolves best the seven changes together are worth under one
  percent either way.
  <span class="src">tools/perf/results/yield-d98873cda906/yield_pairs.md · N = 5 per arm</span></figcaption></figure>
  <div class="callout col">
    <p class="eyebrow">recorded before the measurements</p>
    <p>The paired static counts were taken before any timing and predicted this: the largest static difference
    anywhere in the matrix is 0.23 %, against a best resolution of about one point. There was nothing for a
    timing effect to come from. The plain stock pairs are byte-identical in instrumentation on all four
    applications, so whatever they showed would have been the runtime interceptor change alone.</p>
  </div>
</section>

<section>
  <div class="col">
    <p class="eyebrow">resolution · {tightest} to {widest} points</p>
    <h2>What the data can and cannot resolve</h2>
    <p>Resolution differs by an order of magnitude between applications, which is itself a result: a report of
    point estimates alone would read the same across all five. {tightest_app} resolves to about
    {tightest}&thinsp;points and {widest_app} to about {widest}. The effects at issue are one to four percent.</p>
  </div>
  {fig4}
  <figcaption>Median width of the 95 % interval per application. memcached and MySQL cannot separate a
  four-percent effect from parity and are reported as unresolved rather than null.
  <span class="src">tools/perf/results/stageB-d3bf9f8c39fe · median over each application's configurations</span></figcaption></figure>
  <div class="col">
    <p>Where an application's tests differ sharply in noise, the tables carry a second geometric mean over the
    subtests the data can resolve — those whose run-to-run variation, pooled across every configuration rather
    than read off one baseline, is at most five percent. The set is a property of the workload, applies to
    every row alike, and is suppressed entirely when fewer than half the subtests survive. SQLite keeps four of
    seven; MySQL keeps one of five and therefore gets no second column at all.</p>
    <p>Buying resolution with repetitions was costed and rejected. memcached's interval narrows as the square
    root of the count: reaching a width that could resolve a two-percent effect needs about eighty repetitions,
    some sixty-four hours of machine time for one application. Retiring nine contaminated runs bought more,
    for half an hour.</p>
  </div>
</section>

<section>
  <div class="col">
    <p class="eyebrow">method · r = {rcorr} over {nruns} runs</p>
    <h2>Keeping the numbers honest</h2>
    <p>Every run records the busy share of the CPUs outside the pinned set, where nothing of ours can run.
    Expressing each run's duration relative to its own configuration's median cancels the configuration effect
    and leaves foreign activity as the only systematic term.</p>
  </div>
  {fig8}
  <figcaption>Penalty by foreign-activity band, over {nruns} runs. Below a five-percent share the machine
  behaves as if it were ours alone; between ten and twenty the penalty is about ten percent.
  <span class="src">per-run meta.json · outside_busy_share against relative wall-clock</span></figcaption></figure>
  {band_table}
  <div class="col">
    <p>The disturbance gate had been set at 0.25, above the band where a visible penalty starts, so runs
    costing ten percent were passing it silently while the effects under measurement were one to four percent.
    It was tightened to 0.10 and nine already-recorded runs were retired and re-run. That correction alone cut
    memcached's interval widths roughly in half.</p>
    <p>Two further checks are worth naming. The retirement mechanism initially only renamed a run's directory,
    which left it still matching the top-up's counting glob and still reading clean in its own metadata — the
    quarantine would have quarantined nothing while the tables looked correct. And the variable-clock
    hypothesis for the residual spread was retired by measurement rather than argument: over {clock_h} hours
    and {clock_n} samples, whenever at least eight cores are working the busy-core clock reads p10
    {clock_p10}&thinsp;MHz, median {clock_med}, p90 {clock_p90}. The governor cannot account for run-to-run
    differences of five to twenty percent, so the residual spread belongs to the workloads.</p>
  </div>
</section>

<section>
  <div class="col">
    <p class="eyebrow">context · earlier compiler</p>
    <h2>The same answer on the hardened tip</h2>
    <p>An earlier pass measured a smaller configuration set at three repetitions on
    <code>tsan-dev-729521af8965</code>, the hardened tip rather than the performance branch. It agrees with
    Stage B on Redis, SQLite and MySQL. It disagrees on memcached and FFmpeg, and in both cases the earlier
    pass is the contaminated one: memcached's client was configured with too few requests per iteration to
    time anything meaningful, and FFmpeg's thread count was set high enough to break one codec outright. Both
    defects were found and fixed before Stage B.</p>
    <p>The conclusion holds on both compilers regardless: no configuration gained on either.</p>
  </div>
  {fig7}
  <figcaption>The four configurations both passes measured. Speedup only — the earlier compiler carries the P3
  eviction counters, which make its stock baseline artificially slow and its slowdown-against-native figures
  unusable.
  <span class="src">results/2026-09-04-729521af8965 (N = 3) against stageB-d3bf9f8c39fe (N = 5)</span></figcaption></figure>
</section>

<section>
  <div class="col">
    <p class="eyebrow">provenance</p>
    <h2>What this rests on</h2>
    <p>Both compilers are self-contained frozen copies under <code>/extra/alexey/builds/</code>, never the
    shared working build, and every binary's stamp was checked against the campaign's hash before it was
    measured. Results live in <code>tools/perf/results/stageB-d3bf9f8c39fe</code> and
    <code>tools/perf/results/yield-d98873cda906</code>; the scripts and notes are committed at
    <code>ffb2d5a</code>.</p>
    <p>Chromium is not here. It remains twelve builds of roughly six hours each plus about six days of
    benchmarking, and it is not scheduled.</p>
  </div>
</section>

<hr class="major">

<section class="appendix">
  <div class="col">
    <p class="eyebrow">appendix A</p>
    <h2>Every measured row</h2>
    <p>All {n_rows} Stage B configurations, then the 16 yield pairs.</p>
  </div>
  {appA_table}
  <div class="col"><h3>Yield A/B pairs</h3></div>
  {yield_table}
</section>

<section class="appendix">
  <div class="col">
    <p class="eyebrow">appendix B · comparison with the published figures</p>
    <h2>Why the numbers changed</h2>
    <p>This section compares against the paper's published results and can be removed without affecting
    anything above it.</p>
    <p><b>The analyses' reach collapsed when they were made sound.</b> On SQLite's <code>threadtest3</code>,
    instrumentation actually emitted fell from 58&thinsp;324 sites to 32&thinsp;635 under the paper compiler —
    44&thinsp;% removed. On the hardened compiler the same configuration removes 3.2&thinsp;%. The soundness
    fixes to single-threaded detection, lock ownership and dominance elimination account for the difference,
    and a three-percent reduction cannot buy a large speedup.</p>
    <p><b>The published 2.77× additionally rests on one unrepeatable run.</b> The figure is a geometric mean
    over seven subtests, and dropping <code>stress1</code> alone takes it to 1.965. On that subtest the March
    stock-TSan baseline recorded 6&thinsp;417 iterations where the same compiler, same sources and same flags
    produce 106&thinsp;704 today — a factor of 16.6. Stage B gives 65 instrumented <code>stress1</code> runs
    across thirteen configurations, and their entire envelope is 81&thinsp;553 to 187&thinsp;109 iterations, a
    factor of 2.29 end to end, continuous rather than bimodal. The March baseline therefore sits about seven
    times further from today's median than the subtest's whole observed range, so run-to-run variance does not
    explain it and no number of repetitions would have produced it.</p>
    <p>The paper compiler on this machine today reproduces 1.271 on the same comparison, not 2.773.</p>
  </div>
</section>

</div>
"""


TEMPLATES["ru"] = r"""
<div class="wrap">

<header class="title">
  <p class="eyebrow">P5 · переизмерение производительности · 2026-09-09</p>
  <h1>Чего стоят оптимизации инструментации</h1>
  <p class="lede">Пять приложений и {n_rows} конфигураций, переизмеренных на укреплённом компиляторе. {n_hits}
  строк отличаются от штатного ThreadSanitizer, {n_null} — нет. Единственный существенный эффект вообще не
  является оптимизацией: это ставка на форму нагрузки, которая выигрывает на одном приложении и проигрывает
  на двух других.</p>
  <div class="meta">
    <span>компилятор этапа B <b>tsan-perf-d3bf9f8c39fe</b></span>
    <span>A/B ветки yield <b>tsan-yield-d98873cda906</b></span>
    <span><b>N = 5</b> на строку</span>
    <span>закреплено на <b>4-27,60-83</b></span>
    <span><b>{good_b} + {good_y}</b> чистых запусков</span>
  </div>
</header>

<section>
  <div class="col">
    <p class="eyebrow">что измерялось</p>
    <h2>Кампания</h2>
    <p>На этапе B измерены все конфигурации из набора статьи на <code>tsan-perf-d3bf9f8c39fe</code> — ветке
    производительности, из которой исключены счётчики вытеснения P3. Поэтому обе стороны каждого отношения
    используют одну и ту же библиотеку времени выполнения, и цифры замедления корректны. Пять повторений на
    строку, по одному измерению за раз под общемашинной блокировкой задач, с закреплением на 24 физических
    ядрах и их SMT-близнецах. Порядок — по повторениям, так что конфигурация и её эталон измеряются в соседние
    минуты.</p>
    <p>В таблицы вошло {good_b} чистых запусков, ещё {ret_b} отбраковано и перезапущено. Затем второй этап
    измерил семь изменений ветки yield как A/B-пары внутри одного компилятора: ещё {good_y} запусков,
    {ret_y} отбраковано.</p>
  </div>
  {fig0}
  {nat_table}
  <figcaption>Чего стоит ThreadSanitizer до всякой оптимизации: код без инструментации против штатного
  инструментированного, среднее геометрическое по тестам приложения.
  <span class="src">tools/perf/results/stageB-d3bf9f8c39fe/perf_&lt;app&gt;.json · N = 5</span></figcaption></figure>
</section>

<section>
  <div class="col">
    <p class="eyebrow">результат · {n_hits} строк из {n_rows}</p>
    <h2>Почти ничто не отличается от штатного</h2>
    <p>Каждая строка ниже — ускорение одной конфигурации относительно штатного ThreadSanitizer с её 95 %
    бутстрэп-интервалом. Пунктирная линия — паритет. Строка, чей интервал пересекает эту линию, вообще не
    показала отличия от штатного варианта.</p>
  </div>
  {fig1}
  <div class="legend">
    <span><span class="dot" style="background:var(--accent)"></span> интервал не пересекает паритет</span>
    <span><span class="dot" style="background:var(--muted);opacity:.55"></span> интервал пересекает паритет</span>
  </div>
  <figcaption>{n_rows} конфигураций на пяти приложениях; {n_null} интервалов пересекают 1.0. Каждый отдельный
  анализ, оба набора AllOpt, межпрограммные сводки, вручную заверенные имена однопоточных функций и peeling
  циклов — все они среди пересекающих.
  <span class="src">tools/perf/results/stageB-d3bf9f8c39fe · среднее геометрическое по тестам, бутстрэп 2000 выборок</span></figcaption></figure>

  <div class="col">
    <h3>Строки, которые всё же отличаются</h3>
  </div>
  {hit_table}
  <div class="col">
    <p>Две из них — настоящий, но небольшой выигрыш на Redis, два-три процента. Остальные три — один и тот же
    рычаг, динамическое определение однопоточности, направленный по-разному на разных приложениях.</p>
  </div>
</section>

<section>
  <div class="col">
    <p class="eyebrow">почему · охват от {reach_min}% до {reach_max}%</p>
    <h2>Удалять почти нечего</h2>
    <p>Анализы были укреплены после подачи статьи, и на этом компиляторе их охват мал. По всем конфигурациям и
    приложениям доля удалённой инструментации относительно штатной лежит в пределах от {reach_min}&thinsp;% до
    {reach_max}&thinsp;%; отрицательный край — это peeling циклов, который точки <em>добавляет</em>. Ускорение
    остаётся плоским на всём этом диапазоне.</p>
  </div>
  {fig2}
  <div class="legend">
    <span><span class="dot" style="background:var(--mc)"></span> memcached</span>
    <span><span class="dot" style="background:var(--rd)"></span> redis</span>
    <span><span class="dot" style="background:var(--sq)"></span> sqlite</span>
    <span><span class="dot" style="background:var(--ff)"></span> ffmpeg</span>
    <span><span class="dot" style="background:var(--my)"></span> mysql</span>
  </div>
  <figcaption>Удалённые точки против измеренного ускорения, по точке на конфигурацию; усы — 95 % интервал.
  Удаление восьми процентов инструментации не даёт ничего измеримого, как и добавление семи.
  <span class="src">static-counts.csv · подсчёт точек доступа к памяти по objdump</span></figcaption></figure>
</section>

<section>
  <div class="col">
    <p class="eyebrow">единственный реальный эффект</p>
    <h2>Динамическая однопоточность, в обе стороны</h2>
    <p>DynSTC заменяет обработчик доступа к памяти защищённым вариантом: прочитать число активных потоков и
    пропустить вызов, пока оно равно единице. Приложение с действительно однопоточными фазами получает этот
    пропуск; приложение, которое однопоточным не бывает никогда, платит за чтение и не получает ничего.
    Статическое число точек меняется меньше чем на процент везде, так что весь эффект — во времени выполнения.</p>
  </div>
  {fig3}
  <figcaption>Одна и та же конфигурация на пяти приложениях. FFmpeg выигрывает одиннадцать процентов, Redis и
  SQLite теряют два-три, memcached и MySQL не позволяют это разрешить.
  <span class="src">tools/perf/results/stageB-d3bf9f8c39fe · SQLite по разрешимым подтестам</span></figcaption></figure>

  <div class="callout col">
    <p class="eyebrow">механизм</p>
    <p><b>Redis никогда не однопоточен.</b> <code>main</code> вызывает <code>bioInit</code> при запуске, до
    подключения первого клиента, и тот порождает фоновые потоки ввода-вывода. Счётчик больше единицы с момента
    до начала теста и до завершения сервера, поэтому каждая проверка — чистая добавка.</p>
    <p><b>SQLite многопоточен там, где расходуется время.</b> <code>threadtest3</code> запускает рабочие потоки
    на каждый подтест и присоединяет их в его конце, так что окна с одним потоком — это промежутки между
    подтестами, а не измеряемые участки.</p>
    <p><b>FFmpeg однопоточен фазами.</b> Демультиплексирование, разбор и подготовка контейнера идут в одном
    потоке, а пул рабочих потоков кодека существует только вокруг кодирования.</p>
    <p>Про FFmpeg это выведено из структуры нагрузки, а не измерено счётчиком; про Redis и SQLite — прочитано
    в исходном коде.</p>
  </div>

  <div class="col">
    <h3>Выигрыш воспроизводится на втором компиляторе</h3>
    <p>Одно приложение с выигрышем в одиннадцать процентов там, где не движется ничто другое, — это ровно та
    форма, которую принимает артефакт измерения. Он был измерен ещё раз, непреднамеренно, на отдельно
    собранном компиляторе с другой базой в рамках этапа yield.</p>
  </div>
  {fig6}
  <figcaption>Три независимые постановки на двух компиляторах, почти одинаковая величина, ни один интервал не
  касается паритета. Отношение «без инструментации к штатному» на этой нагрузке тоже совпадает между сборками:
  2.80× и 2.81×.
  <span class="src">stageB-d3bf9f8c39fe и yield-d98873cda906 · FFmpeg, N = 5 в каждой</span></figcaption></figure>
</section>

<section>
  <div class="col">
    <p class="eyebrow">ветка yield · 16 пар</p>
    <h2>Изменения ветки yield не дают ничего</h2>
    <p>Каждое из семи изменений ветки yield скрыто за ключом компилятора, включённым по умолчанию, поэтому
    каждую строку удалось измерить против её же сборки с выключенными ключами внутри одного компилятора. Обе
    половины разделяют базу, дерево исходников и рецепт сборки, что отделяет семь изменений от ветки, на
    которой они лежат: сравнение с компилятором этапа B смешало бы одно с другим.</p>
  </div>
  {fig5}
  <figcaption>Шестнадцать пар; ни один интервал не исключает паритет. Самая узкая граница — пара sound на
  FFmpeg, 1.000 [0.992, 1.008]: на приложении с лучшим разрешением семь изменений вместе стоят меньше процента
  в любую сторону.
  <span class="src">tools/perf/results/yield-d98873cda906/yield_pairs.md · N = 5 на каждое плечо</span></figcaption></figure>
  <div class="callout col">
    <p class="eyebrow">записано до измерений</p>
    <p>Парные статические подсчёты были сделаны до всякого измерения времени и предсказали именно это:
    наибольшая статическая разница во всей матрице — 0.23 %, при лучшем разрешении около одного пункта.
    Эффекту времени выполнения просто неоткуда было взяться. Пары штатной конфигурации побайтово совпадают по
    инструментации на всех четырёх приложениях, поэтому всё, что они показали бы, относилось бы только к
    изменению перехватчиков во время выполнения.</p>
  </div>
</section>

<section>
  <div class="col">
    <p class="eyebrow">разрешение · от {tightest} до {widest} пунктов</p>
    <h2>Что данные позволяют разрешить, а что нет</h2>
    <p>Разрешение отличается между приложениями на порядок, и это само по себе результат: отчёт из одних лишь
    точечных оценок читался бы одинаково для всех пяти. {tightest_app} разрешает примерно
    {tightest}&thinsp;пункта, {widest_app} — около {widest}. Интересующие нас эффекты — от одного до четырёх
    процентов.</p>
  </div>
  {fig4}
  <figcaption>Медианная ширина 95 % интервала по приложениям. memcached и MySQL не отделяют четырёхпроцентный
  эффект от паритета и указаны как неразрешённые, а не как нулевые.
  <span class="src">tools/perf/results/stageB-d3bf9f8c39fe · медиана по конфигурациям приложения</span></figcaption></figure>
  <div class="col">
    <p>Там, где тесты приложения резко различаются по шуму, таблицы несут второе среднее геометрическое — по
    подтестам, которые данные позволяют разрешить: тем, чья изменчивость от запуска к запуску, объединённая по
    всем конфигурациям, а не снятая с одного эталона, не превышает пяти процентов. Набор является свойством
    нагрузки, применяется ко всем строкам одинаково и подавляется целиком, если выживает меньше половины
    подтестов. У SQLite остаётся четыре из семи; у MySQL — один из пяти, поэтому второй колонки он не получает
    вовсе.</p>
    <p>Покупка разрешения повторениями была посчитана и отвергнута. Интервал memcached сужается как корень из
    числа повторений: чтобы разрешить двухпроцентный эффект, нужно около восьмидесяти повторений — примерно
    шестьдесят четыре часа машинного времени на одно приложение. Отбраковка девяти загрязнённых запусков дала
    больше, за полчаса.</p>
  </div>
</section>

<section>
  <div class="col">
    <p class="eyebrow">методика · r = {rcorr} по {nruns} запускам</p>
    <h2>Как цифры удерживались честными</h2>
    <p>Каждый запуск записывает долю занятости процессоров вне закреплённого набора, где ничто наше работать не
    может. Выражение длительности запуска относительно медианы его собственной конфигурации снимает эффект
    конфигурации и оставляет постороннюю активность единственным систематическим слагаемым.</p>
  </div>
  {fig8}
  <figcaption>Штраф по полосам посторонней активности, по {nruns} запускам. Ниже пяти процентов машина ведёт
  себя так, будто она наша целиком; между десятью и двадцатью штраф составляет около десяти процентов.
  <span class="src">meta.json каждого запуска · outside_busy_share против относительного времени</span></figcaption></figure>
  {band_table}
  <div class="col">
    <p>Порог отбраковки стоял на 0.25 — выше полосы, где начинается заметный штраф, поэтому запуски ценой в
    десять процентов проходили его молча, тогда как измеряемые эффекты составляют один-четыре процента. Порог
    ужесточён до 0.10, девять уже записанных запусков отбракованы и перезапущены. Одна эта поправка сократила
    ширину интервалов memcached примерно вдвое.</p>
    <p>Стоит назвать ещё две проверки. Механизм отбраковки поначалу лишь переименовывал каталог запуска, и тот
    по-прежнему попадал под шаблон подсчёта в проходе дозаполнения и по-прежнему выглядел чистым в собственных
    метаданных: карантин ничего бы не изолировал, а таблицы выглядели бы правильными. И гипотеза о переменной
    частоте как источнике остаточного разброса была отвергнута измерением, а не рассуждением: за {clock_h}
    часов и {clock_n} выборок, когда работают не менее восьми ядер, частота занятых ядер даёт p10
    {clock_p10}&thinsp;МГц, медиану {clock_med}, p90 {clock_p90}. Регулятор частоты не может объяснить различия
    в пять-двадцать процентов между запусками, значит остаточный разброс принадлежит самим нагрузкам.</p>
  </div>
</section>

<section>
  <div class="col">
    <p class="eyebrow">контекст · более ранний компилятор</p>
    <h2>Тот же ответ на укреплённой вершине</h2>
    <p>Более ранний проход измерил меньший набор конфигураций при трёх повторениях на
    <code>tsan-dev-729521af8965</code> — укреплённой вершине, а не ветке производительности. Он согласуется с
    этапом B на Redis, SQLite и MySQL. Он расходится на memcached и FFmpeg, и в обоих случаях загрязнён именно
    ранний проход: у memcached клиент был настроен на слишком малое число запросов за итерацию, чтобы измерять
    хоть что-то осмысленное, а у FFmpeg число потоков было задано настолько большим, что один кодек ломался
    полностью. Оба дефекта найдены и исправлены до этапа B.</p>
    <p>Вывод в любом случае держится на обоих компиляторах: ни одна конфигурация не выиграла ни там, ни там.</p>
  </div>
  {fig7}
  <figcaption>Четыре конфигурации, измеренные обоими проходами. Только ускорение: ранний компилятор несёт
  счётчики вытеснения P3, из-за которых его штатный эталон искусственно замедлен, а цифры замедления
  относительно неинструментированного кода непригодны.
  <span class="src">results/2026-09-04-729521af8965 (N = 3) против stageB-d3bf9f8c39fe (N = 5)</span></figcaption></figure>
</section>

<section>
  <div class="col">
    <p class="eyebrow">происхождение</p>
    <h2>На чём это основано</h2>
    <p>Оба компилятора — самодостаточные замороженные копии в <code>/extra/alexey/builds/</code>, а не общая
    рабочая сборка, и штамп каждого бинарника сверялся с хешем кампании до измерения. Результаты лежат в
    <code>tools/perf/results/stageB-d3bf9f8c39fe</code> и
    <code>tools/perf/results/yield-d98873cda906</code>; скрипты и заметки зафиксированы в коммите
    <code>ffb2d5a</code>.</p>
    <p>Chromium сюда не входит. Это по-прежнему двенадцать сборок примерно по шесть часов каждая плюс около
    шести суток измерений, и он не запланирован.</p>
  </div>
</section>

<hr class="major">

<section class="appendix">
  <div class="col">
    <p class="eyebrow">приложение A</p>
    <h2>Все измеренные строки</h2>
    <p>Все {n_rows} конфигураций этапа B, затем 16 пар этапа yield.</p>
  </div>
  {appA_table}
  <div class="col"><h3>A/B-пары ветки yield</h3></div>
  {yield_table}
</section>

<section class="appendix">
  <div class="col">
    <p class="eyebrow">приложение B · сравнение с опубликованными цифрами</p>
    <h2>Почему цифры изменились</h2>
    <p>Этот раздел сравнивает с опубликованными результатами статьи и может быть удалён без ущерба для всего,
    что выше.</p>
    <p><b>Охват анализов рухнул, когда их сделали корректными.</b> На <code>threadtest3</code> из SQLite
    фактически выпущенная инструментация падала с 58&thinsp;324 точек до 32&thinsp;635 под компилятором статьи
    — удалено 44&thinsp;%. На укреплённом компиляторе та же конфигурация удаляет 3.2&thinsp;%. Разницу
    объясняют исправления корректности в определении однопоточности, владении блокировками и устранении по
    доминированию, а трёхпроцентное сокращение не может дать большого ускорения.</p>
    <p><b>Опубликованные 2.77× вдобавок держатся на одном невоспроизводимом запуске.</b> Это среднее
    геометрическое по семи подтестам, и удаление одного лишь <code>stress1</code> переводит его в 1.965. На
    этом подтесте мартовский эталон со штатным TSan показал 6&thinsp;417 итераций там, где тот же компилятор,
    те же исходники и те же флаги дают сегодня 106&thinsp;704 — в 16.6 раза больше. Этап B даёт 65
    инструментированных запусков <code>stress1</code> по тринадцати конфигурациям, и весь их размах — от
    81&thinsp;553 до 187&thinsp;109 итераций, то есть 2.29 раза от края до края, непрерывно, а не бимодально.
    Значит, мартовский эталон отстоит от сегодняшней медианы примерно в семь раз дальше, чем весь наблюдаемый
    размах подтеста: изменчивостью от запуска к запуску это не объясняется, и никакое число повторений его бы
    не дало.</p>
    <p>Компилятор статьи на этой машине сегодня воспроизводит 1.271 на том же сравнении, а не 2.773.</p>
  </div>
</section>

</div>
"""

if __name__ == "__main__":
    main()
