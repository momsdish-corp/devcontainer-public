#!/usr/bin/env bash
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install base
source "${SCRIPT_DIR}/inc/post-start-base.sh"

#################
### Functions ###
#################

helper_routing_chrome() {
    echo "Allowing Claude to use Chrome on your host machine..."
    echo "====================================================="
    echo "To allow Claude to use a Chrome browser on your host machine, run:"
    echo "/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 --remote-debugging-address=0.0.0.0 --user-data-dir=/tmp/chrome-debug-profile"
    echo "Claude chrome-devtools MCP will be able to connect to the browser."
}

##############
### Script ###
##############

helper_routing_chrome
