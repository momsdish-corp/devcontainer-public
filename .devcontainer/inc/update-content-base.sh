# Widely used env variable to disable data collection
export DISABLE_TELEMETRY=1 DO_NOT_TRACK=1
echo "DISABLE_TELEMETRY=1" | tee -a /etc/environment
echo "DO_NOT_TRACK=1" | sudo tee -a /etc/environment

# Set Non Interactive Installation on entire script
export NONINTERACTIVE=1 HOMEBREW_NO_ASK=1

#################
### Functions ###
#################

provision_git() {
  # Add the directory as safe
  echo 'Adding the directory as safe...'
  git config --global --add safe.directory "$PWD"

  # When DevPod is created over SSH, it sets this workspace's remote to SSH,
  # so we have to change it: rewrite GitHub SSH->HTTPS (broker is HTTPS-only).
  echo 'Forcing GitHub remotes to use HTTPS...'
  git config --global url."https://github.com/".insteadOf "git@github.com:"
}

install_brew() {
    # Homebrew Settings
    export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1
    echo "HOMEBREW_NO_AUTO_UPDATE=1" | tee -a /etc/environment
    echo "HOMEBREW_NO_ANALYTICS=1" | tee -a /etc/environment
    # Install Homebrew if not already installed
    if ! command -v brew &> /dev/null; then
        echo 'Installing Homebrew...'
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add Homebrew to PATH
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' | tee -a ~/.profile
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    else
        echo 'Homebrew is already installed.'
    fi
}

install_claude() {
    # Install Claude CLI
    echo 'Installing Claude CLI...'
    # Append @latest, as brew cask doesn't install the latest version
    brew install --cask claude-code@latest

    # Disable Claude tracking
    echo "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1" | tee -a /etc/environment
    echo "CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1" | tee -a /etc/environment
    echo "CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL=1" | tee -a /etc/environment
}

install_codex() {
    # Install OpenAI Codex CLI
    echo 'Installing Codex CLI...'
    brew install --cask codex
}

install_htmlq() {
    # Install htmlq for HTML parsing
    echo 'Installing htmlq...'
    brew install htmlq
}

# For converting html to markdown
install_pandoc() {
    # Install Pandoc for document conversion
    echo 'Installing Pandoc...'
    brew install pandoc
}

# Install tmux for terminal multiplexing
install_tmux() {
    # Install Tmux
    echo 'Installing Tmux...'
    brew install tmux

    # Allow mouse scrolling
    echo 'Configuring Tmux for mouse scrolling...'
    echo 'set -g mouse on' | tee -a ~/.tmux.conf

    # Instructions
    echo "Example usage: tmux new -As claude1"
}

add_playwright_mcp() {
    # Add MCP Client configuration
    echo 'Configuring Playwright MCP...'
    claude mcp add playwright --scope user -- npx -y @playwright/mcp@latest --browser chromium --ignore-https-errors --no-sandbox --output-dir=/workspace/tmp/mcp-playwright --caps=install,tabs,pdf
    codex mcp add playwright -- npx -y @playwright/mcp@latest --browser chromium --ignore-https-errors --no-sandbox --output-dir=/workspace/tmp/mcp-playwright --caps=install,tabs,pdf
    
}

# Install Dolt — the versioned SQL database engine behind beads
install_dolt() {
    echo 'Installing Dolt...'
    brew install dolt
}

# Install beads (bd) — dependency-aware issue tracker for AI agents
# https://github.com/gastownhall/beads
install_beads() {
    echo 'Installing beads...'
    brew install beads

    # Set up the beads issue tracker (Dolt server mode).
    # Issue data lives in /workspace/.beads/dolt — inside the workspace bind
    # mount — so issues survive container rebuilds. Only the binaries and the
    # server process need re-setup, which is what this function handles.
    echo 'Setting up beads...'

    # Dolt requires a committer identity for its internal data commits
    if ! dolt config --global --get user.name &> /dev/null; then
        dolt config --global --add user.name "$(git -C /workspace config user.name || echo 'Momsdish Dev')"
        dolt config --global --add user.email "$(git -C /workspace config user.email || echo 'dev@momsdish.com')"
    fi

    # Don't share anonymous bd usage metrics
    bd metrics off > /dev/null 2>&1 || true

    # Idempotent: on a fresh clone this creates the Dolt database at
    # .beads/doltpost-create; once initialized it skips with exit 0.
    mkdir -p /workspace/.beads && chmod 700 /workspace/.beads
    (cd /workspace && bd init --server --non-interactive --init-if-missing)

    # Setup rich instructions
    bd setup claude
    bd setup codex
}

##############
### Script ###
##############

# Provision
provision_git

# Install prerequisites
install_brew
install_htmlq
install_pandoc
install_tmux
install_dolt
install_beads

# Install AI CLIs
install_claude
install_codex

# Configure MCP Clients
add_playwright_mcp