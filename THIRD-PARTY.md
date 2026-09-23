# Third-party components

Nothing here is modified except where a "Modification" line says so. Modified files are kept apart
from the originals so the difference is visible.

| Component | Version | License | How it enters the artifact | Modification |
|---|---|---|---|---|
| LLVM / clang / compiler-rt | trunk commit `c609043dd009` (19.0.0git, 6 May 2024) | Apache-2.0 with LLVM Exceptions | fetched by the container build; our changes are the patch series in `compiler/patches/` | our patches only |
| ThreadSanitizer's regression suite, from the same commit | as above | Apache-2.0 with LLVM Exceptions | **vendored** in `tests/tsan`, `tests/sanitizer_common`, `tests/compiler-rt-src` and the two `lit.common.*` files, 445 files including the upstream licence text at `tests/LICENSE.TXT`, so the preservation suite runs without a compiler-rt checkout and the licence travels with the code it covers. Four of the 445 are our own code inside the vendored tree: `tests/tsan/tools/preservation/` (the report-replay scripts), under the artifact's MIT licence | one, marked in the file: `tests/lit.common.cfg.py` compares glibc versions as tuples instead of through `distutils`, which Python 3.12 no longer has (without it no `glibc-*` feature was detected, one test ran that upstream marks unsupported on this glibc and two that require glibc 2.30 were skipped). Our own tests are in `tests/ir` and in `tests/tsan/tools/preservation/` and are not third-party |
| memcached | 1.6.29 | BSD-3-Clause | the upstream archive ships unmodified in `third-party/sources/`, sha256 pinned in `third-party/SOURCES.md` | none |
| memtier_benchmark | 2.1.1 | GPL-2.0 | the upstream archive ships unmodified in `third-party/sources/`; built by `scripts/40-perf.sh memcached` when first needed | none |
| Redis | 7.0.15 | BSD-3-Clause | the upstream archive ships unmodified in `third-party/sources/`, sha256 pinned in `third-party/SOURCES.md` | build flags only, to inject the TSan compiler, applied by `harness/nosql/redis/Makefile.patch` |
| SQLite | 3.50.2 (`sqlite-src-3500200`) | Public domain | the upstream archive ships unmodified in `third-party/sources/`, sha256 pinned in `third-party/SOURCES.md` | `threadtest3.c` replaced by our copy, which adds the `--w1-threads` argument; our copy is `harness/sql/sqlite/threadtest3.c`, to be diffed against the file in the SQLite source tarball named above |
| MySQL | 8.0.39 | GPL-2.0 | fetched from GitHub, sha256 pinned in `third-party/SOURCES.md`; Boost 1.77 fetched by its build | none |
| Boost | 1.77 | BSL-1.0 | fetched by MySQL's own build (`everything` tier only); see `third-party/SOURCES.md` | none |
| FFmpeg | n4.3.9, built with `--enable-gpl` (libx264, libx265) | GPL-2.0 (with those options) | the upstream source archive ships unmodified in `third-party/sources/`, sha256 pinned in `third-party/SOURCES.md` | none |
| FFmpeg input clip | Blender Foundation open movie cut, see `docs/ffmpeg-input.md` | CC BY 3.0 | redistributed as an asset of this repository's GitHub release `inputs-v1`, with attribution in the release notes (Blender Foundation, mango.blender.org); also derivable from the source URL by the exact ffmpeg command in `docs/ffmpeg-input.md` | derived cut: 100 s from 06:00, cropped and scaled to 1366x768, re-encoded |
| Chromium | revision `bdef6783a05f0b3f885591e7d2c7b2aec1a89dea` | BSD-3-Clause | not included (documented only, `docs/chromium.md`) | four Telemetry files with raised timeouts and one build-flag line, neither shipped (`docs/chromium.md` records what they were); neither is exercised here, since Chromium is documented rather than run |

Paths beginning `harness/` are in the measurement harness, our own code, copied into this repository from the authors' harness repository; `harness/MANIFEST.tsv` lists every file
with its sha256.

If a component's license in this table turns out to be wrong, that is our error; please tell us.
