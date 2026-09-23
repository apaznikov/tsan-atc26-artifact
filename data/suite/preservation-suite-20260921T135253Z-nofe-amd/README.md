# The regression suite with the upstream flag `-tsan-instrument-func-entry-exit=false`, K = 5 (21 Sep 2026)

The suite gate behind the "Upstream flag" section of `PERFORMANCE.md` (measured, not claimed): `scripts/30-preservation-suite.sh 5`
on the second host (AMD EPYC 9115, 64 threads) from a scratch clone of the artifact, taken on 21 Sep, whose
`data/preservation/lit-configurations.txt` had two rows appended, `nofe` and `AllOpt+peel+DynSTC+nofe` (the last two
lines of `configurations.txt` here; the shipped matrix has twelve rows and does not carry them, because the flag is not
one of the paper's configurations). Layout as `../preservation-suite-20260921T052239Z`: `failures.tsv` (configuration,
repeat, kind, test), `report.txt` (the candidate-loss rule's output), `manifest.txt`, `ran.txt`, one `lit-<config>-<k>.log`
per repeat. Three configurations ran, stock and the two with the flag (`ran.txt`; `manifest.txt` counts the matrix
file's fourteen rows, not the run's). Result: stock 0 failures; the two flag configurations 20 candidate losses each,
the same twenty tests, failing in every repeat. The twelve paper configurations' K = 5 result on the shipped compiler
is `../preservation-suite-20260921T052239Z/`, 0 failures. The classification of the twenty (eighteen on report content, one on a
suppression, one on report count) was made by re-running them with `lit -v -a` on the same host and reading the
reports; that run's logs (188 MB) are not shipped, the classification is in `PERFORMANCE.md`, "Upstream flag".
