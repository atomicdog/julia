#!/bin/bash
# This file is a part of Julia. License is MIT: https://julialang.org/license
#
# Build the Julia ppc64le dev container image. Bakes in a binary-dist
# tarball produced by `make install` so the resulting image is
# self-contained.
#
# Usage:
#     contrib/ppc64le/dev/build.sh
#
# Picks up the most recent julia-*-linuxppc64le.tar.gz from the repo root
# unless JULIA_TARBALL is set in the environment. CONTAINER_RUNTIME
# defaults to podman; set IMAGE to override the tag.

set -ue

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JULIA_HOME="$(cd "$HERE/../../.." && pwd)"
CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-podman}"
IMAGE="${IMAGE:-julia-ppc64le-dev}"

JULIA_TARBALL="${JULIA_TARBALL:-$(find "$JULIA_HOME" -maxdepth 1 -name 'julia-*-linuxppc64le.tar.gz' -print -quit)}"
if [ -z "${JULIA_TARBALL:-}" ] || [ ! -f "$JULIA_TARBALL" ]; then
    cat >&2 <<EOF
error: no julia-*-linuxppc64le.tar.gz found in $JULIA_HOME

Build one first. The simplest path that reuses the existing release
build (no distclean rebuild):

    podman run --rm -v "\$PWD":/src:Z -w /src localhost/julia-ppc64le-build \\
        sh -c 'make -j32 install \\
            && tar -zcf julia-\$(git rev-parse --short=10 HEAD)-linuxppc64le.tar.gz \\
                       julia-\$(git rev-parse --short=10 HEAD)'

Or set JULIA_TARBALL=/path/to/julia-*.tar.gz to point at an existing one.
EOF
    exit 1
fi

CTX="$(mktemp -d)"
trap 'rm -rf "$CTX"' EXIT

cp "$JULIA_TARBALL" "$CTX/julia.tar.gz"
cp "$HERE/Containerfile" "$CTX/"

echo "Building $IMAGE from $JULIA_TARBALL"
"$CONTAINER_RUNTIME" build -t "$IMAGE" "$CTX"
