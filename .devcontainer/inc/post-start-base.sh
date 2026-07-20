#!/usr/bin/env bash
set -Eeo pipefail

#################
### Functions ###
#################

start_dolt_server() {
    echo "Starting beads Dolt server..."
    # bd is baked into the prebuilt image at /usr/local/bin
    if command -v bd &> /dev/null; then
        # bd auto-starts its managed dolt sql-server on demand; this just warms it up
        (cd /workspace && bd dolt start) || true
    else
        echo "bd not installed yet (post-create pending?) — skipping"
    fi
}

##############
### Script ###
##############

start_dolt_server