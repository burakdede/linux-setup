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

# Copy dotfiles
echo_header "Installing Dotfiles"
for file in "dotfiles"/*; do
    filename="$(basename "$file")"
    if [ "$filename" != "install.sh" ]; then
        echo "Copying $filename to ~/$filename"
        cp -f "$file" "~/$filename"
    fi
done

# Verify installation
echo_header "Final Verification"
for cmd in code spotify consul; do
    if command -v "$cmd" &> /dev/null; then
        echo "$cmd is installed successfully"
    else
        echo "Warning: $cmd is not installed"
    fi
done

echo ""
echo "Setup completed successfully!"
echo "Note: Some changes may require a logout/restart to take effect."
echo "You may want to restart your terminal session to apply all changes."
