#!/usr/bin/env python3
"""meta_tool.py mark <meta.json> <foreign_max> | is-disturbed <meta.json> | is-done <meta.json>"""
import json, sys
op, p = sys.argv[1], sys.argv[2]
try: m = json.load(open(p))
except Exception: sys.exit(0 if op == "is-disturbed" else 1)
if op == "mark":
    # Disturbance = foreign CPU activity, measured on the CPUs outside our pinned set, where nothing of
# ours can run.  (foreign_cpu_share depends on process accounting and undercounts servers we start
# outside the timed region; it stays in the record but no longer decides.)
    # A null share is NOT a zero. An unpinned session has no outside CPUs, so the gate cannot be applied;
    # comparing None with a float raises TypeError in Python 3, and substituting 0.0 would be a gate that
    # always passes. An ABSENT key (metas written before the field existed) still falls back to the old
    # process-accounting figure, so legacy trees mark exactly as they did.
    share = m["outside_busy_share"] if "outside_busy_share" in m else m.get("foreign_cpu_share", 0)
    m["disturbed"] = bool(m.get("rc", 1) != 0 or (share is not None and share > float(sys.argv[3])))
    m["gate_applied"] = share is not None
    json.dump(m, open(p, "w"), indent=1); print("DISTURBED" if m["disturbed"] else "ok")
elif op == "is-disturbed": sys.exit(0 if m.get("disturbed") else 1)
elif op == "is-done":
    # AN ABSENT "disturbed" KEY MEANS THE GATE NEVER RAN, NOT THAT THE RUN WAS CLEAN. `m.get("disturbed")`
    # returned None for a meta.json that never reached `mark`, which is falsy, so such a cell counted as
    # DONE and was skipped on the next pass -- a run whose disturbance was never assessed, treated as
    # assessed and clean. Today run.sh always marks, so this was latent; requiring the key to be present
    # makes a future path that forgets to mark redo the cell instead of inheriting a pass. (Audit,
    # 2026-09-19.) is-disturbed keeps its meaning: it answers "was it marked disturbed", and an unmarked
    # cell is not re-run at the end because is-done has already sent it back through the runner.
    sys.exit(0 if (m.get("rc") == 0 and "disturbed" in m and not m["disturbed"]) else 1)
