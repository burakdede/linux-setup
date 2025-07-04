#!/usr/bin/env bash
# SDKMAN Installation and Configuration Script

# Exit on error
set -e

# Source common functions
source "utils.sh"

# Check if Java is installed
echo_header "Checking Java Installation"
if ! check_command "java"; then
    echo "Warning: Java is not installed. Some SDKs may require Java."
fi

# Check if SDKMAN is already installed
echo_header "Checking SDKMAN Installation"
if [ -d "$HOME/.sdkman" ]; then
    echo "SDKMAN is already installed"
    source "$HOME/.sdkman/bin/sdkman-init.sh"
else
    echo "Installing SDKMAN"
    if ! curl -s "https://get.sdkman.io" | bash; then
        echo "Error: Failed to install SDKMAN"
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
echo_header "Installing Development Tools"
for tool in maven gradle java groovy scala kotlin springboot grails visualvm sbt; do
    echo "Installing $tool..."
    if ! sdk install "$tool" 2>/dev/null; then
        echo "Warning: Failed to install $tool"
    fi
    # Check if tool is installed and current
    if sdk current "$tool" &> /dev/null; then
        echo "$tool is installed and current"
    else
        echo "$tool installation failed or not current"
    fi
done

# Verify installations
echo_header "Verification"
echo "Installed SDKMAN tools:"
sdk list | grep -v "\--"

# Show usage instructions
echo ""
echo "SDKMAN setup completed!"
echo "To use the installed tools, add the following line to your ~/.bashrc:"
echo "source "$HOME/.sdkman/bin/sdkman-init.sh""
echo "Then restart your terminal or run: source ~/.bashrc"

# Check if SDKMAN is properly initialized
echo_header "Checking SDKMAN Initialization"
if ! command -v sdk &> /dev/null; then
    echo "Warning: SDKMAN is not properly initialized"
    echo "Please add the following line to your ~/.bashrc:"
    echo "source "$HOME/.sdkman/bin/sdkman-init.sh""
    echo "Then restart your terminal or run: source ~/.bashrc"
fi
