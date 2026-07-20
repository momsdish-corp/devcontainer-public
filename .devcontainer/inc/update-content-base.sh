# Runtime provisioning for the prebuilt devcontainer image
# (ghcr.io/momsdish-corp/devcontainer-public — see ../base-image/).
#
# Tools (htmlq, pandoc, tmux, dolt, beads, Claude Code, Codex, node) and
# telemetry opt-outs are baked into the image, on the standard PATH under
# /usr/local/bin. This script only does the setup that depends on the
# workspace or the container user's home directory, so it must stay fast and
# idempotent — no package installs here.

#################
### Functions ###
#################

require_baked_tools() {
    # Guard: everything below expects the prebuilt image
    local tool
    for tool in bd dolt claude codex; do
        if ! command -v "$tool" &> /dev/null; then
            echo "ERROR: '$tool' not found. This devcontainer expects the prebuilt image" >&2
            echo "ghcr.io/momsdish-corp/devcontainer-public (built from .devcontainer/base-image/)." >&2
            exit 1
        fi
    done
}

provision_git() {
  # Add the directory as safe
  echo 'Adding the directory as safe...'
  git config --global --add safe.directory "$PWD"

  # When DevPod is created over SSH, it sets this workspace's remote to SSH,
  # so we have to change it: rewrite GitHub SSH->HTTPS (broker is HTTPS-only).
  echo 'Forcing GitHub remotes to use HTTPS...'
  git config --global url."https://github.com/".insteadOf "git@github.com:"
}

# Set up the beads issue tracker (Dolt server mode).
# Issue data lives in /workspace/.beads/dolt — inside the workspace bind
# mount — so issues survive container rebuilds. The binaries are baked into
# the image; this re-runs the per-workspace/per-user setup.
setup_beads() {
    echo 'Setting up beads...'

    # Dolt requires a committer identity for its internal data commits
    if ! dolt config --global --get user.name &> /dev/null; then
        dolt config --global --add user.name "$(git -C /workspace config user.name || echo 'Momsdish Dev')"
        dolt config --global --add user.email "$(git -C /workspace config user.email || echo 'dev@momsdish.com')"
    fi

    # Don't share anonymous bd usage metrics
    bd metrics off > /dev/null 2>&1 || true

    # Idempotent: on a fresh clone this creates the Dolt database at
    # /workspace/.beads/dolt; once initialized it skips with exit 0.
    mkdir -p /workspace/.beads && chmod 700 /workspace/.beads
    (cd /workspace && bd init --server --non-interactive --init-if-missing)

    # Setup rich instructions
    bd setup claude
    bd setup codex
}

add_playwright_mcp() {
    # MCP client config lives in the user's home, which does not survive
    # container rebuilds — so (re-)register it here.
    echo 'Configuring Playwright MCP...'
    claude mcp add playwright --scope user -- npx -y @playwright/mcp@latest --browser chromium --ignore-https-errors --no-sandbox --output-dir=/workspace/tmp/mcp-playwright --caps=install,tabs,pdf
    codex mcp add playwright -- npx -y @playwright/mcp@latest --browser chromium --ignore-https-errors --no-sandbox --output-dir=/workspace/tmp/mcp-playwright --caps=install,tabs,pdf
}

##############
### Script ###
##############

require_baked_tools

# Provision
provision_git
setup_beads

# Configure MCP Clients
add_playwright_mcp
