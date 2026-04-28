#!/bin/bash
# This file is a part of Julia. License is MIT: https://julialang.org/license
#
# Launch (or relaunch) Pluto inside the long-lived `jdev` dev container.
#
# - Starts the container if it is not running.
# - Kills any prior tmux session named `pluto` and starts a fresh one.
# - Waits for Pluto to bind its port, then prints the URL with secret.
# - Pluto runs detached in a tmux session inside the container, so it
#   survives the SSH session that started it. Attach with:
#       podman exec -it jdev tmux attach -t pluto
#   (Ctrl-b d to detach.)
#
# Usage:
#     contrib/ppc64le/dev/pluto.sh
#
# Then on your laptop:
#     ssh -L 1234:localhost:1234 core@<host>
#     # open the printed URL in a browser

set -ue

CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-podman}"
NAME="${NAME:-jdev}"
PLUTO_TIMEOUT="${PLUTO_TIMEOUT:-180}"

# Inside the container, the persistent Pkg depot is bind-mounted at
# /root/.julia, so the URL file lives there and survives container destroy.
URL_PATH_IN_CONTAINER=/root/.julia/.pluto-url

if ! "$CONTAINER_RUNTIME" container exists "$NAME" 2>/dev/null; then
    echo "error: $NAME container does not exist; run contrib/ppc64le/dev/start.sh first" >&2
    exit 1
fi

if [ "$("$CONTAINER_RUNTIME" inspect -f '{{.State.Running}}' "$NAME")" != "true" ]; then
    echo "starting $NAME"
    "$CONTAINER_RUNTIME" start "$NAME" >/dev/null
fi

"$CONTAINER_RUNTIME" exec "$NAME" tmux kill-session -t pluto 2>/dev/null || true
"$CONTAINER_RUNTIME" exec "$NAME" rm -f "$URL_PATH_IN_CONTAINER" 2>/dev/null || true

"$CONTAINER_RUNTIME" exec -d "$NAME" tmux new-session -d -s pluto \
    'julia --project=@v1.14 /root/pluto-launch.jl 2>&1 | tee /root/.julia/.pluto.log'

echo "waiting for Pluto to bind port (up to ${PLUTO_TIMEOUT}s)..."
deadline=$(( $(date +%s) + PLUTO_TIMEOUT ))
while [ "$(date +%s)" -lt "$deadline" ]; do
    if "$CONTAINER_RUNTIME" exec "$NAME" test -s "$URL_PATH_IN_CONTAINER" 2>/dev/null; then
        url=$("$CONTAINER_RUNTIME" exec "$NAME" cat "$URL_PATH_IN_CONTAINER")
        # Pluto only binds the socket after some compile work; gate on that
        # too so we don't print a URL that isn't ready yet.
        if "$CONTAINER_RUNTIME" exec "$NAME" sh -c "grep -q ':04D2' /proc/net/tcp" 2>/dev/null; then
            echo
            echo "Pluto is ready. URL:"
            echo "    $url"
            echo
            echo "From your laptop:"
            echo "    ssh -L 1234:localhost:1234 core@<host>"
            echo "    # then open the URL above in a browser"
            exit 0
        fi
    fi
    sleep 3
done

echo "error: Pluto did not start within ${PLUTO_TIMEOUT}s" >&2
echo "tail of log:" >&2
"$CONTAINER_RUNTIME" exec "$NAME" tail -20 /root/.julia/.pluto.log >&2 2>/dev/null || true
exit 1
