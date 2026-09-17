#!/bin/bash
# fetch_archive.sh <archive-path> — ensure the archive is present and correct, fetching it if it is not.
#
# The artifact promises that "the harness fetches them at build time and must verify each archive against
# the sha256 before unpacking". Three build scripts did fetch; two errored out and told the reader to go
# and find the file themselves, which is no use to an evaluator. This makes all five behave the same way,
# and — the part that matters — a fetch is ALWAYS followed by the same verification a local file gets, so
# a moved or changed upstream file is a stop rather than a silently different build.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST="$HERE/source_archives.sha256"
A=${1:?usage: fetch_archive.sh <archive>}
B=$(basename "$A")
if [ ! -f "$A" ]; then
  URL=$(awk -v b="$B" '!/^#/ && $2==b {print $3}' "$LIST" | head -1)
  [ -n "$URL" ] || { echo "fetch_archive: $B is absent and has no URL in $LIST" >&2; exit 1; }
  command -v wget >/dev/null || { echo "fetch_archive: $B is absent and wget is not installed" >&2; exit 1; }
  echo "fetch_archive: $B absent; fetching from $URL"
  # to a temporary name, so an interrupted download never looks like a complete archive on the next run
  wget -q -O "$A.part" "$URL" || { rm -f "$A.part"; echo "fetch_archive: download failed for $URL" >&2; exit 1; }
  mv "$A.part" "$A"
fi
exec "$HERE/verify_archive.sh" "$A"
