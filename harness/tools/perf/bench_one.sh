#!/bin/bash
# bench_one.sh — one repetition of one application's paper workload for one configuration.
# Usage: ./bench_one.sh <app> <cfg> <run> <out-root> [cpuset]
# Writes <out-root>/<app>/<cfg>/run<k>/{raw artefact(s), meta.json, cmd.log}. The workload is pinned with
# taskset to the cpuset (default lib.sh P5_CPUSET_DEFAULT); nproc inside it = the pinned CPU count.
set -uo pipefail
cd "$(dirname "$0")"; source ./lib.sh; source ./configs.sh
APP=${1:?}; CFG=${2:?}; RUN=${3:?}; OUTROOT=${4:?}; CPUSET=${5:-$P5_CPUSET_DEFAULT}
BASE=$(p5_base "$CFG"); TAG=$(p5_tag "$CFG"); APPDIR=$(p5_app_dir "$APP"); BIN=$(p5_binary "$APP" "$CFG")
[ -x "$BIN" ] || p5_die "no binary for $APP $CFG: $BIN"
if [ -n "${P5_HASH:-}" ]; then   # provenance gate: the binary must carry the hash this sweep is about
  bstamp=$(grep -m1 "^compiler_head:" "$(p5_build_dir "$APP" "$CFG")/build_info.txt" 2>/dev/null | awk '{print substr($2,1,12)}')
  [ "$bstamp" = "${P5_HASH:0:12}" ] || p5_die "STALE BINARY for $APP $CFG: build_info compiler_head=${bstamp:-none}, sweep hash=$P5_HASH (rebuild with build.sh)"
  # SECOND GATE, and the one that actually covers what runs. Only memcached is launched from $BIN; redis,
  # sqlite, mysql and ffmpeg are launched by NAME (BUILD_OPTIONS=, "$BASE$TAG", FF_BUILD_LIST=…) and their
  # scripts resolve that name in the CANONICAL directory. p5_binary, by contrast, falls back to
  # old-builds/<dir>.<hash> when the canonical directory holds another compiler's build — so when those two
  # disagree the gate above reads the archive, passes, and the run measures the canonical build instead. The
  # gate and the measurement would be looking at different binaries, which is the precise shape of the
  # 2026-09-05 stale-binary error this gate was added to prevent.
  # Observed for real here: the 14 Redis rows built on aa8a6dd8a2e8 for the governed static diff left
  # aa8a6 in the canonical directory with f3deebfbab60 archived beside it, and the first gate still passed.
  cbin=$( P5_HASH=""; p5_binary "$APP" "$CFG" )
  case "$APP" in mysql|ffmpeg) cdir=$(dirname "$(dirname "$cbin")");; *) cdir=$(dirname "$cbin");; esac
  cstamp=$(grep -m1 "^compiler_head:" "$cdir/build_info.txt" 2>/dev/null | awk '{print substr($2,1,12)}')
  [ "$cstamp" = "${P5_HASH:0:12}" ] || p5_die "CANONICAL BUILD IS ANOTHER COMPILER for $APP $CFG: $cdir has compiler_head=${cstamp:-none}, sweep hash=$P5_HASH. The runner selects this build by name and would measure it whatever p5_binary resolved (rebuild with build.sh)."
fi
# P5_RUN_PREFIX lets run.sh place a discarded warm-up beside the measured runs. aggregate.py collects only
# directories matching run\d+ exactly, so "warmup1" is invisible to it without any further filtering — the
# warm-up leaves its STATE behind (SQLite's database built, FFmpeg's input in page cache, MySQL's buffer pool
# populated) while its numbers are never read.
D="$OUTROOT/$APP/$CFG/${P5_RUN_PREFIX:-run}$RUN"; mkdir -p "$D"; LOG="$D/cmd.log"
# TASKSET REFUSES AN EMPTY CPU LIST. `taskset -c "" cmd` is not an unpinned run, it is
# "taskset: failed to parse CPU list:" and exit 1 -- so with ART_CPUSET unset, the artifact's DOCUMENTED
# DEFAULT, every call here failed: NCPU came back empty, the meta block became `"ncpu": ,` and died with
# `SyntaxError: expression expected after dictionary key and ':'`, and all eight cells of a leg failed in
# six seconds. The lab always pins, so the default path had never once been executed (defect 14,
# 2026-09-17, found by the unpinned leg that existed to look for exactly this).
# lib.sh's p5_taskset already had the right shape; this is the same rule applied at the eight call sites.
TSPIN=""; [ -n "${CPUSET:-}" ] && TSPIN="taskset -c $CPUSET"
NCPU=$($TSPIN nproc)
# THE SHAPE OF THE PROCESSOR SET, NOT ONLY ITS SIZE. Equal logical counts are not equal machines: the
# campaign's 48 was 24 physical cores with both SMT siblings of each, and 48 contiguous processors on this
# host would be 48 separate cores with none -- twice the compute, no sibling contention. Recorded per cell
# so a row can be compared with an interval only when the shapes match, and so a shape change is visible
# in the first meta.json anyone opens rather than after the numbers disagree. (2026-09-20.)
read -r NPHYS NPAIRS _ <<< "$(python3 ./cpu_snapshot.py --topology "${CPUSET:-}")"
# env.sh documents ART_MEMCACHED_PORT as "change if it collides with something on your host" -- and
# nothing read it: the port was written 7777 at seven places here, so an evaluator whose 7777 was taken
# had no recourse but to edit the harness. A documented knob that nothing reads is worse than an
# undocumented constant, because it is advertised. (Audit, 2026-09-19.)
MC_PORT="${ART_MEMCACHED_PORT:-7777}"
# THE EFFECTIVE THREAD COUNT, COMPUTED ONCE AND BOTH USED AND RECORDED. It used to be inlined at each call
# site while meta.json recorded the OVERRIDE -- "${MC_THREADS:-}" -- so a run that took the default wrote an
# EMPTY field, and an empty field reads as "nothing to see" rather than as a value. That hid a real
# difference for a day: the campaign set MC_THREADS=48 from a lab launcher, the shipped path sets nothing
# and falls to NCPU/2, so the artifact ran memcached with 24 server threads against the 48 the documents
# describe -- and on this workload the thread count moves the result more than any compiler flag does.
# One variable, used in the command and written to the record, so the two cannot disagree.
case "${MC_THREADS:-}${MYSQL_THREADS:-}${FF_THREADS:-}" in "") THREADS_FROM_ENV=False;; *) THREADS_FROM_ENV=True;; esac
# THE CAMPAIGN'S RULE, NOT A FIXED NUMBER AND NOT NCPU/2. The campaign's parameter was a RULE -- threads
# equal to the PINNED PROCESSORS, three quarters of them for sysbench (campaign-parameters.md R1) -- and on
# the 48-CPU bench set the rule yields exactly the 48 and 36 the cells record. The defaults here had an
# erroneous extra /2 and produced 24 and 18 on that same set: documented figures the code could not produce
# (defect 13, 2026-09-17).
#
# Proportional rather than fixed, deliberately. A fixed 48 on a 32-processor evaluator is oversubscription
# the paper never measured, which is a different regime, not a smaller one; the rule puts that machine on
# its own point of the SAME rule, which is what the paper's concurrency section describes and what
# "comparable on comparable hardware" already qualifies. Neither choice makes a differently-sized machine
# comparable to ours -- what the rule preserves is the regime, threads at parity with cores, rather than a
# number. FFmpeg's 4 stays ABSOLUTE: libx265 refuses more than 16 frame threads and drops the codec
# silently above it, so that one is a property of the encoder and not of the machine.
case "$APP" in
  memcached) THREADS_EFFECTIVE="${MC_THREADS:-$NCPU}";;
  mysql)     THREADS_EFFECTIVE="${MYSQL_THREADS:-$((NCPU * 3 / 4))}";;
  ffmpeg)    THREADS_EFFECTIVE="${FF_THREADS:-4}";;
  *)         THREADS_EFFECTIVE="";;
esac
export TSAN_OPTIONS="${TSAN_OPTIONS:-report_bugs=0}"
TS() { $TSPIN "$@"; }
# The machine lock, the sidecar and the 32G memory scope are taken by run.sh's machine-lock wrapper around this
# script (one process per run); nothing here locks.
read -r busy0 idle0 <<< "$(p5_cpu_snapshot)"; read -r in0 out0 nin nout <<< "$(python3 ./cpu_snapshot.py "$CPUSET")"
load0=$(p5_loadavg); mhz0="$(p5_cpu_mhz 4)/$(p5_cpu_mhz 60)"; regime=$(p5_regime); t0=$(date +%s.%N)
# Foreign processes ON the measurement cpuset. The disturbance gate reads outside_busy_share — busy time on
# the CPUs OUTSIDE our set, which is foreign by construction — and is therefore blind to anything that lands
# INSIDE it. That is not hypothetical: docker.slice carries AllowedCPUs=4-55,60-111 (service lane, 2026-09-15),
# which wholly contains 4-27,60-83, so a container can occupy the measurement cores and the gate will keep
# every run. This RECORDS, it does not gate: a threshold invented now would not be pre-registered, and
# inside-busy cannot be separated from our own benchmark after the fact. If the cpuset overlap is fixed the
# field should read zero on every run, which makes it a check on the fix too.
( while :; do
    ps -eo psr,pcpu,comm --no-headers 2>/dev/null | awk -v cs="$CPUSET" '
      BEGIN{n=split(cs,parts,","); for(i=1;i<=n;i++){split(parts[i],r,"-"); lo=r[1]; hi=(r[2]==""?r[1]:r[2]); for(c=lo;c<=hi;c++) in_set[c]=1}}
      BEGIN{split("threadtest3 redis-server redis-benchmark memcached memtier_benchmar ffmpeg mysqld sysbench ps awk sleep taskset time bash sh",o," "); for(i in o) ours[o[i]]=1}
      $2>0.5 && ($1 in in_set) && !($3 in ours) {print $3, $2}'
    sleep 2
  done ) > "$D/cpuset-intruders.raw" 2>/dev/null &
SAMPLER=$!
EXTRA_TICKS=0   # CPU time of ours that /usr/bin/time cannot see (a server started outside the timed region)
TIMEF=/usr/bin/time; OURS="$D/ours.time"
rc=0
case "$APP" in
  memcached)
    # paper workload: server -c 4096 -t <cpus> -p $MC_PORT; memtier -t 10 -x 5 --pipeline 16 -P memcache_text --random-data
    (echo > /dev/tcp/127.0.0.1/$MC_PORT) 2>/dev/null && p5_die "port $MC_PORT busy (set ART_MEMCACHED_PORT to use another)"
    $TSPIN "$BIN" -c 4096 -t "$THREADS_EFFECTIVE" -p $MC_PORT -U 0 > "$D/server.out" 2>&1 &   # MC_THREADS: thread-policy pilot
    spid=$!
    for i in $(seq 1 60); do (echo > /dev/tcp/127.0.0.1/$MC_PORT) 2>/dev/null && break; sleep 1; done; sleep 1
    $TIMEF -f "%U %S %M" -o "$OURS" $TSPIN "$APPDIR/memtier_benchmark-2.1.1/memtier_benchmark" --hide-histogram \
      -t 10 -p $MC_PORT -x "${NTESTS:-5}" --requests "${MC_REQUESTS:-100000}" --pipeline 16 -P memcache_text --random-data > "$D/memtier.txt" 2> "$LOG"; rc=$?
    # MC_REQUESTS: the paper's 10 000 requests per client (5 M per iteration) made an iteration last ~1 s on the
    # counters-off runtime (2 M ops/s) and ~1 s on native, and memtier's per-iteration ops/s is computed from
    # 1-second progress samples: single iterations reported 57 M ops/s on native and 3.5 M on tsan-dom, i.e.
    # garbage. 100 000 per client (50 M per iteration, 10-25 s) makes memtier's aggregate meaningful again.
    # Stage A ran with 10 000; Stage B from 2026-09-07 with 100 000.
    grep VmHWM /proc/$spid/status 2>/dev/null > "$D/server.rss"      # peak RSS of the server before it exits
    # the server runs outside the timed region: add its ticks to ours, else its 48 threads look like foreign load
    EXTRA_TICKS=$(awk '{print $14+$15+$16+$17}' /proc/$spid/stat 2>/dev/null || echo 0)
    kill -TERM "$spid" 2>/dev/null; wait "$spid" 2>/dev/null
    for i in $(seq 1 30); do (echo > /dev/tcp/127.0.0.1/$MC_PORT) 2>/dev/null || break; sleep 1; done
    ;;
  redis)
    ( cd "$APPDIR" && REDIS_ORIG_MULT=1 BUILD_OPTIONS="$(p5_redis_name "$CFG")" BUILD_TAG="$TAG" $TIMEF -f "%U %S %M" -o "$OURS" $TSPIN ./redis.sh --test-only ) > "$LOG" 2>&1; rc=$?
    cp "$APPDIR/redis-polygon/__results_redis__/results.txt" "$D/results.txt" 2>/dev/null || rc=1
    ;;
  sqlite)
    # SQLITE_W1_THREADS turns this into the contention cell the March sweeps ran: threadtest3 --w1-threads N
    # walthread1, one 20-second test, written to results/contention/<cfg>_<N>threads.log instead of the
    # seven-subtest log. The parser keys on "Running walthread1" either way, so the rest of the pipeline is
    # unchanged; only the artefact's path and the absence of a memory line differ.
    ( cd "$APPDIR" && $TIMEF -f "%U %S %M" -o "$OURS" $TSPIN ./run_sqlite_test.sh "$BASE$TAG" ${SQLITE_W1_THREADS:-} ) > "$LOG" 2>&1; rc=$?
    if [ -n "${SQLITE_W1_THREADS:-}" ]; then
      cp "$APPDIR/results/contention/${BASE}${TAG}_${SQLITE_W1_THREADS}threads.log" "$D/threadtest3.log" 2>/dev/null || rc=1
    else
      cp "$APPDIR/results/$BASE$TAG.log" "$D/threadtest3.log" 2>/dev/null || rc=1
      grep "^$BASE$TAG	" "$APPDIR/results/memory.txt" 2>/dev/null | tail -1 > "$D/memory.txt"
    fi
    ;;
  mysql)
    ( cd "$APPDIR/benchmysql" && SYSBENCH_RUN_SECONDS="${MYSQL_SECONDS:-180}" SYSBENCH_RUN_THREADS="$THREADS_EFFECTIVE" \
        $TIMEF -f "%U %S %M" -o "$OURS" $TSPIN ./run-one.sh "mysql-$BASE$TAG" "$D" ) > "$LOG" 2>&1; rc=$?
    ;;
  ffmpeg)
    # -threads goes straight to the encoder: libx265 maps it to frame threads and refuses anything above
    # X265_MAX_FRAME_THREADS (16), so a pinned-CPU-count default of 48 makes the h265 codec fail on every
    # build and vanish from the results.  The paper's runs used 4; keep that unless FF_THREADS says otherwise.
    # The clip is part of the measurement's provenance: FFmpeg numbers taken on different inputs are not
    # comparable, and the retired WatchingEyeTexture.mkv cannot be redistributed. Record its hash per run.
    INPUT_FILE="${FF_TEST_VIDEO:-$APPDIR/input/TearsOfSteel-1366x768-100s.mkv}"
    [ -f "$INPUT_FILE" ] && INPUT_SHA=$(sha256sum "$INPUT_FILE" | cut -d" " -f1)
    # A hash on its own leaves the reader to know which one is the reference. A regenerated clip is a
    # supported path (ensure_input_clip.sh cuts one from the Blender source) and such a run is valid but
    # NOT bit-comparable with ours, so the artefact says which it is rather than implying it.
    FF_REFERENCE_SHA=43b0fba97eb05a0e44d7518fe9d6993c140680531a17a240ea6d53582fbe9985
    # Python literals, not shell ones: this value is interpolated into the python3 meta block below,
    # where `true` is as much a NameError as `null` was. Capitalised here so the dict builds.
    [ "${INPUT_SHA:-}" = "$FF_REFERENCE_SHA" ] && INPUT_IS_REF=True || INPUT_IS_REF=False
    ( cd "$APPDIR" && RUNS_COUNT=1 FF_BUILD_LIST="ffmpeg-$BASE$TAG" FFMPEG_BENCH_NPROC_COUNT="$THREADS_EFFECTIVE" \
        SUMMARY_CSV="$D/summary.csv" SUMMARY_JSON="$D/summary.json" \
        $TIMEF -f "%U %S %M" -o "$OURS" $TSPIN ./bench_ffmpeg_all.sh ) > "$LOG" 2>&1; rc=$?
    [ -s "$D/summary.csv" ] || rc=1
    ;;
esac
t1=$(date +%s.%N); read -r busy1 idle1 <<< "$(p5_cpu_snapshot)"; read -r in1 out1 nin nout <<< "$(python3 ./cpu_snapshot.py "$CPUSET")"
load1=$(p5_loadavg)
kill "$SAMPLER" 2>/dev/null; wait "$SAMPLER" 2>/dev/null
# one line per (process, cpu%) sample; summarise to a count of distinct foreign processes and their peak share
INTRUDERS=$(awk '{c[$1]++; if($2+0>m[$1]) m[$1]=$2+0} END{n=0; for(k in c) n++; print n}' "$D/cpuset-intruders.raw" 2>/dev/null || echo 0)
INTRUDER_PEAK=$(awk 'BEGIN{p=0} {if($2+0>p) p=$2+0} END{printf "%.1f", p}' "$D/cpuset-intruders.raw" 2>/dev/null || echo 0)
awk '{c[$1]++; if($2+0>m[$1]) m[$1]=$2+0} END{for(k in c) printf "%s samples=%d peak_pcpu=%.1f\n", k, c[k], m[k]}' \
    "$D/cpuset-intruders.raw" 2>/dev/null | sort -k2 -t= -nr > "$D/cpuset-intruders.txt" 2>/dev/null
rm -f "$D/cpuset-intruders.raw"
read -r ou os om <<< "$(tail -1 "$OURS" 2>/dev/null)"
HZ=$(getconf CLK_TCK); machine_busy=$(( (busy1 - busy0) )); ours_ticks=$(python3 -c "print(int((${ou:-0}+${os:-0})*$HZ) + ${EXTRA_TICKS:-0})")
# A cell whose workload produced no throughput is a FAILED cell, not a fast one. memtier prints
# "Totals 0.00 ops/sec" when the server never accepted a connection, and this runner used to file that
# as an ordinary success of 70 seconds; the aggregator then met a table of zeros and died in the one
# place that had no idea what had gone wrong. The check reuses aggregate.py's own parsers, so this gate
# and the table it guards cannot disagree about what the workload produced. Sibling of the meta-block
# rule: a cell whose meta block did not build is not a cell, and neither is one whose workload did not run.
# The reason travels through a FILE, never through this unquoted heredoc, where a parser's message
# containing a backtick or a $ would be executed rather than recorded.
# Two gates, two exit codes, one reason file. They are separate because their failures mean different
# things: 65 says the workload produced nothing at all, 66 says it produced a DIFFERENT TEST SET from
# every other cell, which is the more dangerous of the two because it still yields a plausible number.
rm -f "$D/cell_error.txt"
if [ "$rc" = 0 ]; then
  if ! python3 ./throughput_check.py "$APP" "$D" > "$D/cell_error.txt" 2>&1; then
    p5_log "NO THROUGHPUT $APP $CFG run$RUN: $(head -1 "$D/cell_error.txt")"
    rc=65
  elif [ "$APP" = ffmpeg ] && ! python3 ./check_ffmpeg_codecs.py --run "$D" > "$D/cell_error.txt" 2>&1; then
    p5_log "MISSING CODEC $APP $CFG run$RUN: $(head -1 "$D/cell_error.txt")"
    rc=66
  else
    rm -f "$D/cell_error.txt"
  fi
fi
python3 - "$D" <<PY
import json, hashlib, os, sys, time
d = sys.argv[1]
bi = {}
for cand in ("$(p5_build_dir "$APP" "$CFG")/build_info.txt",):
    if os.path.exists(cand):
        bi = dict(l.split(": ",1) for l in open(cand).read().splitlines() if ": " in l)
meta = {
  "app": "$APP", "config": "$CFG", "run": $RUN, "rc": $rc,
  "binary": "$BIN", "sha256": hashlib.sha256(open("$BIN","rb").read()).hexdigest(),
  "compiler_version": bi.get("compiler_version"), "compiler_head": bi.get("compiler_head"), "flags": bi.get("flags"), "summaries": bi.get("summaries"),
  "start": $t0, "end": $t1, "seconds": round($t1 - $t0, 1),
  "cpuset": ("$CPUSET" or "all"), "ncpu": $NCPU, "mode": "${P5_MODE:-pinned}",
  "governor": "$(p5_governor)", "no_turbo": "$(p5_turbo)",
  "regime": "$regime", "bench_session": $(p5_bench_session), "cpu_mhz_start": "$mhz0", "cpu_mhz_end": "$(p5_cpu_mhz 4)/$(p5_cpu_mhz 60)",
  "loadavg_before": "$load0", "loadavg_after": "$load1",
  "machine_busy_ticks": $machine_busy, "ours_ticks": $ours_ticks, "extra_ticks": ${EXTRA_TICKS:-0}, "hz": $HZ,
  "inside_busy_share": round(($in1 - $in0) / max(1.0, ($t1 - $t0) * $HZ * $nin), 4),
  # UNPINNED MEANS THERE ARE NO OUTSIDE CPUs, SO THERE IS NO SHARE TO REPORT. Dividing by an empty set
  # would give 0.0, which reads as a perfectly quiet machine and passes the disturbance gate
  # unconditionally — a gate that always passes. null says the quantity does not exist here; gate_checked
  # says so positively, because a reader filtering on the share alone cannot tell null from absent.
  "outside_busy_share": (round(($out1 - $out0) / max(1.0, ($t1 - $t0) * $HZ * $nout), 4) if $nout > 0 else None),
  "gate_checked": ($nout > 0),
  "n_inside": $nin, "n_outside": $nout,
  "n_physical_cores": ${NPHYS:-0}, "smt_pairs_complete": ${NPAIRS:-0},
  "foreign_ticks": max(0, $machine_busy - $ours_ticks),
  "foreign_cpu_share": round(max(0, $machine_busy - $ours_ticks) / max(1.0, ($t1 - $t0) * $HZ * $(nproc)), 4),
  "tsan_options": "$TSAN_OPTIONS", "max_rss_kb": ${om:-0},
  "input_sha256": "${INPUT_SHA:-}",
  # Read from a file rather than interpolated: aggregate.py already renders meta["error"] as the reason
  # a configuration produced no usable run, so a failed cell explains itself in the table.
  "error": (open(os.path.join(d, "cell_error.txt")).read().strip()
            if os.path.exists(os.path.join(d, "cell_error.txt")) else None),
  # Python, not JSON: this dict is built by python3 and dumped with json.dump, so the absent case is
  # None. Writing null here (no backticks: this heredoc is UNQUOTED, so backticks would run the word as
  # a command) made every non-FFmpeg run die with NameError inside the meta block, and the runner then
  # recorded each one as DISTURBED — a measurement that never happened, filed as one
  # that happened badly. Twenty redis runs in 10 s is what that looks like from outside.
  "input_is_reference": ${INPUT_IS_REF:-None},
  "cpuset_intruders": ${INTRUDERS:-0}, "cpuset_intruder_peak_pcpu": ${INTRUDER_PEAK:-0},
  # The EFFECTIVE value, never the override: an empty string here used to mean "defaulted", which is
  # indistinguishable in the record from "not applicable", and both read as nothing worth checking.
  "threads_setting": "${THREADS_EFFECTIVE:-}",
  "threads_from_env": ${THREADS_FROM_ENV:-False},
}
json.dump(meta, open(os.path.join(d, "meta.json"), "w"), indent=1)
print(f"{meta['app']} {meta['config']} run{meta['run']} rc={meta['rc']} {meta['seconds']}s "
      f"outside_busy={meta['outside_busy_share']} inside_busy={meta['inside_busy_share']} foreign_cpu_share={meta['foreign_cpu_share']}")
PY
exit $rc
