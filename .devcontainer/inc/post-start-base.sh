#!/usr/bin/env bash
set -Eeo pipefail

#################
### Functions ###
#################

start_dolt_server() {
    echo "Starting beads Dolt server..."
    # bd is baked into the prebuilt image at /usr/local/bin
    if ! command -v bd &> /dev/null; then
        echo "bd not installed yet (post-create pending?) — skipping"
        return
    fi

    # Self-heal: .beads/metadata.json records server mode and the database
    # name. Without it bd silently falls back to a fresh empty embedded DB,
    # so regenerate it (init reconnects to the existing .beads/dolt data).
    if [ ! -f /workspace/.beads/metadata.json ]; then
        echo 'beads metadata.json missing — re-provisioning...' >&2
        (cd /workspace && bd init --server --non-interactive --init-if-missing)
    fi

    # bd auto-starts its managed dolt sql-server on demand; this just warms it up
    (cd /workspace && bd dolt start) || echo "warning: 'bd dolt start' failed" >&2

    # Hard requirement: in embedded fallback bd shows an empty tracker
    # instead of the real issue database, so fail the start loudly.
    if ! (cd /workspace && bd dolt status 2>/dev/null) | grep -q 'Dolt server'; then
        echo 'ERROR: beads is not in server mode — bd would show an empty issue tracker.' >&2
        echo 'Fix: cd /workspace && bd init --server --non-interactive --init-if-missing' >&2
        exit 1
    fi
}

##############
### Script ###
##############

start_dolt_server
