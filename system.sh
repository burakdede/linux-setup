#!/usr/bin/env bash
# System Package Installer Script

# Exit on error
set -e

# Source common functions
source "utils.sh"

# Directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Update system
echo_header "System Updates"
if ! sudo apt-get update || sudo apt-get upgrade -y || sudo apt-get autoremove -y; then
    echo "Error: Failed to update system packages"
    exit 1
fi

# Install Basic Utilities
echo_header "Install Basic Utilities"
if ! sudo apt-get install -y --no-install-recommends xclip ubuntu-restricted-extras; then
    echo "Error: Failed to install basic utilities"
    exit 1
fi

# Install APT packages
echo_header "Installing APT Packages"
if [ -f apt-packages.txt ]; then
    while IFS= read -r package; do
        if [ -n "$package" ] && [[ ! $package =~ ^# ]]; then
            echo "Installing APT package: $package"
            if ! sudo apt-get install -y --no-install-recommends "$package"; then
                echo "Warning: Failed to install APT package $package"
            fi
        fi
    done < apt-packages.txt
fi

# Install Snap packages
echo_header "Installing Snap Packages"
if [ -f snap-packages.txt ]; then
    while IFS= read -r package; do
        if [ -n "$package" ] && [[ ! $package =~ ^# ]]; then
            echo "Installing Snap package: $package"
            if ! sudo snap install "$package" --classic 2>/dev/null; then
                echo "Warning: Failed to install Snap package $package"
            fi
        fi
    done < snap-packages.txt
fi

# Install VS Code
echo_header "Installing VS Code"
if ! command -v code &> /dev/null; then
    echo "Setting up VS Code repository"
    if ! sudo apt-get install -y wget gpg || \
       wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg || \
       sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings || \
       sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' || \
       sudo apt update || sudo apt install -y --no-install-recommends code; then
        echo "Error: Failed to install VS Code"
        exit 1
    fi
fi

# Install Cursor
echo_header "Installing Cursor"
if ! command -v cursor &> /dev/null; then
    echo "Installing Cursor AppImage..."
    if ! wget -q "https://github.com/cursor-editor/cursor/releases/download/latest/cursor.AppImage" -O /tmp/cursor.AppImage || \
       chmod +x /tmp/cursor.AppImage || \
       sudo mv /tmp/cursor.AppImage /usr/local/bin/cursor || \
       sudo ln -sf /usr/local/bin/cursor /usr/share/applications/cursor.desktop; then
        echo "Warning: Failed to install Cursor"
    fi
else
    echo "Cursor is already installed"
fi

# Install Windsurf
echo_header "Installing Windsurf"
if ! command -v windsurf &> /dev/null; then
    echo "Setting up Windsurf repository"
    if ! sudo apt-get install -y wget gpg || \
       wget -qO- "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | gpg --dearmor > windsurf-stable.gpg || \
       sudo install -D -o root -g root -m 644 windsurf-stable.gpg /etc/apt/keyrings/windsurf-stable.gpg || \
       echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/windsurf-stable.gpg] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" | sudo tee /etc/apt/sources.list.d/windsurf.list > /dev/null || \
       rm -f windsurf-stable.gpg; then
        echo "Error: Failed to set up Windsurf repository"
        exit 1
    fi

    echo "Installing required packages"
    if ! sudo apt install -y apt-transport-https || \
       sudo apt update; then
        echo "Error: Failed to install required packages"
        exit 1
    fi

    echo "Installing Windsurf..."
    if ! sudo apt install -y windsurf; then
        echo "Warning: Failed to install Windsurf"
    fi
else
    echo "Windsurf is already installed"
fi

# Install Ulauncher
echo_header "Installing Ulauncher"
if ! command -v ulauncher &> /dev/null; then
    echo "Adding Ulauncher repository"
    if ! sudo add-apt-repository universe -y || \
       sudo add-apt-repository ppa:agornostal/ulauncher -y || \
       sudo apt update || \
       sudo apt install -y ulauncher; then
        echo "Warning: Failed to install Ulauncher"
    fi
else
    echo "Ulauncher is already installed"
fi

# Install Database Systems
echo_header "Installing Database Systems"
for db in postgresql mysql-server; do
    if ! sudo apt install -y --no-install-recommends "$db" || ! sudo systemctl start "${db%.server}".service; then
        echo "Warning: Failed to install/start $db"
    fi
    # Check if service is running
    if ! sudo systemctl is-active --quiet "${db%.server}".service; then
        echo "Warning: $db service is not running"
    fi
    # Verify database version
    if command -v "${db%.server}" &> /dev/null; then
        version=$(${db%.server} --version 2>/dev/null || echo "Unknown")
        echo "${db%.server} version: $version"
    fi
done

# Install JetBrains Toolbox
echo_header "Installing JetBrains Toolbox"
if ! command -v jetbrains-toolbox &> /dev/null; then
    echo "Downloading JetBrains Toolbox..."
    if ! wget -q "https://download.jetbrains.com/toolbox/jetbrains-toolbox-1.27.1.17047.tar.gz" -O /tmp/jetbrains-toolbox.tar.gz; then
        echo "Error: Failed to download JetBrains Toolbox"
        exit 1
    fi
    
    echo "Extracting JetBrains Toolbox..."
    if ! tar -xzf /tmp/jetbrains-toolbox.tar.gz -C /tmp; then
        echo "Error: Failed to extract JetBrains Toolbox"
        exit 1
    fi
    
    echo "Installing JetBrains Toolbox..."
    if ! sudo mv /tmp/jetbrains-toolbox-*/jetbrains-toolbox /usr/local/bin/; then
        echo "Error: Failed to move JetBrains Toolbox to system path"
        exit 1
    fi
    
    echo "Cleaning up..."
    rm -rf /tmp/jetbrains-toolbox* 2>/dev/null
    
    echo "JetBrains Toolbox installed successfully!"
    echo "You can run it with: jetbrains-toolbox"
else
    echo "JetBrains Toolbox is already installed"
fi

# Install Consul
echo_header "Installing Consul"
if ! wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg || \
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list || \
   sudo apt update || sudo apt install -y --no-install-recommends consul; then
    echo "Warning: Failed to install Consul"
fi

# Install Spotify
echo_header "Installing Spotify"
if ! curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg || \
   echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list || \
   sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7A3A762FAFD4A51F || \
   sudo apt-get update || sudo apt-get install -y --no-install-recommends spotify-client; then
    echo "Warning: Failed to install Spotify"
fi

# Verify installations
echo_header "Verification"
for cmd in code spotify consul; do
    if ! verify_tool_version "$cmd"; then
        echo "Warning: $cmd is not installed"
    fi
done

echo "System package installation completed successfully!"
