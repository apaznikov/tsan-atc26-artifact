#!/bin/bash
# The rules that decide this artifact's two preservation claims, checked against synthetic cases before
# either is trusted on real ones. Both are controls in the sense the week taught: they require the rule
# to fire on the one shape that is a failure AND to refrain one case short of it, because a control that
# only ever fires shows that a rule can speak, not that it can distinguish.
#
#   preservation_verdict.py --self-test   the application-level rule: LOST only when stock reports a site
#                                         in every run and the configuration in none; UNDETERMINED one run
#                                         short of that; KEPT whatever stock's frequency; ONLY-OPTIMIZED
#                                         labelled rather than dropped.
#
# The suite-level counterpart is scripts/30-preservation-suite.sh --self-test, which blinds a detector and
# requires the harness to report the induced losses; it needs a compiler and minutes, so it lives in the
# full correctness set rather than here. This one needs nothing and costs under a second.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/scripts/_lib.sh"
[ $# -eq 0 ] || { echo "$(basename "$0") takes no arguments (got: $*)"; exit 2; }
need_harness tools/preservation
python3 "$harness/tools/preservation/preservation_verdict.py" --self-test
