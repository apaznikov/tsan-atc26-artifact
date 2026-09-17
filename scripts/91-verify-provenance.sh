#!/usr/bin/env bash
# Checks that every measured run in a results tree is attributable: that it records the compiler it
# was built by, the binary it ran, the input it read, the processor set and mode it ran under, the
# foreign-activity share the disturbance gate saw, and that each configuration has its full N.
#
# Usage: scripts/91-verify-provenance.sh [root ...]      default: every root under data/perf
#
# This answers "was this measured the way we say", and it reads only what the runs themselves
# recorded, so it cannot be satisfied by a script having been told the right thing. Two limits worth
# knowing: it does not check that a configuration's flags were the intended ones (that is the build
# guard, at build time, in build_info.txt), and it says nothing about whether a number is right. A
# tree can pass this and still be wrong; it cannot pass this and be unattributable.
set -euo pipefail
for a in "$@"; do case "$a" in -*) echo "$(basename "$0") takes results roots, not flags (got: $a)"; exit 2 ;; esac; done
. "$(dirname "$0")/_lib.sh"
need_harness tools/perf

# Two kinds of root. The campaign roots (data/perf/campaign-*) are the ones every performance claim in
# CLAIMS.md rests on, and they are checked strictly: any problem fails this script. The earlier trees
# shipped beside them (Stage B, the sweeps, the profiles) were recorded before the harness wrote every
# field this checks -- their FFmpeg runs, for one, carry an empty input hash -- and were measured on
# earlier compilers, so they are reported here for information and never counted as a pass or a
# failure. No claim rests on them. With no campaign root present, nothing is verified and the script
# says so with exit 2 rather than passing on the legacy trees.
roots=("$@")
if [ ${#roots[@]} -eq 0 ]; then
  mapfile -t roots < <(find "$ART_DATA/perf" -mindepth 1 -maxdepth 1 -type d | sort)
fi
[ ${#roots[@]} -gt 0 ] || { echo "no results roots found under $ART_DATA/perf"; exit 2; }
strict=(); legacy=()
for r in "${roots[@]}"; do case "$(basename "$r")" in campaign-*) strict+=("$r") ;; *) legacy+=("$r") ;; esac; done

budget "provenance of ${#strict[@]} campaign root(s), ${#legacy[@]} earlier tree(s) for information" "2 min" "1 min" "none"
rc=0
CAMPAIGN_HASH=f3deebfbab602f4e05289e0acbde0efd06b8058c
for r in "${strict[@]}"; do
  echo "== $r  (campaign root: checked strictly against $CAMPAIGN_HASH)"
  python3 "$harness/tools/perf/verify_provenance.py" --expect="$CAMPAIGN_HASH" "$r" || rc=1
done
# An earlier tree is asked the question that applies to it: did every run in it use one compiler, one
# processor set and one mode, and are its fields present -- not whether that compiler is today's.
# The counter and profile trees (combo-counters, merge-counters, profile-2026-09-09*) were recorded by
# an earlier harness that wrote no compiler head into run metadata at all; for those the self-check
# reports that no expectation can be derived, which is the correct description: the field is absent,
# not inconsistent. Their compiler is recorded in their build logs (build/*.log, naming the frozen
# copies tsan-merge-afe47a2a75a5 and tsan-perf-d3bf9f8c39fe) and in data/README.md, not per run.
# Two known findings on the Stage B tree are stated rather than left to be inferred: its FFmpeg runs
# carry an empty input hash (the relative-path trap, fixed since), and five of its 500 runs sit above
# today's 0.10 foreign-activity gate; they were inside the 0.25 gate in force when they were taken.
for r in "${legacy[@]}"; do
  echo "== $r  (earlier tree: checked against its own compiler, for information; not counted)"
  python3 "$harness/tools/perf/verify_provenance.py" --expect-self "$r" 2>&1 | grep -E "EMPTY|MISSING|PROBLEM|OK|runs,|agree|above" | sed 's/^/    /' || true
done
if [ ${#strict[@]} -eq 0 ]; then
  echo "No campaign root under $ART_DATA/perf: nothing that a claim rests on was verified." >&2
  exit 2
elif [ "$rc" = 0 ]; then
  echo "Every campaign run is attributable: compiler stamp, binary hash, input hash, processor set and"
  echo "mode, gate share and run count are present, singular per configuration, and consistent."
else
  echo "Provenance failed on a campaign root above. A table computed from it carries conditions it cannot state." >&2
fi
exit "$rc"
