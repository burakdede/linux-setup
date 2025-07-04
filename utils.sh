#!/usr/bin/env bash

# Common utility functions for setup scripts

# Function to log messages with header
echo_header() {
    echo ""
    echo "${1}"
    echo "$(printf '=%.0s' {1..${#1}})"
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then 
        echo "Error: Please run this script as a normal user, not root"
        exit 1
    fi
}

# Function to check if in correct directory
check_directory() {
    if [ ! -f "run.sh" ]; then
        echo "Error: Please run this script from the project root directory"
        exit 1
    fi
}

# Function to verify command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed"
        exit 1
    fi
}

# Function to verify file exists
check_file() {
    if [ ! -f "$1" ]; then
        echo "Warning: $1 not found"
        return 1
    fi
    return 0
}

# Function to verify directory exists
check_dir() {
    if [ ! -d "$1" ]; then
        echo "Warning: Directory $1 not found"
        return 1
    fi
    return 0
}

# Function to verify package installation
verify_package() {
    if ! dpkg -l | grep -q "$1"; then
        echo "Warning: $1 is not installed"
        return 1
    fi
    return 0
}

# Function to verify snap package installation
verify_snap() {
    if ! snap list | grep -q "$1"; then
        echo "Warning: Snap package $1 is not installed"
        return 1
    fi
    return 0
}

# Function to verify tool version
verify_tool_version() {
    if ! command -v "$1" &> /dev/null; then
        echo "Warning: $1 is not installed"
        return 1
    fi
    version=$($1 --version 2>/dev/null || echo "Unknown")
    echo "$1 version: $version"
    return 0
}

# Function to install a package if missing
install_package() {
    if ! verify_package "$1"; then
        echo "Installing $1..."
        if ! sudo apt-get install -y "$1"; then
            echo "Error: Failed to install $1"
            exit 1
        fi
    fi
}

# Function to install a snap package if missing
install_snap() {
    if ! verify_snap "$1"; then
        echo "Installing snap package $1..."
        if ! sudo snap install "$1" --classic 2>/dev/null; then
            echo "Warning: Failed to install snap package $1"
        fi
    fi
}

# Function to check system prerequisites and install missing ones
check_system_prerequisites() {
    echo_header "Checking System Prerequisites"
    
    # Check essential system tools
    for tool in apt apt-get sudo dpkg; do
        if ! check_command "$tool"; then
            echo "Error: Essential system tool $tool is missing"
            exit 1
        fi
    done
    
    # Check SSH tools and install if missing
    for tool in openssh-client openssh-server; do
        install_package "$tool"
    done
    
    # Check basic utilities and install if missing
    for tool in xclip; do
        install_package "$tool"
    done
    
    # Install other required packages
    install_package "ubuntu-restricted-extras"
    install_package "curl"
    install_package "wget"
    
    # Verify installations
    echo_header "Verifying Prerequisites"
    for tool in ssh-keygen ssh ssh-agent xclip; do
        if ! check_command "$tool"; then
            echo "Warning: $tool is still missing after installation attempt"
        fi
    done
    
    echo "System prerequisites check and installation completed"
}
