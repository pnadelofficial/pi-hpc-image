#!/usr/bin/env bash
# Seeds a writable Pi agent directory from the image on first run.
# Override the location with PI_AGENT_DIR (e.g. a scratch or project dir
# if your home quota is tight).
set -euo pipefail

export PI_CODING_AGENT_DIR="${PI_AGENT_DIR:-$HOME/.pi/agent}"
SKEL=/opt/pi-skel/agent
STAMP="$PI_CODING_AGENT_DIR/.seeded-from-image"

if [ ! -f "$STAMP" ]; then
    echo "[pi-entrypoint] Seeding $PI_CODING_AGENT_DIR from image..." >&2
    mkdir -p "$PI_CODING_AGENT_DIR"
    # -n: never overwrite files you already have (settings, auth, sessions)
    cp -rn "$SKEL/." "$PI_CODING_AGENT_DIR/"
    touch "$STAMP"
fi

exec "$@"