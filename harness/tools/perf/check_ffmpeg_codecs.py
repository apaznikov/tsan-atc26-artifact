#!/usr/bin/env python3
"""check_ffmpeg_codecs.py <results-root> — every FFmpeg run must carry all four codecs.

WHY THIS EXISTS. `-threads` goes straight to the encoder, and libx265 refuses anything above
X265_MAX_FRAME_THREADS (16): at a pinned-CPU-count default of 48 the h265 codec FAILS ON EVERY BUILD and
simply vanishes from the results. Nothing errors. The run parses, the table is produced, and the geomean is
taken over three codecs instead of four -- a different quantity, reported under the same name.

That is why the leg sets FF_THREADS=4. This checks the outcome rather than the setting, because a flag that
reached the script is not the same as a codec that produced a number, and the campaign has already been
bitten once by exactly that gap (a flag recorded in build_info.txt that had not reached the compiler).

A missing codec is not a smaller sample. It changes the SET OF TESTS the geomean covers, so an FFmpeg row
computed over three codecs cannot be compared with one computed over four -- including with the paper's.
"""
import json, glob, os, sys
from collections import defaultdict

EXPECTED = {"copy_passthrough", "h264_libx264", "h265_libx265", "mjpeg"}

def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "results/campaign-f3deebfbab60/primary"
    import importlib.util
    spec = importlib.util.spec_from_file_location("agg", os.path.join(os.path.dirname(os.path.abspath(__file__)), "aggregate.py"))
    agg = importlib.util.module_from_spec(spec); sys.modules["agg"] = agg; spec.loader.exec_module(agg)
    parser, _ = agg.PARSERS["ffmpeg"]
    d = os.path.join(root, "ffmpeg")
    if not os.path.isdir(d):
        print(f"no ffmpeg runs under {root}"); return 1
    bad = []; seen = defaultdict(set); n = 0
    for m in sorted(glob.glob(f"{d}/*/run*/meta.json")):
        rd = os.path.dirname(m); b = os.path.basename(rd)
        if not b[3:].isdigit(): continue                      # run1.disturbed.*, warmup*
        j = json.load(open(m))
        if j.get("rc") != 0 or j.get("disturbed"): continue
        n += 1
        try: got = {k for k in parser(rd) if not k.startswith("_")}
        except Exception as e: bad.append((j["config"], b, f"parse error: {e}")); continue
        seen[j["config"]] |= got
        missing = EXPECTED - got
        if missing: bad.append((j["config"], b, "missing " + ", ".join(sorted(missing))))
    print(f"ffmpeg runs checked: {n}")
    if not n:
        # SKIP, not PASS (tsan-paper's distinction, 2026-09-16). "No runs exist yet" and "every run carries
        # all four codecs" are opposite states, and returning 0 for both means an automated caller treats an
        # unmeasured leg as a verified one -- the same shape as the leg that reported complete having run
        # nothing. Exit 3 so a caller can tell absence of evidence from evidence.
        print("  SKIP: no ffmpeg runs in this tree — nothing was checked, and that is not a pass")
        return 3
    if bad:
        print(f"  RUNS WITH A MISSING CODEC: {len(bad)}  <<< the geomean would cover a different test set")
        for cfg, run, why in bad[:20]: print(f"    {cfg:38s} {run:8s} {why}")
        print("  Check FF_THREADS: libx265 refuses more than 16 frame threads and drops out silently.")
        return 2
    print(f"  all {n} runs carry all four codecs: {', '.join(sorted(EXPECTED))}")
    odd = {c: v for c, v in seen.items() if v != EXPECTED}
    if odd:
        print("  configurations whose codec set differs from the expected four:")
        for c, v in odd.items(): print(f"    {c}: {sorted(v)}")
        return 2
    return 0

sys.exit(main())
