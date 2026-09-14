# Third-party components

Nothing here is modified except where a "Modification" line says so. Modified files are kept apart
from the originals so the difference is visible.

| Component | Version | License | How it enters the artifact | Modification |
|---|---|---|---|---|
| LLVM / clang / compiler-rt | trunk commit `c609043dd009` (19.0.0git, 6 May 2024) | Apache-2.0 with LLVM Exceptions | fetched by the container build; our changes are the patch series in `compiler/patches/` | our patches only |
| memcached | 1.6.29 | BSD-3-Clause | source tarball, fetched or vendored | none |
| memtier_benchmark | 2.1.1 | GPL-2.0 | source tarball | none |
| Redis | 7.0.15 | BSD-3-Clause | source tarball | `Makefile.patch`: build flags only, to inject the TSan compiler; kept as a separate patch file |
| SQLite | 3.50.0 (`sqlite-src-3500200`) | Public domain | fetched from sqlite.org | `threadtest3.c` replaced by our copy, which adds the `--w1-threads` argument; the diff against SQLite's file is in `compiler/../third-party/sqlite-threadtest3.diff` |
| MySQL | 8.0.39 | GPL-2.0 | fetched from GitHub; Boost 1.77 fetched by its build | none |
| FFmpeg | n4.3.9, built with `--enable-gpl` (libx264, libx265) | GPL-2.0 (with those options) | source tarball | none |
| FFmpeg input clip | Blender Foundation open movie cut, see `docs/ffmpeg-input.md` | CC-BY | not redistributed: the artifact ships the source URL and the exact ffmpeg command that produces the cut | derived cut, produced by the script |
| Chromium | revision `bdef6783a05f0b3f885591e7d2c7b2aec1a89dea` | BSD-3-Clause | not included (documented only, `docs/chromium.md`) | four Telemetry files with raised timeouts, shipped as a diff |

If a component's license in this table turns out to be wrong, that is our error; please tell us.
