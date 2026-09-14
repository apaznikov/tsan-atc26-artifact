# Builds the TSan-enabled compiler from a pinned upstream LLVM commit plus this artifact's
# patch series, installs it to /opt/tsan-llvm, and checks that the install is self-contained.
#
# Build:  docker build --build-arg JOBS=$(nproc) -t tsan-atc26 -f docker/Dockerfile .
# The image is also published prebuilt; see README.md. This file is the recipe either way.

FROM ubuntu:24.04 AS build
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      git ca-certificates cmake ninja-build python3 g++ gcc libstdc++-13-dev \
      zlib1g-dev libzstd-dev libxml2-dev binutils file \
    && rm -rf /var/lib/apt/lists/*

# Upstream base commit and the patch series that turns it into the paper's compiler.
ARG LLVM_BASE=c609043dd00955bf177ff57b0bad2a87c1e61a36
ARG JOBS=8
WORKDIR /src
RUN git init llvm-project && cd llvm-project \
    && git remote add origin https://github.com/llvm/llvm-project.git \
    && git fetch --depth 1 origin ${LLVM_BASE} && git checkout FETCH_HEAD
COPY compiler/patches/ /src/patches/
RUN cd llvm-project && for p in $(ls /src/patches/*.patch | sort); do \
      echo "applying $p"; git apply --index "$p" || exit 1; done

# Configure and build INSIDE the container at the final path, with a relocatable install:
# LLVM_LINK_LLVM_DYLIB puts the LLVM libraries in one shared object under the prefix, and
# cmake --install writes lit configuration files with the prefix's own paths.
RUN cmake -G Ninja -S llvm-project/llvm -B build \
      -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=ON \
      -DLLVM_ENABLE_PROJECTS="clang;lld;compiler-rt" \
      -DLLVM_TARGETS_TO_BUILD=X86 \
      -DLLVM_BUILD_LLVM_DYLIB=ON -DLLVM_LINK_LLVM_DYLIB=ON -DBUILD_SHARED_LIBS=OFF \
      -DCMAKE_INSTALL_PREFIX=/opt/tsan-llvm \
    && ninja -C build -j ${JOBS} clang lld compiler-rt llvm-lit FileCheck not count opt llvm-objdump \
    && ninja -C build install

# The RUNPATH check: every LLVM library the installed clang loads must live under the prefix.
RUN ldd /opt/tsan-llvm/bin/clang | grep -i llvm | grep -qv /opt/tsan-llvm && { echo "clang resolves an LLVM library outside the prefix"; exit 1; } || true \
    && /opt/tsan-llvm/bin/clang --version

FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-numpy git make cmake ninja-build binutils file util-linux \
      libstdc++-13-dev gcc g++ pkg-config ca-certificates wget unzip \
      libevent-dev libssl-dev libx264-dev libx265-dev libgnutls28-dev nasm yasm \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /opt/tsan-llvm /opt/tsan-llvm
ENV TSAN_LLVM_ROOT=/opt/tsan-llvm PATH=/opt/tsan-llvm/bin:$PATH
WORKDIR /artifact
COPY . /artifact
RUN chmod +x /artifact/scripts/*.sh /artifact/docker/*.sh
CMD ["/bin/bash"]
