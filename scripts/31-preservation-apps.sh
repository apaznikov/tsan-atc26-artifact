#!/usr/bin/env bash
# Race reports on the applications: N runs per configuration with reporting ON, union of distinct races
# compared with stock ThreadSanitizer at L1 (kind + both frames function@file:line + location), L2 (functions)
# and L3 (location + writer). Usage: scripts/31-preservation-apps.sh <sqlite|memcached> [N]
set -euo pipefail
. "$(dirname "$0")/_lib.sh"
need_harness tools/preservation; need_compiler
app="${1:?usage: 31-preservation-apps.sh <sqlite|memcached> [N]}"; n="${2:-${ART_RUNS}}"
[ "$ART_SMOKE" = 1 ] && n=1
budget "preservation on $app, N=$n" "3 h" "1.5 h" "5 GB"
smoke_banner
exec python3 "$harness/tools/preservation/run_preservation.py" --app "$app" --runs "$n" --out "$ART_RESULTS/preservation-$app-$(stamp)" "${@:3}"
