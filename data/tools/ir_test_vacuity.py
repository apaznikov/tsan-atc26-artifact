#!/usr/bin/env python3
"""Classify the vendored TSan IR tests by what each one can actually detect.

A CHECK-NOT with no CHECK counterpart proves nothing: a test that asserts an access
was removed will also pass against a compiler that never instrumented it in the first
place. This tool separates the two directions mechanically, without trusting names.

For each test, every RUN line is executed twice -- once as written, once with every
-tsan-* flag stripped -- and the __tsan read/write call sites are counted in each:

  removal test   flags ON produce FEWER sites than flags stripped. The analysis is doing
                 something here, so the test MUST fail when the flags are stripped.
                 If it still passes, its CHECK-NOT is not pinning the removal: vacuous.
  control test   the counts are equal. The test asserts instrumentation STAYS, which is
                 the positive-control direction; passing without the analysis is correct.

Exit status is non-zero if any test is vacuous, or if the removal/control split does not
match --expect-removal / --expect-control when those are given.

Usage: ir_test_vacuity.py <llvm-root> <test-dir> [--expect-removal N] [--expect-control N]
"""
import argparse, glob, json, os, re, subprocess, sys

FLAG = re.compile(r'\s--?tsan-[A-Za-z0-9-]+(=[A-Za-z0-9._]+)?')
TOOL = re.compile(r'\b(opt|FileCheck|llvm-link|count|not)\b')
SITE = re.compile(r'@__tsan_(?:read|write|unaligned)')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("llvm_root"); ap.add_argument("test_dir")
    ap.add_argument("--expect-removal", type=int); ap.add_argument("--expect-control", type=int)
    ap.add_argument("--json", help="write the per-test classification here")
    a = ap.parse_args()
    bindir = os.path.join(a.llvm_root, "bin")
    if not os.path.isdir(bindir):
        print(f"no bin/ under {a.llvm_root}", file=sys.stderr); return 2

    def sh(c):
        return subprocess.run(["/bin/sh", "-c", c], capture_output=True, text=True)

    def tools(c):
        return TOOL.sub(lambda m: os.path.join(bindir, m.group(1)), c)

    out = {"removal": [], "control": [], "vacuous": [], "skipped": []}
    for t in sorted(glob.glob(os.path.join(a.test_dir, "*.ll"))):
        b, ap_ = os.path.basename(t), os.path.abspath(t)
        runs = [l.split("RUN:", 1)[1].strip() for l in open(t) if re.match(r'^;\s*RUN:', l)]
        runs = [r for r in runs if "%t" not in r and "|" in r]
        if not runs:
            out["skipped"].append(b); continue
        is_removal, vacuous = False, True
        for r in runs:
            m = FLAG.sub(' ', r)
            if m == r:
                continue
            on = sh(tools(r.split("|")[0].replace("%s", ap_))).stdout
            off = sh(tools(m.split("|")[0].replace("%s", ap_))).stdout
            if len(SITE.findall(on)) < len(SITE.findall(off)):
                is_removal = True
                if sh(tools(m.replace("%s", ap_))).returncode != 0:
                    vacuous = False
        if not is_removal:
            out["control"].append(b)
        elif vacuous:
            out["vacuous"].append(b)
        else:
            out["removal"].append(b)

    print(f"  removal tests, fail when the analysis flags are stripped : {len(out['removal'])}")
    print(f"  control tests, instrumentation stays                     : {len(out['control'])}")
    print(f"  VACUOUS, claim a removal but pass without the analysis    : {len(out['vacuous'])}")
    for f in out["vacuous"]:
        print(f"      {f}")
    if out["skipped"]:
        print(f"  skipped, multi-step or no FileCheck pipe                 : {len(out['skipped'])} {out['skipped']}")
    if a.json:
        with open(a.json, "w") as fh:
            json.dump(out, fh, indent=1)

    rc = 0
    if out["vacuous"]:
        print("FAIL: a test asserts a removal it cannot detect.", file=sys.stderr); rc = 1
    for key, want in (("removal", a.expect_removal), ("control", a.expect_control)):
        if want is not None and len(out[key]) != want:
            print(f"FAIL: expected {want} {key} tests, found {len(out[key])}.", file=sys.stderr); rc = 1
    return rc


if __name__ == "__main__":
    sys.exit(main())
