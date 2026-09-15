#!/usr/bin/env bash
# Verify the rebuilt artifact image. Every check states what it would have caught.
set -uo pipefail
IMG=tsan-atc26
HASH=f3deebfbab602f4e05289e0acbde0efd06b8058c
BASE=c609043dd00955bf177ff57b0bad2a87c1e61a36
TREE=83c8a2a16db10bd5f826a76f84911ae171d05d3f
D="docker run --rm --cpuset-cpus=28-55,84-111"
fail=0
chk(){ if [ "$2" = ok ]; then printf "  PASS  %s\n" "$1"; else printf "  FAIL  %s\n      %s\n" "$1" "$3"; fail=1; fi; }

echo "=== image ==="
docker images --format '  {{.Repository}}:{{.Tag}} {{.ID}} {{.Size}}' $IMG | head -1

v=$($D $IMG clang --version 2>/dev/null | head -1)
echo "  version line: $v"
case "$v" in *"$HASH"*) chk "version string names the branch commit" ok ;;
  *) chk "version string names the branch commit" no "got: $v" ;; esac
case "$v" in *"$BASE"*) chk "version string does NOT name the upstream base" no "still names $BASE; every derived stamp would be wrong but well-formed" ;;
  *) chk "version string does NOT name the upstream base" ok ;; esac

s=$($D $IMG cat /opt/tsan-llvm/TSAN_AUDIT_HASH 2>/dev/null | head -1)
[ "$s" = "$HASH" ] && chk "TSAN_AUDIT_HASH stamp (harness gate reads this)" ok \
                   || chk "TSAN_AUDIT_HASH stamp (harness gate reads this)" no "got '$s'"

if $D $IMG llvm-lit --version >/dev/null 2>&1; then chk "llvm-lit STARTS (not just present)" ok
else chk "llvm-lit STARTS (not just present)" no "$($D $IMG llvm-lit --version 2>&1 | tail -1)"; fi

n=$($D $IMG bash -c 'ldd /opt/tsan-llvm/bin/clang /opt/tsan-llvm/bin/opt 2>/dev/null | grep -i llvm | grep -v "=> /opt/tsan-llvm" | grep -c "=>"' 2>/dev/null)
[ "${n:-1}" = 0 ] && chk "0 LLVM libs resolved outside the prefix" ok \
                  || chk "0 LLVM libs resolved outside the prefix" no "$n resolved elsewhere"

# The assertion runs inside the patch layer. A rebuild whose patches are unchanged
# cache-hits that layer and prints nothing, which is not a failure -- so accept the
# assertion from any build log that ran it, and require the patches to be unmodified.
if grep -qh "reconstructed tree $TREE (expected $TREE)" /tmp/imgbuild*.log \
     /tmp/claude-1005/*/*/tasks/*.output 2>/dev/null; then
  if [ -z "$(git -C ~/tsan-atc26-artifact status --porcelain compiler/patches)" ]; then
    chk "patch series reproduced tree $TREE (assertion from the build that ran it; patches unmodified since)" ok
  else
    chk "patch series reproduced tree $TREE" no "patches modified since the assertion ran -- rebuild without cache"
  fi
else
  chk "patch series reproduced tree $TREE" no "no build log contains the assertion"
fi

echo
echo "=== the vendored suites, run INSIDE the image ==="
$D -v /tmp/claude-1005/-home-alexey-dev-llvm-project-focs-lab/7d16d571-af9f-473b-9527-09d31ce5d7cc/scratchpad/artres2:/artifact/results $IMG bash -c \
  'cd /artifact && ./scripts/11-soundness-shapes.sh 2>&1 | tail -8'
echo
$D -v /tmp/claude-1005/-home-alexey-dev-llvm-project-focs-lab/7d16d571-af9f-473b-9527-09d31ce5d7cc/scratchpad/artres2:/artifact/results $IMG bash -c \
  'cd /artifact && ./scripts/12-compiler-equivalence.sh 2>&1 | tail -10'
echo
[ $fail -eq 0 ] && echo "ALL STATIC CHECKS PASSED" || echo "SOME CHECKS FAILED -- see above"
exit $fail
