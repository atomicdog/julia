#!/bin/bash
# This file is a part of Julia. License is MIT: https://julialang.org/license
#
# Start (or restart) a long-lived Julia ppc64le dev container.
#
# - The host home dir is bind-mounted at /workspace and HOME is set to it,
#   so `.julia/` (Pkg depot, project envs, REPL history) persists across
#   container lifecycle.
# - Pluto (1234), Jupyter (8888), and a generic IDE port (3000) are
#   exposed on 127.0.0.1 only; reach them from your laptop with an SSH
#   port forward (e.g. `ssh -L 1234:localhost:1234 core@<host>`).
#
# Usage:
#     contrib/ppc64le/dev/start.sh   # start (or no-op if running)
#     podman exec -it jdev bash      # shell in
#     podman stop jdev               # stop (preserves state)
#     podman rm jdev                 # destroy (workspace contents persist)

set -ue

CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-podman}"
IMAGE="${IMAGE:-julia-ppc64le-dev}"
NAME="${NAME:-jdev}"
HOSTHOME="${HOSTHOME:-$HOME}"

if "$CONTAINER_RUNTIME" container exists "$NAME" 2>/dev/null; then
    if [ "$("$CONTAINER_RUNTIME" inspect -f '{{.State.Running}}' "$NAME")" = "true" ]; then
        echo "$NAME is already running"
        exit 0
    fi
    echo "Starting existing $NAME"
    "$CONTAINER_RUNTIME" start "$NAME"
    exit 0
fi

echo "Creating $NAME from $IMAGE (workspace=$HOSTHOME)"
"$CONTAINER_RUNTIME" run -d \
    --name "$NAME" \
    --restart=unless-stopped \
    -v "$HOSTHOME":/workspace:Z \
    -e HOME=/workspace \
    --workdir=/workspace \
    -p 127.0.0.1:1234:1234 \
    -p 127.0.0.1:8888:8888 \
    -p 127.0.0.1:3000:3000 \
    "$IMAGE" \
    sleep infinity
