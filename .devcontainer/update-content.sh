#!/usr/bin/env bash
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install base
source "${SCRIPT_DIR}/inc/update-content-base.sh"

#################
### Functions ###
#################

install_example() {
    # Repo-specific runtime provisioning goes here; bake new tools into
    # .devcontainer/base-image/Dockerfile instead of installing them at runtime
    echo "Add repo-specific runtime provisioning via .devcontainer/update-content.sh"
}

##############
### Script ###
##############

install_example