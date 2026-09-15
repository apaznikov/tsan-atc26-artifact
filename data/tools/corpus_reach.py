#!/usr/bin/env python3
"""Reach of each analysis on the IR corpus: how many instrumentation sites it removes.

Static sites, not executed accesses. Counts @__tsan_read/write/unaligned call sites per
module under each configuration and reports the reduction against stock. A configuration
that removes nothing anywhere is reported as such rather than averaged into silence.

Usage: corpus_reach.py <llvm-root> <ir-dir> <configurations.txt> [--csv out.csv]
"""
import argparse, glob, os, re, subprocess, sys

SITE = re.compile(r'@__tsan_(?:read|write|unaligned)[a-z0-9_]*')


def sites(opt, flags, path):
    p = subprocess.run([opt, "-passes=module(tsan-module),function(tsan)", *flags,
                        "-S", "-o", "-", path], capture_output=True, text=True)
    if p.returncode != 0:
        return None
    return len(SITE.findall(p.stdout))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("llvm_root"); ap.add_argument("ir_dir"); ap.add_argument("configs")
    ap.add_argument("--csv")
    a = ap.parse_args()
    opt = os.path.join(a.llvm_root, "bin", "opt")

    cfgs = []
    for ln in open(a.configs):
        if ln.startswith("#") or "|" not in ln:
            continue
        n, f = ln.rstrip("\n").split("|", 1)
        if n:
            cfgs.append((n, f.split()))
    mods = sorted(glob.glob(os.path.join(a.ir_dir, "*.ll")))

    rows, failed = [], []
    for m in mods:
        name = os.path.basename(m)[:-3]
        base = sites(opt, [], m)
        if base is None:
            failed.append((name, "stock")); continue
        for cn, cf in cfgs:
            if cn == "stock":
                continue
            n = sites(opt, cf, m)
            if n is None:
                failed.append((name, cn)); continue
            rows.append((name, cn, base, n, base - n))

    if failed:
        print(f"  opt FAILED on {len(failed)} (module, config) pairs: {failed[:5]}")
        print("  A failed run is not a zero-reach result. Fix before reading the table.")

    by_cfg = {}
    for _, cn, b, n, d in rows:
        s = by_cfg.setdefault(cn, [0, 0, 0])
        s[0] += b; s[1] += n; s[2] += 1 if d else 0
    print(f"\n  {'configuration':22s} {'stock sites':>12s} {'after':>10s} {'removed':>9s} {'%':>7s}  modules touched")
    for cn, (b, n, t) in by_cfg.items():
        pct = 100.0 * (b - n) / b if b else 0.0
        print(f"  {cn:22s} {b:12d} {n:10d} {b-n:9d} {pct:6.2f}%  {t}/{len(mods)}")
    zero = [c for c, (b, n, t) in by_cfg.items() if b == n]
    if zero:
        print(f"\n  configurations removing NOTHING anywhere in this corpus: {zero}")

    if a.csv:
        with open(a.csv, "w") as fh:
            fh.write("module,config,stock_sites,sites,removed\n")
            for r in rows:
                fh.write(",".join(str(x) for x in r) + "\n")
        print(f"\n  -> {a.csv}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
