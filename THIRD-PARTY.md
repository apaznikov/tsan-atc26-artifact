# Third-party components

Nothing here is modified except where a "Modification" line says so. Modified files are kept apart
from the originals so the difference is visible.

| Component | Version | License | How it enters the artifact | Modification |
|---|---|---|---|---|
| LLVM / clang / compiler-rt | trunk commit `c609043dd009` (19.0.0git, 6 May 2024) | Apache-2.0 with LLVM Exceptions | fetched by the container build; our changes are the patch series in `compiler/patches/` | our patches only |
| ThreadSanitizer's regression suite, from the same commit | as above | Apache-2.0 with LLVM Exceptions | **vendored** in `tests/tsan`, `tests/sanitizer_common`, `tests/compiler-rt-src` and the two `lit.common.*` files, 507 files, so the preservation suite runs without a compiler-rt checkout | none; our own tests are in `tests/ir` and are not third-party |
| memcached | 1.6.29 | BSD-3-Clause | fetched at build time, sha256 pinned in `third-party/SOURCES.md` | none |
| memtier_benchmark | 2.1.1 | GPL-2.0 | fetched and built by `scripts/40-perf.sh memcached` if absent | none |
| Redis | 7.0.15 | BSD-3-Clause | fetched at build time, sha256 pinned in `third-party/SOURCES.md` | build flags only, to inject the TSan compiler, applied by `harness/nosql/redis/Makefile.patch` |
| SQLite | 3.50.2 (`sqlite-src-3500200`) | Public domain | fetched from sqlite.org, sha256 pinned in `third-party/SOURCES.md` | `threadtest3.c` replaced by our copy, which adds the `--w1-threads` argument; our copy is `harness/sql/sqlite/threadtest3.c`, to be diffed against the file in the SQLite source tarball named above |
| MySQL | 8.0.39 | GPL-2.0 | fetched from GitHub, sha256 pinned in `third-party/SOURCES.md`; Boost 1.77 fetched by its build | none |
| FFmpeg | n4.3.9, built with `--enable-gpl` (libx264, libx265) | GPL-2.0 (with those options) | fetched at build time, sha256 pinned in `third-party/SOURCES.md` | none |
| FFmpeg input clip | Blender Foundation open movie cut, see `docs/ffmpeg-input.md` | CC-BY | not redistributed: the artifact ships the source URL and the exact ffmpeg command that produces the cut | derived cut, produced by the script |
| Chromium | revision `bdef6783a05f0b3f885591e7d2c7b2aec1a89dea` | BSD-3-Clause | not included (documented only, `docs/chromium.md`) | four Telemetry files with raised timeouts, and `harness/chromium/patches/tsan_extra_cflags.patch`; neither is exercised here, since Chromium is documented rather than run |

Paths beginning `harness/` are in the measurement harness, which `scripts/vendor-harness.sh` places
there; until that has been run they are absent, and the scripts that need them say so.

If a component's license in this table turns out to be wrong, that is our error; please tell us.
