#!/bin/bash
# This file is a part of Julia. License is MIT: https://julialang.org/license
#
# Usage:
#     contrib/ppc64le/build.sh [<make_targets>...]
#
# Build Julia for ppc64le inside the reference container. Runs Podman by
# default; set CONTAINER_RUNTIME=docker to use Docker instead.

set -ue

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JULIA_HOME="$(cd "$HERE/../.." && pwd)"

CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-podman}"
IMAGE="${IMAGE:-julia-ppc64le-build}"

if ! "$CONTAINER_RUNTIME" image exists "$IMAGE" 2>/dev/null; then
    "$CONTAINER_RUNTIME" build -t "$IMAGE" -f "$HERE/Containerfile" "$JULIA_HOME"
fi

exec "$CONTAINER_RUNTIME" run --rm \
    -v "$JULIA_HOME:/src:Z" \
    -w /src \
    "$IMAGE" \
    make -j"$(nproc)" "$@"
