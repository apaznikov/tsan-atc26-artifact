#!/usr/bin/env bash
# Verifies the artifact image: that it is the compiler this artifact claims, that its tools start,
# that it is self-contained, and that the two vendored suites pass inside it. Every check states
# what it would have caught. Usage: scripts/13-verify-image.sh [image]     default: tsan-atc26
#
# Three outcomes per check, and the distinction matters: PASS, FAIL, and SKIP. A check is skipped
# only when the evidence it needs does not exist in this context, and it says how to produce it. A
# skipped check never counts as a pass. The script exits non-zero if anything FAILED.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/scripts/_lib.sh"

static_only=0
args=()
for a in "$@"; do case "$a" in
  --static) static_only=1 ;;   # the checks that take seconds; skips the two suites
  *) args+=("$a") ;;
esac; done
IMG=${args[0]:-${ART_IMAGE:-tsan-atc26}}
HASH=f3deebfbab602f4e05289e0acbde0efd06b8058c
BASE=c609043dd00955bf177ff57b0bad2a87c1e61a36
TREE=83c8a2a16db10bd5f826a76f84911ae171d05d3f
cpus=(); [ -n "${ART_CPUSET:-}" ] && cpus=(--cpuset-cpus "$ART_CPUSET")
D=(docker run --rm --security-opt seccomp=unconfined "${cpus[@]}")
pass=0; failed=0; skipped=0
chk(){ case "$2" in
  ok)   printf '  PASS  %s\n' "$1"; pass=$((pass+1)) ;;
  skip) printf '  SKIP  %s\n        %s\n' "$1" "${3:-}"; skipped=$((skipped+1)) ;;
  *)    printf '  FAIL  %s\n        %s\n' "$1" "${3:-}"; failed=$((failed+1)) ;;
esac; }

docker image inspect "$IMG" >/dev/null 2>&1 || { echo "no such image: $IMG (build it with docker/build.sh)"; exit 2; }
echo "=== image ==="
docker images --format '  {{.Repository}}:{{.Tag}} {{.ID}} {{.Size}}' "$IMG" | head -1

v=$("${D[@]}" "$IMG" clang --version 2>/dev/null | head -1 || true)
echo "  version line: ${v:-<none>}"
# Positive control first: without it, an image with no clang at all answers every question below
# with an empty string, and "the version line does not name the upstream base" passes vacuously.
case "$v" in
  "clang version"*)
    chk "the image has a clang that runs" ok
    case "$v" in *"$HASH"*) chk "version string names the branch commit" ok ;;
      *) chk "version string names the branch commit" no "got: $v" ;; esac
    case "$v" in *"$BASE"*) chk "version string does NOT name the upstream base" no "still names $BASE; every derived stamp would be wrong but well-formed" ;;
      *) chk "version string does NOT name the upstream base" ok ;; esac ;;
  *)
    chk "the image has a clang that runs" no "\`clang --version\` gave: ${v:-nothing}. Every check below it would pass on an empty answer, so they are not attempted." ;;
esac

s=$("${D[@]}" "$IMG" cat /opt/tsan-llvm/TSAN_AUDIT_HASH 2>/dev/null | head -1 || true)
case "$s" in "$HASH") chk "TSAN_AUDIT_HASH present and correct" ok ;;
  "") chk "TSAN_AUDIT_HASH present" no "absent; the harness compiler gate refuses to start" ;;
  *) chk "TSAN_AUDIT_HASH correct" no "got: $s" ;; esac

if "${D[@]}" "$IMG" llvm-lit --version >/dev/null 2>&1; then chk "llvm-lit STARTS (not just present)" ok
else chk "llvm-lit STARTS (not just present)" no "$("${D[@]}" "$IMG" llvm-lit --version 2>&1 | tail -1)"; fi

# Again a positive control: count the LLVM libraries resolving INSIDE the prefix. If that is zero
# there is nothing dynamically linked to be self-contained about, and "none outside" means nothing.
read -r inside outside < <("${D[@]}" "$IMG" bash -c 'l=$(ldd /opt/tsan-llvm/bin/clang /opt/tsan-llvm/bin/opt 2>/dev/null | grep -i llvm); printf "%s %s" "$(printf "%s" "$l" | grep -c "=> /opt/tsan-llvm")" "$(printf "%s" "$l" | grep -v "=> /opt/tsan-llvm" | grep -c "=>")"' 2>/dev/null || echo "0 0")
if [ "${inside:-0}" -gt 0 ] 2>/dev/null; then
  case "$outside" in 0) chk "no LLVM library resolves outside /opt/tsan-llvm ($inside resolve inside it)" ok ;;
    *) chk "no LLVM library resolves outside /opt/tsan-llvm" no "$outside do; the install is not self-contained" ;; esac
else
  chk "the install is self-contained" no "no LLVM library resolves inside /opt/tsan-llvm either, so there is nothing to be self-contained about: the prefix is missing or the binaries are not there"
fi

# The tree the patch step measured is the image's own second stamp line since 20 Sep 2026, so the check
# is made from the image, from any checkout. An image built before that carries the expected constant
# there instead; for it, accept the assertion from a build log if one is here, otherwise say what the
# image is and how to replace it, because absence of a record is not evidence of a bad tree.
stamp2=$("${D[@]}" "$IMG" sed -n 2p /opt/tsan-llvm/TSAN_AUDIT_HASH 2>/dev/null || true)
case "$stamp2" in
  "reconstructed-tree $TREE")
    chk "patch series reproduced tree $TREE (the image's own stamp, written by its build from the measured tree)" ok ;;
  reconstructed-tree\ *)
    chk "patch series reproduced tree $TREE" no "the image's stamp says ${stamp2#reconstructed-tree }: not built from these patches" ;;
  *)
    logs=$(ls "$ART_RESULTS"/image-build*.log "$here"/docker/build*.log /tmp/imgbuild*.log 2>/dev/null || true)
    if [ -n "$logs" ] && grep -qh "reconstructed tree $TREE (expected $TREE)" $logs 2>/dev/null; then
      if [ -z "$(git -C "$here" status --porcelain compiler/patches 2>/dev/null)" ]; then
        chk "patch series reproduced tree $TREE (from a build log; patches unmodified since)" ok
      else
        chk "patch series reproduced tree $TREE" no "patches modified since that log -- rebuild with ./docker/build.sh --no-cache"
      fi
    else
      chk "patch series reproduced tree $TREE" skip \
        "this image was built from an earlier checkout, before the build stamped the measured tree into it, and no build log here carries the assertion; ./evaluate.sh <tier> --rebuild builds it again (15-25 min) and stamps it"
    fi ;;
esac

echo
echo "=== the vendored suites, run INSIDE the image ==="
mkdir -p "$ART_RESULTS"
if [ "$static_only" = 1 ]; then
  # Not a skip: with --static the two suites are left to the correctness set, which runs them as its steps 11
  # and 12 on this same image (an evaluator read the former SKIP line as a check not made, 20 Sep 2026).
  echo "  (the two suites, 11-soundness-shapes and 12-compiler-equivalence, are run by the correctness set on this image, not here)"
fi
for suite in $([ "$static_only" = 1 ] || echo 11-soundness-shapes 12-compiler-equivalence); do
  out=$("${D[@]}" -v "$ART_RESULTS:/artifact/results" "$IMG" bash -c "cd /artifact && ./scripts/$suite.sh" 2>&1); src=$?
  printf '%s\n' "$out" | tail -8 | sed 's/^/    /'
  [ "$src" = 0 ] && chk "$suite passes inside the image" ok \
                 || chk "$suite passes inside the image" no "exit $src; full output above"
done

echo
printf 'checks: %d passed, %d failed, %d skipped\n' "$pass" "$failed" "$skipped"
[ "$failed" = 0 ] || echo "SOME CHECKS FAILED -- see above" >&2
exit $(( failed > 0 ? 1 : 0 ))
