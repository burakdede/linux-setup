#!/usr/bin/env bash
# Web App Installer Script
# This script installs various web applications as desktop apps using the web2app function

# Exit on error
set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the utils script to get the logging functions
UTILS_DIR="$SCRIPT_DIR/../utils"
source "$UTILS_DIR/utils.sh"

# Source the shared web apps configuration
source "$SCRIPT_DIR/config.sh"

# Source the .bash_aliases file to get the web2app function
BASHRC_DIR="$SCRIPT_DIR/../dotfiles"
if [ -f "$BASHRC_DIR/.bash_aliases" ]; then
    source "$BASHRC_DIR/.bash_aliases"
else
    log_error "Could not find .bash_aliases file"
    exit 1
fi

echo_header "Installing Web Applications"

# Ensure icons directory exists
ICON_DIR="$HOME/.local/share/applications/icons"
mkdir -p "$ICON_DIR"

# Install each web app
for app in "${!WEB_APPS[@]}"; do
    IFS=' ' read -r url icon_url <<< "${WEB_APPS[$app]}"
    log_info "Installing $app..."
    
    # Call the web2app function with the app details
    if web2app "$app" "$url" "$icon_url"; then
        log_success "Successfully installed $app"
    else
        log_warn "Failed to install $app"
    fi
    
    echo ""
done

log_success "Web applications installation completed!"

# Refresh desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$HOME/.local/share/applications"
fi
