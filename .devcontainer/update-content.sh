#!/usr/bin/env bash
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install base
source "${SCRIPT_DIR}/inc/update-content-base.sh"

#################
### Functions ###
#################

install_example() {
    # Install Homebrew if not already installed
    echo "Install additional tools via .devcontainer/post-create.sh"
}

##############
### Script ###
##############

install_example