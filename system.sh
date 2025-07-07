#!/usr/bin/env bash
# System Package Installer Script
# Fixed for modern Ubuntu with proper GPG key handling

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Source common functions first
source "utils.sh"

# Trap errors
trap handle_error ERR

# Directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Using logging functions from utils.sh

# Update system
echo_header "System Updates"
log_info "Updating system packages..."

if ! run_with_output sudo apt-get update && run_with_output sudo apt-get upgrade -y && run_with_output sudo apt-get autoremove -y; then
    log_warn "Some system updates may have failed"
fi

# Install Basic Utilities
echo_header "Install Basic Utilities"
log_info "Installing basic utilities..."

if ! run_with_output sudo apt-get install -y --no-install-recommends xclip ubuntu-restricted-extras curl wget gpg software-properties-common; then
    log_warn "Failed to install some basic utilities"
fi

# Install APT packages
echo_header "Installing APT Packages"
if [ -f apt-packages.txt ]; then
    log_info "Installing packages from apt-packages.txt..."
    
    while IFS= read -r package; do
        if [ -n "$package" ] && [[ ! $package =~ ^# ]]; then
            log_info "Installing APT package: $package"
            if ! sudo_run apt-get install -y --no-install-recommends "$package"; then
                log_warn "Failed to install APT package $package"
            fi
        fi
    done < apt-packages.txt
else
    log_warn "apt-packages.txt not found, skipping APT package installation"
fi

# Install Snap packages
echo_header "Installing Snap Packages"
if [ -f snap-packages.txt ]; then
    log_info "Installing packages from snap-packages.txt..."
    
    while IFS= read -r package; do
        if [ -n "$package" ] && [[ ! $package =~ ^# ]]; then
            log_info "Installing Snap package: $package"
            if ! sudo_run snap install "$package" --classic 2>/dev/null; then
                log_warn "Failed to install Snap package $package"
            fi
        fi
    done < snap-packages.txt
else
    log_warn "snap-packages.txt not found, skipping Snap package installation"
fi

# Install VS Code
echo_header "Installing VS Code"

if ! command_exists code; then
    log_info "Installing VS Code..."
    
    # Create keyrings directory if it doesn't exist
    run_with_output sudo mkdir -p /etc/apt/keyrings
    
    # Clean up any existing Microsoft repository configurations
    sudo rm -f /etc/apt/sources.list.d/vscode.list /etc/apt/sources.list.d/vscode.sources
    
    # Create keyrings directory if it doesn't exist
    run_with_output sudo mkdir -p /etc/apt/keyrings
    
    # Download and add Microsoft GPG key (modern method)
    if ! wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.gpg; then
        log_warn "Failed to download Microsoft GPG key"
        return 1
    fi
    
    # Add VS Code repository using the trusted keyring
    if ! echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null; then
        log_warn "Failed to add VS Code repository"
        return 1
    fi
    
    # Set correct permissions
    sudo chmod 644 /etc/apt/trusted.gpg.d/microsoft.gpg
    
    # Update and install VS Code
    if ! run_with_output sudo apt-get update || ! run_with_output sudo apt-get install -y code; then
        log_warn "Failed to install VS Code"
        return 1
    fi
    
    # Install VS Code extensions
    if ! command -v code &> /dev/null; then
        log_warn "VS Code not found after installation"
        return 1
    fi
    
    log_info "VS Code installed successfully!"
else
    log_info "VS Code is already installed"
fi

# Install VS Code extensions
echo_header "Installing VS Code Extensions"
if ! command_exists code; then
    log_warn "VS Code is not installed. Skipping extension installation."
else
    if [ -f vscode-extensions.txt ]; then
        log_info "Installing VS Code extensions..."
        
        # Create extensions directory
        mkdir -p "$HOME/.vscode/extensions" 2>/dev/null || true
        
        # Read and install each extension
        while IFS= read -r extension; do
            # Skip empty lines and comments
            if [ -z "$extension" ] || [[ $extension =~ ^# ]]; then
                continue
            fi
            
            # Skip if already installed (case-insensitive)
            if code --list-extensions | tr '[:upper:]' '[:lower:]' | grep -iq "$(echo "$extension" | tr '[:upper:]' '[:lower:]')"; then
                log_info "Extension '$extension' is already installed."
                continue
            fi
            
            # Install extension
            log_info "Installing extension: $extension"
            if ! code --install-extension "$extension" --force; then
                log_warn "Failed to install extension: $extension"
            fi
        done < vscode-extensions.txt
    else
        log_warn "vscode-extensions.txt not found, skipping extension installation"
    fi
fi

# Install Cursor
echo_header "Installing Cursor"
if ! command -v cursor &> /dev/null; then
    log_info "Installing Cursor AppImage..."
    
    # Install required dependencies
    if ! sudo apt-get install -y fuse3 libfuse2; then
        log_warn "Failed to install required dependencies"
        return 1
    fi

    # Download and install Cursor
    if ! curl -L "https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable" | \
        jq -r '.downloadUrl' | \
        xargs curl -L -o /tmp/cursor.appimage; then
        log_warn "Failed to download Cursor"
        return 1
    fi

    if ! sudo mv /tmp/cursor.appimage /opt/cursor.appimage || \
       ! sudo chmod +x /opt/cursor.appimage || \
       ! sudo ln -sf /opt/cursor.appimage /usr/local/bin/cursor; then
        log_warn "Failed to install Cursor"
        return 1
    fi

    # Create desktop entry
    DESKTOP_FILE="$HOME/.local/share/applications/cursor.desktop"
    ICON_DIR="$HOME/.local/share/icons"
    ICON_PATH="$ICON_DIR/cursor.png"
    
    # Create directories and download icon
    if ! mkdir -p "$HOME/.local/share/applications" "$ICON_DIR"; then
        log_warn "Failed to create necessary directories"
        return 1
    fi

    # Download icon
    if ! curl -L "https://github.com/basecamp/omakub/blob/8d641e981766b03ac326a383e947170e1357436e/applications/icons/cursor.png?raw=true" -o "$ICON_PATH"; then
        log_warn "Failed to download icon"
        return 1
    fi

    # Create desktop entry
    if ! echo -e "[Desktop Entry]\nName=Cursor\nComment=AI-powered code editor\nExec=/opt/cursor.appimage --no-sandbox\nIcon=$ICON_PATH\nType=Application\nCategories=Development;IDE;\nStartupWMClass=cursor\nTerminal=false" | tee "$DESKTOP_FILE" > /dev/null; then
        log_warn "Failed to create desktop entry"
        return 1
    fi

    # Update desktop database
    if ! update-desktop-database "$HOME/.local/share/applications"; then
        log_warn "Failed to update desktop database"
        return 1
    fi

    log_info "Cursor installed successfully!"

    if command -v gsettings &> /dev/null; then
        if ! gsettings set org.gnome.shell favorite-apps "['cursor.desktop']"; then
            log_warn "Failed to add Cursor to dock"
        fi
    fi
    
    log_info "Successfully created desktop entry and icon for Cursor"
    
    # Cleanup
    if [ -f /tmp/cursor.appimage ]; then
        rm -f /tmp/cursor.appimage
    fi
    
    log_info "Cursor installed successfully"
else
    log_info "Cursor is already installed"
fi

# Install Windsurf
echo_header "Installing Windsurf"
if ! command_exists windsurf; then
    log_info "Setting up Windsurf repository..."
    
    # Create keyrings directory
    sudo mkdir -p /etc/apt/keyrings
    
    # Download and add Windsurf GPG key
    if ! wget -qO- "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/windsurf-stable.gpg; then
        log_warn "Failed to add Windsurf GPG key"
        return 1
    fi
    
    # Add Windsurf repository
    if ! echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/windsurf-stable.gpg] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" | sudo tee /etc/apt/sources.list.d/windsurf.list > /dev/null; then
        log_warn "Failed to add Windsurf repository"
        return 1
    fi
    
    # Update and install Windsurf
    if ! sudo apt update || ! sudo apt install -y windsurf; then
        log_warn "Failed to install Windsurf"
        return 1
    fi
    
    log_info "Windsurf installed successfully!"
else
    log_info "Windsurf is already installed"
fi

# Install Google Chrome
echo_header "Installing Google Chrome"
if ! command_exists google-chrome; then
    log_info "Installing Google Chrome..."
    
    # Create keyrings directory
    sudo mkdir -p /etc/apt/keyrings
    
    # Download and add Google Chrome GPG key
    if ! wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg; then
        log_warn "Failed to add Google Chrome GPG key"
        return 1
    fi

    # Add Google Chrome repository
    if ! echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null; then
        log_warn "Failed to add Google Chrome repository"
        return 1
    fi

    # Update and install Google Chrome
    if ! sudo apt update || ! sudo apt install -y google-chrome-stable; then
        log_warn "Failed to install Google Chrome"
        return 1
    fi
    
    log_info "Google Chrome installed successfully!"
else
    log_info "Google Chrome is already installed"
fi

# Install JetBrains Toolbox following official guide
# https://www.jetbrains.com/help/toolbox-app/toolbox-app-silent-installation.html
echo_header "Installing JetBrains Toolbox"

if ! command_exists jetbrains-toolbox; then
    log_info "Setting up JetBrains Toolbox..."
    
    # Configuration
    INSTALL_DIR="$HOME/.local/share/JetBrains/Toolbox"
    DOWNLOAD_URL=$(curl -s 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' | \
        jq -r '.TBA[0].downloads.linux.link')
    
    if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
        log_warn "Failed to get download URL from JetBrains"
        return 1     
    fi

    # Prepare installation directory
    if [ -d "$INSTALL_DIR" ]; then
        log_info "Cleaning up existing installation..."
        if ! rm -rf "$INSTALL_DIR"/*; then
            log_warn "Failed to clean up existing installation"
            return 1
        fi
    else
        if ! mkdir -p "$INSTALL_DIR"; then
            log_warn "Failed to create installation directory"
            return 1
        fi
    fi

    # Download and extract
    log_info "Downloading JetBrains Toolbox..."
    if ! wget -q "$DOWNLOAD_URL" -O "$INSTALL_DIR/jetbrains-toolbox.tar.gz" || \
       ! tar -xzf "$INSTALL_DIR/jetbrains-toolbox.tar.gz" -C "$INSTALL_DIR"; then
        log_warn "Failed to download or extract JetBrains Toolbox"
        return 1
    fi

    # Find extracted directory
    EXTRACTED_DIR=$(find "$INSTALL_DIR" -name "jetbrains-toolbox-*" -type d | head -1)
    if [ -z "$EXTRACTED_DIR" ]; then
        log_warn "Failed to find extracted directory"
        return 1
    fi

    # Install files
    if ! cp -r "$EXTRACTED_DIR"/* "$INSTALL_DIR/" || \
       ! sudo ln -sf "$INSTALL_DIR/bin/jetbrains-toolbox" "/usr/local/bin/jetbrains-toolbox"; then
        log_warn "Failed to install JetBrains Toolbox"
        return 1
    fi

    # Cleanup
    if ! rm -rf "$EXTRACTED_DIR" "$INSTALL_DIR/jetbrains-toolbox.tar.gz"; then
        log_warn "Failed to clean up installation files"
        return 1
    fi

    # Verify and run
    if ! command -v jetbrains-toolbox &> /dev/null || ! jetbrains-toolbox --version &> /dev/null; then
        log_warn "Failed to verify JetBrains Toolbox installation"
        return 1
    fi

    jetbrains-toolbox &
    sleep 5

    # Create desktop entry
    DESKTOP_FILE="$HOME/.local/share/applications/jetbrains-toolbox.desktop"
    if ! mkdir -p "$HOME/.local/share/applications"; then
        log_warn "Failed to create applications directory"
        return 1
    fi

    if ! echo -e "[Desktop Entry]\nName=JetBrains Toolbox\nComment=JetBrains IDE Manager\nExec=$INSTALL_DIR/bin/jetbrains-toolbox\nIcon=$INSTALL_DIR/bin/toolbox.svg\nType=Application\nCategories=Development;IDE;\nTerminal=false\nStartupWMClass=jetbrains-toolbox" | tee "$DESKTOP_FILE" > /dev/null; then
        log_warn "Failed to create desktop entry"
        return 1
    fi

    # Update desktop database
    if ! update-desktop-database "$HOME/.local/share/applications"; then
        log_warn "Failed to update desktop database"
        return 1
    fi

    # Add to dock if possible
    if command -v gsettings &> /dev/null; then
        if ! gsettings set org.gnome.shell favorite-apps "['jetbrains-toolbox.desktop']"; then
            log_warn "Failed to add JetBrains Toolbox to dock"
            return 1
        fi
    fi

    log_info "JetBrains Toolbox installed successfully!"
    log_info "It has been installed to $INSTALL_DIR/bin"
    log_info "The icon should appear in your main menu automatically"
    log_info "Please log in to your JetBrains Account to activate licenses"
else
    log_info "JetBrains Toolbox is already installed"
fi


# Install Spotify
echo_header "Installing Spotify"
if ! command_exists spotify; then
    log_info "Installing Spotify..."
    
    # Download and add Spotify GPG key (using official method)
    if ! curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg; then
        log_error "Failed to add Spotify GPG key"
        exit 1
    fi
    
    # Add Spotify repository
    if ! echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list > /dev/null; then
        log_error "Failed to add Spotify repository"
        exit 1
    fi
    
    # Update and install Spotify
    if ! sudo apt-get update || ! sudo apt-get install -y spotify-client; then
        log_error "Failed to install Spotify"
        exit 1
    fi
    
    log_info "Spotify installed successfully!"
else
    log_info "Spotify is already installed"
fi

# Install LastPass
echo_header "Installing LastPass"
if ! command -v lastpass-cli &> /dev/null; then
    log_info "Installing LastPass..."
    
    # Download and install LastPass CLI
    if ! sudo apt-get install -y lastpass-cli; then
        log_error "Failed to install LastPass CLI"
        exit 1
    fi
    
    # Create temp directory for LastPass installation
    LASTPASS_TEMP_DIR=$(mktemp -d)
    cd "$LASTPASS_TEMP_DIR"
    
    # Download and install LastPass Desktop
    LASTPASS_URL="https://download.cloud.lastpass.com/linux/lplinux.tar.bz2"
    LASTPASS_FILE="lplinux.tar.bz2"
    
    log_info "Downloading LastPass desktop package..."
    if ! wget -q "$LASTPASS_URL" -O "$LASTPASS_FILE"; then
        log_error "Failed to download LastPass desktop package"
        exit 1
    fi
    
    log_info "Extracting LastPass package..."
    if ! tar xjvf "$LASTPASS_FILE"; then
        log_error "Failed to extract LastPass package"
        exit 1
    fi
    
    log_info "Running LastPass installation script..."
    if ! ./install_lastpass.sh; then
        log_error "Failed to run LastPass installation script"
        exit 1
    fi
    
    # Clean up
    rm -f "$LASTPASS_FILE"
    rm -f install_lastpass.sh
    cd - > /dev/null
    rm -rf "$LASTPASS_TEMP_DIR"
    
    log_info "LastPass installed successfully!"
    log_info "You can now launch LastPass from your applications menu"
else
    log_info "LastPass is already installed"
fi

# Verify installations
echo_header "Verification"
log_info "Verifying installations..."

INSTALLED_APPS=()
FAILED_APPS=()

for app in code spotify google-chrome cursor windsurf jetbrains-toolbox lpass; do
    if command_exists "$app"; then
        INSTALLED_APPS+=("$app")
        log_info "✓ $app is installed"
    else
        FAILED_APPS+=("$app")
        log_warn "✗ $app is not installed"
    fi
done

# Summary
echo_header "Installation Summary"
log_info "Successfully installed: ${#INSTALLED_APPS[@]} applications"
if [ ${#FAILED_APPS[@]} -gt 0 ]; then
    log_warn "Failed to install: ${FAILED_APPS[*]}"
fi

log_info "System package installation completed!"
log_info "You may need to restart your system or log out and back in for some applications to work properly."
