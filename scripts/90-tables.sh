#!/usr/bin/env bash
# Regenerates every table from recorded runs: the per-application performance tables (aggregate.py),
# the results ledger (results_ledger.py), and the preservation and eviction tables. Works on the
# data we shipped (default) or on a results tree you produced with 40-perf.sh.
#
#   scripts/90-tables.sh                     # from the shipped campaign roots and sweep under data/perf, plus the ledger trees
#   scripts/90-tables.sh results/perf-XXXX   # from your own run
#
# Nothing is written into data/: the trees are copied to results/tables/<name>/ and regenerated there,
# so the shipped files stay as evidence of what we saw and your regeneration can be diffed against them.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../env.sh
. "$here/env.sh"
for a in "$@"; do
  case "$a" in
    -*) echo "$(basename "$0") takes results trees, not flags (got: $a). With no argument it regenerates from the shipped data."; exit 2 ;;
    *) [ -d "$a" ] || { echo "not a results tree: $a"; exit 2; } ;;
  esac
done
tools="$ART_DATA/tools/perf"
out="$ART_RESULTS/tables"; mkdir -p "$out"

regen_perf() { # regen_perf <results tree>
  local tree="$1" name; name="$(basename "$tree")"
  local copy="$out/$name"; rm -rf "$copy"; cp -r "$tree" "$copy"
  rm -f "$copy"/perf_*.md "$copy"/perf_*.csv "$copy"/perf_*.json
  python3 "$tools/aggregate.py" "$copy" >"$copy/aggregate.log" 2>&1 || { tail -5 "$copy/aggregate.log"; return 1; }
  # A tree that ships runs-2-5 cross-check tables needs the second invocation that produces them, or the
  # comparison below asks for files this run cannot have written and reports a difference that is not one.
  if ls "$tree"/perf_*.runs2-5.json >/dev/null 2>&1; then
    python3 "$tools/aggregate.py" --runs 2-5 "$copy" >>"$copy/aggregate.log" 2>&1 || { tail -5 "$copy/aggregate.log"; return 1; }
  fi
  echo "  $name: $(grep -cE '^[a-z]+: [0-9]+ configs' "$copy/aggregate.log") applications -> $copy/perf_summary.md"
  if ls "$tree"/perf_*.json >/dev/null 2>&1; then
    local same=1 missing=0 f b
    for f in "$tree"/perf_*.json; do
      b="$(basename "$f")"
      [ -f "$copy/$b" ] || { echo "    NOT REGENERATED: $b"; missing=1; continue; }
      cmp -s "$f" "$copy/$b" || { echo "    DIFFERS: $b"; same=0; }
    done
    if [ "$same" = 1 ] && [ "$missing" = 0 ]; then
      echo "    identical to the shipped tables"
    else
      # A shipped table that does not follow from the shipped runs is the one thing this script exists to
      # detect, so it is a failure and not a remark. Until 19 Sep 2026 it printed the line and exited 0,
      # and the correctness set reported PASS over it.
      echo "    the shipped tables do not follow from the shipped runs (regenerated copies in $copy)" >&2
      return 1
    fi
  fi
}

if [ $# -eq 0 ]; then
  echo "Regenerating the performance tables from the shipped runs:"
  # The campaign roots first: they are what every performance claim rests on. Until 19 Sep 2026 this
  # regenerated only the two Stage B trees, which are shipped as data and support no claim, so the
  # documented one-command check re-derived the retired numbers and not the paper's.
  rc=0
  for r in "$ART_DATA"/perf/campaign-*/*/ "$ART_DATA"/perf/ffmpeg-threadsweep-*/*/ "$ART_DATA"/perf/sweep-apollo-*/*/; do
    [ -d "$r" ] && { regen_perf "${r%/}" || rc=1; }
  done
  regen_perf "$ART_DATA/perf/stageB-d3bf9f8c39fe" || rc=1
  regen_perf "$ART_DATA/perf/redis-stageB-repeat-2026-09-14" || rc=1
  echo
  echo "Regenerating the results ledger (what each configuration is worth):"
  python3 "$tools/results_ledger.py" --print >"$out/results-ledger-tables.md"
  echo "  $out/results-ledger-tables.md ($(wc -l <"$out/results-ledger-tables.md") lines)"
  echo
  echo "Preservation tables (race reports per configuration): shipped as data/preservation/*/preservation_<app>.md;"
  echo "regenerate one with: python3 $ART_DATA/tools/preservation/tsan_reports.py <tree>  (see its --help)"
else
  rc=0
  for t in "$@"; do regen_perf "$t" || rc=1; done
fi
if [ $# -eq 0 ]; then
  # Last, after the regeneration, so it checks what this step produced and not what was on disk before it:
  # do the documents still agree with the data they ship? Every configuration row CLAIMS.md claims, against
  # the shipped campaign cells, through the same comparator an evaluator's run ends with. It asserts that
  # some rows were judged and that none is outside; the count is printed, not asserted, because CLAIMS.md
  # can gain a row without anything being wrong. "0 judged, 0 outside" is the state it exists to refuse.
  echo
  echo "The documents against the data they ship (harness/tools/perf/check_shipped_comparison.sh):"
  chk="$ART_ROOT/harness/tools/perf/check_shipped_comparison.sh"
  if out=$("$chk" 2>&1); then printf '%s\n' "$out" | tail -1 | sed 's/^/  /'
  else printf '%s\n' "$out" | tail -4 | sed 's/^/  /'; rc=1; fi
  # And the refusal that makes the comparison mean something: a tree whose clip is not the reference one must
  # be reported as not comparable, never judged. Built here from copies of the shipped FFmpeg cells' metadata
  # with input_is_reference set to false; nothing shipped is touched. Until 20 Sep 2026 a chain-ordering
  # defect judged exactly such trees, which this control would have caught.
  ctl=$(mktemp -d); src="$ART_DATA/perf/campaign-f3deebfbab60/primary"; t="$ctl/perf-ffmpeg-control"
  mkdir -p "$t" && cp "$src/perf_ffmpeg.md" "$t/"
  while IFS= read -r m; do
    mkdir -p "$t/$(dirname "$m")"
    python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); d["input_is_reference"]=False; json.dump(d,open(sys.argv[2],"w"))' "$src/$m" "$t/$m"
  done < <(cd "$src" && find ffmpeg -name meta.json)
  # Captured, then searched: `python3 ... | grep -q` under pipefail reports failure when grep closes the pipe
  # on the first match and the comparator dies of SIGPIPE, which is how this control failed on its first run.
  cout=$(python3 "$ART_ROOT/harness/tools/perf/compare_with_claims.py" "$ART_ROOT/CLAIMS.md" "$t" 2>&1 || true)
  if printf '%s\n' "$cout" | grep -c 'not comparable: not the reference clip' >/dev/null; then
    echo "  ok: a run on a clip that is not the reference is refused, not judged (control)"
  else
    echo "  FAIL: a run on a non-reference clip was not refused by the comparator (control)" >&2; rc=1
  fi
  rm -rf "$ctl"
fi
if [ "${rc:-0}" -ne 0 ]; then
  echo "Done, with at least one tree whose shipped tables do not follow from its shipped runs, or a document that disagrees with the data." >&2
  exit 1
fi
echo "Done."
