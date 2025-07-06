#!/usr/bin/env bash
# Ubuntu Developer Machine Setup Orchestration Script

# Exit on error
set -e

# Source common functions
source "utils.sh"

echo_header "Starting Ubuntu Developer Machine Setup"

echo_header "Checking Prerequisites"
check_root
check_directory
check_system_prerequisites

echo_header "Starting Main Installation"

# Install system packages and configurations
bash system.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Copy and source dotfiles
echo_header "Installing and Sourcing Dotfiles"

# Check if dotfiles directory exists
if [ ! -d "dotfiles" ]; then
    log_error "dotfiles directory not found"
    exit 1
fi

# Enable dotglob to match hidden files (dotfiles)
shopt -s dotglob

# Check if dotfiles directory has any files
if [ -z "$(ls -A dotfiles/ 2>/dev/null)" ]; then
    log_info "dotfiles directory is empty"
    shopt -u dotglob  # Reset dotglob
    exit 0
fi

for file in dotfiles/*; do
    # Skip if no files match (in case of empty directory)
    [ -e "$file" ] || continue
    
    filename="$(basename "$file")"
    echo "Copying and sourcing $filename"
    cp -f "$file" "$HOME/$filename"
    # Source the file if it's a shell configuration file
    case "$filename" in
        .bashrc|.bash_profile|.zshrc|.profile|.pam_environment|.bash_aliases|.inputrc)
            echo "Sourcing $filename"
            source "$HOME/$filename"
            ;;
        *)
            echo "Not sourcing $filename (not a shell config file)"
            ;;
    esac
done

# Reset dotglob to its original state
shopt -u dotglob

log_info "Dotfiles installation completed!"

# Install SDKMAN and development tools
if [ -f sdk.sh ]; then
    echo_header "Installing SDKMAN and Development Tools"
    bash sdk.sh
else
    echo "Warning: sdk.sh not found. Skipping SDKMAN installation."
fi

# Setup GitHub SSH key
if [ -f git.sh ]; then
    echo_header "Setting up GitHub SSH Key"
    bash git.sh
else
    echo "Warning: git.sh not found. Skipping GitHub SSH key setup."
fi

# Configure Ubuntu settings
if [ -f settings.sh ]; then
    echo_header "Configuring Ubuntu Settings"
    bash settings.sh
else
    echo "Warning: settings.sh not found. Skipping Ubuntu settings configuration."
fi


echo ""
echo "Setup completed successfully!"
echo "Note: Some changes may require a logout/restart to take effect."
echo "You may want to restart your terminal session to apply all changes."
