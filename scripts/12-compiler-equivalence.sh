#!/usr/bin/env bash
# Does the compiler in this checkout produce the same instrumentation as the one the
# paper's numbers were measured with? Recomputes the __tsan_* histogram of every module
# in the vendored IR corpus under every configuration and compares with the reference
# table taken from the frozen campaign compiler.
# Usage: scripts/12-compiler-equivalence.sh [--keep-ir]     --keep-ir leaves the unpacked corpus
set -euo pipefail
. "$(dirname "$0")/_lib.sh"
need_compiler

keep=0
case "${1:-}" in
  --keep-ir) keep=1 ;;
  "") ;;
  *) echo "usage: scripts/12-compiler-equivalence.sh [--keep-ir]"; exit 2 ;;
esac

budget "compiler equivalence on the IR corpus" "3 min" "1 min" "200 MB"
refuse_if_lit_running    # opt is cheap, but a lit run competing for cores makes this crawl

ref="$ART_DATA/equivalence/reference-histograms.tsv"
cfgs="$ART_DATA/equivalence/configurations.txt"
tarball="$ART_DATA/equivalence/ir-corpus.tar.gz"
for f in "$ref" "$cfgs" "$tarball"; do
  [ -f "$f" ] || { echo "missing vendored input: $f"; exit 2; }
done

name="compiler-equivalence-$(stamp)"
outdir="$ART_RESULTS/$name"; mkdir -p "$outdir"
ir="$outdir/ir"; mkdir -p "$ir"
tar -C "$ir" -xzf "$tarball"

# Provenance and behaviour are two different questions and this script answers both
# separately, because the corpus cannot answer the first. Measured 2026-09-15: the whole
# 24-commit soundness series (aa8a6dd8a2e8 -> f3deebfbab60) changes ZERO of the 112 rows
# below -- the lost-race shapes it fixes do not occur in these programs. So an identical
# corpus proves the compiler instruments identically, NOT that it is the same commit.
ref_stamp=$(grep -m1 '^#   stamp ' "$ART_DATA/equivalence/reference-histograms.tsv" | awk '{print $3}')
got_stamp=$(head -1 "$TSAN_LLVM_ROOT/TSAN_AUDIT_HASH" 2>/dev/null || echo "")
echo "compiler : $TSAN_LLVM_ROOT"
echo "           $("$TSAN_LLVM_ROOT/bin/clang" --version | head -1)"
echo "corpus   : $(find "$ir" -name '*.ll' | wc -l) modules"
echo "reference: $ref"
echo
echo "=== provenance: the stamp, which the corpus comparison cannot establish ==="
if [ -z "$got_stamp" ]; then
  echo "  WARNING: no TSAN_AUDIT_HASH in $TSAN_LLVM_ROOT -- provenance unverified."
  stamp_rc=1
elif [ "$got_stamp" = "$ref_stamp" ]; then
  echo "  ok: $got_stamp, the commit the reference table was produced with"
  stamp_rc=0
else
  echo "  MISMATCH: this compiler stamps $got_stamp, the reference table $ref_stamp"
  echo "  The histogram comparison below may still come out clean: it is insensitive to"
  echo "  changes whose shapes do not occur in this corpus."
  stamp_rc=1
fi
echo

# The corpus is unpacked from a tarball, so every .ll is a real file. In the source tree
# these are symlinks into another directory; bind-mounting only their names into a
# container gives opt nothing to read and every histogram comes back empty. That is why
# the empty-hash count below is asserted rather than assumed.
: > "$outdir/measured.tsv"
while IFS='|' read -r cname cflags; do
  [ -n "$cname" ] || continue
  for f in "$ir"/*.ll; do
    m=$(basename "$f" .ll)
    h=$("$TSAN_LLVM_ROOT/bin/opt" -passes='module(tsan-module),function(tsan)' \
          $cflags -S -o - "$f" 2>/dev/null \
        | grep -oE "@__tsan_[a-z0-9_]+" | sort | uniq -c | md5sum | cut -c1-12)
    printf "%s\t%s\t%s\n" "$m" "$cname" "$h" >> "$outdir/measured.tsv"
  done
done < "$cfgs"

set +e
python3 - "$ref" "$outdir/measured.tsv" <<'PY' | tee "$outdir/report.txt"
import sys, collections
EMPTY = "d41d8cd98f00"          # md5 of the empty string: opt produced no output at all
def load(p):
    d = {}
    for ln in open(p):
        if ln.startswith("#") or not ln.strip():
            continue
        m, c, h = ln.rstrip("\n").split("\t")
        d[(m, c)] = h
    return d
ref, got = load(sys.argv[1]), load(sys.argv[2])
missing = sorted(set(ref) - set(got)); extra = sorted(set(got) - set(ref))
shared = sorted(set(ref) & set(got))
diff = [k for k in shared if ref[k] != got[k]]
empty = [k for k in shared if got[k] == EMPTY]
print(f"  rows compared                 : {len(shared)}")
print(f"  rows in the reference, not run: {len(missing)} {missing[:4]}")
print(f"  rows run, not in the reference: {len(extra)} {extra[:4]}")
print(f"  EMPTY histograms (opt failed) : {len(empty)} {empty[:4]}")
print(f"  rows DIFFERING                : {len(diff)}")
for k in diff[:20]:
    print(f"      {k[0]:24s} {k[1]:8s} reference={ref[k]} measured={got[k]}")

# Sensitivity, from the reference table itself: if every configuration produced the same
# histogram on every module, agreement would be free and would prove nothing.
bym = collections.defaultdict(set)
for (m, c), h in ref.items():
    bym[m].add(h)
sep = sum(1 for hs in bym.values() if len(hs) > 1)
print(f"  modules whose histogram separates the configurations: {sep}/{len(bym)}")
print(f"  distinct histograms across the reference table      : {len(set(ref.values()))}")

rc = 0
if empty:
    print("FAIL: opt produced no output for some rows. This is an instrument failure, not a"); rc = 1
    print("      compiler difference -- fix it before reading anything else here.")
if missing or extra:
    print("FAIL: the corpus or the configuration list does not match the reference table."); rc = 1
if diff:
    print("FAIL: this compiler does not instrument the corpus the way the campaign compiler did."); rc = 1
if sep < 2:
    print("FAIL: the reference table cannot separate the configurations; agreement is vacuous."); rc = 1
if rc == 0:
    print("RESULT: identical instrumentation on every module in every configuration,")
    print("        and the comparison is one that would have shown a difference.")
sys.exit(rc)
PY
rc=${PIPESTATUS[0]}
set -e
if [ "${stamp_rc:-1}" -ne 0 ]; then
  echo "NOTE: the instrumentation matches but the provenance stamp does not. Treat this as"
  echo "      'behaves like the campaign compiler', not 'is the campaign compiler'."
  rc=1
fi
[ $keep -eq 1 ] || rm -rf "$ir"
echo "-> $outdir"
exit $rc
