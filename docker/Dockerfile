# Builds the TSan-enabled compiler from a pinned upstream LLVM commit plus this artifact's
# patch series, installs it to /opt/tsan-llvm, and checks that the install is self-contained.
#
# Build:  ./docker/build.sh   (derives JOBS from the daemon's memory; one job per processor thrashes
#         under a memory cap, docker/build.sh says why). This file is the recipe.

# The base is pinned by DIGEST, not by the tag: `ubuntu:24.04` moves, and two builds a month apart would then
# start from different images (one evaluator's build on 21 Sep 2026 started from 008173c2..., this host's from
# the digest below). The compiler's own identity is asserted by the reconstructed source tree hash further
# down, so the base only supplies the toolchain and the runtime libraries; pinning it removes one way for two
# builds of this artifact to differ. Package versions inside the image can still move (docs/troubleshooting.md).
FROM ubuntu@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54 AS build
ARG DEBIAN_FRONTEND=noninteractive
# Acquire::Retries: a package fetch that drops mid-way (a student's build on 21 Sep 2026 died in this layer with
# apt exit code 100 when the network blinked) is retried by apt itself instead of failing the whole build.
RUN apt-get -o Acquire::Retries=5 update && apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
      git ca-certificates cmake ninja-build python3 g++ gcc libstdc++-13-dev \
      zlib1g-dev libzstd-dev libxml2-dev binutils file \
    && rm -rf /var/lib/apt/lists/*

# Runtime-stage packages, measured rather than assumed: the applications' linkage and build steps, and every
# external program the shipped scripts invoke (/usr/bin/time, sysbench, jq, bc, killall) checked against the image:
# memcached libevent; memtier libevent, pcre, ssl, zlib and the autotools (its make.sh runs autoreconf);
# FFmpeg libx264, libx265, nasm; SQLite's threadtest3 nothing beyond libc (no tcl);
# MySQL bison, ssl, aio, numa, protobuf and its compiler, ncurses, tirpc and rpcgen.
# Upstream base commit and the patch series that turns it into the paper's compiler.
ARG LLVM_BASE=c609043dd00955bf177ff57b0bad2a87c1e61a36
ARG JOBS=8
WORKDIR /src
RUN git init llvm-project && cd llvm-project \
    && git remote add origin https://github.com/llvm/llvm-project.git \
    && git fetch --depth 1 origin ${LLVM_BASE} && git checkout FETCH_HEAD
COPY compiler/patches/ /src/patches/
# `git apply --index` fails in this image with "does not match index" on 24 files even
# though every preimage blob matches the index and is present in the object store; plain
# `git apply` applies the identical patches cleanly. The index is not used by the build, so
# apply to the working tree and verify the RESULT instead of trusting the mechanism: the
# reconstructed tree must hash to the branch's tree, which is the reproducibility claim a
# reviewer can check without building anything.
ARG EXPECTED_TREE=83c8a2a16db10bd5f826a76f84911ae171d05d3f
RUN cd llvm-project && for p in $(ls /src/patches/*.patch | sort); do \
      echo "applying $p"; git apply "$p" || exit 1; done \
    && git add -A \
    && t=$(git write-tree) \
    && echo "reconstructed tree $t (expected ${EXPECTED_TREE})" \
    && echo "$t" > /reconstructed-tree \
    && [ "$t" = "${EXPECTED_TREE}" ] || { echo "TREE MISMATCH: the patch series did not reproduce the branch"; exit 1; }

# llvm-lit is NOT a ninja target: cmake generates bin/llvm-lit at configure time and there is
# no install rule for it, so it is installed explicitly below. Do not re-add it to the ninja
# target list. LLVM_INSTALL_UTILS=ON is what installs FileCheck, not and count.
# Configure and build INSIDE the container at the final path, with a relocatable install:
# LLVM_LINK_LLVM_DYLIB puts the LLVM libraries in one shared object under the prefix, and
# cmake --install writes lit configuration files with the prefix's own paths.
# The branch commit this image reconstructs. It is NOT the upstream base (LLVM_BASE): the
# harness derives a build stamp from the first 40-hex string in `clang --version`, so a
# version line naming only the base would hand every downstream build a wrong-but-well-formed
# stamp. Both the version string and the TSAN_AUDIT_HASH file below carry the branch commit; the file's
# second line carries the tree hash the patch step MEASURED (not the expected constant), so that
# scripts/13-verify-image.sh can check the reconstruction from the image itself, from any checkout,
# without the build log (until 20 Sep 2026 the log was the only record, and a second checkout of the
# repository reported the check as not made).
ARG AUDIT_HASH=f3deebfbab602f4e05289e0acbde0efd06b8058c
RUN cmake -G Ninja -S llvm-project/llvm -B build \
      -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=ON \
      -DLLVM_ENABLE_PROJECTS="clang;lld;compiler-rt" \
      -DLLVM_TARGETS_TO_BUILD=X86 \
      -DLLVM_BUILD_LLVM_DYLIB=ON -DLLVM_LINK_LLVM_DYLIB=ON -DBUILD_SHARED_LIBS=OFF \
      -DCMAKE_INSTALL_PREFIX=/opt/tsan-llvm \
      -DLLVM_INSTALL_UTILS=ON \
      -DLLVM_APPEND_VC_REV=ON \
      -DLLVM_FORCE_VC_REPOSITORY=https://github.com/focs-lab/llvm-project \
      -DLLVM_FORCE_VC_REVISION=${AUDIT_HASH} \
    && ninja -C build -j ${JOBS} clang lld compiler-rt FileCheck not count opt llvm-objdump \
    && ninja -C build -j ${JOBS} install \
    && install -m755 build/bin/llvm-lit /opt/tsan-llvm/bin/llvm-lit \
    && printf '%s\nreconstructed-tree %s\n' "${AUDIT_HASH}" "$(cat /reconstructed-tree)" > /opt/tsan-llvm/TSAN_AUDIT_HASH \
    && mkdir -p /opt/tsan-llvm/lib/python-lit \
    && cp -r llvm-project/llvm/utils/lit/lit /opt/tsan-llvm/lib/python-lit/lit

# The RUNPATH check: every LLVM library the installed clang loads must live under the prefix.
RUN ldd /opt/tsan-llvm/bin/clang | grep -i llvm | grep -qv /opt/tsan-llvm && { echo "clang resolves an LLVM library outside the prefix"; exit 1; } || true \
    && /opt/tsan-llvm/bin/clang --version
RUN v=$(/opt/tsan-llvm/bin/clang --version | head -1) \
    && echo "version line: $v" \
    && case "$v" in *"${AUDIT_HASH}"*) : ;; \
         *) echo "version string does not name the branch commit ${AUDIT_HASH}"; exit 1 ;; esac \
    && case "$v" in *"${LLVM_BASE}"*) echo "version string still names the upstream base ${LLVM_BASE}; the stamp would be wrong"; exit 1 ;; \
         *) : ;; esac \
    && grep -q "${AUDIT_HASH}" /opt/tsan-llvm/TSAN_AUDIT_HASH \
    && echo "stamp ok: $(head -1 /opt/tsan-llvm/TSAN_AUDIT_HASH)"
ENV PYTHONPATH=/opt/tsan-llvm/lib/python-lit
RUN /opt/tsan-llvm/bin/llvm-lit --version

FROM ubuntu@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -o Acquire::Retries=5 update && apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
      python3 python3-numpy python3-psutil git make cmake ninja-build binutils file util-linux \
      libstdc++-13-dev gcc g++ pkg-config ca-certificates wget unzip ffmpeg \
      libevent-dev libssl-dev libx264-dev libx265-dev libgnutls28-dev nasm yasm \
      libpcre3-dev zlib1g-dev autoconf automake libtool \
      bison libaio-dev libnuma-dev libprotobuf-dev protobuf-compiler libncurses-dev libtirpc-dev rpcsvc-proto \
      time sysbench jq bc psmisc \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /opt/tsan-llvm /opt/tsan-llvm
ENV TSAN_LLVM_ROOT=/opt/tsan-llvm PATH=/opt/tsan-llvm/bin:$PATH \
    PYTHONPATH=/opt/tsan-llvm/lib/python-lit
WORKDIR /artifact
COPY . /artifact
RUN chmod +x /artifact/scripts/*.sh /artifact/docker/*.sh
CMD ["/bin/bash"]
