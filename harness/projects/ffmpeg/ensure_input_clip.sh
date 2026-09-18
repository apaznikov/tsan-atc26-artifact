#!/bin/bash
# ensure_input_clip.sh — make the FFmpeg benchmark input present, by whichever of three paths applies.
#
# The clip is not vendored: 78 MB, and derived from a 557 MB source. But NOTHING fetched it, so an
# evaluator whose FFmpeg built then found no input — a failure at run time, after the build cost.
#
# Three paths, in this order, because they differ in what they can promise:
#   1. ART_FFMPEG_CLIP_URL  — a prepared copy (the Zenodo deposit, once it exists). Fetched and checked
#                             against the pinned sha256, so it is bit-identical to what we measured.
#   2. ART_FFMPEG_SOURCE    — a local copy of the Blender source; cut here with the recorded command.
#   3. the Blender source    — fetched from download.blender.org (557 MB, CC-BY 3.0), verified, then cut.
#
# Paths 2 and 3 RE-ENCODE, and a re-encode's sha256 may differ from ours even when the command is identical
# — encoder builds and versions differ. That is why the run records input_is_reference: a run on a
# regenerated clip is valid and is NOT bit-comparable with our numbers, and the artefact says which it is.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]:-$0}")"
CLIP=input/TearsOfSteel-1366x768-100s.mkv
WANT=43b0fba97eb05a0e44d7518fe9d6993c140680531a17a240ea6d53582fbe9985
SRC_URL=https://download.blender.org/demo/movies/ToS/tears_of_steel_1080p.mov.zip
SRC_SHA=d87a41de040d3814dbde143e9ab85ef122caf22265f660b0bebf476cd8b357a5
mkdir -p input
say() { echo "ensure_input_clip: $*"; }

if [ -f "$CLIP" ]; then
  got=$(sha256sum "$CLIP" | cut -d' ' -f1)
  [ "$got" = "$WANT" ] && { say "present, sha256 matches the reference clip"; exit 0; }
  say "present but sha256 differs from the reference — a regenerated clip. Valid, not bit-comparable."; exit 0
fi

if [ -n "${ART_FFMPEG_CLIP_URL:-}" ]; then
  [ -w "$(dirname "$CLIP")" ] || { say "cannot write to $(dirname "$CLIP") — is the harness mounted read-only? Nothing was fetched."; exit 1; }
  # A LOCAL PATH IS NOT A URL WGET CAN FETCH. GNU wget speaks http, https and ftp -- not file:// -- so an
  # evaluator who has the clip on disk and points this variable at it gets "download failed" and falls
  # through to regenerating 557 MB, which is the opposite of what they asked for. Accept a plain path or a
  # file:// URL by copying, and verify the result the SAME way a download is verified: the check below is
  # common to both branches, so a local copy is no more trusted than a remote one.
  src="$ART_FFMPEG_CLIP_URL"; case "$src" in file://*) src="${src#file://}";; esac
  if [ -f "$src" ]; then
    say "copying a prepared clip from $src"
    cp "$src" "$CLIP.part" || { rm -f "$CLIP.part"; say "copy failed from $src"; exit 1; }
  else
    say "fetching a prepared clip from $ART_FFMPEG_CLIP_URL"
    wget -q -O "$CLIP.part" "$ART_FFMPEG_CLIP_URL" || { rm -f "$CLIP.part"; say "download failed from $ART_FFMPEG_CLIP_URL (a local path must exist; wget cannot fetch file://)"; exit 1; }
  fi
  mv "$CLIP.part" "$CLIP"
  got=$(sha256sum "$CLIP" | cut -d' ' -f1)
  [ "$got" = "$WANT" ] || { say "SHA256 MISMATCH: a prepared clip must be the reference one."; say "  pinned $WANT"; say "  actual $got"; rm -f "$CLIP"; exit 1; }
  say "fetched and verified against the reference"; exit 0
fi

SRC="${ART_FFMPEG_SOURCE:-}"
if [ -z "$SRC" ]; then
  Z=input/tears_of_steel_1080p.mov.zip
  if [ ! -f "$Z" ]; then
    say "no clip and no source: fetching the Blender source, 557 MB, CC-BY 3.0, from download.blender.org"
    # Say WHAT failed before blaming the network. On a read-only harness mount wget cannot create its
    # output file, and reporting that as "source download failed" sends the reader to check their network
    # when the problem is the mount. That misdirection cost a diagnosis during the 17 Sep dry run.
    [ -w "$(dirname "$Z")" ] || { say "cannot write to $(dirname "$Z") — is the harness mounted read-only? Nothing was downloaded."; exit 1; }
    wget -q -O "$Z.part" "$SRC_URL" || { rm -f "$Z.part"; say "source download failed from $SRC_URL (the directory is writable, so this is the network or the server)"; exit 1; }
    mv "$Z.part" "$Z"
  fi
  got=$(sha256sum "$Z" | cut -d' ' -f1)
  [ "$got" = "$SRC_SHA" ] || { say "source SHA256 MISMATCH — refusing to cut from an unverified source."; say "  pinned $SRC_SHA"; say "  actual $got"; exit 1; }
  say "source verified"
  ( cd input && unzip -o -q tears_of_steel_1080p.mov.zip ) || { say "unzip failed"; exit 1; }
  SRC=$(find input -name 'tears_of_steel_1080p.mov' | head -1)
  [ -n "$SRC" ] || { say "the source archive did not contain tears_of_steel_1080p.mov"; exit 1; }
fi

command -v ffmpeg >/dev/null || { say "need an ffmpeg on PATH to cut the clip"; exit 1; }
say "cutting the clip with the recorded command (crop 1422x800 then scale, fps 30) — see input/PROVENANCE.md"
ffmpeg -hide_banner -loglevel error -ss 360 -t 100 -i "$SRC" \
  -vf crop=1422:800,scale=1366:768,fps=30 -c:v libx264 -preset medium -b:v 6400k \
  -pix_fmt yuv420p -c:a libvorbis -ar 48000 -ac 2 -y "$CLIP" || { say "ffmpeg failed"; exit 1; }
got=$(sha256sum "$CLIP" | cut -d' ' -f1)
if [ "$got" = "$WANT" ]; then say "cut, and bit-identical to the reference clip"
else say "cut. sha256 $got differs from the reference $WANT — expected for a re-encode; runs record input_is_reference=false"; fi
