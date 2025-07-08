#!/usr/bin/env bash
# SDKMAN Installation and Configuration Script

# Exit on error
set -e

# Directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/../utils/utils.sh"

# Check if Java is installed
echo_header "Checking Java Installation"
if ! check_command "java"; then
    log_warn "Java is not installed. Some SDKs may require Java."
fi

# Check if SDKMAN is already installed
echo_header "Checking SDKMAN Installation"
if [ -d "$HOME/.sdkman" ]; then
    log_info "SDKMAN is already installed."
    source "$HOME/.sdkman/bin/sdkman-init.sh"
else
    log_info "Installing SDKMAN..."
    if ! curl -s "https://get.sdkman.io" | bash; then
        log_error "Failed to install SDKMAN."
        exit 1
    fi
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Update SDKMAN
echo_header "Updating SDKMAN"
sdk version
sdk selfupdate
sdk update

# Install development tools
echo_header "Installing Development Tools from packages.txt"
for tool in $(cat "$SCRIPT_DIR/packages.txt"); do
    log_info "Installing $tool..."
    if ! sdk install "$tool" 2>/dev/null; then
        log_warn "Failed to install $tool."
    fi
    # Check if tool is installed and current
    if sdk current "$tool" &> /dev/null; then
        log_success "$tool is installed and current."
    else
        log_error "$tool installation failed or not current."
    fi
done

# Verify installations
echo_header "Verification"
log_info "Installed SDKMAN tools:"
sdk list | grep -v "\--"

# Show usage instructions
log_success "SDKMAN setup completed!"
log_info "To use the installed tools, add the following line to your ~/.bashrc:"
log_info "source \"$HOME/.sdkman/bin/sdkman-init.sh\""
log_info "Then restart your terminal or run: source ~/.bashrc"

# Check if SDKMAN is properly initialized
echo_header "Checking SDKMAN Initialization"
if ! command -v sdk &> /dev/null; then
    log_warn "SDKMAN is not properly initialized."
    log_warn "Please add the following line to your ~/.bashrc:"
    log_warn "source \"$HOME/.sdkman/bin/sdkman-init.sh\""
    log_warn "Then restart your terminal or run: source ~/.bashrc"
fi
