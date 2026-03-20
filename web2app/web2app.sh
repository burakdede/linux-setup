#!/usr/bin/env bash
# Install desktop launchers for selected web apps.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../utils/utils.sh"

trap 'handle_error $? $LINENO' ERR

# shellcheck source=/dev/null
source "$SCRIPT_DIR/config.sh"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/../dotfiles/.bash_aliases"

echo_header "Installing Web Applications"

ICON_DIR="$HOME/.local/share/applications/icons"
mkdir -p "$ICON_DIR"

if ! command_exists google-chrome && ! command_exists chromium && ! command_exists microsoft-edge; then
    log_warn "Skipping web apps because no supported browser command is installed."
    exit 0
fi

export PATH="$HOME/.local/bin:$PATH"

for app in "${!WEB_APPS[@]}"; do
    IFS=' ' read -r url icon_url <<< "${WEB_APPS[$app]}"
    log_info "Installing $app..."

    if web2app "$app" "$url" "$icon_url"; then
        log_success "Successfully installed $app"
    else
        log_warn "Failed to install $app"
    fi
done

log_success "Web applications installation completed!"

if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$HOME/.local/share/applications"
fi
