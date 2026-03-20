#!/usr/bin/env bash
# SDKMAN installation and package bootstrap.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../utils/utils.sh"

trap 'handle_error $? $LINENO' ERR

SDKMAN_INIT="$HOME/.sdkman/bin/sdkman-init.sh"
PACKAGES_FILE="$SCRIPT_DIR/packages.txt"

load_sdkman() {
    if [[ -s "$SDKMAN_INIT" ]]; then
        # shellcheck source=/dev/null
        source "$SDKMAN_INIT"
        return 0
    fi

    log_info "Installing SDKMAN."
    curl -s "https://get.sdkman.io" | bash
    # shellcheck source=/dev/null
    source "$SDKMAN_INIT"
}

install_sdk_packages() {
    echo_header "SDKMAN packages"

    if [[ ! -f "$PACKAGES_FILE" ]]; then
        log_warn "Missing ${PACKAGES_FILE}; skipping SDKMAN packages."
        return 0
    fi

    local candidate
    while IFS= read -r candidate || [[ -n "$candidate" ]]; do
        candidate="${candidate%%#*}"
        candidate="$(trim "$candidate")"
        [[ -z "$candidate" ]] && continue

        log_info "Installing SDKMAN candidate: $candidate"
        sdk install "$candidate" || log_warn "Unable to install ${candidate}. Review available versions with 'sdk list ${candidate}'."
    done < "$PACKAGES_FILE"
}

main() {
    load_sdkman
    sdk selfupdate || true
    sdk update || true
    install_sdk_packages

    echo_header "SDKMAN setup complete"
    log_success "SDKMAN is initialized for future shells via ~/.sdkman/bin/sdkman-init.sh."
}

main
