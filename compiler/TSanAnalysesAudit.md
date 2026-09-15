# ThreadSanitizer static analyses — audit ledger

> **Paper references.** This ledger cites the paper by section. Where an earlier
> internal revision named source files, they resolve as: §4.1 STC, §4.2 SWMR, §4.3 LO,
> §4.4 EA, §5 DE, §6 (peeling, DynSTC), §7 pipeline, §8 experiments, and the lo-proof,
> de-proofs, ea, peeling and concrete-semantics appendices.
>
> **Scope.** This is the audit ledger for the analyses, vendored from the tree the
> artifact's compiler is built from. It records every access the analyses decline to
> instrument and why that is sound, the function-level audit, and the verification runs.
> It is the document behind the soundness claims `scripts/11-soundness-shapes.sh` checks.

One row per function of the five analyses, the instrumentation pass and the
runtime additions; one section per analysis comparing what the paper proves
with what the code does. Line numbers are those of `b4bf8b8f4613` (the
the audited tree (branch artifact/paper-sound)); fixes reference commits on `tsan-audit`.

**Verdict legend.** `sound` — fail-closed as written, argued in its row.
`fixed:<id>` — a fail-open shape was confirmed by running the pass and closed
by the named fix. `pending:<id>` — confirmed or predicted by reading, fix
scheduled. `precision` — conservative in a way that only costs reach.
`hygiene` — no soundness bearing. `decision:<who>` — a policy choice recorded
in the plan.

**Method.** Three inventories (every function, its contract, its default on an
unknown), sixteen minimal-IR probes against the built `opt` for every
predicted fail-open, then a fix with a negative test that fails on the parent
commit and a positive control that still elides. Reach is measured per commit
(`-mllvm -stats` on sqlite3.c, shell.c, memcached's 26 modules).

## Confirmed lost-race shapes (all in the shipped default configurations)

| # | shape | root | fix |
|---|---|---|---|
| 1 | object escapes whole, then a field is written (`foo(&s); s.f1 = 1;`) | exact (object, field-path) lookup | EA-2 — fixed d06851ec7a6d |
| 2 | `&x` stored into an already published container | container's escaped *state* never consulted | EA-3 — fixed cbeb570ed61c |
| 3 | `&x` published via a `cmpxchg` value operand | `EscReasonTy` too narrow; reason truncated to 0 | EA-1 — fixed 667343f20eaf |
| 4 | `&x` stored through an unidentifiable pointer | incomplete object walk skipped | EA-5 — fixed 957f8e506697 (refined 67e9532aa926) |
| 5 | pointer loaded from a `memcpy`-filled struct, dereferenced | slot with no recorded pointee answers local | EA-6 — fixed 09b9a74d17b7 |
| 6 | access through a loaded pointer, object published later | sound-FS rule walks the wrong object | EA-9 — fixed fe9c96cfd10f |
| 7 | `helper()` after `pthread_create()` in a non-`main` function | creator's callees never marked MT | STC-1 — fixed a633cc3f0e77 |
| 8 | `extern` global read here, written elsewhere (memcached `current_time`) | no linkage check | SWMR-1 — fixed def2cf34faeb (benchmark-confirmed by tsan-exp, N=10) |
| 9 | callee releases the caller's lock | callee releases unmodelled | LO-2 — fixed 20c178992bfd |
| 10 | any name containing `lock` is an acquisition | substring matching | LO-1 — fixed 12399f969130 |
| 11 | dominance across `write(2)` | `TLI::isSyncFree` defaults true | DE-5 — fixed 450fc39a8545 |
| 12 | post-dominance across `read(2)` | same | DE-5 — fixed 450fc39a8545 |
| 13 | a store reached from a lock-free path counted as protected (held-lock record from an intermediate visit; found during the audit, reproduced on 297881ddc1c5) | worklist seeded with the entry only; empty held set never recorded | LO-3/5 — fixed c8debe12f363 |
| 14 | an access after `pthread_mutex_timedlock` (or a timed/clock rwlock, `mtx_timedlock`) counted as protected on the timeout path, which the runtime treats as no lock (found in the second read of the consolidated tree, reproduced on 7d856d641027) | timed acquisitions were unconditional in the lock table; only try-locks were conditional | LO-6 — fixed 3d70ff61f640 (static counts unchanged: no timed locks in memcached, sqlite3.c, shell.c) |
| 15 | `main(){ start_worker(); g = 1; }` with the thread that writes `g` started inside a call this unit has no body for — a helper in another unit, a library's initialisation; an indirect call in a helper likewise (the STC-3 decision, closed 2026-09-04; reproduced on 3d70ff61f640 by `preservation_stc_unknown_external.c`: the race unreported in 8/8 runs, reported 8/8 after) | a bodiless callee was MultiThreaded (per-unit) or SingleThreaded (whole-program), never a creator; an indirect call outside `main` was skipped by the fixpoint | STC-3 — fixed 198e1b5c1332 (with STC-3b: a static constructor that starts a thread makes `main` multi-threaded from its entry) |
| 16 | dominance across `qsort` whose comparator releases a lock that another thread acquires before writing the location (the sync-free-default decision, closed 2026-09-04; reproduced on 3d70ff61f640 by `elim-by-dominance-tli-sync-free-table.ll`) | `TLI::isSyncFree` answered true for every library function its blocklist did not name — every file, directory and time system call, `qsort`, `strtok`, the `_unlocked` stream family | DE-6 — fixed 92f2b95e9d83 |
| 17 | a store after `__kmpc_fork_call` counted as protected although the microtask, which the fork runs on the calling thread too, released the lock (found in the STC-3 design review; reproduced on 3d70ff61f640 by `fork-call-runs-on-caller.ll`) | LO's callback exemption assumed every known thread creator runs its routine only on the new thread | LO-7 — fixed 729521af8965 |
| 18 | `f(&local, &slot)` where `f` stores its first argument through its second; the caller publishes the slot's content and starts a thread that writes through it; the caller's later store to `local` was elided (found in the performance-pass design review; reproduced on 729521af8965 by `escape-callee-out-param.ll`) | the bottom-up summary recorded the stored argument as escaping only by the seed bit `PTR_ARG_ALIASING`, which callers mask out as "merely an argument" | EA-10 — fixed on the performance branch (commit `EA: a pointer stored through an argument has escaped to the caller`) |
| 19 | `%r = call ptr @f(ptr %local)` where `f` stores its argument to a global and returns an escaped pointer; a thread writes through the global; the caller's later store to `local` was elided (found while writing the budget test; reproduced on 729521af8965 by `escape-arg-of-escaped-result-call.ll`; the void-returning callee was handled) | `getEscInfoCall` answered "the result escapes" for every pointer operand of such a call, so its arguments were never classified; **fixed:EA-11** (shape 19: the escaped-result answer only on the callee operand; arguments classified) | EA-11 — fixed on the performance branch (commit `EA: the arguments of a call whose result escapes are analysed too`), escape-arg-of-escaped-result-call |
| 20 | `@slot = global ptr @g` — the address of a local-linkage global in another global's initializer (directly, inside a constant aggregate, or through `llvm.used`); a thread loads the pointer and writes through it; SWMR counted `g` read-only and elided main's read of it after the thread started, LO counted it protected (found by the C4 agent while sizing the read-only-argument rule; reproduced on 94764fe839df by `swmr-address-in-initializer.ll` and `LockOwnership/address-in-initializer.ll`) | `collectAccessingInstrs` listed instruction users and recursed into constant expressions and aliases, dropping every other user silently; **fixed:SWMR-2, LO-8** (the walk reports an address it cannot follow to an instruction; both consumers treat the global as escaped) | SWMR-2, LO-8 — fixed on the performance branch (commit `SWMR, LO, EA: two more published-address shapes (20, 21)`), swmr-address-in-initializer, address-in-initializer |
| 21 | `%r = strchr(%b, c); store %r, @g` — any library call that returns a pointer into its argument (strchr, strstr, memchr, strcpy, memcpy, fgets, realloc, …); a thread writes `b` through the published pointer; `b`'s accesses were elided — after the publication by the per-point verdict, before it by the later-escape rule, which did not follow the result either (found by the C6 agent while guarding the interceptor toggle; reproduced on 94764fe839df by `escape-libcall-result-alias.ll`) | the result of such a call was an object of its own, an "escaped call" register unrelated to the argument; **fixed:EA-12** (`TargetLibraryInfo::returnsPointerIntoArg`; the object walk continues from the argument at the whole-object path; `collectLaterEscapes` walks the result's uses; realloc's argument no longer "escapes" through the call since the result stands for the block; realloc(NULL) stays an object of its own) | EA-12 — fixed on the performance branch (same commit), escape-libcall-result-alias |
| 22 | `strtol(buf, &end, 10); g = end;` — a library call stores a pointer into its argument through an out-parameter (the strtol/strtod family's end pointer) and the slot's content is published; a thread writes `buf` through it; `buf`'s accesses were elided (found while deriving the thread-free vouch lists for tsan-exp; reproduces on 729521af8965 and d3bf9f8c39fe by `escape-libcall-out-pointer.ll`) | the library table said only that the string is not retained; nothing recorded that the slot now points into it, so the later load-and-publish of the slot escaped nothing; **fixed:EA-13** (`TargetLibraryInfo::storesArgThroughArg`: the call is the store `*end = s` for the escape analysis, and a store site for the later-escape rule; a null end pointer stores nothing) | EA-13 — fixed on the performance branch (commit `EA: a library call that stores a pointer to its argument through another argument (shape 22)`), escape-libcall-out-pointer |
| 23 | `g = realpath(p, b); b[0] = 'x';` — `realpath(path, buf)` and `ctermid(buf)` fill a caller-supplied buffer and return a pointer into it; the result is published and a thread writes `buf` through it; `buf`'s accesses were elided (found by the classification sweep against `e90a3fc41004` while checking `returnsPointerIntoArg`'s exclusion list; reproduced by `escape-libcall-fills-and-returns-arg.ll`, which fails on the frozen parent `tsan-merge-afe47a2a75a5` at the first shape check while that parent's `strchr_published` control still reads 1) | both names are deliberately absent from `returnsPointerIntoArg` (`realpath(p, NULL)` allocates, `ctermid(NULL)` answers from a static buffer, so the result cannot be said to alias the argument) and both sat in `doesArgEscape`'s known-not-to-escape list, so neither side paid for the buffer; **fixed** (`doesArgEscape` answers true for realpath's second argument and ctermid's only one; the buffer escapes at the call whether or not the result is published, pinned by `realpath_result_unpublished`; neither name occurs in the 28-module corpus, so sqlite3.ll 55 752 and shell.ll 6 302 are unchanged) | fixed on `artifact/paper-sound` at `aa8a6dd8a2e8` (commit `EA: realpath and ctermid fill a buffer they return a pointer into`), escape-libcall-fills-and-returns-arg; details in "A 23rd lost-race shape" below |

## Design versus paper

### STC — single-threaded context (`§4.1 STC`, Prop. stc-conc)

*Paper.* An access executed only before the program creates additional
threads cannot race. MT is computed per function, per block in `main`: blocks
of `main` creating threads; functions creating threads and their transitive
callers; address-taken functions; callees of MT functions; successors of MT
blocks of `main` and their callees. "May call" is an over-approximation.

*Code.* `runSTMTAnalysis` (SingleThreaded.cpp:199-284), `computeMainMTBlocks`
(:102), `propagateMTFromMain` (:122). Deviations: (a) the rule "callees of MT
functions" is not applied to a *creator's* callees — `pending:STC-1`; (b) a
function this unit never calls and never takes the address of defaults to ST,
which is only valid with whole-program visibility — `pending:STC-2` (per-TU:
external linkage ⇒ MT); (c) a call to a bodiless function is not a possible
thread creation — `fixed:STC-3` (198e1b5c1332; see below); (d) the paper's
"program starts at `main`, never called" is assumed and unchecked; a static
constructor of this unit that starts a thread now makes `main`
multi-threaded from its entry — `fixed:STC-3b` (same commit) — while
constructors of other units remain the assumption. The dynamic variant
(`th:stc-dyn`) is implemented as the paper says: counter in the runtime,
incremented at create, decremented at join, guard load `monotonic` and never
instrumented — `sound`.

*STC-3, the rule.* A call may start a thread if its callee is unknown (an
indirect call, inline asm), a known creator, a function mapped as a creator,
or a callback carrier (`qsort`, `signal`, `pthread_once`, `atexit`, …)
handed a callback that is not a constant or is itself a creator. Every
declaration is seeded as a creator unless it is *known thread-free*: an
intrinsic (other than the statepoint/patchpoint/branch-funnel wrappers), a
library function TargetLibraryInfo recognises by name and prototype, a
carrier, a name the whole-program summary found single-threaded, an exact
name from the POSIX/glibc/runtime allowlist in SingleThreaded.cpp, a closed
runtime family by prefix (`__tsan_`, `__sanitizer_`, `Annotate`, `__cxa_`,
`_Unwind_`, `__kmpc_`, `omp_`, `__isoc99_`, `__isoc23_`, the fortify
`__…_chk` shape), or a member of namespace `std` other than
`std::thread`'s members, `std::async`, the future machinery and
`std::jthread`. Kept creators on purpose: `sigaction` (the handler arrives
in a struct through memory), `clone`, `timer_create`, `mq_notify`, `aio_*`,
`getaddrinfo_a`, `dlopen`/`dlclose`, `daemon`, `qsort_r`, `__once_proxy`
(so `std::call_once` is a creator), every non-libc library. Processes are
not threads: `fork`, `vfork`, `posix_spawn`, `system`, `popen`, `exec*`
are thread-free. The same predicate now decides `main`'s per-block
classification and the fixpoint's per-call-site test, so an indirect call or
a creating callback in a helper is no longer missed. Recorded assumptions:
a libc/libstdc++ name binds to that library (the assumption EA's and LO's
library tables already make); inline asm counts as creation (a raw `clone`
syscall is possible, `rdtsc` pays for it). Cost: memcached's
single-threaded prefix now ends at `event_init()` (libevent, bodiless),
before `stats_init`, `conn_init`, `assoc_init`, `slabs_init` and
`memcached_thread_init`; `signal(SIGINT, handler)` with a constant handler,
`setbuf`, `getopt_long`, `getrlimit`/`setrlimit` and `getpwnam` stay
thread-free. A project may vouch for further exact names with
`-tsan-thread-free-names=<names>` (a hidden option; the default list stays
sound on its own, a listed name is the user's responsibility, a known
creator cannot be overridden). Measured deltas in the verification section
at the end.

### SWMR (`§4.2 SWMR`, Prop. swmr)

*Paper.* A read of locations L cannot race if every write to L occurs in ST
context.

*Code.* `findSWMRGlobals` (:314-367) elides *all* accesses to a global no MT
instruction writes — reads and writes; the writes so elided are ST by the
same verdict, so this is a restriction of the proposition, not an extension —
`sound`. Address escape ⇒ not read-only — `sound`. Externally linked globals
qualified — `fixed:SWMR-1`. An address in another global's
initializer (directly, in a constant aggregate, `llvm.used`) is an escape the
access list cannot show — `fixed:SWMR-2` (performance branch; shape 20). Inherits STC's verdict for the writes, so STC-1/2/3
also gate it.

### LO — lock ownership (`§4.3 LO`, `the lo-proof appendix`)

*Paper.* Interprocedural, context-insensitive must-held locksets per access;
per location the intersection over MT accesses; an access needs no
instrumentation if every location it may touch is owned, given an
over-approximation of the accesses to each location.

*Code.* Restricted to `GlobalVariable`s with direct users
(`findProtectedGlobalVariables`) — a restriction, `sound` as far as it
goes once the "over-approximation of accesses" premise holds: the variable
must be a local-linkage definition (another unit cannot name it) and every
use of its address the pointer operand of a load or store (nothing reaches
it through a path the scan does not see) — `fixed:LO-4/4b` (12399f969130). The
address in another global's initializer is such a path; the access walk now
reports it — `fixed:LO-8` (performance branch; shape 20).
Lock identity by global + constant offset — `sound` (51c96792787b).
Acquisition recognised by name substring ("block" contains "lock") —
`fixed:LO-1` (12399f969130; exact tables, pthread/mtx/omp). Callee
releases — `fixed:LO-2` (20c178992bfd): syntactic release summaries closed
over the call graph, applied at every call before the callee's exit
acquisitions. Opaque calls (indirect, non-transparent declarations) —
policy C as decided: may release any non-private mutex and a private one
only through a callback; private = local-linkage global used only as a
mutex operand; callback candidates = externally visible functions and
address-taken locals other than thread start routines. The start-routine
exemption is exact to the creators that run the routine only on the new
thread (`pthread_create`, `__pthread_create_2_1`, `thrd_create`,
`std::thread`'s start): an OpenMP fork runs its microtask on the calling
thread as well, and a fiber on the same OS thread, so a routine handed to
`__kmpc_fork_call`, `__kmpc_fork_teams`, `__kmpc_fork_call_if` or
`__tsan_create_fiber` may release the caller's mutex — `fixed:LO-7` (the
last commit on tsan-dev). Cost on memcached:
LO alone 46 → 9 elisions (its mutexes are external globals). Must-analysis
initialisation and the recording of held sets from an intermediate iteration
— `pending:LO-3/5` (predicted; the constructed counterexample did not
reproduce, so hardening only).

### EA — escape analysis (`§4.4 EA`, Props. ea0/ea1)

*Paper.* An object escapes if its pointer is stored to a global, stored into a
field of an escaped object, passed to a callee whose parameter escapes, or
returned; a non-escaped object is thread-local, per object.

*Code.* A flow-sensitive dataflow per block with a points-to relation and
field paths, plus bottom-up/top-down IPA. Extensions beyond the proposition:
per-program-point elision, made sound by the later-escape rule
(b4bf8b8f4613) — `sound` on alloca objects, `fixed:EA-9` for objects reached
through memory; field sensitivity (`{s,[1]}` vs `{s,[2]}`) — `sound` for
programs without out-of-bounds arithmetic. Holes against the definition's own
clauses: whole-object escape not covering a field (`fixed:EA-2`), "stored into
a field of an escaped object" only in one order (`fixed:EA-3`), reason bits
lost (`fixed:EA-1`, `fixed:EA-4`), unknown objects dropped (`fixed:EA-5`),
unlisted opcodes and loaded pointers with no recorded pointee
(`fixed:EA-6`), argument escape for functions reached other than by a direct
call (`fixed:EA-7`), library retention table (`fixed:EA-8`). A pointee stored through a pointer that is external only by being an argument now carries `GPTR_ALIASING` beside the seed bit, so the callers' mask cannot erase the escape — `fixed:EA-10` (performance branch; shape 18). The escaped-result answer of a call is now given once, on the callee operand, so the argument operands of a call whose returned pointer escapes go through the ordinary classification — `fixed:EA-11` (performance branch; shape 19). A library call that returns a pointer into its argument (strchr, strcpy, memcpy, fgets, realloc, …) no longer yields an object of its own: the object walk continues from the argument, at the whole-object path, and the later-escape walk follows the result — `fixed:EA-12` (performance branch; shape 21). A library call that stores a pointer into its argument through an out-parameter (strtol's end pointer) is the store `*end = s` for the analysis and a store site for the later-escape rule — `fixed:EA-13` (performance branch; shape 22).

### DE — dominance elimination (`§5 DE`, `the de-proofs appendix`)

*Paper.* Redundant if dominated by an access to the same (must-alias)
location, write⇒write, with all interprocedural paths free of release-like
instructions (unlock, create) and external calls; post-dominance additionally
requires no acquire-like instructions, no loops and no calls on the paths.

*Code.* `eliminateInstrByPrePostDominance` (ThreadSanitizer.cpp:1720-1862)
with `locationCovers` (must-alias **and** size coverage — stronger than the
paper's footnote), `classifySyncEffect`, `scanPaths`. Extensions: calls that
are `nosync`/sync-free-by-summary are allowed on dominance paths (the paper
forbids external calls; a call proven sync-free is not one — `sound`);
post-dominance allows calls proven to return — option (ii) as decided:
willreturn on call or callee, or defined and loop-free, for every call
including libfuncs and intrinsics — `fixed:DE-3` (3b23aa757035; yield
unchanged at -O2 where the attributes are inferred); fd I/O (`read/write/pread/pwrite/open`)
fell to the sync-free default although TSan's interceptors make them
release/acquire edges — `fixed:DE-5` (450fc39a8545, listed as not
sync-free); the default itself inverted — `fixed:DE-6` (92f2b95e9d83: the
table now names the sync-free functions — mathematics, integer and bit
operations, memory and string operations on the caller's buffers,
conversions, formatting into buffers, byte order — and every other library
function is treated as possibly synchronising: every file, directory and
time system call, the `_unlocked` stream family, `strtok`, `qsort`; the
inversion also propagates through the sync-free summary, since a function
calling an unlisted library function is no longer sync-free; measured cost
in the verification section at the end). Lock names were never a DE problem: `classifySyncEffect`
always used TargetLibraryInfo's exact table; `invoke` callees not scanned — `fixed:DE-1`; the sync-free summary
consulted its own not-yet-built static pointer — `fixed:DE-2`
(2aa46b60cb86: a module analysis, explicit pointer; measured reach at -O2
identical because FunctionAttrs already infers nosync/willreturn — the
summary only adds reach on unoptimised IR); transitive cover chains —
`sound` (argued) and re-scanned against the surviving root — `fixed:DE-4`
(dc7d9e0a8a20).

*Model deviation, quantified (tsan-exp, `tools/eviction-stress`, f80e80b1dbe6).*
The paper's argument that a covered access is redundant assumes the covering
access's shadow record is still there when the conflicting access arrives.
TSan's shadow is four slots per granule; stock re-inserts the record at every
access, an elided access does not. A synthetic program that evicts the
dominating store's record between the two stores (fillers, trace-position
victim, no happens-before) shows it: stock and sound-only report the race
1000/1000 (the second store re-inserts), DE-only and AllOpt+peel 748/1000 —
0/252 when the record had been evicted, 748/748 when it had not. On the
real workloads (SQLite wal-index, memcached `current_time`) eviction was
measured equal across builds and no race was lost to it, but the mechanism
is real and belongs in the paper's statement of the model (bounded shadow),
not in the soundness claim for unbounded shadow. `decision:Alexey` whether
dominance elimination should be qualified this way in the revision or
guarded (e.g. keep a covered access when the path between crosses many other
granules); no code change made.

The symmetric variant (both effects on one granule) shows the deviation is
two-sided: where the dominating record was evicted, DE loses the A–B race in
0/236 of those runs and keeps C–B in 236/236 of them, while stock's
re-inserting store evicts a third party's record and loses C–B in 71/71 of
the runs where that happens; overall stock 0.91 races per run (A–B 22.8 %,
C–B 68.2 %) against DE 0.93 (17.4 %, 75.3 %) — complementary effects,
comparable totals. Also established (identical in every build): TSan clears
the granule's shadow after a race report, so a second race on the same
granule reported by the same thread is wiped by the first report.

### Whole-program mode via summaries (S)

`-tsan-use-analysis-summaries` with the linked program analysed once under
`-tsan-whole-program` (fafbebedb41e): only externally visible entities are
written, sorted, stamped with `-tsan-summary-id` and ignored on mismatch;
readers overlay on the per-unit analysis (a summary-listed external function
is not an externally reachable root; summary-listed variables join the SWMR
and protected sets; the escape whitelist applies to external callees only);
a seeded compile never overwrites its summary; `-tsan-summary-dir` replaces
the fixed directory; a second header line records the writer's whole-program
setting as provenance (an IR hash is not something a unit that has only
itself could verify; the id is the check). Measured on memcached (26 modules,
-O2): sound-only
per-unit 6356 → with summaries 5852; AllOpt+peel 6865 → 6262 (the unsound
per-unit `-tsan-whole-program` switch gives 5975 for comparison). The
premise the mode asserts: nothing outside the linked module calls into it
except through addresses it takes itself, and `main`.

### Preservation at the application level (tsan-exp, N=10, both stock baselines)

On 297881ddc1c5 (instrumentation identical to the final tree for every
per-unit configuration): SQLite sound and AllOpt+peel report exactly the
stock set (5 L1 / 2 L2); memcached sound-only loses nothing at L2; memcached
AllOpt+peel shows two L2 rows absent — conn_new@memcached.c:761 and
lru_pull_tail@items.c:1207, both readers of `current_time`. Verified from the
IR of both builds: every access to `current_time` is instrumented identically
(clock_handler's two writes, every reader, the two reported sites included;
peeling adds reads), and the only elided read of it anywhere is a covered
read inside do_item_update, neither site. The same pair is 0/10 under the
old stock and 0/30 on def2cf34faeb and 10/10 only under this hash's stock:
it flips with the surrounding instrumentation in both directions. tsan-exp
then confirmed the relocation: under AllOpt+peel clock_handler's write is
reported 10/10 paired with do_item_link:495, lru_maintainer_thread:1671 and
try_read_command_ascii:493 (as under stock) and 3/10 with
lru_maintainer_juggle:1426 — only the two pairs moved. Detection of a race
whose covered read is elided moves from the reader side to the writer side,
which names whichever reader's record is in the cell: the expected
consequence of dominance elimination. Under the L3 key (kind + location +
writer site, readers collapsed) the race is preserved; instrumented accesses
to `current_time` on the binary: stock 71, sound 70, AllOpt+peel 74. `evict_watch` on
`&current_time` (N=5, ASLR off, memtier workload): 41.6M / 39.0M / 38.6M
evictions per run on that granule for stock / sound / AllOpt+peel, all
uncovered and all plain in every build, within 7 %; the writer's record
survives equally, timing decides which reader is named.

Final rows (43111f84d936 summaries builds and the ad0623610ef6 per-unit
builds, N=10 against the 297881ddc1c5 stock): memcached sound + whole-program
summaries keeps all ten frequent stock sites at 10/10, conn_new:761 included,
and loses nothing at L3 outside the 1/10 conn_new burst family; AllOpt+peel +
summaries the same except conn_new:761 (the DE relocation above). Per-unit
ad0623610ef6: sound keeps the ten frequent sites at 9–10/10, AllOpt+peel nine
of ten; every L3 loss is the burst family. Whole-binary static counts with
summaries: sound 6197 → 5717, AllOpt+peel 6658 → 6107.

### Bounded shadow and the optimised builds (P3/P4, tsan-exp with `evict_watch`)

SQLite threadtest3 on 43111f84d936, N=10, ASLR off, the three wal-index
header granules watched (medians, total / uncovered / uncovered-plain):
stock 39008/2220/612, 653104/70282/0, 224874/24346/0; tsan-sound
38462/2181/584, 656228/68186/0, 225423/24561/0; AllOpt+peel
38080/2206/590, 642671/68868/0, 220406/25043/0 — every counter within 3 %
across builds, the ~590 uncovered plain records per run all on the
nBackfill/aReadMark[0] word, none on the read-mark words. The 2.3× seen in
single traced runs was the tracing overhead. On the racing granules the
optimised builds neither increase nor decrease eviction: the bounded-shadow
effect on these races is a property of the workload and the runtime, not of
the instrumentation.

### Second read of the consolidated tree (2026-09-03, tsan-dev 7d856d641027)

Re-read after the history consolidation with the same question: where does a
fail-open answer survive. Verified sound by reading and probing: the
per-instruction single-threaded test in `main` (a creator earlier in the
block ends the single-threaded prefix; indirect calls count as creation);
SWMR's address-escape rule; `collectLaterEscapes` uses CFG reachability
(back edges included); the intrinsic table falls to "not sync-free" for any
intrinsic without nosync/no-memory attributes (x86 fences probed: three
stores kept); every fd-synchronising interceptor that is a library function
(`read/pread/write/pwrite/open/open64`) is listed as not sync-free, and
`fstatvfs` is an FD_ACCESS, not a sync. Found and fixed: shape 14, timed
acquisitions (LO-6, 3d70ff61f640; gate on it 12 × 292/0 and check-tsan 371/0;
the gate on 7d856d641027 before it the same). Recorded assumptions, not holes: a plain
`pthread_mutex_lock` returning an error is assumed not to happen (the
runtime records the lock only on success; a program that proceeds after a
failed plain lock is outside the model, unlike the timed variants whose
timeout is a normal path); thread creation through `clone()` or a
`timer_create` SIGEV_THREAD notification is not on the creator list — closed
by STC-3 on 2026-09-04: neither name is thread-free, so both calls end the
single-threaded prefix.

Branches: the audit branch was merged linearly into `tsan-dev` (main
branch); merged and superseded TSan branches were moved under `archive/`,
the two tools not present on `tsan-dev` kept as `tools/tsan-interceptor-trace`
(interceptor file/line tracing, PRs #44/#45) and
`tools/tsan-access-trace-oracle` (the MemoryAccess trace, PR #52); other
groups' remote branches were not touched.

## Function ledger

Each row's last cell carries the measured coverage of that function (`lines`, `branches`) from the run described under *Coverage*; rows for several functions carry the first one's.


Columns: function · contract · what it must preserve · verdict · tests.
Lines as of b4bf8b8f4613.

### EscapeAnalysis.cpp / .h

| function | contract | preserves | verdict | tests |
|---|---|---|---|---|
| `printEscReason` (63) | debug print of reason bits | — | hygiene (indexed bit 6 of a 6-bit set; widened by EA-1) | — · lines 0.00%, branches 0.00% |
| `printIPAFuncEscInfo` (75), `printSCC` (99), `dbg*` (108-140), `printArgEscStatus` (142) | debug | — | hygiene | — · lines 0.00%, branches 0.00% |
| `isLocalAndExactFunc` (160) | defined, exact-definition function | indirect-call guard (`nullptr` ⇒ false) | sound | ipa-* · lines 100.00%, branches 100.00% |
| `isPointerArgument` (164) | pointer-typed `Argument` | — | sound | ptr-args.ll · lines 100.00%, branches 100.00% |
| `EscapeState::checkAndUpdEscStatus` (175) | escape a pointee when its pointer is escaped | definition clause 2 | fixed:EA-3 (only external status consulted); **fixed:EA-10** (shape 18: a pointee stored through an argument carries `GPTR_ALIASING`, which the callers' summary mask keeps) | escape-transitive-store-both-orders, escape-callee-out-param |
| `EscapeState::forEachPointeeDo` (196) | iterate a slot's pointees | — | sound | aliases.ll |
| `EscapeState::addPointsTo` (207) | record pointer→pointee, transitively | points-to closure | sound (recursion bounded by pair dedup); **compile time** (`perf/ea-pointee-views`): the closure is a depth-first walk whose visited mark is membership in the pointer's list — edges into objects already reached are skipped without the lookup (`addPointsToClosure`), the order of every pair and escape check kept | aliases.ll, escape-pointee-chain |
| `PointsToRelTy::*` (250-340) | two-level map obj→path→pointees; `forEachPointee` subsumes empty path | path lattice | sound; EA-2 makes the escape side match; **compile time**: the list is walked in place when one stored path matches (it was copied per query, an allocation per element), the union built only when several overlap — the same order either way | field-sensitive.ll, escape-pointee-chain |
| `EscapeState::getEscReason` (346) | reason for (obj,path) | lookup must cover prefixes | fixed:EA-2 (exact match) | escape-field-lattice |
| `EscapeState::addEscObjOrReason` (360) | leaf insert, empty-path erases fields | — | sound after EA-2 | — |
| `EscapeState::addEscObj` (405) | escape object and its transitive pointees | definition clause 2 | sound; **compile time**: the walk marks on push (its calls carry one set of bits and commute), and a node a walk at the same points-to version already marked with those bits is pruned with its subtree (`WalkedClosure`, a per-transfer cache: pairs are only added, bits only grow, merges drop it) | escape-transitive-store-both-orders, escape-pointee-chain |
| `mergeEscapedObjects` (429) | union of escaped sets | meet | sound (normalised by EA-2's lookup) | loops-and-if.ll · lines 100.00%, branches 100.00% |
| `getArgEscBottomTopIPA` (444) | callee's argument escape from its summary | clause 3 | precision: missing function ⇒ escaped; missing arg index inserts 0 — fixed with EA-6/7 (data-operand vs argument index) | arg-esc.ll · lines 87.50%, branches 50.00% |
| `getArgEscTopDownIPA` (455) | caller-side argument escape | clause 3 | sound (missing ⇒ escaped) | arg-esc.ll · lines 87.50%, branches 75.00% |
| `isNonConstGV` (466) | non-constant global | — | sound | — · lines 100.00%, branches 100.00% |
| `getExtObjStatus` (472) / `getExtObjStatusIPA` (565) | syntactic status: global / argument / pointer-returning call | — | fixed:EA-6 (`CallInst` only; invoke result "fresh") | escape-opcode-table · lines 100.00%, branches 87.50% |
| `getIPAFuncRetEscStatus` (488) | callee returns escaped memory? | clause 4 | pending:EA-6 (absent ⇒ false; made true) | ipa-return.ll · lines 100.00%, branches 50.00% |
| `isCallNotReturnEscaped` | library call returns fresh memory? | — | fixed:EA-8 (bfaa2b859100): by prototype, `TLI.has`, no name list; realloc escaping | tli-retention · lines 100.00%, branches 83.33% |
| `isSafeExternalCall` | summary whitelist | — | fixed:EA-8 (bfaa2b859100): no summary ⇒ nothing safe; empty line ⇒ nothing known | — · lines 90.91%, branches 83.33% |
| `isCallMayEscape` (536) | may the call's result be non-fresh memory | — | sound for indirect/external; inherits `getIPAFuncRetEscStatus` | ipa-passing-func-ptr.ll · lines 94.44%, branches 75.00% |
| `EscapeAnalysisInfo` ctor (588) | RPO worklist fixpoint over blocks | transfer deterministic in the in-state; escapedness monotone, the map's keys not (an empty-path escape erases the field entries) | sound; only reachable blocks seeded (see `findObjInBBEscState`); **compile time** (performance branch): a block is evaluated only when a predecessor's out-state changed, with the pop sequence kept (a different order could reach a different fixpoint) and returning blocks never skipped (their transfer reads their own previous out-state); budgets with `abandon()` fail closed; verdicts identical (see the performance pass) | loops-and-if.ll · lines 100.00%, branches 43.75%, escape-budget, escape-worklist-large-switch |
| `updRetEscStatus` (646) | mark return-escape from the in-progress state | clause 4 | sound (compensates for stale committed state) | ipa-return.ll · lines 100.00%, branches 62.50% |
| `addEscapedPtrArgs` (672) | seed entry state with escaped pointer args | clause 3 | sound | func-arguments.ll · lines 100.00%, branches 70.00% |
| `compBBEscapeState` (690) | transfer function | all clauses | fixed:EA-5 (incomplete operand skipped); duplicated add at :729/:743 hygiene | escape-incomplete-walk · lines 100.00%, branches 0.00% |
| `mergePredEscapeStates` (761) | meet over predecessors | — | sound (missing pred = empty) | loops-and-if.ll · lines 100.00%, branches 100.00% |
| `typeContainsPointerType` (779) | aggregate transitively holds a pointer | memcpy modelling | sound (9f9eab6db1e0) | escape-adversarial · lines 100.00%, branches 100.00% |
| `getEscInfoCall` (793) | classify a call operand use | clause 3 | sound for indirect/inline-asm/varargs; memcpy source must be an alloca (precision); aggregate-typed args — fixed:EA-6 | ipa-*, escape-adversarial · lines 96.43%, branches 84.85% |
| `getEscInfoLoad` (897) | volatile load = escape | — | sound | — · lines 100.00%, branches 100.00% |
| `getEscInfoStore` (906) | stored pointer aliases the destination | clause 1/2 | fixed:EA-5 (empty destination ⇒ no escape); non-pointer value — fixed:EA-6 | escape-incomplete-walk, escape-opcode-table · lines 92.86%, branches 80.00% |
| `getEscInfoAtomicRMW` (929) | value operand escapes | — | sound | — · lines 100.00%, branches 62.50% |
| `getEscInfoAtomicCmpXchg` (944) | value operands escape | — | fixed:EA-1 (reason truncated) | escape-cmpxchg-publishes · lines 100.00%, branches 60.00% |
| `getEscInfoGetElementPtr` (959) | vector GEP escapes | — | fixed:EA-1 | — · lines 80.00%, branches 50.00% |
| `getEscInfoICmp` (971) | comparison is not an escape | — | sound (a compared pointer cannot be dereferenced elsewhere) | — · lines 93.75%, branches 70.00% |
| `getEscInfoRet` (1001) | returned pointer escapes | clause 4 | fixed:EA-6 (aggregates) | escape-opcode-table · lines 100.00%, branches 100.00% |
| `getEscInfoForOpnd` (1012) | dispatcher | all | fixed:EA-6 (default NO_ESCAPE) | escape-opcode-table · lines 87.76%, branches 80.36% |
| `isDereferenceableOrNull` (1046) | CaptureTracking helper | — | hygiene (vestigial) | — · lines 100.00%, branches 0.00% |
| `findObjInBBEscState` (1062) | block's escaped set lookup | — | hygiene→pending: bare `assert` on an unreachable block (release UB); guard with "not analysed ⇒ escaped" | — · lines 100.00%, branches 0.00% |
| `findObjInFuncEscState` (1070) | per-function union (flag) | — | sound (cache invalidated, 9864b0e9e094) | escape-flow-insensitive · lines 93.33%, branches 87.50% |
| `isEscapedForBBImpl` (1088) | external status, then block/union state | — | sound | simple.ll · lines 100.00%, branches 94.44% |
| `isEscapedForBB/IPA` (1115/1122), `isEscapedInFuncIPA` (1129) | wrappers | — | sound | — · lines 0.00%, branches 0.00% |
| `forEachPointeeDo` (1149) | per-block pointees | — | same `assert` note as above | — · lines 100.00%, branches 62.50% |
| `getFullEscReasonForBB` (1158) | OR of external and state reasons | — | sound | — · lines 100.00%, branches 0.00% |
| `isEscapedForFunc` (1165) | union over blocks, OR-ed | summary input | sound | ipa-top-bottom.ll · lines 100.00%, branches 87.50% |
| `printEscapingForBB` (1181), `print` (1204) | printers | — | hygiene | all Analysis/EscapeAnalysis tests · lines 100.00%, branches 85.71% |
| `EscapeAnalysis::run` (1213), printer (1219) | non-IPA mode | — | sound; note PASS-1 double-sanitize did not reproduce | — |
| `setAllPtrArgsNotEscaped` (1231), `isRecursiveCallGraphNode` (1238) | SCC optimistic init | fixpoint | sound with `traverseCGBottomTop`'s iteration | ipa-recursive.ll, ipa-SCC2.ll · lines 100.00%, branches 100.00% |
| `updIPAFuncEscInfo` (1249) | write bottom-up summary | — | sound | ipa-simple.ll · lines 100.00%, branches 45.45% |
| `traverseSCCsAndInitIPAEscInfo` (1276) | find recursive functions/SCCs | — | sound; `assert` on null node hygiene | ipa-SCC2.ll · lines 100.00%, branches 78.57% |
| `getFuncToCallSitesMap` | direct call sites per function | clause 3 top-down | sound as a call-site map; the address-taken rule lives in evalTopDownArgEscStatus | ipa-address-taken-table (planned) · lines 100.00%, branches 91.67% |
| `EscapeAnalysisInfo::TLI` (member) | library knowledge for the function | — | fixed (c402aec8dec3): was a reference to a function-analysis result freed by `PreservedAnalyses::none()` while the module result lived on — a use-after-free on every later query, latent until prototype validation dereferenced it | tli-retention (crashed before) · lines 100.00%, branches 43.75% |
| `evalTopDownArgEscStatus` | caller-side argument escape | clause 3 | fixed:EA-7 (bfaa2b859100): address taken or externally visible ⇒ every pointer argument escapes | ipa-address-taken-table (ed) · lines 100.00%, branches 16.67% |
| `traverseCGBottomTop` (1419) | leaf-first summaries | — | sound; declarations get no entry (⇒ escaped) | ipa-top-bottom.ll · lines 100.00%, branches 75.00% |
| `isFuncPassedToObjCSelector` (1472) | ObjC selector mitigation | — | precision (substring) | — · lines 38.89%, branches 22.22% |
| `traverseCGTopDown` (1494) | callers-first refinement | — | sound (non-local linkage skipped ⇒ escaped) | ipa-top-bottom.ll · lines 97.56%, branches 82.14% |
| `readNonEscapingFuncs` (1555), `writeIPASummary` (1788), `getFileNameFromPath` (1605), `createLogDir` (1611) | summary files | whole-program mode | pending:S (trust, keying, determinism) | (planned) · lines 82.35%, branches 59.09% |
| `EscapeAnalysisGlobalInfo` ctor (1619) | driver | — | sound | ipa-* · lines 100.00%, branches 29.17% |
| `isEscapedUndrlObjOrPointee` (1683) | TSan entry: object or pointee escaped at block | — | sound (incomplete ⇒ escaped; escape-unidentified.ll) | escape-unidentified · lines 100.00%, branches 57.14% |
| `isEscapedForBBTSan` (1713) | per object, then pointees | — | fixed:EA-4 (reason clobbered); loaded slot with no pointee — fixed:EA-6 | escape-loaded-from-escaped-slot, escape-loaded-unknown-pointee · lines 100.00%, branches 0.00% |
| `isEscapedUndrlObjOrPointeeAnywhere` (1740) | per-object variant | sound-FS rule | fixed:EA-4 | escape-later-through-loaded-pointer · lines 100.00%, branches 0.00% |
| `isStructFieldGEP` (1867), `getUnderlyingObjectWithPath` (1903) | object + field path | field lattice | sound (non-struct GEP resets to whole); a library call that returns into its argument is looked through, to the argument at the whole-object path (**fixed:EA-12**, performance branch; shape 21) | field-sensitive.ll · lines 76.47%, branches 80.00% |
| `getUnderlObjThroughLoads` (1970) | look through loads (unbounded) | — | precision; bound with MaxLookup (hygiene) | — · lines 100.00%, branches 100.00% |
| `getUnderlObjsWithoutPHIInvCheck` (1986) | phi/select fan-out | — | fixed:EA-2 (path reset to empty) | escape-field-lattice · lines 100.00%, branches 100.00% |
| `getUnderlyingObjectFromInt` (2026) | integer→object | — | sound (ValueTracking copy) | escape-incomplete-walk · lines 100.00%, branches 64.29% |
| `getUnderlObjsForCodeGenWithoutPHIInvCheck` (2054) | fail-closed object walk | — | sound | escape-unidentified · lines 97.73%, branches 77.27% |
| `getUnderlyingMayEscObjs` (2103) | public entry with `IsComplete` | — | sound; callers must honour `IsComplete` (EA-5) | — · lines 100.00%, branches 22.22% |
| `EscapeAnalysisGlobal::run` (1849), printer (1854) | plumbing | — | sound | — |

### TargetLibraryInfo.cpp (fork additions)

| function | contract | verdict | tests |
|---|---|---|---|
| `doesArgEscape` (1417) | does libc retain the argument | fixed:EA-8 (bfaa2b859100: `setbuf/setvbuf` retain arg 1, realloc arg 0 aliases the result); default true sound | tli-retention |; realloc's argument no longer escapes through the call — the result stands for the block (EA-12)
| `isReturnValueEscaping` (1723) | does libc return non-fresh memory | fixed:EA-8 (bfaa2b859100: `realloc` family escaping; section III left as is, unreachable for pointer returns) | tli-retention |
| `returnsPointerIntoArg` (new) | does libc return a pointer into an argument: strchr/strrchr/strstr/strpbrk/memchr/memrchr, the copy family and its `_chk` variants, fgets/gets, realloc | **fixed:EA-12** (performance branch; shape 21): the object walk and the later-escape walk look through such calls; strtok, ctermid and realpath excluded (static or earlier memory) | escape-libcall-result-alias |
| `storesArgThroughArg` (new) | does libc store a pointer into one argument through another: the strtol/strtoul/strtoll/strtoull/strtod/strtof/strtold end pointer | **fixed:EA-13** (performance branch; shape 22): modelled as the store `*end = s` in `getEscInfoCall` and as a store site in `collectLaterEscapes`; a null end pointer stores nothing | escape-libcall-out-pointer |
| `isSyncFree` (1836) | libc function synchronises? | fixed:DE-5 (450fc39a8545: fd I/O not sync-free); fixed:DE-6 (92f2b95e9d83: an explicit sync-free list, unlisted ⇒ not sync-free; the blocklist kept and tested first) | elim-by-dominance-across-fd-io, elim-by-dominance-tli-sync-free-table |
| `isLockAcquireFunction` / `isLockReleaseFunction` (2123/2148) | exact-name lock tables | sound; LO now has the same exact-name discipline (LO-1) | elim-by-dominance-across-acq-rel-* |

### SingleThreaded.cpp / .h

| function | contract | preserves | verdict | tests |
|---|---|---|---|---|
| `collectAccessingInstrs` (45) | users of a global through ConstantExpr/alias | over-approximation of accesses; false for a user not followed to an instruction (another global's initializer, `llvm.used`) | **fixed:SWMR-2, LO-8** (performance branch; shape 20) | aggregate-and-st-only.ll, swmr-address-in-initializer, address-in-initializer · lines 90.00%, branches 60.00% |
| `isKnownThreadCreator` (58) | creator by exact name / mangled prefix (`__kmpc_fork_call_if` added) | rule 2 | sound; single list after NAMES-1 | thread-creators.ll · lines 100.00%, branches 100.00% |
| `isKnownThreadFree`, `callbackParams`, `isStdNamespaceName`, `intrinsicWrapsCall` (new) | is a bodiless function known not to start a thread: intrinsic, TLI-recognised library function, carrier, exact allowlist, closed prefix families, namespace std minus thread starters | rule 2 | fixed:STC-3 (198e1b5c1332): tables, unlisted ⇒ creator; recorded assumption: a libc/libstdc++ name binds to that library | unknown-external.ll, thread-free-names.ll · lines 96.30%, branches 86.36% |
| `isSingleThreaded(Function*)` (67) | wholesale ST; `main` never | — | sound at the query | single-threaded.ll · lines 100.00%, branches 87.50% |
| `mayCreateThread` (75) | call may start a thread: unknown callee, known or mapped creator, carrier handed a non-constant or creating callback; one predicate for `main`'s blocks and the fixpoint | rule 2 | **fixed:STC-3** (198e1b5c1332; before, a bodiless callee answered false and the fixpoint skipped indirect calls) | unknown-external.ll, single-threaded-unknown-external.ll, swmr-unknown-external.ll, preservation_stc_unknown_external.c · lines 92.59%, branches 85.71% |
| `blockCreatesThreads` (97), `computeMainMTBlocks` (102), `ctorMayCreateThread` (new) | MT blocks of `main` = successors of creating blocks, closed; the entry block when a static constructor of this unit is a creator | rule 1/5 | fixed:STC-3b (198e1b5c1332) | single-threaded.ll, global-ctor-creates-threads.ll · lines 90.00%, branches 75.00% |
| `propagateMTFromMain` (122) | callees of MT instructions of `main` | rule 5 | sound | single-threaded.ll · lines 100.00%, branches 83.33% |
| `isSingleThreaded(Instruction*)` (143) | per-instruction in `main` | rule 1 | sound | preservation_stc_main.cpp · lines 100.00%, branches 87.50% |
| `identifyBaseThreadCreators` (165) | seed creators, and every declaration not known thread-free (after `loadSummary`, whose declarations are exempt) | rule 2 | fixed:STC-3 (198e1b5c1332) | thread-creators.ll, unknown-external.ll, unknown-external-summary.ll · lines 100.00%, branches 61.11% |
| `markFuncAndAllCalleesAsMultithreaded` (175) | mark F and callees MT | rule 4 | **fixed:STC-1** (no-op at its call site) | single-threaded-creator-callee · lines 100.00%, branches 75.00% |
| `runSTMTAnalysis` (199) | fixpoint over the call graph; `mayCreateThread` at every call-site edge | rules 1-5 | fixed:STC-2 (default ST for unseen functions); fixed:STC-3 (198e1b5c1332: indirect calls and callbacks judged in every function, not only `main`) | single-threaded-linkage, unknown-external.ll · lines 98.65%, branches 50.00% |
| ctor (286) | driver; ignores `runSTMTAnalysis`'s return | — | hygiene | — |
| `findSWMRGlobals` (314) | globals never written in MT | Prop. swmr | **fixed:SWMR-1, SWMR-2** | swmr.ll, swmr-linkage, swmr-address-in-initializer · lines 100.00%, branches 62.50% |
| `print` (369), `createLogDir` (416), `writeSummary` (424), `readSummary` (451) | printer, summaries | whole-program mode | pending:S | (planned) · lines 100.00%, branches 100.00% |
| `SingleThreaded::run` (502), printer (516) | plumbing | — | sound | — |

### LockOwnership.cpp / .h

| function | contract | preserves | verdict | tests |
|---|---|---|---|---|
| `getTopDownSCCList` (30) | unused | — | hygiene (dead) | — · lines 0.00%, branches 0.00% |
| `intersectLockStates`, `computeMeet` | must-meet over predecessors | must-lockset | fixed:LO-3 (c8debe12f363): RPO seeding, so a skipped predecessor is a back edge only (optimistic seed of the standard fixpoint) | loop-unlock-in-body, stale-held-record · lines 100.00%, branches 40.91% |
| `canonicalLockIdentity` (132) | global + constant offset, else unknown | lock identity | sound (51c96792787b, 35a2bae9aad5) | lock-identity.ll · lines 93.75%, branches 83.33% |
| `getLockCallInfo` | classify a call as lock/unlock | — | fixed:LO-1 (exact tables); defined wrappers go through summaries | exact-names · lines 94.44%, branches 94.44% |
| `handleLock` (181), `handleUnlock` (200) | state transitions | — | sound (no assert; pair only with an acquisition) | lock-identity.ll · lines 83.33%, branches 22.73% |
| `applyTransferFunc` | transfer incl. callee releases, exit acquisitions, opaque calls | interprocedural must-lockset | fixed:LO-2 (20c178992bfd); unknown release clears — sound | callee-releases, external-call-policy · lines 96.43%, branches 70.00% |
| `computeReleaseSummaries`, `mayBeCalledBack`, `startsRoutineOnNewThreadOnly`, `isPrivateMutex`, `applyOpaqueCall`, `applyCalleeReleases` | syntactic may-release facts, callback set, private-mutex policy C | interprocedural must-lockset | fixed:LO-2 — sound: releases are a may-set applied as definite; a thread start routine cannot release the creator's mutex — **fixed:LO-7** (the last commit on tsan-dev): only for creators that run it solely on the new thread; OpenMP forks and fibers run it on the caller | external-call-policy, fork-call-runs-on-caller · lines 100.00%, branches 88.89% |
| `buildSummary` | per-function fixpoint + exit state | — | fixed:LO-3/5 (c8debe12f363): every block seeded once in RPO; the held-lock record is replaced on every visit and erased when empty | stale-held-record · lines 100.00%, branches 66.67% |
| `doIPALockOwnershipAnalysis` (378) | bottom-up SCC iteration | — | sound | — · lines 95.45%, branches 85.71% |
| `loadSummary`, `writeSummary` | whole-program summaries: external entities only, sorted, id-stamped; overlay on the per-unit result | whole-program mode | fixed:S (fafbebedb41e) | summary-whole-program.ll · lines 100.00%, branches 75.00% |
| `moduleIgnoresSync` (456) | give up under ignore-sync annotations | — | sound | ignore-sync.ll · lines 100.00%, branches 75.00% |
| ctor (469) | driver | — | sound | — |
| `isAnnotationFunc`, `isTryLockFunc`, `isSharedLockFunc` | name predicates | — | fixed:LO-6: a conditional acquisition (try, timed, clock variants) holds nothing on the failure path the runtime does not record | annotations.ll, locks.ll · lines 100.00%, branches 75.00% |
| `findLockUnlockFunctions` | recognise lock/unlock functions | — | fixed:LO-1 (12399f969130; exact names) | exact-names · lines 100.00%, branches 78.57% |
| `getLocksProtecting` (592) | held set at an instruction | — | sound | — · lines 100.00%, branches 50.00% |
| `findProtectedGlobalVariables`, `isDirectAccessOf` | intersection over MT accesses of a private, unescaped global | Prop. protection | fixed:LO-4/4b (12399f969130), **LO-8** (performance branch; shape 20) | linkage-and-escape, address-in-initializer · lines 100.00%, branches 58.57% |
| `print` (676), `LockOwnership::run` (781), printer (794) | plumbing | — | hygiene (dead commented body) | — · lines 100.00%, branches 100.00% |

### ThreadSanitizer.cpp / .h

| function | contract | preserves | verdict | tests |
|---|---|---|---|---|
| ctor (345) | flag sanity | — | hygiene (`llvm_shutdown` on conflict is not an exit) | — |
| `~ThreadSanitizer` (362) | disabled stats dump | — | hygiene (dead) | — |
| `tryPeelLoops` (628) | peel first iteration when a loop-invariant access exists | — | sound (transformation only) | peeling.ll · lines 100.00%, branches 100.00% |
| `ThreadSanitizerPass::run` (702) | per-function driver | — | pending:PASS-2 (`optional<T*>` null); PASS-1 not reproduced | — |
| `ModuleThreadSanitizerPass::run` (757) | module driver; `SFI` static | — | pending:DE-2 | elim-by-dominance-inter-calls |
| `initialize` (843) | declare callees | — | sound | — |
| `isVtableAccess` (997), `shouldInstrumentReadWriteFromAddress` (1005), `addrPointsToConstantData` (1031) | upstream elisions | — | sound (upstream) | read_from_global.ll, tsan_address_space_attr.ll · lines 100.00%, branches 100.00% |
| `updateEscapeStatistics` (1054) | counters | — | hygiene (OTHER/INVALID never counted before EA-1) | — · lines 94.44%, branches 93.75% |
| `isThreadCreatorName` (1085) | second creator list | — | fixed:NAMES-1 pending | — |
| `allLoadsAcquire` (1095) | every load of G is acquire | release-like publication | fixed:EA-9 pending (no linkage check) | escape-later-through-loaded-pointer · lines 92.86%, branches 75.00% |
| `LaterEscapes::allReleaseLike` (1136) | nothing non-release-like reachable | — | sound given a correct `Seen` | escape-adversarial |
| `collectLaterEscapes` (1146) | reachable escape sites of the access's object | sound-FS rule | **fixed:EA-9 pending** (wrong object; memcpy source); follows the result of a call that returns into the argument (**fixed:EA-12**, shape 21); a library call storing a pointer into the argument through another argument is a store site (**fixed:EA-13**, shape 22) | escape-later-through-loaded-pointer · lines 100.00%, branches 75.00% |
| `attributeFlowSensitiveElision` (1236) | statistics | — | hygiene | — · lines 41.67%, branches 41.67% |
| `chooseInstructionsToInstrument` (1273) | the elision pipeline | all propositions | sound in order; each step's analysis verdict is what this ledger audits; LO/STC/SWMR steps gain counters (STATS-1) | ThreadSanitizerNew/* |
| `createInstrIndexMap` (1458), `getReverseReachable` (1467) | indices; predecessor closure (memoised) | — | sound | elim-by-dominance-paths |
| `locationCovers` (1494) | must-alias and size coverage | condition 2 | sound (stronger than the paper) | elim-by-dominance-locations |
| `isTsanAtomic` (1527) | atomic access | — | sound | — · lines 100.00%, branches 100.00% |
| `classifySyncEffect` (1537) | acquire/release/unknown/may-not-return per instruction | conditions 4/5 | fixed:DE-5 (450fc39a8545); fixed:DE-6 (92f2b95e9d83, through `isSyncFree`'s inverted default); fixed:DE-3 (3b23aa757035, termination bit for every call); fixed:DE-2 (2aa46b60cb86, explicit SFI pointer) | elim-by-dominance-across-fd-io, elim-by-dominance-tli-sync-free-table, across-acq-rel-*, across-intrinsics |
| `isInstrDangerous` (1604) | any sync effect | — | sound | — |
| `scanPaths` (1619) | union of effects on all paths, incl. the removed access's cycle | conditions 4/5 | sound; DE-4 root re-check added (dc7d9e0a8a20) | elim-by-dominance-paths, elim-by-dominance-chain-across-latch |
| `eliminateInstrByPrePostDominance` (1720) | find covers, chain them | Props. really-red / post | sound (chains argued and, since dc7d9e0a8a20, re-scanned against the root); dead `ToRemove` test hygiene | elim-by-*-simple/diamond/coverage |
| `InsertRuntimeIgnores` (1864) | upstream | — | sound | sanitize-thread-no-checking.ll |
| `sanitizeFunction` (1874) | per-function pipeline | — | sound; `__tsan_disable/enable` regions untested (coverage) | — |
| `checkActiveThreadCount` (2117) | `monotonic` load, `> 1` | th:stc-dyn | sound | (planned: dynstc.ll) |
| `instrumentLoadOrStore` (2139) | emit callback, optional guard | — | sound; vtable paths skip the guard (precision) | tsan_basic.ll |
| `createOrdering` (2242) | upstream | — | sound | atomic.ll · lines 85.71%, branches 87.50% |
| `disableInterceptorForInstr` (2259) | toggle TLS flag around a call | — | fixed:RT-1 (223406c284b6): a `CallInst` can unwind through the frame; guarded only when nounwind | intercepted-call-may-unwind |
| `isPointerEscaped` | interceptor may be skipped only under the sound flow-sensitive rule (not escaped here, later escapes release-like) | Prop. ea0 + sound-FS | fixed:PASS-3 (4df6138b85ca) | memintrinsic-later-escape · lines 100.00%, branches 83.33% |
| `instrumentInterceptedCalls`, `instrumentMemIntrinsic` | skip interceptor for local operands | — | fixed:PASS-3 (4df6138b85ca): toggles report their IR; `struct.timeval` workaround deleted — `signal_thread_sigctx_race.cpp` passes 9/9 across stock/EA/AllOpt+peel without it, the failure was the lost interception itself (hypothesis H1), not signal timing (H2 not needed) | memintrinsic-later-escape, intercepted-call-may-unwind |
| `instrumentAtomic` (2397), `getMemoryAccessFuncIndex` (2485) | upstream | — | sound | atomic.ll |
| `SyncFreeInfo` ctor (2520), `findFunsContainsLoops` (2623) | per-SCC sync-free / loop-free summaries | conditions 4/5 | fixed:DE-1/DE-2 (2aa46b60cb86): `CallBase` scans, pessimistic init, `SyncFreeAnalysis` module analysis, ctor passes itself (sound in bottom-up SCC order) | elim-by-dominance-inter-calls, elim-by-dominance-transitive-clean, elim-by-dominance-invoke-callee · lines 100.00%, branches 0.00% |
| `SyncFreeInfo::isSyncFree` / `isLoopFree` (.h 68/82) | queries, unknown ⇒ false | — | sound | — · lines 100.00%, branches 0.00% |

### Runtime (compiler-rt/lib/tsan, sanitizer_common)

| site | contract | verdict |
|---|---|---|
| `__tsan_active_thread_count` (tsan_rtl.cpp:35; `ThreadCreate` :117 `+1`, `ThreadJoin` :320 `-1`, both `seq_cst`) | counter for the dynamic guard | sound (decrement at join, not exit; detach/fork over-count) |
| `InterceptorEnabled` (sanitizer_common.cpp:23, THREADLOCAL) and its six readers | skip a string/memory interceptor for local operands | sound (real call still performed); RT-1 note |
| `MutexLock/ReadLock` `process_lock` guards (tsan_rtl_mutex.cpp) | ReX bookkeeping only with `g_filter` | sound (1af068d46cae) |
| ReX filter (`tsan_filter.*`, `filter_ctx`) | research code | fixed:RT-2 (0d63553b3e43): behind `COMPILER_RT_TSAN_REX_FILTER` (default OFF); with OFF, upstream's `tsan_rtl_mutex.cpp` compiled with this tree's headers is byte-identical except `__LINE__` immediates, `ThreadState` has upstream's members, `tsan_rtl_access.cpp` differs by `NoteEviction` and its two call sites only (and since the performance pass not even by those: see the `NoteEviction` row); the dead RUN-less `ReXFilter/` tests are deleted (previously: compiled in, hooks dead, `enable_filter=1` paid and never filteredcal |
| `__tsan_enable/__tsan_disable` (tsan_interface.inc) | no-op symbols | fixed:RT-2 (the racy `int GV` counter, the `MemoryRangeFreed` VPrintf and the CheckRaces debug prints are gone) |
| `NoteEviction` (tsan_rtl_access.cpp, eviction branch of both `CheckRaces`), `evict_total` / `evict_concurrent_foreign` / `evict_concurrent_foreign_plain`, flags `print_evictions`, `trace_evictions`, `evict_watch` (per-granule counters, 248f45c260ef) | measure the bounded-shadow loss channel: overwrites of another thread's uncovered access | P3 implemented (5eca63015f63); **fixed:RT-3** (performance pass, branch `perf/runtime-counters`): the counters were an unconditional lock-prefixed increment on one process-global cache line per eviction and an out-of-line call inside the inlined `CheckRaces`, which cost every `__tsan_read*/write*` a three-register callee-saved prologue on its fast path — stock TSan ran ~1.4× slower than the paper compiler's (SQLite threadtest3; 2.67× on `checkpoint_starvation_1`, 3.0e8 evictions in 10 s). Now behind `COMPILER_RT_TSAN_EVICTION_STATS` (default OFF): with OFF every symbol of `tsan_rtl_access.cpp` is byte-identical to upstream c609043dd009 compiled with the same command line, except the fork-only `__tsan_enable/__tsan_disable` and one `CHECK` line immediate in `DoReportRaceV`; with ON the counters are per-thread plain increments handed to `Context` at thread finish, the watch/trace work out of line (`preserve_most`), and the access callbacks keep one callee-saved register (`rbx`) — a measurement build. The uncovered evictions in lock-heavy code are the interceptors' atomic reads on the mutex word, hence the plain subset | shadow_evictions.c (`REQUIRES: tsan-eviction-stats`) |

## Verification on the final tree

`check-llvm` 31541 passed, 2 failed: `Bindings/OCaml/debuginfo.ml` ("Unbound
module Llvm_debuginfo", the OCaml debuginfo binding is not built in this
configuration; no fork change under `llvm/bindings`) and
`function-pass-alone.ll`, run before the PASS-1 code it tests was built
(passes since). `check-clang` 33721 passed, 0 failed. `check-tsan` 371/0,
`check-asan` 545/0, `check-lsan` 160/0, `check-ubsan` 658/0,
`check-sanitizer` 1332/1 (a unit-test shard of allocator tests, passing 3/3
standalone). The 12-configuration TSan suite matrix 292/0 in every
configuration. The faithful K=5 report replay against stock (294 tests, 137
reporting) on 9ef1fce44e2d: L1-identical in every one of the twelve
configurations; the only "other" buckets are the documented non-deterministic
tests — `race_on_barrier2.c` (either side reports), `fd_location_closed.cpp`
(location descriptor varies) — and `fork_atexit.cpp`, which a K=20
re-replay shows reported in 3/20 stock runs and 4–7/20 under SWMR, DE,
DE+peel and sound-only: a timing-dependent report in every configuration,
stock included, now listed with the other two.

## Verification after STC-3, DE-6 and LO-7 (2026-09-04)

The tree after the three fixes (working tree over `3d70ff61f640`; the same
code was then committed as the three commits named in the commit map and
rebuilt for the stamp). The 12-configuration TSan suite matrix 293/0 in
every configuration (one test more than before: the end-to-end
`preservation_stc_unknown_external.c`); `check-tsan` 372/0; the faithful
K=5 report replay against stock (295 tests, 138 reporting) L1-identical in
every configuration, the only "other" buckets the documented
non-deterministic `race_on_barrier2.c` and `fork_atexit.cpp`; `check-llvm`
31556 passed, 0 failed; `check-clang` 33721 passed, 0 failed. Every new
negative test was run against the frozen parent (`3d70ff61f640`'s `opt`
and `clang`) and fails there at the intended check; the end-to-end test's
race is unreported in 8/8 runs of the parent's STC build and reported in
8/8 runs of the new one (stock: 4/4 in both).

Reach, static instrumented-access counts at -O2 (`-fsanitize=thread`,
`grep -c __tsan_(read|write|unaligned)`), frozen parent `3d70ff61f640`
against the new tree, before the `-tsan-thread-free-names` option was
added (it changes nothing when unset):

| configuration | memcached (26 modules) old → new | sqlite3.c old → new | shell.c old → new |
|---|---|---|---|
| stock | 6911 → 6911 | 56636 → 56636 | 6452 → 6452 |
| STC | 6515 → 6910 | 56636 → 56636 | 4336 → 6447 |
| SWMR | 6893 → 6911 | 56636 → 56636 | 6380 → 6452 |
| LO | 6902 → 6902 | 56636 → 56636 | 6452 → 6452 |
| sound-only | 6356 → 6760 | 55725 → 55725 | 4235 → 6304 |
| DE | 6672 → 6672 | 55699 → 55699 | 6302 → 6312 |
| DE+peel | 7510 → 7510 | 61323 → 61323 | 7409 → 7419 |
| AllOpt+peel | 6865 → 7338 | 60380 → 60380 | 4757 → 7254 |
| AllOpt+peel, per-unit `-tsan-whole-program` | 5975 → 6941 | — | — |

What the numbers say. DE-6 costs ten accesses on shell.c and none on
memcached or sqlite3.c: on this code the unlisted library calls that sit
between a covering access and a covered one are rare, and the sync-free
summary's propagation changes nothing at -O2. LO-7 costs nothing (no OpenMP
forks or fibers in the three programs). STC-3 removes nearly all of the
single-threaded-context yield on memcached and shell.c, and SWMR's with it:
memcached's `main` begins with `sanitycheck()`, whose first call is
libevent's `event_get_version()`, and shell.c's `main` calls into sqlite3.c
before anything else — a bodiless callee in both cases, so the
single-threaded prefix ends at once and everything `main` calls afterwards
is multi-threaded. That is the rule working as specified: the thread that
races with the prefix is started inside exactly such a call in the general
case, and the analysis cannot tell libevent from a thread pool by name. Two
sound ways to recover the yield exist and are Alexey's to choose: the
whole-program summaries (the `unknown-external-summary.ll` path) and the
`-tsan-thread-free-names=<names>` option added with this change, which lets
a project vouch for a library's API by exact name (libevent's `event_*`,
say) on the user's responsibility while the default stays sound.

**Corrected 2026-09-13, and the correction matters.** This paragraph said
shell.c's callees "are found single-threaded there, so the seeded per-unit
compile keeps its prefix". Measured on the corpus, it does not: the summary
generated from the linked shell + sqlite3 module names **nine**
externally-visible single-threaded functions, and per-unit reach moves
6 447 → 6 430 — 17 accesses of the 2 111, 0.8 %. With the vouch as well it
reaches 6 365, still 3.9 %. On memcached the same pair works far better,
6 910 → 6 697, recovering **213 of 395 (54 %)**, and there the summaries must
be *generated under the same vouch* or they recover nothing at all.

The deeper reason shell.c cannot be recovered is that the reach was not sound
to begin with. Of the 1 915 instrumented accesses in the 39 functions the
paper's STC classified single-threaded in `shell.ll`, **1 736 — 91 % — are in
the 18 that transitively call `pthread_create`** in the linked program:
`do_meta_command` alone is 1 141. And a vouch list over SQLite's API would be
false for seven of the names shell calls (`sqlite3_exec`, `sqlite3_step`,
`sqlite3_prepare_v2`, `sqlite3_declare_vtab`, `sqlite3_deserialize`,
`sqlite3_stmt_explain`, `sqlite3_table_column_metadata`), each of which
reaches a creator. Repeating the experiment with the honest 123 names leaves
STC's recovery unchanged at 65 accesses, while SWMR's apparent 359-access gain
collapses to **3** — the whole of it had come from the seven wrong entries.
A vouch list tuned by watching the number go down measures its own errors.
sqlite3.c has no `main`, so STC never applied to it and its counts do not
move.

Coverage of the changed functions on the IR suites (shadow libraries with
`-fprofile-instr-generate`, `llvm-cov` per function; lines / branches):
`mayCreateThread` 92.59% / 85.71%, `isKnownThreadFree` 96.30% / 86.36%,
`callbackParams` 100% / 100%, `isStdNamespaceName` 54.05% / 50.00% before
the thunk and substitution cases were added to `unknown-external.ll`,
`identifyBaseThreadCreators` 100% / 61.11%, `runSTMTAnalysis` 98.65% /
50.00%, `computeMainMTBlocks` 90.00% / 75.00%, `ctorMayCreateThread`
82.61% / 68.18%, `mayBeCalledBack` 100% / 88.89%,
`startsRoutineOnNewThreadOnly` 100% / 100%, `isSyncFree` 27.58% / 51.37%
(a table: only the named cases the tests call are counted as covered).

## Coverage

Measured on tsan-audit ad0623610ef6 with the five translation units
(EscapeAnalysis, SingleThreaded, LockOwnership, TargetLibraryInfo,
ThreadSanitizer) rebuilt under `-fprofile-instr-generate -fcoverage-mapping`
into shadow `libLLVMAnalysis.so` / `libLLVMInstrumentation.so` and the IR test
directories (`Instrumentation/ThreadSanitizer{,New}`,
`Analysis/{EscapeAnalysis,SingleThreaded,LockOwnership}`) run against them:

| file | functions | lines | regions | (+ runtime suite, AllOpt+peel) functions | lines | regions |
|---|---|---|---|---|---|---|
| EscapeAnalysis.cpp | 87.8 % | 82.8 % | 75.2 % | 90.8 % | 89.8 % | 82.0 % |
| SingleThreaded.cpp | 82.6 % | 71.6 % | 65.7 % | 96.0 % | 95.3 % | 87.3 % |
| LockOwnership.cpp | 90.0 % | 85.5 % | 75.9 % | 96.7 % | 94.8 % | 84.6 % |
| ThreadSanitizer.cpp | 90.9 % | 81.1 % | 73.3 % | 100 % | 92.0 % | 84.7 % |
| TargetLibraryInfo.cpp (upstream tables included) | 47.6 % | 38.3 % | 26.8 % | 57.1 % | 55.7 % | 55.2 % |

The first three columns are the IR directories alone on ad0623610ef6; the
last three add the 292-test runtime suite under AllOpt+peel on babd3b0a01df
with the audit's tests in place. The only non-debug functions never executed
are dead code: `EscapeAnalysisInfo::isEscapedForBB` (an unused query
variant) and `LockOwnershipInfo::getTopDownSCCList`.

Zero-coverage functions were debug printers, the summary readers/writers
(covered since by the split-file summary tests), and: the dynamic
single-threaded guard, volatile under dominance, atomicrmw publication, the
acquire-only publication rule, post-dominance loop termination, the
two-site lockset meet — each now has a test (44da093b1b45). The runtime
suite (12 configurations) adds coverage on top of this; the fail-closed
branches of every fix in this ledger are executed by the negative test
named in its row.



## Performance pass (2026-09-05, separate branches off 729521af8965)

Prompted by tsan-exp's Stage A: (1) `sql_yacc.cc` compiles for 3 h 02 min
under `-tsan-use-escape-analysis-global` (16–55 s without) — the escape
analysis's per-function fixpoint, not its verdicts; Chromium's
`vk_safe_struct_utils.cc` is a second cliff, distinct from the parser's: its
`SafePnextCopy` links 543 `new` results into one pNext chain through a phi,
and the state's points-to closure over that clique — a copy of the pointee
list and a full escape-marking walk per step — did not finish in an hour
even with the fixpoint fixed (`perf/ea-pointee-views`); (2) stock TSan on this
tree ~1.4× slower than the paper compiler's — the eviction counters (RT-3
above); (3) after the soundness fixes no configuration beats stock by much
(memcached 0.80 with peeling and summaries, FFmpeg 0.83 with summaries,
SQLite/Redis/MySQL ≈ 1.0), because the paper's dominance yield came from
the unsound location test. Nothing here lands on `tsan-dev`; each branch
carries its own tests, static-count delta and frozen copy.

| branch | change | gate and measurement |
|---|---|---|
| `perf/runtime-counters` | RT-3: counters behind `COMPILER_RT_TSAN_EVICTION_STATS` (OFF), per-thread when ON | objdump per-symbol identity with upstream (above); check-tsan OFF/ON: <RT3-CHECK> |
| `perf/ea-compile-time` (first commit) | EA-10, shape 18: the out-parameter escape | `escape-callee-out-param.ll` fails on 729521af8965 at both checks |
| `perf/ea-compile-time` (second commit) | EA-11, shape 19: arguments of an escaped-result call | `escape-arg-of-escaped-result-call.ll` fails on 729521af8965 |
| `perf/ea-compile-time` (third commit) | the escape analysis's fixpoint: a block is evaluated only when a predecessor's out-state changed (returning blocks always), the object's entries are erased by range, merges insert with a hint; a fail-closed budget (`-tsan-ea-max-blocks`, `-tsan-ea-max-evals-per-block`, `-tsan-ea-max-state-entries`; abandoned = everything escaped) | verdict identity: `-tsan-ea-verify-skips` re-evaluates every skipped block and asserts it a no-op — 0 failures over both lit suites and the 28-module corpus (sqlite3.c, shell.c, memcached) in all three modes; static counts equal to the branch without the change in all nine configurations (memcached / sqlite3.c / shell.c); canonical printed states <CANON>; compile time <EATIME> |
| `perf/ea-compile-time` (fourth commit) | `unknown-external-summary.ll`: overlapping CHECK-DAG patterns anchored (the flake) | 3/3 |
| `perf/stage-b` (sixth commit) | EA-13, shape 22 — the strtol-family end pointer (found while deriving tsan-exp's vouch lists) | `escape-libcall-out-pointer.ll` fails on 729521af8965 and d3bf9f8c39fe; static counts on the patched corpus unchanged in all four configurations (EA, SWMR, LO, sound bundle: memcached 6829 / 6928 / 6919 / 6819, sqlite3.c 55834 / 56713 / 56713 / 55834, shell.c 6303 / 6453 / 6453 / 6298) — no program in the corpus publishes an end pointer; five suites 123 passed / 1 unsupported / 0 failed |
| `perf/ea-compile-time` (fifth commit) | SWMR-2/LO-8, shape 20 and EA-12, shape 21 — both found by the yield agents on 94764fe839df | the three tests fail on 94764fe839df; static counts (opt on the `sanitize_thread`-patched corpus, EA / SWMR / LO / sound bundle): memcached and sqlite3.c unchanged in all four, shell.c −10 under EA and the bundle — accesses through never-published realloc'd buffers in `main` and `process_input` (the argument no longer escapes at the call; the result stands for the block); five suites 123/0 |
| `yield/dynstc-runs` c877c6eca80b | C1 (Y4): a DynSTC guard run spans calls that cannot create a thread (`SingleThreadedInfo::callMayCreateThread`); guards hoisted to loop preheaders; the vtable paths guarded; switch `-tsan-dynstc-runs-across-thread-free-calls` | `dynstc-runs.ll`, `dynstc-hoist.ll`, `dynstc-vptr.ll` fail on the parent; `__tsan_read/write` counts unchanged; `NumThreadCountLoads` (DynSTC alone) sqlite3.c 30 932 → 28 908 (−6.5 %), shell.c 4 360 → 3 742 (−14.2 %), memcached 4 313 → 3 771 (−12.6 %); three compiler-rt tests, run under the integrated build |
| `yield/de-atomic-ordering` eede63e4e9b5 | C2 (Y2): an atomic on a DE path counts by its ordering, exactly as the runtime does (relaxed = no synchronisation; a seq_cst load acquires only); `force_seq_cst_atomics` recorded as incompatible | tests fail on the parent; the classification fires 2 502 times on sqlite3.c but static counts are unchanged on the corpus (every such path has another blocker); two compiler-rt tests |
| `yield/de-cover-containment` 80a25d4ae80a | C3 (Y1): a cover is any access whose byte range contains the covered one (one SSA base with constant offsets, or a re-verified partial alias) | tests fail on the parent; sqlite3.c 6–12 accesses; compiler-rt test |
| `yield/swmr-stc-small` 3c29e065da21 | C4 (Y5b, Y5c): a global read only through nocapture readonly call arguments stays read-only (`callEffectOnGlobal`, switch `-tsan-swmr-readonly-call-args`); a declaration that promises not to write memory starts no thread | three tests fail on the parent; corpus yield 0 (one memcpy source on sqlite3.c, verdict unchanged) |
| `yield/ea-later-escape-summaries` 7fdae665f93f | C5 (Y3): a later call whose summary proves the argument non-retaining is not an escape site (`mayArgEscapeThroughCallee`: one summary, two consumers); switch `-tsan-ea-later-escape-uses-summaries` | tests fail on the parent; sqlite3.c −17, shell.c −2, memcached −3 (EA and the bundle); the sizing's ceiling (173 internal-call sites on sqlite3.c) was never reachable — 156 of those callees do retain the pointer |
| `yield/interceptor-table` 529d7f481ac0 | C6 (Y5a): the interceptor toggle for 18 string/memory functions keyed by `LibFunc` and bound by prototype; the toggle prologue in 15 more interceptors; memchr's toggle repaired (its int argument went through the pointer test); a result-pointer guard for the eight entries returning into the buffer; switch `-tsan-intercepted-call-table` | `intercepted-call-table.ll` fails on the parent; toggles sqlite3.c 3 → 5, shell.c 0 → 5, memcached 0 → 1; the two compiler-rt tests run under the integrated build (check-tsan not run on the branch) |
| `yield/lo-widening-note` ebbf79366181 | C7 (Y6): design note only (`tools/notes/lo-widening-design.md`) — recommends against widening now | — |
| `perf/ea-join-sharing` (one commit off d3bf9f8c39fe) | the escape analysis's block states as a base shared by pointer plus the journal of the block's own transfer (its effect: entries set, entries erased, pairs added -- canonical, so two journals on one base are equal iff the states are); a join folds the journals over the first predecessor's base, other bases once each as a difference, in the from-scratch order; a join with 16+ predecessors keeps its in-journal and refolds only the predecessors that changed, when each of them grew; `-tsan-ea-verify-journal` recomputes every evaluation the old way and aborts on any difference | verify mode: five suites 123/0 (plain and wrapped), 28-module corpus 28/28 exit 0, the extract exit 0; printed-state digests identical to d3bf9f8c39fe's opt under the same conditions: corpus 84 rows, redis-server.ll whole-program 256 451 lines, the MYSQLparse extract as far as both printers got (643 311 / 330 837 canonical lines, 347 / 180 whole blocks, global / local); static counts identical in EA / SWMR / LO / sound bundle on the sanitize_thread corpus (112 rows); the extract through `opt` with EA, reference and new back to back on one CPU: flow-sensitive 1 379 s / 2.78 GB -> 12.7 s / 1.76 GB, flow-insensitive 1 176 s / 2.80 GB -> 13.4 s / 1.76 GB, the same 47 349 pops / 29 972 evaluations / 17 377 skips; sqlite3.ll 7.9 s -> 5.1 s, shell.ll 0.60 s -> 0.60 s; test `escape-join-journal.ll` |
| `perf/ea-pointee-views` | the state's pointee handling, exact: a pointer's stored pointee list is walked in place instead of copied per query (the union is built only when a whole-object query overlaps a field list, or vice versa); the closure of `addPointsTo` skips edges to objects it already reached without a lookup; the escape-marking walk marks on push and prunes a subtree already walked at the same points-to version with the same bits; switches `-tsan-ea-pointee-views`, `-tsan-ea-closure-cuts` (hidden, on) restore the old paths; statistics `NumEAPointeeViews/Snapshots`, `NumEAClosureSteps/Skipped`, `NumEAEscWalkNodes/Pruned` | `escape-pointee-chain.ll` pins states, instrumentation and the statistics with the cuts on and off; five suites 124 tests, 123 passed, 1 unsupported; canonical printed states identical on the 28-module corpus in all three modes (85 rows, sqlite3's flow-sensitive row uncapped), and on redis-server.ll whole-program (on vk.ll this branch's output of both printers is deterministic and the same with the cuts on and off; the reference printers had not finished after four hours, that comparison is pending); static counts identical in all four configurations; compile time (opt, one CPU with an idle SMT sibling, reference / this): vk.ll flow-sensitive > 3600 s unfinished / 50.1 s, flow-insensitive > 3600 s / 51.7 s (18.2 GB either mode, see the remark); the MYSQLparse extract, same core back to back, 1067 s / 1083 s and 1067 s / 1066 s (2.80 GB both; the pointee code is under 0.01 % of its profile, the rest is the merge); sqlite3.ll 7.46 s / 7.10 s and 7.34 s / 7.02 s (493 MB / 512 MB); shell.ll 0.57 s / 0.58 s both modes. On vk.ll: 593 503 lists walked in place, 0 copied, 295 392 closure steps, 79 904 622 closure edges skipped, 743 932 walk nodes, 155 314 subtrees pruned. What remains on vk.ll is outside the pointee handling: every block's state holds the whole 543² clique (18 GB across 555 states), the join re-merges it per evaluation, and the teardown frees it — the join's business |
| `perf/stage-b2` (2dcc82078a60 + `perf/ea-pointee-views` 9e678cc6ae3e cherry-picked and resolved; the second stage-b copy, hash2) | the two compile-time changes together: the pointee-views cuts applied to the templated mutators, so that the closure, the escape-marking walk and the walk cache run the same call sequence over an `EscapeState` and over a `StateView` (a view walks in place the one stored list -- the base's or the journal's -- that overlaps a query, and builds the union as `StateJournal::collectPointees` does when two or more overlap; the walk cache lives in the view and is keyed on the base's pairs plus the journal's) | the gate inputs were regenerated after a reboot emptied `/tmp` (memcached's 26 modules and `sqlite3.ll` from `*-summaries-work`, `shell.ll`, the `MYSQLparse` extract -- 6 189 blocks from the frozen d3bf9f8c39fe clang against the lost original's 7 145 -- and `vk.ll` from the same clang with the corpus recipe, all under `/extra/alexey/worktrees/corpus`; the reference opt is `perf/stage-b` plus the thread-free-list change): five suites 126 tests, 125 passed, 1 unsupported; `-tsan-ea-verify-journal -tsan-ea-verify-skips` appended to every RUN line of the EA and TSanNew suites 79/80 (the one failure is `escape-pointee-chain.ll`'s `STATS` lines, every counter doubled exactly by the reference transfer -- no verifier fired), over the 28-module corpus in all three modes 84/84 exit 0 (sqlite3 ~14 min a row), over the extract through the tsan pipeline exit 0 (6 761 s / 3.59 GB; 40 642 pops, 15 153 of them skippable and evaluated anyway; 378 791 lists walked in place, 865 copied; 10.4 M walk subtrees pruned); on vk.ll the verify run was stopped after 68 min still inside the verifier's own from-scratch join (the 543-predecessor merge redone per predecessor change, 217 MB -- the reference computation the shared bases replaced), so vk.ll is covered instead by identical canonical printed states across the default path, `-tsan-ea-join-cache-min-preds=1000000`, `-tsan-ea-rebase-journal-entries=0 -tsan-ea-rebase-join-journal-entries=0` and the flow-insensitive mode (one digest, 304 155 canonical lines; the cuts-off paths are the old n⁴ closure and do not finish there); static counts identical on 112 rows (full `__tsan_*` callee histograms per module and configuration, EA / SWMR / LO / sound); same-time canonical digests (blocks sorted within a function, lines within a block) identical on 84/84 corpus rows and on the redis-server.ll whole-program print (256 451 lines). Compile time, reference / this, one CPU with an idle SMT sibling, `-passes='module(tsan-module),function(tsan)' -tsan-use-escape-analysis-global`: the extract fs 1 091.6 s / 3.44 GB -> 14.7 s / 1.95 GB, fi 1 076.5 s / 3.44 GB -> 13.4 s / 1.95 GB; vk.ll fs > 1 800 s (stopped by the cap, 121 MB, still in the old closure) -> 11.0 s / 159 MB, fi (> 3 600 s in the pointee-views gate) -> 8.8 s / 158 MB -- the 18 GB of pointee-views alone is gone, every block sharing the clique's base (the print pass on this `-g2` vk.ll spends 170-280 s in the printer's metadata slotting, not in the analysis); sqlite3.ll fs 6.41 -> 4.07 s, fi 6.47 -> 4.00 s; shell.ll 0.48 -> 0.50 s both modes. On vk.ll: 4 966 pops, 2 223 evaluations, 2 743 skipped, 295 392 pairs, 591 866 lists walked in place and none copied, 79 904 622 closure edges skipped, 739 564 walk nodes, 155 284 subtrees pruned, 2 joins materialised, 1 123 journals replayed. A caveat on the digest method: the printed-state digests compare equal only for binaries run side by side (the printer's block order varies between runs of one binary), so the identity of the compile-time changes rests on the assertion verifiers and on the static counts, with the same-time digests as a third witness |
| `perf/granule-merge` bf14520e52a9, 448bee5b541e (off `perf/stage-b2` c38c1e7e94ec) | Two accesses to adjacent fields of one aligned shadow granule carry two different byte masks, so each misses the runtime's `ContainsSameAccess` fast path; merged into one wider access they are one mask and one miss. The merged mask is exactly the union of the masks the group writes today, so no byte is claimed that was not claimed before and no new race becomes reportable. Carried by the lower-addressed member using its own pointer, which therefore always dominates the emission point. Runs after dominance elimination, on the accesses that survived it, so the covering tests there still see the original widths. Iterated to a fixpoint, so four adjacent 2-byte fields of one granule collapse to a single 8-byte access rather than two 4-byte ones; each merge rescans the whole span of the group it forms. Refused when a call or an atomic lies in that span, for compound read-modify-writes, volatile and vtable accesses, and when neither the declared alignment nor the provable pointer alignment reaches the merged width. Switch `-tsan-merge-granule-accesses` (hidden, default on); statistics `NumGranuleMerges`, `NumGranuleMergeBlockedByCall/ByAlignment/ByLockset`, `NumGranuleMergeSkippedNotPlain` | `merge-granule-accesses.ll`: merged shapes and positive controls, each differing from a merged shape by one thing (call between, lock between, atomic between, mixed read/write, straddling the granule boundary, non-adjacent, different bases, under-aligned, different blocks, volatile member, variable index). Fails on the frozen parent `tsan-perf-c38c1e7e94ec` at every merge check (exit 74) and the parent's own output matches the `OFF` prefix exactly, so the flag off is the parent's instrumentation. Static counts, sound bundle, off to on: sqlite3.c 55 752 -> 52 037 (-6.66 %, 3 715 merges), memcached's 26 modules 6 802 -> 6 677 (-1.84 %, 125), MySQL sql_yacc.cc 9 604 -> 9 476 (-1.33 %, 128), shell.c 6 297 -> 6 213 (-1.33 %, 84), Redis whole-program 36 688 -> 36 465 (-0.61 %, 223). No module's count rises. **Against the rule fixed before it was built** (under 2 % of instrumented sites on memcached and the transform is dropped unbuilt): the counting-only sizing said 3.03 % on memcached and the transform delivers 1.84 %, because the sizing tested only that the offset within the object was naturally aligned and not the pointer's alignment (564 pairs refused on sqlite3.c, 8 on memcached's largest module). memcached is below the bar, and the application the transform reaches furthest is SQLite, whose accesses are 92.7 % fast-path hits -- the regime it was not aimed at. Kept for a measurement decision rather than declared to have passed |
| `perf/granule-merge` -- the equal-lockset gate is inert, and the precision cost is unmitigated | The gate proposed as the transform's precondition (merge only accesses with the same must-held lockset) refuses 0 pairs in 68 851 sites and cannot fire: changing a lockset requires a call, and a call in the span is refused first. Probed directly with three functions (`tools/msize/gate-probe.ll`) -- two adjacent field stores with a `pthread_mutex_lock` between them are refused by the call check, and a pair inside one critical section is accepted | Safety rests on the window rule (the instrumentation window is flushed at every call, ThreadSanitizer.cpp:2117, :2121), not on `LockOwnershipInfo`, so the transform is not conditioned on `-tsan-use-lock-ownership`. `NumGranuleMergeBlockedByLockset` is kept as a monitor that must read zero; **a non-zero count means the window rule was widened and merging has become unsound**. With no reachable gate the precision cost stands unmitigated: a race on either of two merged fields is reported as a race on the group, and the compiler cannot separate the case where that matters from the case where it does not. L1 and L2 report movement is therefore published as a precision cost with the granule-sharing worked example; an L3 criterion keys the merged fields together and cannot see the distinction the transform destroys |
| `perf/granule-merge` afe47a2a75a5, ffdbc8d8860f -- the unaligned mechanism, and the frozen copies | An under-aligned pair merges through the unaligned entry point rather than being refused. `UnalignedMemoryAccess` (tsan_rtl_access.cpp:595-634) splits at the granule boundary and masks exactly the requested bytes on each side, so the merged access claims what the pair claims today, touches at most the two granules the pair already touches, and returns after one granule when the address is aligned at run time -- never more shadow work than two separate accesses, always one call instead of two. Switch `-tsan-merge-granule-unaligned` (hidden, default on), so the two mechanisms separate in a measurement | Alignment was the transform's largest single refusal (564 pairs on sqlite3.c; 33 of the 35 candidates on memcached's proto_text) and it is not recoverable by inference: asking LLVM what it can prove about each pointer, rather than what the instruction declares, recovers **zero** extra merges, so those addresses are genuinely under-aligned rather than un-annotated. That forecloses better alignment inference as a line of work. Static counts, aligned-only against aligned-plus-unaligned: sqlite3.c -6.66 % -> **-8.01 %** (4 467 merges, 752 unaligned), memcached's 26 modules -1.84 % -> **-3.12 %** (212, 87), shell.c -1.33 % -> -2.21 % (139, 55), Redis whole-program -0.61 % -> -1.34 % (493, 270), MySQL sql_yacc.cc -1.31 % -> -1.34 % (129, **1**). MySQL is the outlier and the awkward one: it was the transform's second named target for its 44 % miss rate, it sizes lowest of the five, and the unaligned mechanism -- which lifts every other target substantially -- adds a single merge there. Its adjacent pairs are already aligned; there was nothing for the new mechanism to recover. **The 2 % memcached bar is cleared only with the unaligned mechanism, which the rule did not contemplate; the transform the rule was written about delivers 1.84 % and misses. Both figures are quoted and the flattering one does not stand alone.** At -8.01 % SQLite is a larger static change than the campaign ever achieved **on SQLite**, whose own reach never exceeded 3.3 % removal, so this row is 2.4x the largest removal ever measured there. Globally the campaign already reached 7.8 % removal (on FFmpeg), so 8.01 % is 0.2 points past the maximum and not far outside it -- an earlier draft of this row overstated that and is corrected. The reason the row is still worth running is not the magnitude but the mechanism: the campaign's flatness was established over reach achieved by dominance, escape analysis and peeling, each of which removes accesses the runtime's fast path already handles cheaply. A merge removes miss-generating pairs, a different kind of reach. If reach-versus-speedup is flat because of *what* was removed rather than *how much*, this row can break the flatness at 8 % where the campaign's own 7.8 % did not. Frozen for measurement as `/extra/alexey/builds/tsan-merge-afe47a2a75a5` (counters OFF) and `…-astats` (`COMPILER_RT_TSAN_ACCESS_STATS=ON`), one branch so every arm comes from one code state; the counters were verified to fire on the ON copy and to be silent on the OFF one, rather than assumed from the CMake option. Three arms, one switch each: default, `-tsan-merge-granule-unaligned=false` (aligned only), `-tsan-merge-granule-accesses=false` (off) |
| `perf/granule-merge` -- the eviction question points the other way | `CheckRaces` stores one shadow word per access whatever its size, and its same-sid branch reuses a slot only when the masks are equal (tsan_rtl_access.cpp:259-301): today's two adjacent 4-byte writes have disjoint masks, so they occupy **two** of the granule's four slots, while the merged 8-byte write occupies **one** | The merge therefore halves this thread's slot footprint in the granule and leaves a slot free that a remote thread's record would otherwise compete for, so it should **reduce** eviction pressure rather than lengthen a window. Direction pre-registered before the probe runs: merge-on must lose no more races than merge-off at any burst level, and plausibly fewer; more would mean the reasoning above is wrong and the transform is in trouble regardless of any speedup. The existing `tools/eviction-stress` probes cannot test this at all -- they use single-byte accesses from different threads to `static char g[8]`, so no basic block holds two mergeable accesses and every arm would behave identically while exercising nothing (tsan-exp caught this before running it). **The merge shifts the phase of the runtime's replacement pattern, so the two arms are never comparable cell by cell.** The victim slot is `trace_pos / sizeof(Event) % kShadowCnt` (tsan_rtl_access.cpp:293), `trace_pos` advances by exactly one Event per *traced* access (tsan_rtl.h:821), and a fast-path hit returns before `TryTraceMemoryAccess` and so advances nothing. The phase is therefore the thread's cumulative traced-access count mod 4 — and the merge removes trace events, since two missing 4-byte writes emit two events where the merged 8-byte write emits one (`TryTraceMemoryAccessRange` once, on the unaligned path too). Merge-on and merge-off run at different phases for identical source and an identical burst length. An arm-versus-arm comparison at one burst length compares two phases of a four-phase pattern; the comparison must be aggregated over a full residue class (bursts 0..15, plus a random-N cell) rather than read cell by cell. The replacement probe's acceptance conditions: objdump confirms one `__tsan_write8` under merge-on and two `__tsan_write4` under merge-off, per arm; and the merge-off arm must report the race at zero burst, or the probe is broken rather than the transform sound |
| `perf/granule-merge` -- a regression guard that started passing for a new reason | `elim-by-dominance-locations.ll` asserts that dominance elimination does not collapse two disjoint locations -- the `a[0]` versus `a[3]` bug -- and its `@distinct_struct_fields` case writes two adjacent i32 fields of one global. The merge covered them with a single `write8`, so the test began passing for a reason that has nothing to do with what it watches | The merge is disabled in that test's RUN lines so it keeps testing dominance elimination in isolation, and the boundary is pinned in the merge test instead, in both directions: `arr[0]` with `arr[3]` must not merge (four elements apart, no union of them is a granule), `arr[0]` with `arr[1]` must (one aligned granule, mask exactly the eight bytes the pair writes). A guard that passes for a new reason has stopped being a guard |
| `perf/granule-merge` -- model deviation, narrower than first stated | The merged call is emitted at the **lower-addressed** member. When the fields are written in ascending address order -- the common case -- that member is also the earliest, so the call sits ahead of every member, which is where TSan puts a record anyway, and the later fields' records move *earlier*. Only descending order moves a member's record after its own access. Every race is still reported either way: TSan's check is symmetric, both records still execute unconditionally in the same block, and whichever thread records second sees the other's record -- the report may name the other access of the same race | The subset is measured, not assumed: records move later on 243 of 4 467 merged groups on sqlite3.c (5.4 %), 8 of 52 on memcached's largest module (15.4 %), 19 of 129 on MySQL's sql_yacc.cc (14.7 %), 39 of 139 on shell.c (28.1 %). The group's span, which bounds the window, is mean 7.17 instructions and max 38 on sqlite3.c, mean 2.37 and max 6 on sql_yacc.cc, mean 2.26 and max 8 on memcached's largest module. An eviction-stress null is therefore reportable as a bound with a scope -- "no loss at this contention, over groups whose members are at most 38 plain instructions apart" -- rather than as a bare "no reports lost". A span threshold is one line if the distribution ever asks for it; on this distribution it does not |
| `perf/window-coalesce-sizing` b21dad4ff9f7 -- race-preservation sensitivity for the merge | Four end-to-end tests in `compiler-rt/test/tsan` in which the granule merge **fires** and a race **must be reported**: `granule_merge_race_ascending` (fields written low-then-high, remote races the high field only), `granule_merge_race_descending` (written high-then-low, so the merged call sits at the later instruction and the high field's record moves after its own store -- the only arrangement with that property), `granule_merge_race_subword` (a 2-byte pair merged to 4 bytes, remote access narrower than the merged width), `granule_merge_race_multithread` (three threads racing a merged pair at once). Each runs in both arms, so merge-off is the control. Plus a MONITOR run on `merge-granule-accesses.ll` asserting `NumGranuleMergeBlockedByLockset` stays zero, and `window-coalesce-sizing-emits-nothing.ll` pinning the sizing census's emits-no-code claim | **Why these exist: the suite had almost no sensitivity to the merge.** Measured across the whole of `compiler-rt/test/tsan`: 277 tests build, **103 assert that a race is reported, and the merge fired in exactly two of them** (`compare_exchange.cpp` 9 merges, `custom_mutex5.cpp` 3). So the earlier `check-tsan` 371/0 with the merge defaulted on was a clean result from a check that barely exercised the transform -- the same shape as the eviction probes, which use single-byte accesses from different threads and contain no mergeable pair at all. Condition zero was checked before any test counted (`-mllvm -stats`, `NumGranuleMerges` non-zero in each); the first draft of the ascending test compiled to nothing, because the struct was static and never read, so every store was dead-code eliminated. Measured 10/10 runs reporting in every arm of every test; the multithread pair gives an identical 20 reports over ten runs either way. Gate: five IR suites 127 passed / 1 unsupported / 0 failed; `check-tsan` 466 discovered, **375 passed, 0 failed**, 1 expected failure |

## A 23rd lost-race shape: realpath and ctermid (2026-09-13)

`realpath(path, buf)` and `ctermid(buf)` fill a caller-supplied buffer and return a
pointer into it. Both are absent from `returnsPointerIntoArg`, and that absence is
deliberate: `realpath(p, NULL)` allocates and `ctermid(NULL)` answers from a static
buffer, so the result cannot be *said* to alias the argument. But both also sat in
`doesArgEscape`'s "known not to escape" list (`TargetLibraryInfo.cpp:1617, 1625`), so
nothing paid for them on either side:

```c
char b[PATH_MAX]; g = realpath(p, b); b[0] = 'x';   /* b[0] elided, race lost */
```

Reproduced before it was fixed, EA on, merge off, `__tsan_write1` per function:

| function | before | after |
|---|---|---|
| `pub_strchr` (covered by `returnsPointerIntoArg`) | 1 | 1 |
| `pub_strtok` (covered by `doesArgEscape` arg 0) | 1 | 1 |
| `pub_realpath` | **0** | 1 |
| `pub_ctermid` | **0** | 1 |
| `unpub_realpath` (control: never published) | 0 | 1 |

The two working controls are what make the zeros elision rather than "nothing to
instrument". `doesArgEscape` now answers true for realpath's second argument and
ctermid's only one.

The trade is on the conservative side and is pinned in the test rather than hidden:
the buffer escapes at the call whether or not the result is published, which is why
`realpath_result_unpublished` is instrumented. The precise alternative — admitting both
to `returnsPointerIntoArg` under a non-null check on the buffer operand — would keep
that case local. It is not taken because **neither name occurs anywhere in the corpus**
(0 modules of 28), so the conservative form costs nothing measurable and asserts less
about what these calls return.

Static counts, EA, merge off: sqlite3.ll 55 752 and shell.ll 6 302, both unchanged.
Test `escape-libcall-fills-and-returns-arg.ll`: two published cases, the conservative
consequence, and three positive controls (`strchr` published, a never-passed alloca,
and realpath's read-only first argument). It fails on the frozen parent
`tsan-merge-afe47a2a75a5` at the first shape check (exit 74) while that parent's
`strchr_published` still reads 1 — so the failure is this fix and not a broken test.
Five IR suites 129 passed, 1 unsupported.

Found by the classification sweep against `e90a3fc41004` while checking whether
`returnsPointerIntoArg`'s exclusion list was complete. It is; the escape side was not.

## Commit map after the history consolidation (2026-09-03)

The hashes cited above are those of the working history, preserved as
`backup/tsan-audit-2026-09-03` and `backup/tsan-dev-2026-09-03`; the frozen
build copies under `/extra/alexey/builds` carry them in `TSAN_AUDIT_HASH` and in
`clang --version`, with a `CONSOLIDATED_HASH` file beside them naming the
consolidated commit. `tsan-dev` now holds, over the pushed base
`9f5d402cb36b`: Alexey's three March commits, six review steps (tip `8f6899f5c5ff`),
eight audit steps and the LO-6 fix with this ledger.

| frozen copy (old hash) | consolidated commit containing its code |
|---|---|
| `b4bf8b8f4613` tsan-dev-b4bf8b8f4613 (the audited tree (branch artifact/paper-sound)) | `8f6899f5c5ff` |
| `def2cf34faeb` tsan-audit-def2cf34faeb (SWMR-1) | `ccde44118fce` |
| `297881ddc1c5` tsan-audit-297881ddc1c5 (twelve shapes) | `53ff2c8868c8` |
| `a08292850aee`, `ad0623610ef6` (eviction counters; thirteen shapes, EA-7/8, RT-2) | `fe1e4f609675` |
| `43111f84d936`, `f80e80b1dbe6` (summaries mode, evict_watch; final code before LO-6) | `48aebcf67c5d` |
| `8e271eab146d` (LO-6, before the message rewrite) | `3d70ff61f640` |
| the copy frozen from this commit (its hash in `TSAN_AUDIT_HASH`; STC-3, DE-6, LO-7) | the last commit on tsan-dev (this one) |

| fixes (old hashes) | consolidated step |
|---|---|
| 1a59e61cc82d tooling, f3fcc325e521, 145b058805c1 STATS-1, ad0623610ef6 stock controls | `f85db29cf7cf` |
| def2cf34faeb SWMR-1, a633cc3f0e77 STC-1/2 | `ccde44118fce` |
| 667343f20eaf EA-1, 7c35430b549d / dbde56f2e3f7 capture, 58c8ace31c52 PASS-2, d06851ec7a6d EA-2, cbeb570ed61c EA-3, 92c681a2642f EA-4, 7be7dc568f45, 957f8e506697 EA-5, 09b9a74d17b7 EA-6, 67e9532aa926, feb4f802b35b, fe9c96cfd10f EA-9, c402aec8dec3 UAF, bfaa2b859100 EA-7/8 | `c669989b3986` |
| 12399f969130 LO-1/4, 20c178992bfd LO-2, c8debe12f363 LO-3/5 | `53ff2c8868c8` |
| 450fc39a8545 DE-5, 2aa46b60cb86 DE-2, 3b23aa757035 DE-3, 223406c284b6 RT-1, dc7d9e0a8a20 DE-4, 4df6138b85ca PASS-3 | `288f5bc7bff0` |
| 5eca63015f63 P3, 0d63553b3e43 RT-2, 248f45c260ef evict_watch | `fe1e4f609675` |
| fafbebedb41e S, 9ef1fce44e2d PASS-1 | `48aebcf67c5d` |
| 44da093b1b45, babd3b0a01df, d6ea6277e35c tests; every ledger commit | `0f9437de0f82` |
| 4b39e6bde9db LO-6 | `3d70ff61f640` |
| STC-3, STC-3b | 198e1b5c1332 |
| DE-6 | 92f2b95e9d83 |
| LO-7, this verification | the last commit on tsan-dev (this one) |
