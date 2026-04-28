#!/bin/bash
# This file is a part of Julia. License is MIT: https://julialang.org/license
#
# Start (or restart) a long-lived Julia ppc64le dev container.
#
# - WORKSPACE (default $HOME/repo) is bind-mounted into the container at
#   /workspace. Using a regular subdir avoids SELinux relabeling problems
#   that occur when bind-mounting the system home directory directly.
# - JULIA_DEPOT (default $HOME/.julia-jdev) is bind-mounted at /root/.julia
#   so Pkg state, precompile caches, and REPL history persist across
#   container lifecycle.
# - Pluto (1234), Jupyter (8888), and a generic IDE port (3000) are
#   exposed on 127.0.0.1 only; reach them from your laptop with an SSH
#   port forward (e.g. `ssh -L 1234:localhost:1234 core@<host>`).
#
# Usage:
#     contrib/ppc64le/dev/start.sh   # start (or no-op if running)
#     podman exec -it jdev bash      # shell in
#     podman stop jdev               # stop (preserves state)
#     podman rm jdev                 # destroy (workspace+depot persist)

set -ue

CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-podman}"
IMAGE="${IMAGE:-julia-ppc64le-dev}"
NAME="${NAME:-jdev}"
WORKSPACE="${WORKSPACE:-$HOME/repo}"
JULIA_DEPOT="${JULIA_DEPOT:-$HOME/.julia-jdev}"

mkdir -p "$WORKSPACE" "$JULIA_DEPOT"

if "$CONTAINER_RUNTIME" container exists "$NAME" 2>/dev/null; then
    if [ "$("$CONTAINER_RUNTIME" inspect -f '{{.State.Running}}' "$NAME")" = "true" ]; then
        echo "$NAME is already running"
        exit 0
    fi
    echo "Starting existing $NAME"
    "$CONTAINER_RUNTIME" start "$NAME"
    exit 0
fi

echo "Creating $NAME from $IMAGE"
echo "  workspace: $WORKSPACE -> /workspace"
echo "  depot:     $JULIA_DEPOT -> /root/.julia"
"$CONTAINER_RUNTIME" run -d \
    --name "$NAME" \
    --restart=unless-stopped \
    -v "$WORKSPACE":/workspace:Z \
    -v "$JULIA_DEPOT":/root/.julia:Z \
    --workdir=/workspace \
    -p 127.0.0.1:1234:1234 \
    -p 127.0.0.1:8888:8888 \
    -p 127.0.0.1:3000:3000 \
    "$IMAGE" \
    sleep infinity
