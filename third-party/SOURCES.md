# Application sources: what is fetched, from where, and what it must hash to

The application archives ship in this repository, under `third-party/sources/` (every one below but
MySQL's, 31 MB together), and the harness uses the shipped copy; it fetches from the origin URL only when
the shipped file is absent (MySQL, 421 MB, is fetched), and in either case it verifies the archive against
the sha256 below before unpacking it. Until 20 Sep 2026 every archive was fetched at build time, and an
evaluator whose machine could not reach download.redis.io lost the performance tier at its first
application. A hash mismatch is a stop, not a warning.

| Component | Archive | Origin | Size | sha256 |
|---|---|---|---|---|
| memcached 1.6.29 | `memcached-1.6.29.tar.gz` | https://memcached.org/files/memcached-1.6.29.tar.gz | 1.2 MB | `269643d518b7ba2033c7a1f66fdfc560d72725a2822194d90c8235408c443a49` |
| Redis 7.0.15 | `redis-7.0.15.tar.gz` | https://download.redis.io/releases/redis-7.0.15.tar.gz | 2.9 MB | `98066f5363504b26c34dd20fbcc3c957990d764cdf42576c836fc021073f4341` |
| SQLite 3.50.2 | `sqlite-src-3500200.zip` | https://sqlite.org/2025/sqlite-src-3500200.zip | 14 MB | `091eeec3ae2ccb91aac21d0e9a4a58944fb2cb112fa67bffc3e08c2eca2d85c8` |
| FFmpeg 4.3.9 | `FFmpeg-n4.3.9.tar.gz` | https://github.com/FFmpeg/FFmpeg/archive/refs/tags/n4.3.9.tar.gz | 13 MB | `43e77716cc5acd71775c92751859fb744332d152eb45f1db49be1b50533542a9` |
| MySQL 8.0.39 | `mysql-8.0.39.tar.gz` | https://github.com/mysql/mysql-server/archive/refs/tags/mysql-8.0.39.tar.gz (Boost 1.77 is fetched by its build) | 421 MB | `3a72e6af758236374764b7a1d682f7ab94c70ed0d00bf0cb0f7dd728352b6d96` |
| memtier_benchmark 2.1.1 | `memtier_benchmark-2.1.1.tar.gz` | https://github.com/RedisLabs/memtier_benchmark/archive/refs/tags/2.1.1.tar.gz | 0.3 MB | `6e52a4049ecf98928941661ccf98e01d1c97d161447ff5071c512a5afe32970e` |
| LLVM, clang and compiler-rt (the base of the shipped compiler) | a shallow clone of commit `c609043dd00955bf177ff57b0bad2a87c1e61a36`, made by the container build | https://github.com/llvm/llvm-project | about 1 GB | no archive hash: the build applies the 29 patches and asserts that the reconstructed source tree hashes to `83c8a2a16db10bd5f826a76f84911ae171d05d3f` (`git write-tree`), which the image records in its stamp and `scripts/13-verify-image.sh` checks from any checkout |
| Boost 1.77 (MySQL's build dependency) | `boost_1_77_0.tar.bz2`, fetched by MySQL's own CMake (`-DDOWNLOAD_BOOST=1`) during the `everything` tier only | the URL in MySQL 8.0.39's `cmake/boost.cmake` | 108 MB | verified by that file's own MD5 check, not by this list |
| FFmpeg input clip | `TearsOfSteel-1366x768-100s.mkv` | https://github.com/apaznikov/tsan-atc26-artifact/releases/download/inputs-v1/TearsOfSteel-1366x768-100s.mkv (an asset of this repository's release `inputs-v1`, CC BY 3.0, Blender Foundation; the Zenodo record carries the same file); derivable from the Blender source by the command in `docs/ffmpeg-input.md` | 78 MB | `43b0fba97eb05a0e44d7518fe9d6993c140680531a17a240ea6d53582fbe9985` |

The container's base image is `ubuntu:24.04` by tag, not by digest: the compiler's identity is asserted by the
tree hash and the stamp above, and the correctness set depends on the base only for the packages
`docker/Dockerfile` installs, whose presence the image verification checks.

Four of the five hashes were taken from the archives the campaign of 15-17 September 2026 was built
from, on the machine that built it, and verified against them afterwards. The SQLite value is the
exception and is stated as such: the build script deleted the zip after unpacking, so only the unpacked
tree survives from the campaign, and `091eeec3…` is the hash of a fresh download of the same versioned
URL. It is almost certainly the same file, and we cannot demonstrate that the campaign compiled that
archive, only that the tree it left behind is `sqlite-src-3500200`. The harness verifies every archive
against this list before unpacking (`harness/tools/verify_archive.sh`, pinned values in
`harness/tools/source_archives.sha256`) and refuses a missing, unpinned or mismatching one.

One further SQLite provenance note, found by rebuilding in a container without the lab's system packages
(17 Sep 2026). The campaign's SQLite test binaries were compiled against `/usr/include/sqlite3.h` from the
host's `libsqlite3-dev`, which declares SQLite 3.45.1, while linking the amalgamation the pinned 3.50.2
archive produces: the build script's include path did not carry the amalgamation's own header, so a system
header was used when one was installed. We checked the two structures the SQLite test shim depends on,
`sqlite3_vfs` and `sqlite3_io_methods`, and they are byte-for-byte identical between 3.45.1 and 3.50.2, so
this is a provenance discrepancy and not a correctness one. The build script now puts the amalgamation's
own header first (`-I build/`), so the container and the lab both compile against the version the archive
pins, and a host with no `libsqlite3-dev` builds correctly. The measurement harness (`harness/`, 123 files plus their sha256 manifest)
contains no third-party source; it is scripts and documentation of ours. Its vendoring script refuses
any shipped file that carries a bare lab path outside an overridable default, and excludes by name
the lab-only drivers that check found, among them one that deleted a lab directory.
